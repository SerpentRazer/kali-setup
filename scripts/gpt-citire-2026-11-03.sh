#!/bin/bash
# DOAR CITIRE de pe /dev/nvme0n1 -> copii pe STUFF (sda). Nu scrie nimic pe NVMe.
set -u
D=/dev/nvme0n1
O=/mnt/stuff/gpt-2026-11-03
[ "$(id -u)" = 0 ] || { echo "ruleaza cu pkexec"; exit 1; }
findmnt -n /mnt/stuff >/dev/null || { echo "STUFF nu e montat"; exit 1; }
mkdir -p "$O"
N=$(blockdev --getsz $D)
echo "$N" > "$O/sectors.txt"
dd if=$D of="$O/nvme-head.img" bs=512 count=2048 status=none
dd if=$D of="$O/nvme-tail.img" bs=512 skip=$((N-33)) count=33 status=none
sgdisk --backup="$O/gpt.bin" $D > "$O/sgdisk-backup.txt" 2>&1
gdisk -l $D > "$O/gdisk-l.txt" 2>&1
sgdisk -v $D > "$O/sgdisk-v.txt" 2>&1
sha256sum "$O"/nvme-head.img "$O"/nvme-tail.img "$O"/gpt.bin > "$O/SHA256SUMS"
echo "GATA $(date '+%F %T') -> $O"
