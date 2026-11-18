# wm-load-cell-mcu

Firmware and flash tools for the **load cell board (CELL)** of the **WonderMaker ZR Ultra-S**.

- Flash the patched firmware **V2**, or go back to the **original factory firmware**, over CAN.
- **No Pico, no wires, no soldering.** Everything runs from the printer's Raspberry Pi.

Version: see [`VERSION`](VERSION) and [`CHANGELOG.md`](CHANGELOG.md). Credit: ducati1198.

> **At your own risk.** Nothing here comes from WonderMaker. It was tested on **one** board.
> Read [The one risk](#the-one-risk) before you flash.

---

## What V2 fixes

The factory firmware (`KLP_CELL_WM_ZRU_20251223_162212`) sometimes reads the load cell chip while the chip is
already preparing its next sample. That gives a broken value, and a broken value can look like a touch.
On the test printer this showed up as false touches and retries during the tool offset calibration.

V2 (`KLP_CELL_WM_ZRU_RPI_V2_20261117`) waits for a fresh sample before it reads.

| On the test printer | Factory firmware | V2 |
|---|---|---|
| Broken reads, no motion | about 20 in 1900 | 0 in 5200 |
| Retries in a full offset run (240 touches) | about 19 | 0 |

V2 is the factory firmware with that one change. Nothing else is different.

## Why a normal CAN flash does not work on this board

The factory **bootloader** of the load cell board listens for CAN on pins PB8/PB9. The board is wired to
PA11/PA12. So the bootloader can never hear the Pi, and the usual "flash over CAN" fails (the board then stays
silent until the printer is powered off and on).

This repo solves it in software. The running firmware does talk on the right pins and has Klipper's
`debug_read` / `debug_write` commands. The tool `rpi/tools/cell_bl_soft.py` uses them to replace the
bootloader with one that uses PA11/PA12 (same CAN id as before). After that, flashing over CAN works.

## What you need

- A WonderMaker ZR Ultra-S **run by a Raspberry Pi** with Klipper in `~/klipper` and `~/klippy-env`.
- The CAN interface `can0` up, and `[mcu CELL]` with its `canbus_uuid` in `~/printer_data/config`.
- The load cell board running `KLP_CELL_WM_ZRU_20251223_162212` or V2. The tool stops by itself on anything else.
- The printer idle, heaters off. Do not start this during a print.

The factory screen board is **not** supported yet (folder `factory-board/` will come after it is tested).

---

## Install with the menu

On the printer's Raspberry Pi (SSH).

First make sure `git` is installed. Check with:

```bash
git --version
```

If it answers `git version ...`, it is there. If it says `command not found`, install it:

```bash
sudo apt update
sudo apt install -y git
```

Then download this repo and start the menu:

```bash
cd ~
git clone https://github.com/ducati1198/wm-load-cell-mcu.git
cd wm-load-cell-mcu/rpi
bash install.sh
```

```
 WonderMaker load cell board (CELL) - flash over CAN   v1.0.0
 Board firmware now: KLP_CELL_WM_ZRU_20251223_162212
  1) Flash V2        KLP_CELL_WM_ZRU_RPI_V2_20261117
  2) Flash factory   KLP_CELL_WM_ZRU_20251223_162212
  q) Quit
```

Choose `1`. The script then:

1. checks the files, the CAN id and that the printer is not printing;
2. stops Klipper and looks which bootloader is on the board;
3. if it is the factory bootloader: explains the risk, asks for `yes`, replaces it (about 2 seconds);
4. asks for `yes`, flashes the firmware over CAN and verifies it;
5. starts Klipper and prints the firmware name the board reports.

If you do not want to install `git`, download the files with `curl` instead:

```bash
cd ~
curl -L https://github.com/ducati1198/wm-load-cell-mcu/archive/refs/heads/main.tar.gz | tar xz
cd wm-load-cell-mcu-main/rpi
bash install.sh
```

## Install without the menu

One command, same checks and questions as the menu:

```bash
cd ~/wm-load-cell-mcu/rpi
bash 2_flash_app_can.sh --dry-run     # checks only, changes nothing (Klipper stops for a few seconds)
bash 2_flash_app_can.sh               # flash V2
bash 2_flash_app_can.sh --factory     # flash the original factory firmware
```

Options: `--bin FILE` (another application file), `--uuid ID` (CAN id by hand),
`CFGDIR=/path` in front of the command if your config is not in `~/printer_data/config`.

## Fully by hand

The same steps as the script, one by one. Use this only if you know what each line does.

```bash
cd ~/wm-load-cell-mcu/rpi
UUID=$(grep -rhA8 '^\[mcu CELL\]' ~/printer_data/config | awk -F': *' '/canbus_uuid/{print $2; exit}' | tr -d ' \r')
echo $UUID                                    # must show 12 characters, starting with af

sudo systemctl stop klipper

# 1. which bootloader is on the board? (read only)  last line: BOOTLOADER: new | factory | unknown
~/klippy-env/bin/python tools/cell_bl_soft.py $UUID probe

# 2. only if it says "factory": replace it. Do NOT power off while this runs.
~/klippy-env/bin/python tools/cell_bl_soft.py $UUID write firmware/KLP_CELL_WM_ZRU_20251223_162212_new_bootloader.bin

# 3. jump into the bootloader, check that it answers, flash and verify
python3 tools/flashtool.py -i can0 -u $UUID -r
sleep 1
python3 tools/flashtool.py -i can0 -q         # must show: Detected UUID: <your id>, Application: Katapult
python3 tools/flashtool.py -i can0 -f firmware/KLP_CELL_WM_ZRU_RPI_V2_20261117.bin -u $UUID -v

sudo systemctl start klipper
```

If step 1 says `unknown`, stop: the board is not like the tested one. If the query in step 3 does not show
your id, nothing was written; power the printer off and on and start again.

---

## The one risk

Replacing the bootloader takes about 2 seconds. For about **0.2 seconds** of that the board has no bootloader.
If the printer loses power or is switched off in that moment, the board does not start again, and only an
SWD probe can bring it back (see [Rescue](#rescue-with-a-probe)).

- Do not touch the printer while it writes.
- If the tool says the read-back differs, it writes again by itself. Never power off in between.
- The old bootloader is saved to `~/cell-bootloader-before-DATE.bin` first.
- This happens once per board. Later flashes do not touch the bootloader.

## Way back

Everything is reversible.

```bash
cd ~/wm-load-cell-mcu/rpi

# firmware back to factory
bash 2_flash_app_can.sh --factory

# bootloader back to factory (do this last: with the factory bootloader, CAN flashing is gone again)
UUID=$(grep -rhA8 '^\[mcu CELL\]' ~/printer_data/config | awk -F': *' '/canbus_uuid/{print $2; exit}' | tr -d ' \r')
sudo systemctl stop klipper
~/klippy-env/bin/python tools/cell_bl_soft.py $UUID write firmware/KLP_CELL_WM_ZRU_20251223_162212_original_bootloader.bin
sudo systemctl start klipper
```

## Rescue with a probe

Only needed if something went wrong. A Raspberry Pi Pico with the "debugprobe" firmware, and `openocd`
on the printer's Pi. Wires from the Pico to the SWD pads of the load cell board:
GP2 to SWCLK, GP3 to SWDIO, GND to GND (no 3.3 V wire).

```bash
sudo apt install openocd
bash 1_write_bootloader_swd.sh --dry-run    # does the probe see the board?
bash 1_write_bootloader_swd.sh              # write the new bootloader   (--factory: the original one)
bash 3_flash_app_swd.sh                     # write V2                   (--factory: the original firmware)
```

Both scripts save the whole flash to `~/cell-backup-DATE/` first.

---

## Files

| Path | What |
|---|---|
| `rpi/install.sh` | The menu |
| `rpi/2_flash_app_can.sh` | Checks, replaces the bootloader if needed, flashes over CAN |
| `rpi/tools/cell_bl_soft.py` | Replaces the bootloader in software (`probe`, `trial`, `write FILE`) |
| `rpi/tools/flashtool.py` | The factory CAN flash tool (Katapult, unchanged copy) |
| `rpi/firmware/KLP_CELL_WM_ZRU_RPI_V2_20261117.bin` | V2 firmware |
| `rpi/firmware/KLP_CELL_WM_ZRU_20251223_162212.bin` | Original factory firmware, read out of a real board |
| `rpi/firmware/KLP_CELL_WM_ZRU_20251223_162212_new_bootloader.bin` | New bootloader, CAN on PA11/PA12 |
| `rpi/firmware/KLP_CELL_WM_ZRU_20251223_162212_original_bootloader.bin` | Original factory bootloader |
| `rpi/bootloader_source/` | Config, patch and source commit of the new bootloader |
| `rpi/1_write_bootloader_swd.sh`, `rpi/3_flash_app_swd.sh` | Rescue with a probe |
| `rpi/MD5SUMS`, `rpi/SHA256SUMS` | Checksums |
| `rpi/ANALYSIS.md` | Notes about the board and the firmware |

More detail and the full test list: [`rpi/README.md`](rpi/README.md).

## Test status

Tested on one board and one printer (2026-11-18), with a probe wired as a safety net:

- From the factory state (factory bootloader and factory firmware): bootloader replaced in software, V2 flashed over CAN.
- Factory firmware flashed over CAN with the new bootloader.
- Original bootloader written back in software, then everything again.
- A probe confirmed bootloader and firmware byte for byte at the end.

Not tested: other boards, other firmware versions, a power loss during the bootloader write.
If you try it, please report what your board said, good or bad.

## Licence

GPLv3. The new bootloader is built from [CanBoot/Katapult](https://github.com/Arksine/katapult) and
`tools/flashtool.py` is the Katapult flash tool, both GPLv3 (Eric Callahan). The firmware is Klipper (GPLv3).
