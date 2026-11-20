#!/bin/sh
# CS2 pe Linux: fonts.conf-ul Panorama vrea sa limiteze fonturile cu <fontpattern> (extensie Valve, merge doar pe Windows);
# fontconfig-ul de pe Linux o ignora („unknown element”), deci jocul cauta litere prin TOATE cele ~3700 de fonturi din
# /usr/share/fonts -> sacadari cand apare text nou (kill feed, final de runda). Fix: jocul vede doar fonturile proprii
# (NotoSans latin/chirilic/grec, JP/KR/SC/TC, Thai, simboluri, Stratum2) = aproape ce vede si pe Windows.
# Idempotent; Steam il reface la update/verify, de aceea il ruleaza cs2-perf la fiecare pornire. 2026-11-01
# Folosire: cs2-fonts-fix.sh apply | revert | status
F="/mnt/games/SteamLibrary/steamapps/common/Counter-Strike Global Offensive/game/csgo/panorama/fonts/fonts.conf"
B="$HOME/.config-backups/cs2-fonts-original.conf"
[ -f "$F" ] || { echo "lipseste $F"; exit 1; }
case "${1:-status}" in
apply)
    grep -q 'KALI-FONTS-FIX' "$F" && { echo "deja aplicat"; exit 0; }
    mkdir -p "${B%/*}"; cp -p "$F" "$B"
    sed -i -E 's#^(\s*)(<dir>(~/\.fonts|/usr/share/fonts|/usr/local/share/fonts)</dir>|<dir prefix="xdg">fonts</dir>)#\1<!-- KALI-FONTS-FIX \2 -->#' "$F"
    echo "aplicat (original in $B)" ;;
revert)
    sed -i -E 's#<!-- KALI-FONTS-FIX (.*) -->#\1#' "$F"; echo "revenit" ;;
*)
    grep -q 'KALI-FONTS-FIX' "$F" && echo "aplicat" || echo "neaplicat" ;;
esac
grep -nE '<dir|KALI-FONTS-FIX' "$F" | head -8
