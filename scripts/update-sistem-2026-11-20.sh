#!/bin/bash
# Actualizare sistem Kali (20 nov 2026), reteta sigura din 18 oct / 1 nov. Simularea fara root pe listele din 20 nov:
# 532 upgrade, 34 noi, 0 eliminari. NOU fata de 1 nov: kernel 7.2.15 (langa 7.1.5) -> driverul NVIDIA 610 (DKMS) trebuie
# sa se compileze pt el; daca NU se compileaza, GRUB porneste in continuare pe 7.1.5 (nu ramai fara placa video).
# libaquamarine14 (nou, cerut de libhyprtoolkit6) se instaleaza LANGA libaquamarine15 al nostru (cu mgpuwait) -> ok.
# Protejate (STOP daca s-ar atinge): nvidia/libnvidia (pin 610), kitty (patch scroll), libaquamarine15/-dev (patch mgpuwait),
# grub, hyprland (0.57 local), quickshell. HOLD existente: hyprland, hyprland-guiutils, libaquamarine15, libaquamarine-dev.
# Ruleaza intr-un terminal kitty (nu prin Claude, ca sa nu-l taie un timeout):
#   pkexec /bin/bash /home/mastermind/src/legion/update-sistem-2026-11-20.sh
set -u
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l NEEDRESTART_SUSPEND=1
[ "$(id -u)" = 0 ] || { echo "Ruleaza cu pkexec."; exit 1; }
B=/home/mastermind/.config-backups/pre-update-$(date +%Y-%m-%d_%H-%M-%S); mkdir -p $B
exec > >(tee -a "$B/log.txt") 2>&1
trap 'chown -R mastermind:mastermind $B' EXIT
die() { echo; echo "STOP: $*"; echo "Log: $B/log.txt"; exit 1; }
GUARD='^(nvidia|libnvidia|kitty|libaquamarine15|libaquamarine-dev|grub|hyprland|quickshell)'
OLDK=$(uname -r)

echo "== 1. verificari"
pgrep -x cs2 >/dev/null && die "CS2 ruleaza"
pgrep -f "[P]athOfExile" >/dev/null && die "POE ruleaza"
fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock >/dev/null 2>&1 && die "alt apt/dpkg ruleaza"
[ -z "$(dpkg --audit 2>&1)" ] || { dpkg --audit; die "dpkg --audit are probleme"; }
free=$(df --output=avail -BG / | tail -1 | tr -dc 0-9); [ "$free" -ge 5 ] || die "doar ${free}G liberi pe / (trebuie >= 5G)"
echo "  ok (kernel curent $OLDK, liber pe /: ${free}G)"

echo "== 2. backup"
tar -czf $B/etc.tar.gz -C / etc 2>/dev/null; dpkg --get-selections > $B/selectii.txt; apt-mark showhold > $B/hold-inainte.txt
dpkg-query -W -f='${Package}=${Version}\n' > $B/versiuni-inainte.txt
sha256sum /usr/lib/x86_64-linux-gnu/libaquamarine.so* $(find /usr/lib/kitty -name '*.so' 2>/dev/null) 2>/dev/null > $B/sha-inainte.txt
cp -a /etc/default/grub $B/grub-default
cat > $B/revino-apt.sh <<EOF
#!/bin/bash
# NU face downgrade automat. Readuce /etc/apt + /etc/default/grub; pachetele vechi: /var/cache/apt/archives sau snapshot.debian.org.
# Kernelul vechi ($OLDK) ramane instalat: GRUB -> "Advanced options" -> $OLDK.
[ "\$(id -u)" = 0 ] || exit 1
tar -xzf $B/etc.tar.gz -C / etc/apt; cp -a $B/grub-default /etc/default/grub; update-grub
echo "readus /etc/apt + grub; versiunile de dinainte: $B/versiuni-inainte.txt"
EOF
echo "  $B"

echo "== 3. liste noi"
apt-get update; rc=$?
[ $rc -eq 0 ] || echo "  ATENTIE: apt-get update a iesit cu $rc (verific mai jos ce urmeaza sa se instaleze)"

echo "== 4. simulare de control"
apt-get -s full-upgrade > $B/simulare.txt 2>&1 || die "simularea a esuat (vezi $B/simulare.txt)"
grep -E '^[0-9]+ upgraded' $B/simulare.txt
rem=$(awk '/^Remv /{print $2}' $B/simulare.txt | tr '\n' ' ')
[ -z "$rem" ] || die "ar elimina pachete: $rem"
bad=$(awk '/^Inst /{print $2}' $B/simulare.txt | grep -E "$GUARD" | tr '\n' ' ')
[ -z "$bad" ] || die "ar atinge pachete protejate: $bad"
NEWK=$(awk '/^Inst linux-image-[0-9]/{sub("linux-image-","",$2); print $2}' $B/simulare.txt | sort -V | tail -1)
echo "  eliminari: niciuna | protejate: neatinse | kernel nou: ${NEWK:-niciunul}"

echo "== 5. actualizare (10-20 min; NVIDIA + VirtualBox se compileaza pt kernelul nou)"
apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold full-upgrade || die "full-upgrade a esuat"

echo "== 6. verificari dupa"
[ -z "$(dpkg --audit 2>&1)" ] && echo "  dpkg --audit: curat" || dpkg --audit
sha256sum -c --quiet $B/sha-inainte.txt && echo "  aquamarine 15 + kitty: neschimbate" || echo "  ATENTIE: un fisier patch-uit s-a schimbat"
echo "  hyprland: $(dpkg-query -W -f='${Version}' hyprland) | hold: $(apt-mark showhold | tr '\n' ' ')"
if [ -n "$NEWK" ]; then
    mod=$(find /lib/modules/$NEWK -name 'nvidia.ko*' 2>/dev/null | head -1)
    if [ -z "$mod" ]; then
        echo "  NVIDIA nu e compilat pt $NEWK -> incerc o data dkms autoinstall"
        dkms autoinstall -k "$NEWK" 2>&1 | tail -5
        mod=$(find /lib/modules/$NEWK -name 'nvidia.ko*' 2>/dev/null | head -1)
    fi
    [ -n "$(find /lib/modules/$NEWK -name 'vboxdrv.ko*' 2>/dev/null)" ] || echo "  ATENTIE: VirtualBox nu e compilat pt $NEWK (VM-urile nu pornesc pe el)"
    if [ -n "$mod" ] && [ -e /boot/initrd.img-$NEWK ]; then
        echo "  NVIDIA 610 compilat pt $NEWK ($mod) + initramfs ok -> la restart porneste $NEWK"
    else
        echo "  NVIDIA NU merge pe $NEWK -> GRUB ramane pe kernelul vechi $OLDK"
        sub=$(grep -m1 -oP "submenu '\K[^']+" /boot/grub/grub.cfg)
        ent=$(grep -oP "menuentry '\K[^']*" /boot/grub/grub.cfg | grep -F "$OLDK" | grep -v -i recovery | head -1)
        if [ -n "$sub" ] && [ -n "$ent" ]; then
            sed -i "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=\"$sub>$ent\"   # update 20 nov: NVIDIA nu s-a compilat pt $NEWK|" /etc/default/grub
            update-grub 2>&1 | tail -1; echo "  GRUB_DEFAULT -> $sub > $ent"
        else
            echo "  !! nu gasesc intrarea GRUB pt $OLDK: la restart alege manual Advanced options -> $OLDK"
        fi
    fi
fi
echo "  liber pe /: $(df -h --output=avail / | tail -1 | tr -d ' ')"
echo; echo "GATA. Fa RESTART. Log + backup: $B"
