#!/bin/bash
# Login SDDM doar pe monitorul principal (11 nov 2026). Rulare: pkexec bash ~/src/legion/sddm-primary-2026-11-11/aplica.sh
set -u
D=/home/mastermind/src/legion/sddm-primary-2026-11-11
T=/usr/share/sddm/themes/cyberglass
die(){ echo "STOP: $*"; exit 1; }
[ "$(id -u)" = 0 ] || die "ruleaza cu: pkexec bash $0"
[ -f $T/Main.qml ] && [ -f $D/Main.qml ] && [ -f $D/Xsetup-primary ] || die "lipsesc fisiere"
grep -q 'readonly property bool showUi' $D/Main.qml || die "Main.qml pregatit e gresit"
B=/var/backups/sddm/pre-primary-$(date +%F_%H-%M-%S); mkdir -p $B   # backup-urile NU in /etc/sddm.conf.d (SDDM citeste tot de acolo)
cp -p $T/Main.qml $B/Main.qml
install -m 644 $D/Main.qml $T/Main.qml
install -d /etc/sddm
install -m 755 $D/Xsetup-primary /etc/sddm/Xsetup-primary
printf '[X11]\nDisplayCommand=/etc/sddm/Xsetup-primary\n' > /etc/sddm.conf.d/x11-primary.conf
chmod 644 /etc/sddm.conf.d/x11-primary.conf
cat > $B/revino.sh <<R
#!/bin/sh
cp -p $B/Main.qml $T/Main.qml && rm -f /etc/sddm.conf.d/x11-primary.conf /etc/sddm/Xsetup-primary && echo revenit
R
chmod 755 $B/revino.sh
cmp -s $D/Main.qml $T/Main.qml || die "Main.qml instalat difera"
echo "== /etc/sddm.conf.d:"; ls -1 /etc/sddm.conf.d/
echo "GATA. Backup + revino.sh: $B. Se vede la urmatorul logout (NU reporni sddm acum)."
