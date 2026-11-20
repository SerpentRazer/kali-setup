#!/bin/bash
# Punte temporara (1 nov 2026): tine microfonul intern la 20% (orice schimbare -> inapoi la 20%) cat ruleaza CS2. Cand se inchide
# CS2, reporneste pipewire-pulse ca sa se incarce regula permanenta block-source-volume
# (~/.config/pipewire/pipewire-pulse.conf.d/20-blocheaza-agc-microfon.conf), o verifica si iese.
set -u
SRC=alsa_input.pci-0000_00_1f.3.analog-stereo
fix() { local v; v=$(pactl get-source-volume $SRC 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d %); [ -n "$v" ] && [ "$v" != 20 ] && { pactl set-source-volume $SRC 20%; echo "$(date +%T) microfon $v% -> 20%"; }; }
fix
pactl subscribe | while read -r line; do
    case "$line" in *"on source #"*) fix;; esac
    pgrep -x cs2 >/dev/null || break
done &
SUB=$!
while pgrep -x cs2 >/dev/null; do sleep 3; fix; done
kill $SUB 2>/dev/null; pkill -P $SUB 2>/dev/null
echo "$(date +%T) CS2 inchis -> repornesc pipewire-pulse (regula permanenta)"
systemctl --user restart pipewire-pulse.service; sleep 3
pactl set-source-volume $SRC 20%
T=$(mktemp -d); cp /usr/bin/pactl $T/Discord
$T/Discord set-source-volume $SRC 100% 2>/dev/null; sleep 1
echo "test: un program numit Discord a cerut 100% -> microfonul e acum $(pactl get-source-volume $SRC | grep -o '[0-9]*%' | head -1) (trebuie 20%)"
rm -rf $T
