#!/bin/bash
# Curatenie dupa update-ul din 20 nov: sterge pachetele .deb descarcate (8.1 GB) + kernelurile vechi 6.16.8 si 7.0.12 (~0.9 GB).
# Raman: 7.2.15 (curent) + 7.1.5 (rezerva in GRUB -> Advanced options). Simularea: 6 pachete sterse, nimic altceva.
# Rulare:  pkexec bash /home/mastermind/src/legion/curatenie-disc-2026-11-20.sh
set -u
[ "$(id -u)" = 0 ] || { echo "ruleaza cu pkexec"; exit 1; }
[ "$(uname -r)" = "7.2.15+kali-amd64" ] || { echo "STOP: nu rulezi pe 7.2.15"; exit 1; }
echo "inainte: $(df -h --output=avail / | tail -1 | tr -d ' ') liberi"
P="linux-image-6.16.8+kali-amd64 linux-headers-6.16.8+kali-amd64 linux-headers-6.16.8+kali-common linux-image-7.0.12+kali-amd64 linux-headers-7.0.12+kali-amd64 linux-headers-7.0.12+kali-common"
sim=$(apt-get -s purge $P 2>&1); n=$(echo "$sim" | grep -c '^Purg')
[ "$n" = 6 ] || { echo "STOP: simularea ar sterge $n pachete (asteptat 6)"; echo "$sim" | grep '^Purg'; exit 1; }
DEBIAN_FRONTEND=noninteractive apt-get -y purge $P 2>&1 | tail -2
apt-get clean
echo "kerneluri ramase: $(ls /boot/vmlinuz-* | sed 's#/boot/vmlinuz-##' | tr '\n' ' ')"
grep -c "menuentry 'Kali GNU/Linux, with Linux 7.1.5" /boot/grub/grub.cfg | sed 's/^/intrari GRUB 7.1.5 (rezerva): /'
echo "dupa: $(df -h --output=avail / | tail -1 | tr -d ' ') liberi"
