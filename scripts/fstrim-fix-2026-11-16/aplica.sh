#!/bin/bash
# 16 nov 2026: fstrim (saptamanal) a pornit la 20:50 in timpul unui meci CS2 si NU s-a terminat in 6 min: trim-ul pe C: (ntfs-3g,
# FUSE) blocheaza partitia -> Steam (biblioteca/Proton pe C:) s-a blocat -> CS2 agatat la iesire. Fix: C: si bind-ul de fisier
# al manifestului CS2 primesc `X-fstrim.notrim` (fstrim le sare). Windows isi face singur TRIM pe C: (Optimize Drives).
# Rulare: pkexec bash ~/src/legion/fstrim-fix-2026-11-16/aplica.sh
set -u
[ "$(id -u)" = 0 ] || { echo "ruleaza cu pkexec"; exit 1; }
B=/home/mastermind/.config-backups/pre-fstrim-fix-$(date +%F_%H-%M-%S); mkdir -p "$B"; cp -p /etc/fstab "$B/fstab"
python3 -I - <<'PY'
import re
p='/etc/fstab'; L=open(p).read().split('\n'); n=0
for i,l in enumerate(L):
    if l.lstrip().startswith('#') or not l.strip(): continue
    f=l.split()
    if len(f)>=4 and (f[1]=='/mnt/windows' or f[1].endswith('appmanifest_730.acf')) and 'X-fstrim.notrim' not in f[3]:
        L[i]=l.replace(f[3], f[3]+',X-fstrim.notrim',1); n+=1
open(p,'w').write('\n'.join(L)); print("linii modificate:", n)
PY
findmnt --verify --tab-file /etc/fstab 2>&1 | tail -2
systemctl daemon-reload
printf '#!/bin/sh\ncp -p "%s/fstab" /etc/fstab && systemctl daemon-reload && echo revenit\n' "$B" > "$B/revino.sh"; chmod 755 "$B/revino.sh"; chown -R 1000:1000 "$B"
echo "== simulare (fstrim -n): ce ar curata acum"
fstrim --listed-in /etc/fstab:/proc/self/mountinfo --verbose --quiet-unsupported -n 2>&1
echo "GATA. Backup + revino.sh: $B"
