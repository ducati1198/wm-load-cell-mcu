# Changelog

## 1.1.0 - 2026-11-18
- `install.sh` option 3: put the board back to the original factory state (factory firmware first, then the original factory bootloader), in software, no Pico. Script: `rpi/4_restore_factory_bootloader.sh` (`--dry-run` supported).

## 1.0.0 - 2026-11-18
- `rpi/install.sh`: menu to flash the load cell board (CELL) over CAN: V2 (`KLP_CELL_WM_ZRU_RPI_V2_20261117`) or the original factory firmware (`KLP_CELL_WM_ZRU_20251223_162212`).
- `rpi/tools/cell_bl_soft.py`: replaces the factory bootloader (CAN on the wrong pins) in software, through the running firmware. No Pico, no wires, no soldering. `2_flash_app_can.sh` does it automatically and asks first.
- Firmware files: V2, factory application, new CAN bootloader, original factory bootloader. Bootloader source (config, patch, commit).
- Rescue scripts for an SWD probe (Pico): `1_write_bootloader_swd.sh`, `3_flash_app_swd.sh`.
- Tested on one board (see `rpi/README.md`, TEST STATUS).
