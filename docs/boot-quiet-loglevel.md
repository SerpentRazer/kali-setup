---
name: boot-quiet-loglevel
description: "20 nov 2026: eroarea de la pornire „integrity: Problem loading X.509 certificate -65” = cert din UEFI db Lenovo necitibil de kernel, inofensiva; ascunsa cu loglevel=3 in GRUB"
metadata:
  type: project
---

Mesaj pe ecran la boot (KERN_ERR, vizibil cu `quiet` = console loglevel 4): `integrity: Problem loading X.509 certificate -65` +
`Error adding keys to platform keyring UEFI:db` — o intrare din db-ul UEFI (Lenovo, langa 'H1LegionY560760') cu format pe care kernelul nu-l parseaza;
restul certificatelor (Microsoft 2011/2023) se incarca, Secure Boot neafectat. Tot la err: ACPI BIOS Error \_SB.PCI0, `kvm_amd: CPU isn't AMD`.
Fix: `GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3"` (splash il adauga /etc/default/grub.d/kali-themes.cfg; GRUB_CMDLINE_LINUX="gpt" ramane) + update-grub,
script `~/src/legion/boot-quiet-2026-11-20/aplica.sh` (pkexec, backup+revino.sh ~/.config-backups/pre-boot-quiet-2026-11-20_19-04-52). **APLICAT 20 nov 19:04**: 4 intrari GRUB cu loglevel=3 (+gpt, splash). **CONFIRMAT de user dupa reboot 20 nov: mesajul nu mai apare.**
Legat: [[gpt-primary-lba2016-windows]] (plasa `gpt` in GRUB_CMDLINE_LINUX).
