# Pi setup

How the logger Pi was set up, so it can be rebuilt from a blank SD card.

Base: Raspberry Pi OS Lite (64-bit, Debian 13 "trixie"), flashed with Raspberry Pi Imager. In the Imager settings, set the hostname (`canlogger`), user, Wi-Fi (country CA) and SSH.

## Access

- SSH with a dedicated key (`~/.ssh/canlogger` on the dev PC, never in this repo). The `~/.ssh/config` entry `Host canlogger` → `canlogger.local`.
- The login user has passwordless sudo through `/etc/sudoers.d/010_<user>-nopasswd`, containing `<user> ALL=(ALL) NOPASSWD: ALL` and checked with `visudo -cf` before installing. Remove that file to undo.

## Removed (2026-10-24)

Unused on a headless CAN logger. Purged with `apt-get purge --autoremove`. The package count went from 633 to 548.

- Camera stack: `rpicam-apps-*`, `libcamera*`, `libpisp*`, `v4l-utils`
- Pi 5 kernel: `linux-image-rpi-2712` (halves initramfs rebuild time on upgrades)
- Kernel headers / kbuild: the MCP2515 driver is in-kernel, so nothing needs compiling
- Bluetooth: `bluez`, `bluez-firmware`
- Remote access: `rpi-connect-lite`
- Windows/network filesystems: `cifs-utils`, `ntfs-3g`, `udisks2`
- Wi-Fi firmware for USB dongles: `firmware-atheros`, `firmware-libertas`, `firmware-mediatek`, `firmware-realtek` (the onboard chip uses `firmware-brcm80211`, which is kept)
- Man pages: `man-db`, `manpages`, `manpages-dev`
- `rpi-update`, `ssh-import-id`

**Keep `alsa-utils`:** purging it also removes `raspberrypi-sys-mods`, `raspi-config` and `userconf-pi`, which set up GPIO/SPI permissions and Wi-Fi.

## Disabled services and timers

- cloud-init: `/etc/cloud/cloud-init.disabled`. It only applies the Imager settings on first boot, and it cost ~6 s per boot. The Wi-Fi config lives in NetworkManager's netplan files, not cloud-init's.
- `apt-daily.timer`, `apt-daily-upgrade.timer`: the Pi is only online for a minute during warm-up, and it must not spend that minute running apt. Update by hand.
- `e2scrub_all.timer`, `e2scrub_reap.service` (masked): only useful with LVM.

## Installed

- apt: `can-utils` (candump, cansend, isotptp), `rclone`, `python3-venv`
- Python venv at `/opt/canlogger/venv`: `python-can`, `can-isotp`, `udsoncan`

## Google Drive sync (rclone)

- The remote `gdrive` (type `drive`) uses scope **`drive.file`**: rclone can only see files and folders it created itself, so a stolen Pi exposes only the logs, not the rest of the Drive.
- Uploads go to the `pi-can-logger` folder in My Drive, which rclone created.
- Set up with `rclone config` on the Pi, answering "n" to browser auto-auth, then running the printed `rclone authorize "drive" "..."` on a PC with a browser and pasting the token back. The owner does this step themselves, so the token never leaves their hands.
- The token lives in `~/.config/rclone/rclone.conf` (mode 600) on the Pi, never in this repo. `rclone.conf` is in `.gitignore`.
- Tested 2026-10-24: `rclone copy` of a test file to `gdrive:pi-can-logger/`, confirmed from the Drive side.

## Boot config

Originals saved on the Pi as `/boot/firmware/config.txt.orig` and `cmdline.txt.orig`.

`config.txt`:
- `dtparam=audio=off`, `camera_auto_detect=0`, `display_auto_detect=0`
- `vc4-kms-v3d` and `max_framebuffers` commented out (headless; the HDMI text console still works)
- Appended under `[all]`: `gpu_mem=16`, `dtoverlay=disable-bt`, `disable_splash=1`, `dtparam=spi=on`

`cmdline.txt`: removed `console=serial0,115200`, because the RS485 CAN HAT uses UART pins 14/15.

## Results

| | Before | After |
|---|---|---|
| Packages | 633 | 548 |
| Boot (kernel + userspace) | 47.0 s | 36.7 s |
| RAM visible to Linux | 415 MB | 462 MB |
| RAM available after boot | ~279 MB | ~333 MB |

NetworkManager still takes ~20 s (Wi-Fi association). The logger service must not wait for the network: logging starts as soon as the CAN interface is up, and sync runs separately.
