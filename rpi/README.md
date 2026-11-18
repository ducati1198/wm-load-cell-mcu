WonderMaker ZR Ultra-S  -  load cell board (CELL) firmware V2 and flashing over CAN
===================================================================================

Credit: the idea and the first steps come from ducati1198 (Discord, GitHub name "ducati1198").
Thank you. Everything here was tested on a WonderMaker ZR Ultra-S run by a Raspberry Pi (2026-11-17).

WHAT IS IN HERE
  firmware/KLP_CELL_WM_ZRU_20251223_162212.bin
        the FACTORY application of the load cell board, read out of a real board (46732 bytes). Your way back.
  firmware/KLP_CELL_WM_ZRU_RPI_V2_20261117.bin
        the patched application (V2, 46814 bytes), made from the factory file above.
  firmware/KLP_CELL_WM_ZRU_20251223_162212_original_bootloader.bin
        the FACTORY bootloader of the board (3154 bytes). Way back for the bootloader.
  firmware/KLP_CELL_WM_ZRU_20251223_162212_new_bootloader.bin
        a new bootloader (CanBoot, 3798 bytes) that talks CAN on the pins the board really uses (PA11/PA12).
  bootloader_source/   config, patch and commit of that bootloader (CanBoot is GPLv3, source is yours)
  tools/flashtool.py   the factory flash tool (Katapult flashtool, GPLv3, Eric Callahan), unchanged copy
  install.sh                  menu: 1) flash V2 over CAN, 2) flash factory over CAN (runs 2_flash_app_can.sh)
  1_write_bootloader_swd.sh   step 1, once per board, needs a Pico (see below)
  2_flash_app_can.sh          step 2, flash over CAN from the printer's Raspberry Pi, no extra hardware
  3_flash_app_swd.sh          optional: flash the application over SWD with the Pico (fallback)
  ANALYSIS.md         notes about the board and the firmware
  SHA256SUMS / MD5SUMS  check your download

WHY TWO STEPS
  The factory bootloader switches its CAN pins to PB8/PB9, but the board is wired to PA11/PA12. So the
  factory bootloader can never answer on CAN, and "flash over CAN" cannot work on a board with it.
  The new bootloader uses PA11/PA12 and keeps the same CAN id (uuid af..., same bitrate). It has to be
  written ONE TIME over SWD. After that, every flash (V2, factory, later versions) works over CAN, no Pico.

STEP 1  (one time, needs a Raspberry Pi Pico with the "debugprobe" firmware, and openocd on the printer's Pi)
  Wires Pico -> SWD pads of the load cell board:  GP2 -> SWCLK,  GP3 -> SWDIO,  GND -> GND  (no 3.3 V wire)
  sudo apt install openocd
  bash 1_write_bootloader_swd.sh --dry-run     (checks the probe sees the board, writes nothing)
  bash 1_write_bootloader_swd.sh               (backs up the whole flash first, writes, verifies)
  The application (V2 or factory) stays on the board and keeps running. The Pico is not needed again.

STEP 2  (over CAN)
  bash install.sh                              menu with the two choices below
  bash 2_flash_app_can.sh --dry-run
  bash 2_flash_app_can.sh                      flash V2
  bash 2_flash_app_can.sh --factory            way back: factory application
  It reads the CAN id from [mcu CELL] in ~/printer_data/config, jumps into the bootloader, checks that the
  bootloader answers, flashes, verifies, starts Klipper and prints the new firmware name.
  Klipper must not be printing. Heaters off.

WAY BACK  (everything is reversible)
  application:  bash 2_flash_app_can.sh --factory      (or 3_flash_app_swd.sh --factory with the Pico)
  bootloader :  bash 1_write_bootloader_swd.sh --factory   (Pico needed)
  Every SWD script first saves the whole 512 KB flash to ~/cell-backup-DATE/ . Keep that file.

WARNINGS
  - Do NOT run step 2 on a board that still has the FACTORY bootloader. The board stays silent on CAN
    until the printer is powered off and on. Nothing is damaged, but it is confusing. The script asks.
  - The Pico alternative for step 2 is 3_flash_app_swd.sh (works with any bootloader).
  - Always "reset halt" before an SWD write (the scripts do): the board's watchdog resets the chip otherwise.
  - openocd prints "checksum mismatch - attempting binary compare" and then "verified": normal.
  - You do this at your own risk. Nothing here is from WonderMaker.

TEST STATUS (2026-11-17, one board, one printer)
  - New bootloader written over SWD with the Pico: application unchanged, board came back, uuid unchanged.
  - Flash of V2 over CAN with tools/flashtool.py: OK, verified, Klipper reports the V2 name.
  - Flash of the factory application over CAN: OK, verified, Klipper reports KLP_CELL_WM_ZRU_20251223_162212.
  - Way back to the original bootloader over SWD: OK.
  Not tested: other boards, other CAN bitrates than the factory one.
