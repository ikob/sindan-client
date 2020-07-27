#!/biADD speedtest
do_speedtest () {
  if [ $# -ne 1 ]; then
    echo "ERROR: do_speedtest <target_url>." 1>&2
    return 1
  fi

  node speedtest.js "$1"
  return $?
}

get_speedtest_ipv6_rtt () {
  echo "$1" | grep 'IPv6_RTT:'| sed -n 's/IPv6_RTT://p'
  return $?
}

get_speedtest_ipv6_jit () {
  echo "$1"  | grep 'IPv6_JIT:'| sed -n 's/IPv6_JIT://p'
  return $?
}

get_speedtest_ipv6_dl () {
  echo "$1"  | grep 'IPv6_DL:'| sed -n 's/IPv6_DL://p'
  return $?
}

get_speedtest_ipv6_ul () {
  echo "$1"  | grep 'IPv6_UL:'| sed -n 's/IPv6_UL://p'
  return $?
}

get_speedtest_ipv4_rtt () {
  echo "$1" | grep 'IPv4_RTT:'| sed -n 's/IPv4_RTT://p'
  return $?
}

get_speedtest_ipv4_jit () {
  echo "$1" | grep 'IPv4_JIT:'| sed -n 's/IPv4_JIT://p'
  return $?
}

get_speedtest_ipv4_dl () {
  echo "$1" | grep 'IPv4_DL:'| sed -n 's/IPv4_DL://p'
  return $?
}

get_speedtest_ipv4_ul () {
  echo "$1" | grep 'IPv4_UL:'| sed -n 's/IPv4_UL://p'
  return $?
}

cmdset_speedtest () {
  if [ $# -ne 5 ]; then
      echo "ERROR: cmdset_speedtest <layer> <version> <target_type>"	\
           "<target_addr> <count>." 1>&2
    return 1
  fi
  local layer=$1
  local ver=$2
  local type=$3
  local target=$4
  local count=$5
  local result=$FAIL
  local string=" speedtest to extarnal server: $target by $ipv"
  local speedtest_ans
  local speedtest_ipv6_rtt
  local speedtest_ipv6_jit
  local speedtest_ipv6_dl
  local speedtest_ipv6_ul
  local speedtest_ipv4_rtt
  local speedtest_ipv4_jit
  local speedtest_ipv4_dl
  local speedtest_ipv4_ul

  if speedtest_ans=$(do_speedtest ${target}); then
    result=$SUCCESS
  else
    stat=$?
  fi
  if [ "$result" = "$SUCCESS" ]; then
    string="$string\n  status: ok, speed test value: $speedtest_ans"
  else
    string="$string\n  status: ng ($stat)"
  fi
  if [ "$VERBOSE" = "yes" ]; then
    echo -e "$string"
  fi

  if speedtest_ipv6_rtt=$(get_speedtest_ipv6_rtt "$speedtest_ans"); then
    result=$SUCCESS
  fi
  if [ "$result" = "$SUCCESS" ]; then
    write_json "$layer" "ipv6" "v6speedtest_rtt" "$result" "$target"	\
               "$speedtest_ipv6_rtt" "$count"
  fi

  if speedtest_ipv6_jit=$(get_speedtest_ipv6_jit "$speedtest_ans"); then
    result=$SUCCESS
  fi
  if [ "$result" = "$SUCCESS" ]; then
    write_json "$layer" "ipv6" "v6speedtest_jit" "$result" "$target"	\
               "$speedtest_ipv6_jit" "$count"
  fi

  if speedtest_ipv6_dl=$(get_speedtest_ipv6_dl "$speedtest_ans"); then
    result=$SUCCESS
  fi
  if [ "$result" = "$SUCCESS" ]; then
    write_json "$layer" "ipv6" "v6speedtest_dl" "$result" "$target"	\
               "$speedtest_ipv6_dl" "$count"
  fi

  if speedtest_ipv6_ul=$(get_speedtest_ipv6_ul "$speedtest_ans"); then
    result=$SUCCESS
  fi
  if [ "$result" = "$SUCCESS" ]; then
    write_json "$layer" "ipv6" "v6speedtest_ul" "$result" "$target"	\
               "$speedtest_ipv6_ul" "$count"

  fi

  if speedtest_ipv4_rtt=$(get_speedtest_ipv4_rtt "$speedtest_ans"); then
    result=$SUCCESS
  fi
  if [ "$result" = "$SUCCESS" ]; then
    write_json "$layer" "ipv4" "v4speedtest_rtt" "$result" "$target"	\
               "$speedtest_ipv4_rtt" "$count"
  fi

  if speedtest_ipv4_jit=$(get_speedtest_ipv4_jit "$speedtest_ans"); then
    result=$SUCCESS
  fi
  if [ "$result" = "$SUCCESS" ]; then
    write_json "$layer" "ipv4" "v4speedtest_jit" "$result" "$target"	\
               "$speedtest_ipv4_jit" "$count"
  fi

  if speedtest_ipv4_dl=$(get_speedtest_ipv4_dl "$speedtest_ans"); then
    result=$SUCCESS
  fi
  if [ "$result" = "$SUCCESS" ]; then
    write_json "$layer" "ipv4" "v4speedtest_dl" "$result" "$target"	\
               "$speedtest_ipv4_dl" "$count"
  fi

  if speedtest_ipv4_ul=$(get_speedtest_ipv4_ul "$speedtest_ans"); then
    result=$SUCCESS
  fi
  if [ "$result" = "$SUCCESS" ]; then
    write_json "$layer" "ipv4" "v4speedtest_ul" "$result" "$target"	\
               "$speedtest_ipv4_ul" "$count"
  fi
}
### ADD speedtest

#
do_speedindex () {
  if [ $# -ne 1 ]; then
    echo "ERROR: do_speedindex <target_url>." 1>&2
    return 1
  fi

  tracejson=trace-json/$(echo "$1" | sed 's/[.:/]/_/g').json
  node speedindex.js "$1" ${tracejson}
  return $?
}

#
cmdset_speedindex () {
  if [ $# -ne 5 ]; then
    echo "ERROR: cmdset_speedindex <layer> <version> <target_type>"	\
         "<target_addr> <count>." 1>&2
    return 1
  fi
  local layer=$1
  local ver=$2
  local type=$3
  local target=$4
  local count=$5
  local result=$FAIL
  local string=" speedindex to extarnal server: $target by $ipv"
  local speedindex_ans

  if speedindex_ans=$(do_speedindex ${target}); then
    result=$SUCCESS
  else
    stat=$?
  fi
  write_json "$layer" "$ipv" "v${ver}speedindex" "$result" "$target"	\
             "$speedindex_ans" "$count"
  if [ "$result" = "$SUCCESS" ]; then
    string="$string\n  status: ok, speed index value: $speedindex_ans"
  else
    string="$string\n  status: ng ($stat)"
  fi
  if [ "$VERBOSE" = "yes" ]; then
    echo -e "$string"
  fi
}


#
# main
#

####################
## Preparation

# Check parameters
for param in LOCKFILE MAX_RETRY IFTYPE DEVNAME PING_SRVS PING6_SRVS FQDNS GPDNS4 GPDNS6 V4WEB_SRVS V6WEB_SRVS V4SSH_SRVS V6SSH_SRVS; do
  if [ -z $(eval echo '$'$param) ]; then
    echo "ERROR: $param is null in configration file." 1>&2
    exit 1
  fi
done

# Check commands
for cmd in uuidgen iwgetid iwconfig; do
  if ! which $cmd > /dev/null 2>&1; then
    echo "ERROR: $cmd is not found." 1>&2
    exit 1
  fi
done

####################
## Phase 0

# Set lock file
trap 'rm -f $LOCKFILE; exit 0' INT

if [ ! -e "$LOCKFILE" ]; then
  echo $$ >"$LOCKFILE"
else
  pid=$(cat "$LOCKFILE")
  if kill -0 "$pid" > /dev/null 2>&1; then
    exit 0
  else
    echo $$ >"$LOCKFILE"
    echo "Warning: previous check appears to have not finished correctly"
  fi
fi

# Make log directory
mkdir -p log
mkdir -p trace-json

# Cleate UUID
UUID=$(cleate_uuid)

# Get devicename
devicename=$(get_devicename "$IFTYPE")

# Get MAC address
mac_addr=$(get_macaddr "$devicename")

# Get OS version
os=$(get_os)

####################
## Phase 1
echo "Phase 1: Datalink Layer checking..."
layer="datalink"

# Down, Up interface
if [ "$RECONNECT" = "yes" ]; then
  # Down target interface
  if [ "$VERBOSE" = "yes" ]; then
    echo " interface:$devicename down"
  fi
  do_ifdown "$devicename"
  sleep 2

  # Start target interface
  if [ "$VERBOSE" = "yes" ]; then
    echo " interface:$devicename up"
  fi
  do_ifup "$devicename"
  sleep 5
fi

# Check I/F status
result_phase1=$FAIL
rcount=0
while [ "$rcount" -lt "$MAX_RETRY" ]; do
  if ifstatus=$(get_ifstatus "$devicename"); then
    result_phase1=$SUCCESS
    break
  fi
  sleep 5
  rcount=$(( rcount + 1 ))
done
if [ -n "$ifstatus" ]; then
  write_json "$layer" common ifstatus "$result_phase1" self "$ifstatus" 0
fi

# Get iftype
write_json "$layer" common iftype "$INFO" self "$IFTYPE" 0

# Get ifmtu
ifmtu=$(get_ifmtu "$devicename")
if [ -n "$ifmtu" ]; then
  write_json "$layer" common ifmtu "$INFO" self "$ifmtu" 0
fi

#
if [ "$IFTYPE" != "Wi-Fi" ]; then
  # Get media type
  media=$(get_mediatype "$devicename")
  if [ -n "$media" ]; then
    write_json "$layer" "$IFTYPE" media "$INFO" self "$media" 0
  fi
else
  # Get Wi-Fi SSID
  ssid=$(get_wifi_ssid "$devicename")
  if [ -n "$ssid" ]; then
    write_json "$layer" "$IFTYPE" ssid "$INFO" self "$ssid" 0
  fi
  # Get Wi-Fi BSSID
  bssid=$(get_wifi_bssid "$devicename")
  if [ -n "$bssid" ]; then
    write_json "$layer" "$IFTYPE" bssid "$INFO" self "$bssid" 0
  fi
  # Get Wi-Fi AP's OUI
  wifiapoui=$(get_wifi_apoui "$devicename")
  if [ -n "$wifiapoui" ]; then
    write_json "$layer" "$IFTYPE" wifiapoui "$INFO" self "$wifiapoui" 0
  fi
  # Get Wi-Fi channel
  channel=$(get_wifi_channel "$devicename")
  if [ -n "$channel" ]; then
    write_json "$layer" "$IFTYPE" channel "$INFO" self "$channel" 0
  fi
  # Get Wi-Fi RSSI
  rssi=$(get_wifi_rssi "$devicename")
  if [ -n "$rssi" ]; then
    write_json "$layer" "$IFTYPE" rssi "$INFO" self "$rssi" 0
  fi
  # Get Wi-Fi noise
  noise=$(get_wifi_noise "$devicename")
  if [ -n "$noise" ]; then
    write_json "$layer" "$IFTYPE" noise "$INFO" self "$noise" 0
  fi
  # Get Wi-Fi quality
  quarity=$(get_wifi_quality "$devicename")
  if [ -n "$quarity" ]; then
    write_json "$layer" "$IFTYPE" quarity "$INFO" self "$quarity" 0
  fi
  # Get Wi-Fi rate
  rate=$(get_wifi_rate "$devicename")
  if [ -n "$rate" ]; then
    write_json "$layer" "$IFTYPE" rate "$INFO" self "$rate" 0
  fi
  # Get Wi-Fi environment
  environment=$(get_wifi_environment "$devicename")
  if [ -n "$environment" ]; then
    write_json "$layer" "$IFTYPE" environment "$INFO" self		\
               "$environment" 0
  fi
fi

## Write campaign log file (pre)
#ssid=WIRED
#if [ "$IFTYPE" = "Wi-Fi" ]; then
#  ssid=$(get_wifi_ssid $devicename)
#fi
#write_json_campaign $UUID $mac_addr "$os" "$ssid"

# Report phase 1 results
if [ "$VERBOSE" = "yes" ]; then
  echo " datalink information:"
  echo "  datalink status: $result_phase1"
  echo "  type: $IFTYPE, dev: $devicename"
  echo "  status: $ifstatus, mtu: $ifmtu MB"
  if [ "$IFTYPE" != "Wi-Fi" ]; then
    echo "  media: $media"
  else
    echo "  ssid: $ssid, ch: $channel, rate: $rate Mbps"
    echo "  bssid: $bssid"
    echo "  rssi: $rssi dB, noise: $noise dB"
    echo "  quarity: $quarity"
    echo "  environment:"
    echo "$environment"
  fi
fi

echo " done."

####################
## Phase 2
echo "Phase 2: Interface Layer checking..."
layer="interface"

## IPv4
if [ "$EXCL_IPv4" != "yes" ]; then
  # Get IPv4 I/F configurations
  v4ifconf=$(get_v4ifconf "$devicename")
  if [ -n "$v4ifconf" ]; then
    write_json "$layer" IPv4 v4ifconf "$INFO" self "$v4ifconf" 0
  fi

  # Check IPv4 autoconf
  result_phase2_1=$FAIL
  rcount=0
  while [ $rcount -lt "$MAX_RETRY" ]; do
    if v4autoconf=$(check_v4autoconf "$devicename" "$v4ifconf"); then
      result_phase2_1=$SUCCESS
      break
    fi
    sleep 5
    rcount=$(( rcount + 1 ))
  done
  write_json "$layer" IPv4 v4autoconf "$result_phase2_1" self		\
             "$v4autoconf" 0

  # Get IPv4 address
  v4addr=$(get_v4addr "$devicename")
  if [ -n "$v4addr" ]; then
    write_json "$layer" IPv4 v4addr "$INFO" self "$v4addr" 0
  fi

  # Get IPv4 netmask
  netmask=$(get_netmask "$devicename")
  if [ -n "$netmask" ]; then
    write_json "$layer" IPv4 netmask "$INFO" self "$netmask" 0
  fi

  # Get IPv4 routers
  v4routers=$(get_v4routers "$devicename")
  if [ -n "$v4routers" ]; then
    write_json "$layer" IPv4 v4routers "$INFO" self "$v4routers" 0
  fi

  # Get IPv4 name servers
  v4nameservers=$(get_v4nameservers)
  if [ -n "$v4nameservers" ]; then
    write_json "$layer" IPv4 v4nameservers "$INFO" self			\
               "$v4nameservers" 0
  fi

  # Get IPv4 NTP servers
  #TBD

  # Report phase 2 results (IPv4)
  if [ "$VERBOSE" = "yes" ]; then
    echo " interface information:"
    echo "  intarface status (IPv4): $result_phase2_1"
    echo "  IPv4 conf: $v4ifconf"
    echo "  IPv4 addr: ${v4addr}/${netmask}"
    echo "  IPv4 router: $v4routers"
    echo "  IPv4 namesrv: $v4nameservers"
  fi
fi

## IPv6
if [ "$EXCL_IPv6" != "yes" ]; then
  # Get IPv6 I/F configurations
  v6ifconf=$(get_v6ifconf "$devicename")
  if [ -n "$v6ifconf" ]; then
    write_json "$layer" IPv6 v6ifconf "$INFO" self "$v6ifconf" 0
  fi

  # Get IPv6 linklocal address
  v6lladdr=$(get_v6lladdr "$devicename")
  if [ -n "$v6lladdr" ]; then
    write_json "$layer" IPv6 v6lladdr "$INFO" self "$v6lladdr" 0
  fi

  # Report phase 2 results (IPv6)
  if [ "$VERBOSE" = "yes" ]; then
    echo "  IPv6 conf: $v6ifconf"
    echo "  IPv6 lladdr: $v6lladdr"
  fi

  # Get IPv6 RA infomation
  ra_info=$(get_ra_info "$devicename")

  # Get IPv6 RA source addresses
  ra_addrs=$(echo "$ra_info" | get_ra_addrs)
  if [ -n "$ra_addrs" ]; then
    write_json "$layer" IPv6 ra_addrs "$INFO" self "$ra_addrs" 0
  fi

  if [ "$v6ifconf" = "automatic" ] && [ -z "$ra_addrs" ]; then
    # Report phase 2 results (IPv6-RA)
    if [ "$VERBOSE" = "yes" ]; then
      echo "   RA does not exist."
    fi
  else
    if [ "$v6ifconf" = "manual" ]; then
      result_phase2_2=$SUCCESS
      v6autoconf="v6conf is $v6ifconf"
      write_json "$layer" IPv6 v6autoconf "$result_phase2_2" self       \
                 "$v6autoconf" 0
      # Get IPv6 address
      v6addrs=$(get_v6addrs "$devicename" "")
      if [ -n "$v6addr" ]; then
        write_json "$layer" IPv6 v6addrs "$INFO" "$v6ifconf" "$v6addrs" 0
      fi
      s_count=0
      for addr in $(echo "$v6addrs" | sed 's/,/ /g'); do
        # Get IPv6 prefix length
        pref_len=$(get_prefixlen_from_ifinfo "$devicename" "$addr")
        if [ -n "$pref_len" ]; then
          write_json "$layer" IPv6 pref_len "$INFO" "$addr" "$pref_len" \
                     "$s_count"
        fi
        if [ "$VERBOSE" = "yes" ]; then
          echo "   IPv6 addr: ${addr}/${pref_len}"
        fi
        s_count=$(( s_count + 1 ))
      done
      if [ "$VERBOSE" = "yes" ]; then
        echo "   intarface status (IPv6): $result_phase2_2"
      fi
    else
      count=0
      for saddr in $(echo "$ra_addrs" | sed 's/,/ /g'); do
        # Get IPv6 RA flags
        ra_flags=$(echo "$ra_info" | get_ra_flags "$saddr")
        if [ -z "$ra_flags" ]; then
          ra_flags="none"
        fi
        write_json "$layer" RA ra_flags "$INFO" "$saddr" "$ra_flags"	\
                   "$count"

        # Get IPv6 RA parameters
        ra_hlim=$(echo "$ra_info" | get_ra_hlim "$saddr")
        if [ -n "$ra_hlim" ]; then
          write_json "$layer" RA ra_hlim "$INFO" "$saddr" "$ra_hlim"	\
                     "$count"
        fi
        ra_ltime=$(echo "$ra_info" | get_ra_ltime "$saddr")
        if [ -n "$ra_ltime" ]; then
          write_json "$layer" RA ra_ltime "$INFO" "$saddr" "$ra_ltime"	\
                     "$count"
        fi
        ra_reach=$(echo "$ra_info" | get_ra_reach "$saddr")
        if [ -n "$ra_reach" ]; then
          write_json "$layer" RA ra_reach "$INFO" "$saddr" "$ra_reach"	\
                     "$count"
        fi
        ra_retrans=$(echo "$ra_info" | get_ra_retrans "$saddr")
        if [ -n "$ra_retrans" ]; then
          write_json "$layer" RA ra_retrans "$INFO" "$saddr"		\
                     "$ra_retrans" "$count"
        fi

        # Report phase 2 results (IPv6-RA)
        if [ "$VERBOSE" = "yes" ]; then
          echo "  IPv6 RA src addr: $saddr"
          echo "   IPv6 RA flags: $ra_flags"
          echo "   IPv6 RA hoplimit: $ra_hlim"
          echo "   IPv6 RA lifetime: $ra_ltime"
          echo "   IPv6 RA reachable: $ra_reach"
          echo "   IPv6 RA retransmit: $ra_retrans"
        fi

        # Get IPv6 RA prefixes
        ra_prefs=$(echo "$ra_info" | get_ra_prefs "$saddr")
        if [ -n "$ra_prefs" ]; then
          write_json "$layer" RA ra_prefs "$INFO" "$saddr" "$ra_prefs"	\
                     "$count"
        fi

        s_count=0
        for pref in $(echo "$ra_prefs" | sed 's/,/ /g'); do
          # Get IPv6 RA prefix flags
          ra_pref_flags=$(echo "$ra_info"				|
                        get_ra_pref_flags "$saddr" "$pref")
          if [ -n "$ra_pref_flags" ]; then
            write_json "$layer" RA ra_pref_flags "$INFO"		\
                       "${saddr}-${pref}" "$ra_pref_flags" "$s_count"
          fi

          # Get IPv6 RA prefix parameters
          ra_pref_vltime=$(echo "$ra_info"				|
                         get_ra_pref_vltime "$saddr" "$pref")
          if [ -n "$ra_pref_vltime" ]; then
            write_json "$layer" RA ra_pref_vltime "$INFO"		\
                       "${saddr}-${pref}" "$ra_pref_vltime" "$s_count"
          fi
          ra_pref_pltime=$(echo "$ra_info"				|
                         get_ra_pref_pltime "$saddr" "$pref")
          if [ -n "$ra_pref_pltime" ]; then
            write_json "$layer" RA ra_pref_pltime "$INFO"		\
                       "${saddr}-${pref}" "$ra_pref_pltime" "$s_count"
          fi

          # Get IPv6 prefix length
          ra_pref_len=$(get_prefixlen "$pref")
          if [ -n "$ra_pref_len" ]; then
            write_json "$layer" RA ra_pref_len "$INFO"			\
                       "${saddr}-${pref}" "$ra_pref_len" "$s_count"
          fi

          # Report phase 2 results (IPv6-RA-Prefix)
          if [ "$VERBOSE" = "yes" ]; then
            echo "   IPv6 RA prefix: $pref"
            echo "    flags: $ra_pref_flags"
            echo "    valid time: $ra_pref_vltime"
            echo "    preferred time: $ra_pref_pltime"
          fi

          # Check IPv6 autoconf
          result_phase2_2=$FAIL
          rcount=0
          while [ $rcount -lt "$MAX_RETRY" ]; do
            # Get IPv6 address
            v6addrs=$(get_v6addrs "$devicename" "$pref")
            if v6autoconf=$(check_v6autoconf "$devicename" "$v6ifconf"	\
                       "$ra_flags" "$pref" "$ra_pref_flags"); then
              result_phase2_2=$SUCCESS
              break
            fi
            sleep 5

            rcount=$(( rcount + 1 ))
          done
          write_json "$layer" IPv6 v6addrs "$INFO" "$pref" "$v6addrs"	\
                     "$count"
          write_json "$layer" IPv6 v6autoconf "$result_phase2_2"	\
                     "$pref" "$v6autoconf" "$count"
          if [ "$VERBOSE" = "yes" ]; then
            for addr in $(echo "$v6addrs" | sed 's/,/ /g'); do
              echo "   IPv6 addr: ${addr}/${ra_pref_len}"
            done
            echo "   intarface status (IPv6): $result_phase2_2"
          fi

          s_count=$(( s_count + 1 ))
        done

        # Get IPv6 RA routes
        ra_routes=$(echo "$ra_info" | get_ra_routes "$saddr")
        if [ -n "$ra_routes" ]; then
          write_json "$layer" RA ra_routes "$INFO" "$saddr"		\
                     "$ra_routes" "$count"
        fi

        s_count=0
        for route in $(echo "$ra_routes" | sed 's/,/ /g'); do
          # Get IPv6 RA route flag
          ra_route_flag=$(echo "$ra_info"				|
                        get_ra_route_flag "$saddr" "$route")
          if [ -n "$ra_route_flag" ]; then
            write_json "$layer" RA ra_route_flag "$INFO"		\
                       "${saddr}-${route}" "$ra_route_flag" "$s_count"
          fi

          # Get IPv6 RA route parameters
          ra_route_ltime=$(echo "$ra_info"				|
                            get_ra_route_ltime "$saddr" "$route")
          if [ -n "$ra_route_ltime" ]; then
            write_json "$layer" RA ra_route_ltime "$INFO"		\
                       "${saddr}-${route}" "$ra_route_ltime" "$s_count"
          fi

          # Report phase 2 results (IPv6-RA-Route)
          if [ "$VERBOSE" = "yes" ]; then
            echo "   IPv6 RA route: $route"
            echo "    flag: $ra_route_flag"
            echo "    lifetime: $ra_route_ltime"
          fi

          s_count=$(( s_count + 1 ))
        done

        # Get IPv6 RA RDNSSes
        ra_rdnsses=$(echo "$ra_info" | get_ra_rdnsses "$saddr")
        if [ -n "$ra_rdnsses" ]; then
          write_json "$layer" RA ra_rdnsses "$INFO" "$saddr"		\
                     "$ra_rdnsses" "$count"
        fi

        s_count=0
        for rdnss in $(echo "$ra_rdnsses" | sed 's/,/ /g'); do
          # Get IPv6 RA RDNSS lifetime
          ra_rdnss_ltime=$(echo "$ra_info"				|
                            get_ra_rdnss_ltime "$saddr" "$rdnss")
          if [ -n "$ra_rdnss_ltime" ]; then
            write_json "$layer" RA ra_rdnss_ltime "$INFO"		\
                       "${saddr}-${rdnss}" "$ra_rdnss_ltime" "$s_count"
          fi

          # Report phase 2 results (IPv6-RA-RDNSS)
          if [ "$VERBOSE" = "yes" ]; then
            echo "   IPv6 RA rdnss: $rdnss"
            echo "    lifetime: $ra_rdnss_ltime"
          fi

          s_count=$(( s_count + 1 ))
        done

        count=$(( count + 1 ))
      done
    fi

    # Get IPv6 routers
    v6routers=$(get_v6routers "$devicename")
    if [ -n "$v6routers" ]; then
      write_json "$layer" IPv6 v6routers "$INFO" self "$v6routers" 0
    fi

    # Get IPv6 name servers
    v6nameservers=$(get_v6nameservers)
    if [ -n "$v6nameservers" ]; then
      write_json "$layer" IPv6 v6nameservers "$INFO" self "$v6nameservers" 0
    fi

    # Get IPv6 NTP servers
    #TBD

    # Report phase 2 results (IPv6)
    if [ "$VERBOSE" = "yes" ]; then
      echo "  IPv6 routers: $v6routers"
      echo "  IPv6 nameservers: $v6nameservers"
    fi
  fi
fi

echo " done."

####################
## Phase 3
echo "Phase 3: Localnet Layer checking..."
layer="localnet"

# Do ping to IPv4 routers
count=0
for target in $(echo "$v4routers" | sed 's/,/ /g'); do
  cmdset_ping "$layer" 4 router "$target" "$count" &
  count=$(( count + 1 ))
done

# Do ping to IPv4 nameservers
count=0
for target in $(echo "$v4nameservers" | sed 's/,/ /g'); do
  cmdset_ping "$layer" 4 namesrv "$target" "$count" &
  count=$(( count + 1 ))
done

# Do ping to IPv6 routers
count=0
for target in $(echo "$v6routers" | sed 's/,/ /g'); do
  cmdset_ping "$layer" 6 router "$target" "$count" &
  count=$(( count + 1 ))
done

# Do ping to IPv6 nameservers
count=0
for target in $(echo "$v6nameservers" | sed 's/,/ /g'); do
  cmdset_ping "$layer" 6 namesrv "$target" "$count" &
  count=$(( count + 1 ))
done

wait
echo " done."

####################
## Phase 4
echo "Phase 4: Globalnet Layer checking..."
layer="globalnet"

if [ "$EXCL_IPv4" != "yes" ]; then
  v4addr_type=$(check_v4addr "$v4addr")
else
  v4addr_type="linklocal"
fi
if [ "$v4addr_type" = "private" ] || [ "$v4addr_type" = "grobal" ]; then
  count=0
  for target in $(echo "$PING_SRVS" | sed 's/,/ /g'); do
    if [ "$MODE" = "probe" ]; then
      # Do ping to IPv4 routers
      count_r=0
      for target_r in $(echo "$v4routers" | sed 's/,/ /g'); do
        cmdset_ping "$layer" 4 router "$target_r" "$count_r" &
        count_r=$(( count_r + 1 ))
      done
    fi

    # Do ping to extarnal IPv4 servers
    cmdset_ping "$layer" 4 srv "$target" "$count" &

    # Do traceroute to extarnal IPv4 servers
    cmdset_trace "$layer" 4 srv "$target" "$count" &

    if [ "$MODE" = "client" ]; then
      # Check path MTU to extarnal IPv4 servers
      cmdset_pmtud "$layer" 4 srv "$target" "$ifmtu" "$count" &
    fi

    count=$(( count + 1 ))
  done
fi

if [ -n "$v6addrs" ]; then
  count=0
  for target in $(echo "$PING6_SRVS" | sed 's/,/ /g'); do
    if [ "$MODE" = "probe" ]; then
      # Do ping to IPv6 routers
      count_r=0
      for target_r in $(echo "$v6routers" | sed 's/,/ /g'); do
        cmdset_ping "$layer" 6 router "$target_r" "$count_r" &
        count_r=$(( count_r + 1 ))
      done
    fi

    # Do ping to extarnal IPv6 servers
    cmdset_ping "$layer" 6 srv "$target" "$count" &
  
    # Do traceroute to extarnal IPv6 servers
    cmdset_trace "$layer" 6 srv "$target" "$count" &
  
    if [ "$MODE" = "client" ]; then
      # Check path MTU to extarnal IPv6 servers
      cmdset_pmtud "$layer" 6 srv "$target" "$ifmtu" "$count" &
    fi

    count=$(( count + 1 ))
  done
fi

wait
echo " done."

####################
## Phase 5
echo "Phase 5: DNS Layer checking..."
layer="dns"

# Clear dns local cache
#TBD

if [ "$v4addr_type" = "private" ] || [ "$v4addr_type" = "grobal" ]; then
  count=0
  for target in $(echo "$v4nameservers" | sed 's/,/ /g'); do
    if [ "$MODE" = "probe" ]; then
      # Do ping to IPv4 nameservers
      cmdset_ping "$layer" 4 namesrv "$target" "$count" &
    fi

    # Do dns lookup for A record by IPv4
    cmdset_dnslookup "$layer" 4 A "$target" "$count" &

    # Do dns lookup for AAAA record by IPv4
    cmdset_dnslookup "$layer" 4 AAAA "$target" "$count" &

    count=$(( count + 1 ))
  done

  count=0
  for target in $(echo "$GPDNS4" | sed 's/,/ /g'); do
    if [ "$MODE" = "probe" ]; then
      # Do ping to IPv4 routers
      count_r=0
      for target_r in $(echo "$v4routers" | sed 's/,/ /g'); do
        cmdset_ping "$layer" 4 router "$target_r" "$count_r" &
        count_r=$(( count_r + 1 ))
      done

      # Do ping to IPv4 nameservers
      cmdset_ping "$layer" 4 namesrv "$target" "$count" &

      # Do traceroute to IPv4 nameservers
      cmdset_trace "$layer" 4 namesrv "$target" "$count" &
    fi

    # Do dns lookup for A record by IPv4
    cmdset_dnslookup "$layer" 4 A "$target" "$count" &

    # Do dns lookup for AAAA record by IPv4
    cmdset_dnslookup "$layer" 4 AAAA "$target" "$count" &

    count=$(( count + 1 ))
  done
fi

exist_dns64="no"
if [ -n "$v6addrs" ]; then
  count=0
  for target in $(echo "$v6nameservers" | sed 's/,/ /g'); do
    if [ "$MODE" = "probe" ]; then
      # Do ping to IPv6 nameservers
      cmdset_ping "$layer" 6 namesrv "$target" "$count" &
    fi

    # Do dns lookup for A record by IPv6
    cmdset_dnslookup "$layer" 6 A "$target" "$count" &

    # Do dns lookup for AAAA record by IPv6
    cmdset_dnslookup "$layer" 6 AAAA "$target" "$count" &

    # check DNS64
    exist_dns64=$(check_dns64 "$target")

    count=$(( count + 1 ))
  done

  count=0
  for target in $(echo "$GPDNS6" | sed 's/,/ /g'); do
    if [ "$MODE" = "probe" ]; then
      # Do ping to IPv6 routers
      count_r=0
      for target_r in $(echo "$v6routers" | sed 's/,/ /g'); do
        cmdset_ping "$layer" 6 router "$target_r" "$count_r" &
        count_r=$(( count_r + 1 ))
      done

      # Do ping to IPv6 nameservers
      cmdset_ping "$layer" 6 namesrv "$target" "$count" &

      # Do traceroute to IPv6 nameservers
      cmdset_trace "$layer" 6 namesrv "$target" "$count" &
    fi

    # Do dns lookup for A record by IPv6
    cmdset_dnslookup "$layer" 6 A "$target" "$count" &

    # Do dns lookup for AAAA record by IPv6
    cmdset_dnslookup "$layer" 6 AAAA "$target" "$count" &

    count=$(( count + 1 ))
  done
fi

wait
echo " done."

####################
## Phase 6
echo "Phase 6: Application Layer checking..."
layer="app"

if [ "$v4addr_type" = "private" ] || [ "$v4addr_type" = "grobal" ]; then
  count=0
  for target in $(echo "$V4WEB_SRVS" | sed 's/,/ /g'); do
    if [ "$MODE" = "probe" ]; then
      # Do ping to IPv4 routers
      count_r=0
      for target_r in $(echo "$v4routers" | sed 's/,/ /g'); do
        cmdset_ping "$layer" 4 router "$target_r" "$count_r" &
        count_r=$(( count_r + 1 ))
      done

      # Do ping to IPv4 web servers
      cmdset_ping "$layer" 4 websrv "$target" "$count" &

      # Do traceroute to IPv4 web servers
      cmdset_trace "$layer" 4 websrv "$target" "$count" &
    fi

    # Do curl to IPv4 web servers by IPv4
    cmdset_http "$layer" 4 websrv "$target" "$count" &

    # Do measure http throuput by IPv4
    #TBD
    # v4http_throughput_srv

    count=$(( count + 1 ))
  done

  count=0
  for target in $(echo "$V4SSH_SRVS" | sed 's/,/ /g'); do
    if [ "$MODE" = "probe" ]; then
      target_fqdn=$(echo $target | awk -F_ '{print $1}')

      # Do ping to IPv4 ssh servers
      cmdset_ping "$layer" 4 sshsrv "$target_fqdn" "$count" &

      # Do traceroute to IPv4 ssh servers
      cmdset_trace "$layer" 4 sshsrv "$target_fqdn" "$count" &
    fi

    # Do ssh-keyscan to IPv4 ssh servers by IPv4
    cmdset_ssh "$layer" 4 sshsrv "$target" "$count" &

    count=$(( count + 1 ))
  done
fi

if [ -n "$v6addrs" ]; then
  count=0
  for target in $(echo "$V6WEB_SRVS" | sed 's/,/ /g'); do
    if [ "$MODE" = "probe" ]; then
      count_r=0
      for target_r in $(echo "$v6routers" | sed 's/,/ /g'); do
        cmdset_ping "$layer" 6 router "$target_r" "$count_r" &
        count_r=$(( count_r + 1 ))
      done

      # Do ping to IPv6 web servers
      cmdset_ping "$layer" 6 websrv "$target" "$count" &

      # Do traceroute to IPv6 web servers
      cmdset_trace "$layer" 6 websrv "$target" "$count" &
    fi

    # Do curl to IPv6 web servers by IPv6
    cmdset_http "$layer" 6 websrv "$target" "$count" &

    # Do measure http throuput by IPv6
    #TBD
    # v6http_throughput_srv

    count=$(( count + 1 ))
  done

  count=0
  for target in $(echo "$V6SSH_SRVS" | sed 's/,/ /g'); do
    if [ "$MODE" = "probe" ]; then
      target_fqdn=$(echo $target | awk -F_ '{print $1}')

      # Do ping to IPv6 ssh servers
      cmdset_ping "$layer" 6 sshsrv "$target_fqdn" "$count" &

      # Do traceroute to IPv6 ssh servers
      cmdset_trace "$layer" 6 sshsrv "$target_fqdn" "$count" &
    fi

    # Do ssh-keyscan to IPv6 ssh servers by IPv6
    cmdset_ssh "$layer" 6 sshsrv "$target" "$count" &

    count=$(( count + 1 ))
  done

  # DNS64
  if [ "$exist_dns64" = "yes" ]; then
    echo " exist dns64 server"
    count=0
    for target in $(echo "$V4WEB_SRVS" | sed 's/,/ /g'); do
      if [ "$MODE" = "probe" ]; then
        # Do ping to IPv6 routers
        count_r=0
        for target_r in $(echo "$v6routers" | sed 's/,/ /g'); do
          cmdset_ping "$layer" 6 router "$target_r" "$count_r" &
          count_r=$(( count_r + 1 ))
        done

        # Do ping to IPv4 web servers by IPv6
        cmdset_ping "$layer" 6 websrv "$target" "$count" &

        # Do traceroute to IPv4 web servers by IPv6
        cmdset_trace "$layer" 6 websrv "$target" "$count" &
      fi

      # Do curl to IPv4 web servers by IPv6
      cmdset_http "$layer" 6 websrv "$target" "$count" &

      # Do measure http throuput by IPv6
      #TBD
      # v6http_throughput_srv

      count=$(( count + 1 ))
    done

    count=0
    for target in $(echo "$V4SSH_SRVS" | sed 's/,/ /g'); do
      if [ "$MODE" = "probe" ]; then
        target_fqdn=$(echo $target | awk -F_ '{print $1}')

        # Do ping to IPv4 ssh servers by IPv6
        cmdset_ping "$layer" 6 sshsrv "$target_fqdn" "$count" &

        # Do traceroute to IPv4 ssh servers by IPv6
        cmdset_trace "$layer" 6 sshsrv "$target_fqdn" "$count" &
      fi

      # Do ssh-keyscan to IPv4 ssh servers by IPv6
      cmdset_ssh "$layer" 6 sshsrv "$target" "$count" &

      count=$(( count + 1 ))
    done
  fi
fi

# SPEEDTEST
# if [ "$DO_SPEEDTEST" = "yes" ]; then # Not Available yet...
if [ "$v4addr_type" = "private" ] || [ "$v4addr_type" = "grobal" ] ||	\
  [ -n "$v6addrs" ]; then

  count=0
  for target in $(echo "$ST_SRVS" | sed 's/,/ /g'); do

    # Do speedtest
    cmdset_speedtest "$layer" 46 speedtssrv "$target" "$count" &

    count=$(( count + 1 ))
  done
fi
# fi # Not Available yet...

# SPEEDINDEX
if [ "$DO_SPEEDINDEX" = "yes" ]; then
  if [ "$v4addr_type" = "private" ] || [ "$v4addr_type" = "grobal" ] ||	\
     [ -n "$v6addrs" ]; then

    count=0
    for target in $(echo "$SI_SRVS" | sed 's/,/ /g'); do

      # Do speedindex
      cmdset_speedindex "$layer" 46 speedidsrv "$target" "$count" &

      count=$(( count + 1 ))
    done
  fi
fi

wait
echo " done."

####################
## Phase 7
echo "Phase 7: Create campaign log..."

# Write campaign log file (overwrite)
ssid=WIRED
if [ "$IFTYPE" = "Wi-Fi" ]; then
  ssid=$(get_wifi_ssid "$devicename")
fi
write_json_campaign "$UUID" "$mac_addr" "$os" "$ssid"

# remove lock file
rm -f "$LOCKFILE"

echo " done."

exit 0

