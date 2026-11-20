#!/bin/bash
# Steam voice: Automatic Gain Control OFF (1 nov 2026). AGC-ul urca volumul microfonului in sistem la 100% (+60 dB pe DMIC-ul
# laptopului = sasait saturat, „se aude groaznic / prea tare pt altii”). Steam rescrie localconfig.vdf la iesire, deci asteapta
# sa fie inchis complet, apoi schimba DOAR "autoGainControl":true -> false in SteamVoiceSettings (backup inainte).
set -u
V=/home/mastermind/.steam/debian-installation/userdata/461618270/config/localconfig.vdf
echo "astept sa inchizi Steam (Steam > Exit)..."
n=0; while pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; do sleep 1; n=$((n+1)); [ $n -gt 7200 ] && { echo "Steam tot pornit dupa 2 h - renunt"; exit 1; }; done
sleep 2; pgrep -x steam >/dev/null && { echo "Steam a repornit - renunt"; exit 1; }
B=/home/mastermind/.config-backups/steam-voice-agc-$(date +%Y-%m-%d_%H-%M-%S); mkdir -p $B; cp -p $V $B/
python3 -I - "$V" <<'EOF'
import sys
p=sys.argv[1]; s=open(p,encoding='utf-8').read()
on, off = '\\"autoGainControl\\":true', '\\"autoGainControl\\":false'
line=[l for l in s.split('\n') if '"SteamVoiceSettings_' in l]
if len(line)!=1: sys.exit("STOP: nu gasesc exact o linie SteamVoiceSettings")
if off in line[0]: print("deja oprit"); sys.exit(0)
if on not in line[0]: sys.exit("STOP: autoGainControl nu e in forma asteptata")
s=s.replace(line[0], line[0].replace(on, off)); open(p,'w',encoding='utf-8').write(s); print("AGC Steam oprit")
EOF
echo "backup: $B/localconfig.vdf"; grep -o 'autoGainControl\\":[a-z]*' $V
