# Changelog

## 1.0.4 - 2026-11-18
- The install, the update and the restore ask for the sudo password **one time** at the start and keep it for all steps (stop Klipper, flash, start Klipper). New `rpi/lib_sudo.sh`. Needed on boards where `sudo` asks for a password (for example the factory screen board).

## 1.0.3 - 2026-11-18
- `install.sh` menu option `u` (Update): checks the version on GitHub, updates this folder (`git pull`, or a new download if you did not use git), then offers the newest firmware if the board does not run it. The menu header shows when a new version is on GitHub.
- Only ONE confirmation (`yes`) in the install and in the restore (it used to ask twice).
- `rpi/firmware/LATEST` names the newest patched firmware, so an update can bring a newer one.

## 1.0.2 - 2026-11-18
- README: update section simplified (`git pull`). Same firmware, bootloader and scripts as 1.0.0.

## 1.0.0 - 2026-11-18
- `rpi/install.sh`: menu to flash the load cell board (CELL) over CAN: 1) V2 (`KLP_CELL_WM_ZRU_RPI_V2_20261117`), 2) the original factory firmware (`KLP_CELL_WM_ZRU_20251223_162212`), 3) restore the original factory state (factory firmware + original factory bootloader, `rpi/4_restore_factory_bootloader.sh`).
- `rpi/tools/cell_bl_soft.py`: replaces the factory bootloader (CAN on the wrong pins) in software, through the running firmware. No SWD programmer, no Pico, no wires, no soldering. `2_flash_app_can.sh` does it automatically and asks first.
- Firmware files: V2, factory application, new CAN bootloader, original factory bootloader. Bootloader source (config, patch, commit).
- Rescue scripts for an SWD probe (Pico): `1_write_bootloader_swd.sh`, `3_flash_app_swd.sh`.
- README for the WonderMaker ZR Ultra-S and the ZR Ultra (tested on an Ultra-S only), with warning, power-loss warning, install, update and way back.
- Tested on one board (see `rpi/README.md`, TEST STATUS).
