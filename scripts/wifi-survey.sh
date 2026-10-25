#!/usr/bin/env bash
# Log Wi-Fi signal strength and reachability every few seconds, to find a
# mounting spot in the car with good enough signal for syncing.
#
# Output: CSV with time, uptime, signal (dBm), link quality, and whether the
# router and the internet answer a ping. The CSV stays on the Pi: *.csv is
# git-ignored, and it records when and where the car was.
#
# Usage: wifi-survey.sh [output.csv] [interval-seconds]
set -u

OUT="${1:-/opt/canlogger/wifi-survey.csv}"
INTERVAL="${2:-2}"
IFACE=wlan0

[ -s "$OUT" ] || echo "time,uptime_s,signal_dbm,link_quality,router_ping_ms,internet_ping_ms" > "$OUT"

ping_ms() {
  # Prints the round-trip time in ms, or "fail".
  ping -n -c1 -W1 "$1" 2>/dev/null | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p' | grep . || echo fail
}

while true; do
  now="$(date -Is)"
  up="$(cut -d' ' -f1 /proc/uptime)"
  # /proc/net/wireless: "wlan0: 0000   63.  -47.  -256 ..." (quality, level dBm)
  read -r quality level < <(awk -v i="$IFACE:" '$1==i {gsub(/\./,"",$3); gsub(/\./,"",$4); print $3, $4}' /proc/net/wireless)
  gw="$(ip route show default dev "$IFACE" 2>/dev/null | awk '{print $3; exit}')"
  if [ -n "$gw" ]; then router="$(ping_ms "$gw")"; else router="no-link"; fi
  internet="$(ping_ms 1.1.1.1)"
  echo "$now,$up,${level:-none},${quality:-none},$router,$internet" >> "$OUT"
  sleep "$INTERVAL"
done
