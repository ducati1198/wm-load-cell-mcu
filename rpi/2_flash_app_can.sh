#!/bin/bash
# STEP 2: flash the load cell board (CELL) application over CAN with the factory flashtool.py (Katapult tool, in tools/).
# Needs the CAN bootloader of step 1 on the board (one time, with the Pico). With the ORIGINAL factory bootloader
# this does not work: the board stays silent on CAN until it is powered off and on again.
#
#   bash 2_flash_app_can.sh              flash KLP_CELL_WM_ZRU_RPI_V2_20261117.bin (the V2 firmware)
#   bash 2_flash_app_can.sh --factory    way back: flash the original KLP_CELL_WM_ZRU_20251223_162212.bin
#   bash 2_flash_app_can.sh --bin FILE   flash another application file
#   bash 2_flash_app_can.sh --dry-run    check everything and show what it would do, change nothing
#   bash 2_flash_app_can.sh --uuid ID    CAN id of the board (default: canbus_uuid of [mcu CELL] in the printer config)
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
V2="$HERE/firmware/KLP_CELL_WM_ZRU_RPI_V2_20261117.bin";  V2_MD5="a202b3e1a7cab0d77c4c78ca65334945"
FAC="$HERE/firmware/KLP_CELL_WM_ZRU_20251223_162212.bin"; FAC_MD5="e1e4fbc247a306d7854640f22cb6409d"
BIN="$V2"; WANT="$V2_MD5"; DRY=0; UUID=""
FT="$HERE/tools/flashtool.py"
MOON="http://127.0.0.1:7125"
CFGDIR="${CFGDIR:-$HOME/printer_data/config}"
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --factory) BIN="$FAC"; WANT="$FAC_MD5" ;;
    --bin) shift; BIN="$1"; WANT="" ;;
    --uuid) shift; UUID="$1" ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown option $1"; exit 2 ;;
  esac
  shift
done
say() { echo "== $*"; }
die() { echo "STOP: $*"; exit 1; }

[ -f "$BIN" ] || die "file not found: $BIN"
SIZE=$(stat -c %s "$BIN"); SUM=$(md5sum "$BIN" | cut -d' ' -f1)
say "file $(basename "$BIN")  $SIZE bytes  md5 $SUM"
[ -z "$WANT" ] || [ "$SUM" = "$WANT" ] || die "md5 should be $WANT (file damaged?)"
[ "$SIZE" -lt 60000 ] || die "too big for the application area (this must be the application file, not a flash dump)"
[ -f "$FT" ] || die "tools/flashtool.py is missing"

[ -n "$UUID" ] || UUID=$(grep -rhA8 '^\[mcu CELL\]' "$CFGDIR" 2>/dev/null | awk -F': *' '/canbus_uuid/{print $2; exit}' | tr -d ' \r')
[ -n "$UUID" ] || die "no canbus_uuid of [mcu CELL] found in $CFGDIR (use --uuid ID or CFGDIR=...)"
say "CELL board CAN id: $UUID"
ip -br link show can0 2>/dev/null | grep -q "UP" || die "can0 is not up"

INFO=$(curl -s --max-time 5 "$MOON/printer/objects/query?mcu%20CELL&print_stats" || true)
CUR=$(echo "$INFO" | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"]["status"]["mcu CELL"]["mcu_version"])' 2>/dev/null || true)
PST=$(echo "$INFO" | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"]["status"]["print_stats"]["state"])' 2>/dev/null || true)
say "board firmware now: ${CUR:-unknown}   printer state: ${PST:-unknown}"
case "$PST" in printing|paused) die "the printer is printing. Wait until it is finished.";; esac

echo
echo "This only works if the new CAN bootloader (step 1, file ..._new_bootloader.bin) is on the board."
echo "With the original factory bootloader the board will NOT answer, and stays silent until power off/on."
if [ $DRY -eq 0 ]; then
  read -r -p "Is the new bootloader installed on this board? Type yes: " A; [ "$A" = "yes" ] || die "cancelled, nothing changed (run step 1 first)"
  read -r -p "Heaters off, printer idle. Klipper stops for about a minute. Type yes to flash: " A; [ "$A" = "yes" ] || die "cancelled, nothing changed"
fi

PY=python3
if [ $DRY -eq 1 ]; then
  say "dry run, would do:"
  echo "   sudo systemctl stop klipper"
  echo "   $PY $FT -i can0 -u $UUID -r        (jump into the bootloader)"
  echo "   $PY $FT -i can0 -q                 (must list $UUID)"
  echo "   $PY $FT -i can0 -f $BIN -u $UUID -v"
  echo "   sudo systemctl start klipper"
  exit 0
fi

L="$(mktemp -d)"
sudo systemctl stop klipper; sleep 2
say "1/4 jump into the bootloader"
timeout 20 $PY "$FT" -i can0 -u "$UUID" -r > "$L/r.log" 2>&1; cat "$L/r.log"
sleep 1
say "2/4 query"
timeout 20 $PY "$FT" -i can0 -q > "$L/q.log" 2>&1; cat "$L/q.log"
if ! grep -qi "$UUID" "$L/q.log"; then
  sudo systemctl start klipper
  echo "STOP: the bootloader did not answer. Nothing was written."
  echo "If the board does not come back on its own: power the printer off and on. If it still does not answer,"
  echo "the new bootloader is not installed: do step 1 (needs the Pico), or go back with:  bash 1_write_bootloader_swd.sh --factory"
  exit 1
fi
say "3/4 flash"
timeout 150 $PY "$FT" -i can0 -f "$BIN" -u "$UUID" -v > "$L/f.log" 2>&1; RC=$?; tail -12 "$L/f.log"
say "flashtool exit code $RC"
sleep 3
sudo systemctl start klipper
say "4/4 check"
NEW=""
for i in $(seq 1 15); do
  sleep 3
  NEW=$(curl -s --max-time 5 "$MOON/printer/objects/query?mcu%20CELL" | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"]["status"]["mcu CELL"]["mcu_version"])' 2>/dev/null || true)
  [ -n "$NEW" ] && break
done
say "board firmware now: ${NEW:-not reported yet (look in Fluidd)}"
[ $RC -eq 0 ] || { echo "The flash reported an error. Run this script again: the bootloader is still there and answers."; exit $RC; }
