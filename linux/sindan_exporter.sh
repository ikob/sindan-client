#!/bin/bash
# sindan_exporter.sh
#
# Prometheus exporter for SINDAN's non-aggressive Wi-Fi measurements, in the
# node_exporter "textfile collector" style: one run = one collection, written
# atomically to <TEXTFILE_DIR>/sindan_wifi.prom. Expose that directory with
# node_exporter (--collector.textfile.directory=<TEXTFILE_DIR>) or any static
# file server. Collection is separate from transport, so how the metrics get
# past NAT (PushProx, agent remote_write, ...) is decided outside this script.
#
# Neighbour list: first read the kernel's BSS cache ("iw dev <if> scan dump";
# entries expire ~30s after they were last seen), so a scan just done by
# sindan.sh or the OS is reused. Only if the cache is empty is a real scan
# triggered (timeout-guarded, see get_wlan_environment). Run this script
# periodically (e.g. every 600s): the run interval is the upper bound on how
# often it triggers a real scan.
#
# No explicit timestamps are written (Prometheus convention: samples take the
# scrape time). sindan_wifi_scan_timestamp_seconds carries the time of the last
# successful collection so stale data can be detected and alerted on.
#
# The identity of the observation point comes from the scrape target
# (instance label), so no host label is emitted here.
#
# Environment:
#   WLAN_IF=wlan0                    Wi-Fi interface
#   TEXTFILE_DIR=/tmp/sindan-metrics output directory
#   WLAN_SCAN_TIMEOUT=30             real-scan timeout in seconds
#
# version 0.1

set -u

cd "$(dirname "$0")" || exit 1
# shellcheck disable=SC1091
. ./sindan_func1.sh

WLAN_IF="${WLAN_IF:-wlan0}"
TEXTFILE_DIR="${TEXTFILE_DIR:-/tmp/sindan-metrics}"
OUT="$TEXTFILE_DIR/sindan_wifi.prom"

mkdir -p "$TEXTFILE_DIR" || exit 1

with_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout -k 5 "$@"
  else
    shift; "$@"
  fi
}

# --- collect -----------------------------------------------------------------
# Rows are tab-separated so SSIDs containing commas stay intact (iw escapes
# non-printable characters such as tab in SSIDs).
TAB=$'\t'
triggered=0
rows=$(with_timeout 10 iw dev "$WLAN_IF" scan dump 2>/dev/null | parse_wlan_scan "$TAB")
if [ -z "$rows" ]; then
  triggered=1
  rows=$(with_timeout "${WLAN_SCAN_TIMEOUT:-30}" iw dev "$WLAN_IF" scan 2>/dev/null \
         | parse_wlan_scan "$TAB")
fi

# --- render ------------------------------------------------------------------
now=$(date -u '+%s')
# Keep the previous success time when this collection failed.
last_ok=$(awk '/^sindan_wifi_scan_timestamp_seconds/ {print $NF}' "$OUT" 2>/dev/null)

tmp=$(mktemp "$TEXTFILE_DIR/.sindan_wifi.prom.XXXXXX") || exit 1
trap 'rm -f "$tmp"' EXIT

printf '%s\n' "$rows" | awk -F'\t' -v ifname="$WLAN_IF" -v triggered="$triggered" \
                            -v now="$now" -v last_ok="${last_ok:-}" '
# Label escaping. Backslashes are doubled with "&&" (the match, twice): a
# "\\\\" replacement yields a single backslash in mawk, which left the \xNN
# that iw prints (e.g. hidden SSIDs) as an invalid escape and node_exporter
# dropped the file. (No apostrophes here: this program is single-quoted.)
function esc(v) { gsub(/\\/, "&&", v); gsub(/"/, "\\\"", v); return v }
BEGIN {
  print "# HELP sindan_wifi_neighbor_rssi_dbm RSSI of a neighbour AP in the latest Wi-Fi scan."
  print "# TYPE sindan_wifi_neighbor_rssi_dbm gauge"
  n = 0
}
# BSSID SSID Mode Band Channel Bandwidth Security RSSI
$1 != "" && $8 ~ /^-?[0-9]+(\.[0-9]+)?$/ {
  printf "sindan_wifi_neighbor_rssi_dbm{ifname=\"%s\",bssid=\"%s\",ssid=\"%s\",mode=\"%s\",band=\"%s\",channel=\"%s\",bandwidth=\"%s\",security=\"%s\"} %s\n", \
         esc(ifname), esc($1), esc($2), esc($3), esc($4), esc($5), esc($6), esc($7), $8
  n++
}
END {
  ok = (n > 0) ? 1 : 0
  ts = ok ? now : last_ok
  print "# HELP sindan_wifi_neighbors Number of neighbour APs in the latest Wi-Fi scan."
  print "# TYPE sindan_wifi_neighbors gauge"
  printf "sindan_wifi_neighbors{ifname=\"%s\"} %d\n", esc(ifname), n
  print "# HELP sindan_wifi_scan_success 1 if the latest collection returned neighbour APs."
  print "# TYPE sindan_wifi_scan_success gauge"
  printf "sindan_wifi_scan_success{ifname=\"%s\"} %d\n", esc(ifname), ok
  print "# HELP sindan_wifi_scan_triggered 1 if the latest collection had to trigger a real scan (BSS cache was empty)."
  print "# TYPE sindan_wifi_scan_triggered gauge"
  printf "sindan_wifi_scan_triggered{ifname=\"%s\"} %d\n", esc(ifname), triggered
  if (ts != "") {
    print "# HELP sindan_wifi_scan_timestamp_seconds Unix time of the last successful collection."
    print "# TYPE sindan_wifi_scan_timestamp_seconds gauge"
    printf "sindan_wifi_scan_timestamp_seconds{ifname=\"%s\"} %s\n", esc(ifname), ts
  }
}' > "$tmp" || exit 1

chmod 644 "$tmp"
mv -f "$tmp" "$OUT"
exit 0
