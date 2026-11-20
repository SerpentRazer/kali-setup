#!/bin/bash
# Test DUPA curatare + pasta MX-4 (1 nov). Acelasi regim ca faza A din faza2-test-ventilatoare.sh (referinta 09:37):
# 16 fire python 90 s, curba normala de ventilatoare, esantion la 1 s. In plus: ventilatoarele merg in repaus (dupa
# demontare), cat de repede sare temperatura in primele secunde, cat de repede se raceste dupa. ~4 min, ventilatoare tare.
# Ruleaza: pkexec /bin/bash /home/mastermind/src/legion/dupa-pasta-test.sh   (la priza, fara joc pornit)
set -u
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
[ "$(id -u)" = 0 ] || { echo "Ruleaza cu pkexec."; exit 1; }
KO=/home/mastermind/src/legion/LenovoLegionLinux/kernel_module/legion-laptop.ko
REF=/home/mastermind/.cache/legion-faza2-2026-11-01_09-37-37/samples.csv
O=/home/mastermind/.cache/legion-dupa-pasta-$(date +%Y-%m-%d_%H-%M-%S); mkdir -p $O
exec > >(tee -a "$O/log.txt") 2>&1
PIDS=()
stop_load() { for p in "${PIDS[@]}"; do kill $p 2>/dev/null; done; PIDS=(); }
trap 'stop_load; chown -R mastermind:mastermind $O' EXIT
pgrep -f 'cs2|PathOfExile|gamescope' >/dev/null && { echo "STOP: ruleaza un joc"; exit 1; }

if ! lsmod | grep -q '^legion_laptop '; then
    modinfo -F vermagic "$KO" | grep -q "^$(uname -r) " || { echo "STOP: modul compilat pt alt kernel"; exit 1; }
    insmod "$KO" ec_readonly=1 enable_platformprofile=0; echo "insmod (doar citire) exit=$?"
fi
H=$(for h in /sys/class/hwmon/hwmon*; do [ "$(cat $h/name)" = legion_hwmon ] && echo $h; done)
C=$(for h in /sys/class/hwmon/hwmon*; do [ "$(cat $h/name)" = coretemp ] && echo $h; done)
E=/sys/class/powercap/intel-rapl:0/energy_uj
[ -n "$H" ] || { echo "STOP: hwmon legion_hwmon lipseste"; exit 1; }
T() { echo $(( $(cat $C/temp1_input)/1000 )); }

echo "alimentare: $(cat /sys/class/power_supply/ADP0/online) (1 = priza)  profil: $(cat /sys/firmware/acpi/platform_profile)  gpu-mgpu-floor: $(systemctl is-active gpu-mgpu-floor)"
echo "== repaus: pachet $(T)°C  fan1 $(cat $H/fan1_input) fan2 $(cat $H/fan2_input) RPM"
sleep 3
echo "   dupa 3 s: fan1 $(cat $H/fan1_input) fan2 $(cat $H/fan2_input) RPM (0 in repaus poate fi normal; conteaza sa urce sub sarcina)"

n=0; while [ $n -lt 150 ] && [ $(T) -gt 58 ]; do sleep 1; n=$((n+1)); done; echo "pornire de la $(T)°C"

echo "faza,s,fan1,fan2,temp_pachet,mhz_medie,watt_pachet,franari" > $O/samples.csv
# primele 3 s la 0.1 s: doar temperatura (referinta avea deja 96°C la s1)
for i in $(seq 1 $(nproc)); do python3 -I -c 'while True: pass' & PIDS+=($!); done
for k in $(seq 1 30); do sleep 0.1; printf '%s ' $(T); done > $O/primele-3s.txt; echo >> $O/primele-3s.txt
e0=$(cat $E); th0=$(cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_count); s=3
while [ $s -lt 90 ]; do
    sleep 1; s=$((s+1)); e1=$(cat $E); th1=$(cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_count)
    mhz=$(awk '{x+=$1; k++} END {printf "%d", x/k/1000}' /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq)
    printf 'A,%d,%s,%s,%d,%d,%.1f,%d\n' $s $(cat $H/fan1_input) $(cat $H/fan2_input) $(T) $mhz \
        $(awk -v a=$e0 -v b=$e1 'BEGIN{print (b-a)/1e6}') $((th1-th0)) >> $O/samples.csv
    e0=$e1; th0=$th1
done
stop_load
n=0; while [ $n -lt 150 ] && [ $(T) -gt 60 ]; do sleep 1; n=$((n+1)); done; echo "racire dupa sarcina: ${n}s pana la $(T)°C (referinta: 150 s si tot 60°C)"

echo "== temperatura in primele 3 s (la 0.1 s): $(cat $O/primele-3s.txt)"
sum() { awk -F, -v L="$2" 'NR>1 && $1=="A" && $2>45 {n++; f1+=$3; f2+=$4; t+=$5; if($5>tm)tm=$5; m+=$6; w+=$7; th+=$8}
  END {printf "%-7s fan1 %d fan2 %d RPM | pachet %.1f°C (max %d) | %d MHz | %.1f W | franari %.0f/s\n", L, f1/n, f2/n, t/n, tm, m/n, w/n, th/n}' $1; }
echo "== rezumat (ultimele 45 s, acelasi calcul ca la referinta)"
sum $REF INAINTE
sum $O/samples.csv DUPA
echo "date: $O"
