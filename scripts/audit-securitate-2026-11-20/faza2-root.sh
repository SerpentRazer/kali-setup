#!/bin/bash
# Audit de securitate, faza 2 (20 nov 2026) — verificarile care cer root. DOAR CITIRE: nu schimba nicio setare.
# Singura modificare: instaleaza scannerele lynis, rkhunter, chkrootkit, debsums (fara pachete recomandate = fara server de mail).
# Metodologie: skill-urile mukul975/Anthropic-Cybersecurity-Skills — hardening-linux-endpoint-with-cis-benchmark,
#   detecting-rootkit-activity, analyzing-persistence-mechanisms-in-linux, detecting-privilege-escalation-attempts.
# Rulare:  pkexec bash /home/mastermind/src/legion/audit-securitate-2026-11-20/faza2-root.sh      (~5-10 min)
# Rezultat: raport-root.txt + lynis-report.dat in acelasi dosar (le citeste Claude).
set -u
D=/home/mastermind/src/legion/audit-securitate-2026-11-20; U=mastermind
R=$D/raport-root.txt
[ "$(id -u)" = 0 ] || { echo "ruleaza cu pkexec"; exit 1; }
pgrep -x cs2 >/dev/null && { echo "inchide CS2 intai (scanarea incarca discul)"; exit 1; }
: > "$R"
sec() { echo; echo "######## $*"; } >> "$R"
run() { echo "\$ $*" >> "$R"; timeout 900 "$@" >> "$R" 2>&1; }
echo "raport in $R"

echo "== 1/9 instalez scannerele (simulare intai)"
export DEBIAN_FRONTEND=noninteractive
PK="lynis rkhunter chkrootkit debsums"
sim=$(apt-get -s install --no-install-recommends $PK 2>&1)
echo "$sim" | grep -q '^Remv' && { echo "STOP: instalarea ar sterge pachete"; echo "$sim" | grep '^Remv'; exit 1; }
apt-get install -y --no-install-recommends $PK 2>&1 | tail -2

echo "== 2/9 conturi si sudo"
sec "CONTURI: parole goale / stare root / UID 0"
awk -F: '($2 == "") {print "PAROLA GOALA: " $1}' /etc/shadow >> "$R"
awk -F: '($3 == 0) {print "UID 0: " $1}' /etc/passwd >> "$R"
run passwd -S root
run passwd -S mastermind
run passwd -S postgres
sec "SUDOERS (fara comentarii)"
grep -hvE '^\s*(#|$)' /etc/sudoers /etc/sudoers.d/* >> "$R" 2>&1

echo "== 3/9 firewall si docker"
sec "FIREWALL: nft / iptables"
run nft list ruleset
run iptables -S
sec "DOCKER: containere / imagini / porturi publicate"
run docker ps -a --format '{{.Names}} | {{.Image}} | {{.Status}} | {{.Ports}}'
run docker images --format '{{.Repository}}:{{.Tag}} {{.CreatedSince}}'

echo "== 4/9 xrdp: cine s-a conectat (30 zile)"
sec "XRDP: conexiuni si logari (30 zile)"
journalctl -u xrdp -u xrdp-sesman --since "30 days ago" --no-pager 2>/dev/null \
    | grep -iE 'connection (received|accepted)|login (successful|failed)|authentication|session started|from [0-9]' | tail -40 >> "$R"
echo "total linii jurnal xrdp 30 zile: $(journalctl -u xrdp -u xrdp-sesman --since '30 days ago' --no-pager 2>/dev/null | wc -l)" >> "$R"
sec "LOGARI ESUATE (auth, 30 zile)"
journalctl --since "30 days ago" --no-pager _COMM=sshd _COMM=xrdp-sesman _COMM=login _COMM=sddm-helper 2>/dev/null \
    | grep -iE 'fail|invalid|authentication failure' | tail -20 >> "$R"

echo "== 5/9 runZero agent (fisiere, fara continut)"
sec "RUNZERO"
run ls -la /opt/runzero/bin /opt/runzero/bin/tmp
run sha256sum /opt/runzero/bin/runzero-agent-0a29466a-deff-4a04-a670-13c8e24dc363

echo "== 6/9 permisiuni"
sec "GRUB: permisiuni grub.cfg + parola"
run stat -c '%a %U:%G %n' /boot/grub/grub.cfg
grep -c 'password_pbkdf2' /boot/grub/grub.cfg >> "$R" 2>&1
sec "FISIERE SCRIIBILE DE ORICINE in /etc /usr /opt /boot"
find /etc /usr /opt /boot -xdev -type f -perm -0002 2>/dev/null | head -30 >> "$R"

echo "== 7/9 debsums (fisiere din pachete modificate)"
sec "DEBSUMS: fisiere de configurare/binare schimbate fata de pachet"
debsums -s 2>&1 | head -80 >> "$R"

echo "== 8/9 rootkit-uri (chkrootkit + rkhunter)"
sec "CHKROOTKIT (doar ce e suspect)"
run chkrootkit -q
sec "RKHUNTER (doar avertismente)"
rkhunter --propupd --nocolors >/dev/null 2>&1
run rkhunter --check --sk --rwo --nocolors

echo "== 9/9 lynis (audit complet de hardening)"
sec "LYNIS"
lynis audit system --quick --no-colors > "$D/lynis-out.txt" 2>&1
cp /var/log/lynis-report.dat "$D/lynis-report.dat" 2>/dev/null
grep -E '^(hardening_index|warning\[\]|suggestion\[\])' "$D/lynis-report.dat" >> "$R" 2>/dev/null

chown -R $U:$U "$D"
echo
echo "GATA. Spune-i lui Claude (raport: $R)."
