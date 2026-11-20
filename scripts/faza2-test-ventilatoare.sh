#!/bin/bash
# LenovoLegionLinux faza 2 (1 nov): test A/B racire. 16 fire de calcul (python) cate 90 s:
#   A = ventilatoare pe curba EC (4400 RPM maxim), B = fan_fullspeed=1 (modul „max fan” din firmware, prin WMI).
# Masoara la 1 s: RPM, temperatura pachet, MHz medii, putere pachet (RAPL), franari termice. ~5 min, ventilatoare tare.
# Ruleaza: pkexec /bin/bash /home/mastermind/src/legion/faza2-test-ventilatoare.sh   (cu laptopul la priza, fara joc pornit)
set -u
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
[ "$(id -u)" = 0 ] || { echo "Ruleaza cu pkexec."; exit 1; }
L=/sys/devices/platform/legion
[ -w $L/fan_fullspeed ] || { echo "STOP: modulul legion_laptop nu e incarcat (faza1-citire.sh)"; exit 1; }
H=$(for h in /sys/class/hwmon/hwmon*; do [ "$(cat $h/name)" = legion_hwmon ] && echo $h; done)
C=$(for h in /sys/class/hwmon/hwmon*; do [ "$(cat $h/name)" = coretemp ] && echo $h; done)
E=/sys/class/powercap/intel-rapl:0/energy_uj
O=/home/mastermind/.cache/legion-faza2-$(date +%Y-%m-%d_%H-%M-%S); mkdir -p $O
exec > >(tee -a "$O/log.txt") 2>&1
PIDS=()
stop_load() { for p in "${PIDS[@]}"; do kill $p 2>/dev/null; done; PIDS=(); }
finish() { stop_load; echo 0 > $L/fan_fullspeed 2>/dev/null; echo "fan_fullspeed final = $(cat $L/fan_fullspeed)"; chown -R mastermind:mastermind $O; }
trap finish EXIT
pgrep -f 'cs2|PathOfExile|gamescope' >/dev/null && { echo "STOP: ruleaza un joc"; exit 1; }
echo "alimentare: $(cat /sys/class/power_supply/ADP0/online 2>/dev/null) (1 = priza)  profil: $(cat /sys/firmware/acpi/platform_profile)"
sample() { # $1 = faza, $2 = secunde
    local e0 t0 e1 n=0 th0 th1
    e0=$(cat $E); th0=$(cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_count)
    while [ $n -lt $2 ]; do
        sleep 1; n=$((n+1)); e1=$(cat $E); th1=$(cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_count)
        mhz=$(awk '{s+=$1; k++} END {printf "%d", s/k/1000}' /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq)
        printf '%s,%d,%s,%s,%d,%d,%.1f,%d\n' $1 $n $(cat $H/fan1_input) $(cat $H/fan2_input) $(( $(cat $C/temp1_input)/1000 )) $mhz \
            $(awk -v a=$e0 -v b=$e1 'BEGIN{print (b-a)/1e6}') $((th1-th0)) >> $O/samples.csv
        e0=$e1; th0=$th1
    done
}
load() { for i in $(seq 1 $(nproc)); do python3 -I -c 'while True: pass' & PIDS+=($!); done; }
echo "faza,s,fan1,fan2,temp_pachet,mhz_medie,watt_pachet,franari" > $O/samples.csv
cool() { local n=0; while [ $n -lt 150 ] && [ $(( $(cat $C/temp1_input)/1000 )) -gt 58 ]; do sleep 1; n=$((n+1)); done; echo "racit in ${n}s la $(( $(cat $C/temp1_input)/1000 ))°C"; }
echo 0 > $L/fan_fullspeed; cool
echo "== A: curba normala, 90 s"; load; sample A 90; stop_load
echo 0 > $L/fan_fullspeed; cool
echo "== B: fan_fullspeed=1, 90 s"
if echo 1 > $L/fan_fullspeed; then echo "fan_fullspeed = $(cat $L/fan_fullspeed)"; else echo "STOP: scrierea fan_fullspeed a esuat"; exit 1; fi
sleep 5; load; sample B 90; stop_load
echo 0 > $L/fan_fullspeed; sleep 8; echo "dupa revenire: fan1 $(cat $H/fan1_input) fan2 $(cat $H/fan2_input) RPM"
echo "== rezumat (ultimele 45 s din fiecare faza)"
awk -F, 'NR>1 && $2>45 {k=$1; n[k]++; f1[k]+=$3; f2[k]+=$4; t[k]+=$5; if($5>tm[k])tm[k]=$5; m[k]+=$6; w[k]+=$7; th[k]+=$8}
  END {for (k in n) printf "%s: fan1 %d fan2 %d RPM | pachet %.1f°C (max %d) | %d MHz | %.1f W | franari %.0f/s\n", k, f1[k]/n[k], f2[k]/n[k], t[k]/n[k], tm[k], m[k]/n[k], w[k]/n[k], th[k]/n[k]}' $O/samples.csv | sort
echo "date: $O/samples.csv"
