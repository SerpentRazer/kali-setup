#!/bin/bash
# F4 (15 nov 2026): instaleaza Hyprland 0.57.0 (construit local pe aquamarine 0.16 + mgpuwait), gpu-screen-recorder 5.13.8
# si mpvpaper 1.9. Plasa de siguranta: sesiunea „Hyprland 0.56 (rezerva)” in ecranul de login + revino.sh.
# Rulare: pkexec bash /home/mastermind/src/legion/hypr-057/f4-instaleaza.sh
set -u
W=/home/mastermind/src/legion/hypr-057; S=$W/src; R=$W/rollback; U=mastermind
HYP=$S/hyprland_0.57.0+ds-1+local1_amd64.deb
GSR=$S/gpu-screen-recorder-cli_5.13.8-2+local1_amd64.deb
MPV=$S/mpvpaper-1.9/build/mpvpaper
RESC=/usr/local/lib/hyprland-0.56-rezerva
die(){ echo "STOP: $*"; exit 1; }
[ "$(id -u)" = 0 ] || die "ruleaza cu pkexec"
pgrep -x cs2 >/dev/null && die "inchide CS2"
pgrep -f "[P]athOfExile" >/dev/null && die "inchide POE"
for f in "$HYP" "$GSR" "$MPV" "$R/hyprland_0.56.2+ds-1_amd64.deb"; do [ -e "$f" ] || die "lipseste $f"; done
[ "$(dpkg-query -W -f='${Version}' hyprland)" = "0.56.2+ds-1" ] || die "Hyprland nu e 0.56.2+ds-1 (deja schimbat?)"
dpkg -s libaquamarine15 >/dev/null 2>&1 || die "libaquamarine15 (F2) nu e instalat"
export DEBIAN_FRONTEND=noninteractive
B=/home/$U/.config-backups/pre-hyprland-057-$(date +%F_%H-%M-%S); mkdir -p "$B"
exec > >(tee -a "$B/log.txt") 2>&1

echo "== 1. sesiune de rezerva cu Hyprland 0.56 (binarul actual, foloseste libaquamarine13 care ramane instalat)"
install -D -m 755 /usr/bin/Hyprland "$RESC/Hyprland"
ldd "$RESC/Hyprland" | grep -q 'not found' && die "binarul de rezerva nu-si gaseste bibliotecile"
cat > /usr/share/wayland-sessions/hyprland-056-rezerva.desktop <<EOF
[Desktop Entry]
Name=Hyprland 0.56 (rezerva)
Comment=Hyprland-ul vechi, daca 0.57 nu porneste. Apoi: pkexec bash $B/revino.sh
Exec=$RESC/Hyprland
Type=Application
DesktopNames=Hyprland
EOF
echo "   $RESC/Hyprland -> $("$RESC/Hyprland" --version 2>/dev/null | head -1 | cut -c1-40)"

echo "== 2. revino.sh"
dpkg-query -W -f='${Package}=${Version}\n' > "$B/pachete-inainte.txt"
cat > "$B/revino.sh" <<EOF
#!/bin/bash
# Revine la Hyprland 0.56.2 (pachetul salvat in F2). Rulare: pkexec bash $B/revino.sh  (sau sudo din TTY)
[ "\$(id -u)" = 0 ] || { echo "ruleaza cu pkexec/sudo"; exit 1; }
apt-mark unhold hyprland
apt-get install -y --allow-downgrades "$R/hyprland_0.56.2+ds-1_amd64.deb" && apt-mark hold hyprland hyprland-guiutils
echo "revenit la Hyprland \$(dpkg-query -W -f='\${Version}' hyprland). Delogheaza-te si logheaza-te inapoi."
EOF
chmod 755 "$B/revino.sh"

echo "== 3. instalare (simulare intai)"
apt-get -s install --allow-change-held-packages "$HYP" "$GSR" > "$B/sim.txt" 2>&1 || { tail -5 "$B/sim.txt"; die "simulare esuata"; }
grep -q '^Remv' "$B/sim.txt" && { grep '^Remv' "$B/sim.txt"; die "ar sterge pachete"; }
apt-mark unhold hyprland >/dev/null
apt-get install -y --allow-change-held-packages "$HYP" "$GSR" 2>&1 | tail -3
[ "$(dpkg-query -W -f='${Version}' hyprland)" = "0.57.0+ds-1+local1" ] || { echo "instalarea a esuat -> revin"; bash "$B/revino.sh"; die "revenit"; }
# pe hold: Kali ar inlocui cu un Hyprland/aquamarine FARA patch-ul mgpuwait (patrate violet in Hybrid Mode)
apt-mark hold hyprland hyprland-guiutils libaquamarine15 libaquamarine-dev >/dev/null
echo "   hold: $(apt-mark showhold | tr '\n' ' ')"

echo "== 4. gpu-screen-recorder: captura KMS fara parola la fiecare inregistrare"
setcap cap_sys_admin+ep /usr/bin/gsr-kms-server && echo "   $(getcap /usr/bin/gsr-kms-server)"

echo "== 5. mpvpaper in ~/.local/bin (al userului)"
runuser -u $U -- install -D -m 755 "$MPV" /home/$U/.local/bin/mpvpaper && echo "   $(runuser -u $U -- /home/$U/.local/bin/mpvpaper --help 2>&1 | head -1 | cut -c1-60)"

chown -R $U:$U "$B"
echo
echo "GATA. Hyprland $(dpkg-query -W -f='${Version}' hyprland) instalat; sesiunea curenta ramane pe 0.56 pana la relogin."
echo "Pas urmator: SUPER+SHIFT+E (logout) -> login cu sesiunea „Hyprland” (normala)."
echo "Daca NU porneste: alege „Hyprland 0.56 (rezerva)” in ecranul de login, apoi: pkexec bash $B/revino.sh"
