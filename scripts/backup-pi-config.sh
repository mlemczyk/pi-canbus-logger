#!/usr/bin/env bash
# Back up the logger Pi's config (including secrets) to a folder on this PC.
#
# The backup holds Wi-Fi passwords, the rclone Google Drive token and SSH
# host keys. Never point BACKUP_DIR inside this repo or a cloud-synced folder.
#
# Usage: scripts/backup-pi-config.sh [ssh-host] [backup-dir]
#   ssh-host    default: canlogger (an entry in ~/.ssh/config)
#   backup-dir  default: ~/pi-can-logger-backup
set -euo pipefail

HOST="${1:-canlogger}"
BACKUP_DIR="${2:-$HOME/pi-can-logger-backup}"
STAMP="$(date +%Y-%m-%d_%H%M%S)"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
backup_abs="$(mkdir -p "$BACKUP_DIR" && cd "$BACKUP_DIR" && pwd)"
case "$backup_abs/" in
  "$repo_root"/*) echo "Refusing to write secrets inside the repo: $backup_abs" >&2; exit 1 ;;
esac

out="$backup_abs/$STAMP"
mkdir -p "$out"
chmod 700 "$backup_abs" "$out" 2>/dev/null || true

# Files restored as-is onto a fresh SD card (tar keeps owners and modes).
ssh -o BatchMode=yes "$HOST" 'sudo tar czf - --ignore-failed-read \
    --exclude=/opt/canlogger/venv \
    /boot/firmware/config.txt /boot/firmware/cmdline.txt \
    /etc/hostname /etc/hosts \
    /etc/netplan /etc/NetworkManager/system-connections \
    /etc/sudoers.d \
    /etc/ssh/ssh_host_* \
    /etc/cloud/cloud-init.disabled \
    /etc/systemd/system \
    "$HOME/.ssh/authorized_keys" \
    "$HOME/.config/rclone/rclone.conf" \
    /opt/canlogger \
    2>/dev/null' > "$out/pi-config.tar.gz"

# Lists for reinstalling software (not restored by tar).
ssh -o BatchMode=yes "$HOST" 'apt-mark showmanual' > "$out/apt-manual.txt"
ssh -o BatchMode=yes "$HOST" 'dpkg -l | awk "/^ii/{print \$2}"' > "$out/dpkg-installed.txt"
ssh -o BatchMode=yes "$HOST" '/opt/canlogger/venv/bin/pip freeze 2>/dev/null || true' > "$out/pip-freeze.txt"
ssh -o BatchMode=yes "$HOST" 'systemctl list-unit-files --state=enabled,masked,disabled --no-legend' > "$out/systemd-unit-states.txt"
ssh -o BatchMode=yes "$HOST" 'cat /etc/os-release; uname -a' > "$out/os-version.txt"

tar tzf "$out/pi-config.tar.gz" > "$out/pi-config-manifest.txt"
echo "Backup written to $out"
echo "  $(wc -l < "$out/pi-config-manifest.txt") paths in pi-config.tar.gz, $(du -h "$out/pi-config.tar.gz" | cut -f1)"
