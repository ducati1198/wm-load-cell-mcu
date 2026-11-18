# wm-load-cell-mcu

Firmware, bootloader and flash tools for the load cell board (CELL) of the WonderMaker ZR Ultra-S.
Credit: ducati1198.

- `rpi/` : printer run by a Raspberry Pi. Flash V2 or the original factory firmware over CAN (`bash rpi/install.sh`). No Pico, no wires, no soldering: the factory bootloader (which cannot be reached over CAN) is replaced in software first. Read `rpi/README.md` first, it explains the one risk.
- `factory-board/` : (planned) the same for the factory screen board, added after it is tried and tested.

Licence: GPLv3 (the bootloader is CanBoot and `tools/flashtool.py` is the Katapult flash tool, both GPLv3).
