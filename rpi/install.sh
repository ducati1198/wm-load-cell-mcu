#!/bin/bash
# WonderMaker ZR Ultra-S, Raspberry Pi: menu to flash the load cell board (CELL) over CAN with the factory flash tool.
#
#   bash install.sh
#
#   1) Flash V2 (KLP_CELL_WM_ZRU_RPI_V2_20261117)
#   2) Flash the original factory firmware (KLP_CELL_WM_ZRU_20251223_162212)
#   3) Put the board back to the original factory state (factory firmware + original factory bootloader)
#
# No extra hardware. If the board still has the factory bootloader, 2_flash_app_can.sh replaces it in software
# first (it asks). Read README.md, "THE ONE RISK".
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
CAN="$HERE/2_flash_app_can.sh"
MOON="http://127.0.0.1:7125"
VER="$(cat "$HERE/../VERSION" 2>/dev/null || echo "?")"
[ -f "$CAN" ] || { echo "2_flash_app_can.sh is missing next to install.sh"; exit 1; }

current() {
  curl -s --max-time 5 "$MOON/printer/objects/query?mcu%20CELL" 2>/dev/null \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"]["status"]["mcu CELL"]["mcu_version"])' 2>/dev/null
}

while true; do
  CUR="$(current)"
  echo
  echo "=========================================================="
  echo " WonderMaker load cell board (CELL) - flash over CAN   v$VER"
  echo " Board firmware now: ${CUR:-unknown (Klipper not running?)}"
  echo "=========================================================="
  echo "  1) Flash V2        KLP_CELL_WM_ZRU_RPI_V2_20261117"
  echo "  2) Flash factory   KLP_CELL_WM_ZRU_20251223_162212"
  echo "  3) Restore original (factory firmware + original bootloader)"
  echo "  q) Quit"
  read -r -p "Choose: " C
  case "$C" in
    1) bash "$CAN" ;;
    2) bash "$CAN" --factory ;;
    3) bash "$HERE/4_restore_factory_bootloader.sh" ;;
    q|Q|"") exit 0 ;;
    *) echo "Please type 1, 2, 3 or q." ;;
  esac
done
