#!/bin/bash
# LenovoLegionLinux faza 1 (1 nov): incarca modulul compilat DOAR CITIRE (ec_readonly=1), fara platform_profile propriu
# (ramane lenovo-wmi-gamezone), apoi arata ventilatoare/temperaturi/curba din EC. Nimic instalat, dispare la reboot.
# Ruleaza: pkexec /bin/bash /home/mastermind/src/legion/faza1-citire.sh      Scoatere: pkexec rmmod legion_laptop
set -u
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
[ "$(id -u)" = 0 ] || { echo "Ruleaza cu pkexec."; exit 1; }
KO=/home/mastermind/src/legion/LenovoLegionLinux/kernel_module/legion-laptop.ko
O=/home/mastermind/.cache/legion-faza1-$(date +%Y-%m-%d_%H-%M-%S); mkdir -p $O
exec > >(tee -a "$O/log.txt") 2>&1
[ -f "$KO" ] || { echo "STOP: lipseste $KO"; exit 1; }
modinfo -F vermagic "$KO" | grep -q "^$(uname -r) " || { echo "STOP: modul compilat pt alt kernel"; exit 1; }
lsmod | grep -q '^legion_laptop ' && { echo "deja incarcat:"; cat /sys/module/legion_laptop/parameters/ec_readonly; } || {
    T0=$(date '+%F %T')
    insmod "$KO" ec_readonly=1 enable_platformprofile=0; echo "insmod exit=$?"
    journalctl -k --since "$T0" --no-pager -o cat | tail -25
}
echo "== parametri: ec_readonly=$(cat /sys/module/legion_laptop/parameters/ec_readonly 2>/dev/null) platformprofile=$(cat /sys/module/legion_laptop/parameters/enable_platformprofile 2>/dev/null)"
echo "== platform_profile (tot gamezone): $(cat /sys/firmware/acpi/platform_profile 2>/dev/null) / $(cat /sys/firmware/acpi/platform_profile_choices 2>/dev/null)"
for h in /sys/class/hwmon/hwmon*; do
    [ "$(cat $h/name 2>/dev/null)" = legion ] || continue
    echo "== hwmon $h"
    for f in $h/*; do [ -f "$f" ] && [ -r "$f" ] && printf '%-34s %s\n' "$(basename $f)" "$(cat $f 2>/dev/null | head -1)"; done
done
command -v sensors >/dev/null && { echo "== sensors"; sensors 'legion-*' 2>&1 | head -30; }
D=/sys/kernel/debug/legion; [ -d $D ] && for f in $D/*; do echo "== debugfs $(basename $f)"; head -40 "$f" 2>&1; done
chown -R mastermind:mastermind $O; echo "log: $O"
