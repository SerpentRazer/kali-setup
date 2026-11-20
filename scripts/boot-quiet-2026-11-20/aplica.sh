#!/bin/bash
# 20 nov 2026: ascunde la pornire mesajele de nivel „error” inofensive (integrity: Problem loading X.509 certificate -65 = un cert
# din UEFI db al Lenovo cu format necunoscut kernelului; ACPI BIOS Error; kvm_amd pe CPU Intel). loglevel=3 => pe ecran doar crit+.
# Raman in journalctl. Rulare: pkexec bash ~/src/legion/boot-quiet-2026-11-20/aplica.sh
set -u
[ "$(id -u)" = 0 ] || { echo "ruleaza cu pkexec"; exit 1; }
B=/home/mastermind/.config-backups/pre-boot-quiet-$(date +%F_%H-%M-%S); mkdir -p "$B"; cp -p /etc/default/grub "$B/grub.default"
if ! grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=.*loglevel=' /etc/default/grub; then
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 loglevel=3"/' /etc/default/grub
fi
grep '^GRUB_CMDLINE_LINUX' /etc/default/grub
update-grub 2>&1 | tail -2
echo "intrari GRUB cu loglevel=3: $(grep -c 'loglevel=3' /boot/grub/grub.cfg)"
printf '#!/bin/sh\ncp -p "%s/grub.default" /etc/default/grub && update-grub && echo revenit\n' "$B" > "$B/revino.sh"; chmod 755 "$B/revino.sh"; chown -R 1000:1000 "$B"
echo "GATA (se vede la urmatoarea pornire). Backup + revino.sh: $B"
