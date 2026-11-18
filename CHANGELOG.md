# Changelog

## 1.0.0 - 2026-11-18
- `rpi/install.sh`: menu to flash the load cell board (CELL) over CAN: 1) V2 (`KLP_CELL_WM_ZRU_RPI_V2_20261117`), 2) the original factory firmware (`KLP_CELL_WM_ZRU_20251223_162212`), 3) restore the original factory state (factory firmware + original factory bootloader, `rpi/4_restore_factory_bootloader.sh`).
- `rpi/tools/cell_bl_soft.py`: replaces the factory bootloader (CAN on the wrong pins) in software, through the running firmware. No SWD programmer, no Pico, no wires, no soldering. `2_flash_app_can.sh` does it automatically and asks first.
- Firmware files: V2, factory application, new CAN bootloader, original factory bootloader. Bootloader source (config, patch, commit).
- Rescue scripts for an SWD probe (Pico): `1_write_bootloader_swd.sh`, `3_flash_app_swd.sh`.
- README for the WonderMaker ZR Ultra-S and the ZR Ultra (tested on an Ultra-S only), with warning, power-loss warning, install, update and way back.
- Tested on one board (see `rpi/README.md`, TEST STATUS).
