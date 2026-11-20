#!/bin/bash
# CS2 cu/fara gamescope: schimba LaunchOptions (app 730) in localconfig.vdf. Steam rescrie fisierul la iesire, deci scriptul
# ASTEAPTA sa fie Steam inchis complet, apoi face schimbarea (backup inainte). 1 nov 2026.
#   bash cs2-fara-gamescope.sh fara   -> varianta B (fara gamescope: jocul vede direct Samsung-ul, Fullscreen exclusiv)
#   bash cs2-fara-gamescope.sh cu     -> varianta A (inapoi prin gamescope, ca pana acum)
set -u
V=/home/mastermind/.steam/debian-installation/userdata/461618270/config/localconfig.vdf
O=/home/mastermind/src/legion/cs2-launch-options.txt
A=$(sed -n 4p $O); Bv=$(sed -n 7p $O)
case "${1:-}" in fara) OLD=$A; NEW=$Bv;; cu) OLD=$Bv; NEW=$A;; *) echo "folosire: $0 fara|cu"; exit 1;; esac
echo "astept sa inchizi Steam (Steam > Exit)..."
n=0; while pgrep -x steam >/dev/null || pgrep -x steamwebhelper >/dev/null; do sleep 1; n=$((n+1)); [ $n -gt 1800 ] && { echo "Steam tot pornit dupa 30 min - renunt"; exit 1; }; done
sleep 2; pgrep -x steam >/dev/null && { echo "Steam a repornit - renunt"; exit 1; }
B=/home/mastermind/.config-backups/cs2-launch-$(date +%Y-%m-%d_%H-%M-%S); mkdir -p $B; cp -p $V $B/
python3 -I - "$V" "$OLD" "$NEW" <<'EOF'
import sys
p,old,new=sys.argv[1:4]; s=open(p,encoding='utf-8').read()
k='"LaunchOptions"\t\t"'
if s.count(k+new+'"')>=1 and s.count(k+old+'"')==0: print("deja aplicat"); sys.exit(0)
i=s.index('\t"730"\n'); blk=s[i:s.index('\n\t\t\t\t\t}',i)]
if blk.count(k+old+'"')!=1: sys.exit("STOP: nu gasesc exact optiunile vechi in blocul 730 - nu schimb nimic")
s=s[:i]+blk.replace(k+old+'"',k+new+'"')+s[i+len(blk):]
open(p,'w',encoding='utf-8').write(s); print("optiuni CS2 schimbate")
EOF
echo "backup: $B/localconfig.vdf"
grep -c "\"LaunchOptions\"		\"$NEW\"" $V | sed 's/^/verificare (1 = ok): /'
