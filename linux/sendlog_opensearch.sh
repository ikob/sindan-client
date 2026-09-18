#!/bin/bash
# sendlog_opensearch.sh
#
# Push SINDAN's Wi-Fi datalink-environment logs to OpenSearch, storing each
# neighbour AP as ONE document matching perfSONAR's own "prometheus_node"
# exporter schema:  values.<metric>.val (float) + meta.labels.<label> + @timestamp.
# This lets the same Grafana query style (Metric=Average of a values.*.val
# field, Group By Terms on meta.labels.*.keyword, Then By Date Histogram on
# @timestamp) be reused verbatim from the existing host-metrics dashboards.
#
# This is a push-based replacement for sendlog.sh, limited to the
# "wlan_environment" data type. It writes DIRECTLY to the OpenSearch REST
# API (_bulk) into a dedicated sindan-* index. It intentionally does NOT go
# through perfSONAR's /logstash pipeline (that pipeline parses pScheduler
# results, not our schema) and does NOT touch perfSONAR-managed indices.
#
# Correlation with perfSONAR happens in Grafana (add this OpenSearch index as
# a second data source), not in storage.
#
# Required additions to sindan.conf:
#   OS_URL=https://172.27.160.35/opensearch  # OpenSearch REST endpoint (NOT /logstash)
#   OS_INDEX_PREFIX=sindan-wifi         # optional; default sindan-wifi
#   OS_AUTH=user:pass                   # Basic auth; empty if IP-whitelisted
#   OS_INSECURE=yes                     # 'yes' for self-signed TLS (curl -k)
#   PROM_HOST=                          # optional 'host' label; default $(hostname)
#
# NOTE: reachability + auth to the OpenSearch REST API is the deployment
# prerequisite to confirm on the perfSONAR host (the "no auth" ingestion path
# documented for perfSONAR is /logstash, which is a different endpoint).
#
# version 0.1

set -u

cd "$(dirname "$0")" || exit 1
# shellcheck disable=SC1091
. ./sindan.conf

OS_URL="${OS_URL:-}"                            # e.g. https://172.27.160.35/opensearch
OS_INDEX_PREFIX="${OS_INDEX_PREFIX:-sindan-wifi}"
OS_AUTH="${OS_AUTH:-}"
OS_INSECURE="${OS_INSECURE:-no}"                # 'yes' adds curl -k (self-signed TLS)
PROM_HOST="${PROM_HOST:-$(hostname)}"
LOCKFILE="${LOCKFILE_SENDLOG_OS:-/tmp/sindan_sendlog_os.lock}"

if [ -z "$OS_URL" ]; then
  echo "ERROR: OS_URL is not set in sindan.conf." 1>&2
  exit 1
fi
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required." 1>&2; exit 1; }

# --- single-run guard (same convention as sendlog.sh) ----------------------
trap 'rm -f "$LOCKFILE"; exit 0' INT TERM
if [ -e "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE" 2>/dev/null)" 2>/dev/null; then
  exit 0
fi
echo $$ > "$LOCKFILE"

# --- curl options (proxy / auth), same style as sendlog.sh -----------------
curl_opts=(--max-time 30 -s)
[ -n "${PROXY_URL:-}" ]   && curl_opts+=(--proxy "$PROXY_URL")
[ -n "$OS_AUTH" ]         && curl_opts+=(-u "$OS_AUTH")
[ "$OS_INSECURE" = "yes" ] && curl_opts+=(-k)

# jq: one wlan_environment doc -> OpenSearch _bulk ndjson (2 lines per AP).
# detail is the CSV emitted by get_wlan_environment(); row 0 is the header
#   BSSID,SSID,Mode,Band,Channel,Bandwidth,Security,RSSI
# RSSI (a gauge) becomes values.sindan_wifi_neighbor_rssi_dbm.val; the rest
# become meta.labels.* -- mirroring perfSONAR's prometheus_node docs so the
# same Grafana panels apply. _id = campaign+bssid makes re-sends idempotent.
# NOTE: campaign_uuid is deliberately NOT a label. This is a STATIONARY
# observation point (a fixed Wi-Fi sensor), so the series is defined by the
# stable instance ($host = PROM_HOST) + bssid over time -- exporter/Prometheus
# style. campaign is unique per run (a mobile-SINDAN "trip" concept); as a
# label it would explode series cardinality. It stays only in _id (not a
# label) to keep re-sends idempotent.
read -r -d '' JQ_PROG <<'JQ'
. as $d
| (($d.occurred_at | sub(" ";"T")) + "Z") as $ts_iso
| ($d.detail | split("\n"))[1:]
| map(select(length > 0) | split(","))
| .[]
| { bssid:.[0], ssid:.[1], mode:.[2], band:.[3], channel:.[4],
    bandwidth:.[5], security:.[6], rssi:(.[7] | tonumber? // null) }
| select(.rssi != null and .bssid != "" and .bssid != null)
| { index: { _index: $index, _id: ($d.log_campaign_uuid + "_" + .bssid) } },
  { "@timestamp": $ts_iso,
    meta: {
      id: $host,
      labels: {
        host: $host,
        iftype: $d.log_group,
        bssid: .bssid, ssid: .ssid, band: .band, channel: .channel,
        bandwidth: .bandwidth, security: .security, mode: .mode } },
    values: { "sindan_wifi_neighbor_rssi_dbm": { val: .rssi } } }
JQ

sent=0; kept=0
for f in log/sindan_*_wlan_environment_*.json; do
  [ -e "$f" ] || continue

  base=$(basename "$f" .json)
  epoch=${base##*_}                              # trailing epoch from the filename
  day=$(jq -rn --argjson e "${epoch:-0}" '$e | gmtime | strftime("%Y.%m.%d")' 2>/dev/null)
  [ -z "$day" ] && day=$(date -u '+%Y.%m.%d')
  index="${OS_INDEX_PREFIX}-${day}"

  # write_json embeds the CSV in "detail" with RAW newlines, which is invalid
  # JSON (control chars must be escaped). Fold physical newlines to \n first so
  # jq can parse it, then run the transform.
  ndjson=$(awk 'NR==1{printf "%s",$0; next}{printf "\\n%s",$0}' "$f" \
           | jq -c --arg host "$PROM_HOST" --arg index "$index" "$JQ_PROG" 2>/dev/null)
  if [ -z "$ndjson" ]; then
    # empty scan, or LOCAL_NETWORK_PRIVACY=yes replaced detail with 'XXX'
    echo "warn: no neighbour rows in $f (privacy on, or empty scan) -- kept" 1>&2
    kept=$((kept + 1)); continue
  fi

  out=$(printf '%s\n' "$ndjson" | curl "${curl_opts[@]}" \
        -H 'Content-Type: application/x-ndjson' \
        -w $'\n%{http_code}' \
        --data-binary @- "$OS_URL/_bulk")
  code=${out##*$'\n'}
  body=${out%$'\n'*}

  if [ "$code" = "200" ] && [ "$(printf '%s' "$body" | jq -r '.errors' 2>/dev/null)" = "false" ]; then
    rm -f "$f"; sent=$((sent + 1))
  else
    echo "warn: bulk ingest failed for $f (HTTP $code) -- kept" 1>&2
    kept=$((kept + 1))
  fi
done

rm -f "$LOCKFILE"
echo "sendlog_opensearch: sent=$sent kept=$kept"
exit 0
