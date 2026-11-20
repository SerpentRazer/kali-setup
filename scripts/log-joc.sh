#!/bin/bash
# Logger pentru o sesiune de joc (1 nov, dupa pasta MX-4): asteapta sa porneasca CS2, apoi scrie la 1 s temperatura/puterea/
# frecventa placii NVIDIA (MangoHud nu le vede: gamescope + runtime sniper) si temperatura/MHz/franarile procesorului, pana se
# inchide jocul. Fara root, nu schimba nimic. Ruleaza: bash ~/src/legion/log-joc.sh   (iesire: ~/.cache/joc-log-*/)
set -u
# pornit automat de ~/.local/bin/cs2-perf cand exista ~/.config/cs2-log-on (o singura instanta)
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/log-joc.lock"; flock -n 9 || { echo "logger deja pornit"; exit 0; }
C=$(for h in /sys/class/hwmon/hwmon*; do [ "$(cat $h/name)" = coretemp ] && echo $h; done)
TH=/sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_count
w=0; until pgrep -x cs2 >/dev/null; do sleep 2; w=$((w+2)); [ $w -gt ${ASTEAPTA:-900} ] && { echo "CS2 nu a pornit"; exit 1; }; done
O=$HOME/.cache/joc-log-$(date +%Y-%m-%d_%H-%M-%S); mkdir -p $O
echo "CS2 pornit la $(date +%T), log in $O"
echo "s,gpu_c,gpu_w,gpu_mhz,mem_mhz,pstate,gpu_util,motive,cpu_c,cpu_mhz,franari" > $O/log.csv
# starea Hyprland pe Samsung (HDMI-A-2) = cat de aproape e de „exclusive fullscreen”: solitary + tearing + direct scanout
echo "s,solitary,tearing,tearing_blocat,scanout_direct,scanout_blocat,solitary_blocat,gs_fullscreen,gs_tearinghint,gs_size,gs_monitor" > $O/hypr.csv
s=0; th0=$(cat $TH)
while pgrep -x cs2 >/dev/null; do
    sleep 1; s=$((s+1)); th1=$(cat $TH)
    g=$(nvidia-smi --query-gpu=temperature.gpu,power.draw,clocks.gr,clocks.mem,pstate,utilization.gpu,clocks_event_reasons.active \
        --format=csv,noheader,nounits | tr -d ' ')
    mhz=$(awk '{x+=$1; k++} END {printf "%d", x/k/1000}' /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq)
    echo "$s,$g,$(( $(cat $C/temp1_input)/1000 )),$mhz,$((th1-th0))" >> $O/log.csv; th0=$th1
    m=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.name=="HDMI-A-2") |
        [.solitary, .activelyTearing, ((.tearingBlockedBy // [])|join("+")), .directScanoutTo, ((.directScanoutBlockedBy // [])|join("+")), ((.solitaryBlockedBy // [])|join("+"))] | join(",")')
    w=$(hyprctl -j clients 2>/dev/null | jq -r '[.[] | select(.class=="gamescope" or .class=="cs2")][0] // empty |
        [.fullscreen, .tearingHint, (.size|map(tostring)|join("x")), .monitor] | map(tostring) | join(",")')
    echo "$s,$m,${w:-,,,}" >> $O/hypr.csv
done
echo "CS2 inchis la $(date +%T) dupa ${s}s"
awk -F, 'NR>1 {n++; if($3=="true")t++; if($2!="0")so++; if($5!="0")ds++; tb[$4]++; db[$6]++; fs[$8]++}
  END {if(!n) exit; printf "Hyprland pe Samsung: tearing %d%% | solitary %d%% | scanout direct %d%% din %d s\n", 100*t/n, 100*so/n, 100*ds/n, n
    for(k in tb) printf "  tearing blocat de [%s]: %d s\n", k, tb[k]; for(k in db) printf "  scanout blocat de [%s]: %d s\n", k, db[k]
    for(k in fs) printf "  gamescope fullscreen=%s: %d s\n", k, fs[k]}' $O/hypr.csv | tee $O/rezumat-hypr.txt
# rezumat doar pe secundele in care GPU-ul chiar lucra (>=40%), ca meniurile/incarcarile sa nu dilueze mediile
awk -F, 'NR>1 && $7>=40 {n++; gt+=$2; if($2>gm)gm=$2; gw+=$3; gf+=$4; ct+=$9; if($9>cm)cm=$9; cf+=$10; fr+=$11
    r=strtonum($8); if(and(r,0x20)||and(r,0x40)) term++; if(and(r,0x4)) pcap++}
  END {if(!n){print "GPU nu a trecut de 40% (sesiune prea scurta?)"; exit}
    printf "%d s cu GPU >=40%%\nGPU: %.1f°C (max %d) | %.1f W | %d MHz | franare termica %d s, plafon putere %d s\nCPU: %.1f°C (max %d) | %d MHz | franari %d\n",
    n, gt/n, gm, gw/n, gf/n, term, pcap, ct/n, cm, cf/n, fr}' $O/log.csv | tee $O/rezumat.txt
