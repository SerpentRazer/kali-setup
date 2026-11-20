#!/bin/bash
# Alege cum se leaga gamescope (CS2) de Hyprland. 1 nov 2026.
#   wayland : Wayland nativ — tastele/click-urile/mouse-ul ajung direct la gamescope (fara Xwayland-ul Hyprland + SDL)
#   sdl     : varianta veche (gamescope ca aplicatie X11 prin SDL; pe 28 oct 'wayland' omora Hyprland-ul pornit pe Intel)
# Steam rescrie localconfig.vdf la iesire -> scriptul asteapta sa fie Steam inchis. Backup inainte.
#   bash ~/src/legion/cs2-gamescope-backend.sh wayland|sdl
set -u
V=/home/mastermind/.steam/debian-installation/userdata/461618270/config/localconfig.vdf
O=/home/mastermind/src/legion/cs2-launch-options.txt
case "${1:-}" in wayland) OLD=sdl; NEW=wayland;; sdl) OLD=wayland; NEW=sdl;; *) echo "folosire: $0 wayland|sdl"; exit 1;; esac
n=0; while pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; do
    [ $n -eq 0 ] && echo "astept sa inchizi Steam (Steam > Exit)..."; sleep 1; n=$((n+1)); [ $n -gt 1800 ] && { echo "renunt"; exit 1; }; done
B=/home/mastermind/.config-backups/cs2-backend-$(date +%Y-%m-%d_%H-%M-%S); mkdir -p $B; cp -p $V $O $B/
python3 -I - "$V" "$OLD" "$NEW" <<'PY'
import sys
p, old, new = sys.argv[1:4]; s = open(p, encoding='utf-8').read()
i = s.index('\t"730"\n'); j = s.index('\n\t\t\t\t\t}', i); blk = s[i:j]
if blk.count('--backend ' + new) == 1 and blk.count('--backend ' + old) == 0: print("deja pe", new); sys.exit(0)
if blk.count('--backend ' + old) != 1: sys.exit("STOP: nu gasesc --backend " + old + " in optiunile CS2")
s = s[:i] + blk.replace('--backend ' + old, '--backend ' + new) + s[j:]
open(p, 'w', encoding='utf-8').write(s); print("CS2: gamescope --backend", new)
PY
sed -i "4s/--backend $OLD/--backend $NEW/" $O
echo "backup: $B"
