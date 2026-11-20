#!/bin/bash
# Elimina runZero agent (instalat 17 iul 2025, rula ca root, raporta la console.runzero.com, org 0a29466a-...).
# Cerut de user 20 nov 2026 („runZero kill”). Pastreaza o copie a unitatii systemd + hash-ul binarului, ca dovada.
# Rulare:  pkexec bash /home/mastermind/src/legion/audit-securitate-2026-11-20/sterge-runzero.sh
set -u
[ "$(id -u)" = 0 ] || { echo "ruleaza cu pkexec"; exit 1; }
N=runzero-agent-0a29466a-deff-4a04-a670-13c8e24dc363
B=/home/mastermind/.config-backups/runzero-sters-$(date +%F_%H-%M-%S); mkdir -p "$B"
cp -a /etc/systemd/system/$N.service "$B/" 2>/dev/null
sha256sum /opt/runzero/bin/$N > "$B/sha256-binar.txt" 2>/dev/null
ls -laR /opt/runzero > "$B/continut-opt-runzero.txt" 2>/dev/null
journalctl -u $N --no-pager > "$B/jurnal.txt" 2>/dev/null

echo "== 1. opresc si dezactivez serviciul"
systemctl disable --now $N.service 2>&1 | tail -2
pkill -f "/opt/runzero/bin/" 2>/dev/null; sleep 1
echo "== 2. sterg unitatea si fisierele"
rm -f /etc/systemd/system/$N.service /etc/systemd/system/*/$N.service
systemctl daemon-reload; systemctl reset-failed 2>/dev/null
rm -rf /opt/runzero
echo "== 3. verificare"
systemctl list-unit-files 2>/dev/null | grep -i runzero || echo "   unitate: nu mai exista"
pgrep -af "[r]unzero" || echo "   proces: nu mai ruleaza"
[ -e /opt/runzero ] && echo "   ATENTIE: /opt/runzero inca exista" || echo "   /opt/runzero: sters"
chown -R mastermind:mastermind "$B"
echo "GATA. Copie (unitate, hash, jurnal) in $B"
