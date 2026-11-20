#!/bin/bash
# Instaleaza tema 43PR combinata (upstream 31245c8 din 19 nov + patch-urile noastre Kali), 20 nov 2026.
# Ce face: backup -> migreaza starea barei -> copiaza fisierele combinate in ~/.config -> sterge ce a scos upstream
#          -> hyprctl reload + pauza wallpaper video -> reporneste bara (qs) -> verifica.
# Revenire: bash <backup>/revino.sh   (calea o afiseaza la final)
# Ruleaza (din kitty sau cu ! in Claude):  bash ~/src/legion/43pr-merge-2026-11-20/instaleaza.sh
set -u
D=$(dirname "$(readlink -f "$0")")
C=$HOME/.config
B=$HOME/.config-backups/pre-43pr-update-$(date +%Y-%m-%d_%H-%M-%S)
die() { echo "STOP: $*"; exit 1; }
pgrep -x cs2 >/dev/null && die "CS2 ruleaza — inchide jocul intai (se reincarca Hyprland)"
pgrep -f "[P]athOfExile" >/dev/null && die "POE ruleaza — inchide jocul intai"
[ -d "$D/merged" ] || die "lipseste $D/merged"
mkdir -p "$B/config"
exec > >(tee -a "$B/log.txt") 2>&1

echo "== 1. backup in $B"
: > "$B/noi.txt"
while read -r f; do f=${f#./}
    if [ -e "$C/$f" ]; then mkdir -p "$B/config/$(dirname "$f")"; cp -a "$C/$f" "$B/config/$f"; else echo "$f" >> "$B/noi.txt"; fi
done < "$D/fisiere.txt"
while read -r f; do [ -e "$C/$f" ] && { mkdir -p "$B/config/$(dirname "$f")"; cp -a "$C/$f" "$B/config/$f"; }; done < "$D/sterse.txt"
cp -a "$C/quickshell/state" "$B/qs-state"
[ -e "$C/hypr/colors.lua" ] || echo "hypr/colors.lua" >> "$B/noi.txt"
gsettings get org.gnome.desktop.interface icon-theme > "$B/icon-theme.txt"
for g in gtk-3.0 gtk-4.0; do cp -a "$C/$g/settings.ini" "$B/$g-settings.ini" 2>/dev/null; done
cat > "$B/revino.sh" <<EOF
#!/bin/bash
# Revine la tema de dinainte de $(date '+%d %b %H:%M')
cp -a "$B/config/." "$C/"
while read -r f; do [ -n "\$f" ] && rm -f "$C/\$f"; done < "$B/noi.txt"
rm -rf "$C/quickshell/state"; cp -a "$B/qs-state" "$C/quickshell/state"
for g in gtk-3.0 gtk-4.0; do [ -e "$B/\$g-settings.ini" ] && cp -a "$B/\$g-settings.ini" "$C/\$g/settings.ini"; done
gsettings set org.gnome.desktop.interface icon-theme $(cat "$B/icon-theme.txt")
hyprctl reload >/dev/null
pkill -f "[l]ive-wallpaper-pause.sh"; pkill -CONT -x mpvpaper
pkill -x qs; sleep 0.5
QSG_RENDER_LOOP=basic QS_ICON_THEME=Papirus setsid -f qs >/dev/null 2>&1 </dev/null
echo "revenit la tema veche (bara repornita)"
EOF
chmod +x "$B/revino.sh"
echo "  $(find "$B/config" -type f | wc -l) fisiere salvate, $(wc -l < "$B/noi.txt") noi"

echo "== 2. migrare stare bara / hub"
bash "$D/migreaza-stare.sh" "$HOME"

echo "== 3. copiere fisiere combinate"
cp -a "$D/merged/." "$C/"
while read -r f; do rm -f "$C/$f"; done < "$D/sterse.txt"
echo "  $(wc -l < "$D/fisiere.txt") fisiere copiate, $(wc -l < "$D/sterse.txt") sterse"

echo "== 4. theme.py: fara apply (versiunea noua doar adauga comanda palette; culorile raman)"

echo "== 5. Hyprland reload + pauza wallpaper video la fullscreen (nou)"
pkill -f "[l]ive-wallpaper-pause.sh"; setsid -f "$C/hypr/scripts/live-wallpaper-pause.sh" >/dev/null 2>&1 </dev/null
hyprctl reload >/dev/null; sleep 1
err=$(hyprctl configerrors 2>&1 | grep -v '^$')
[ -n "$err" ] && echo "  ERORI config Hyprland: $err" || echo "  config Hyprland: fara erori"

echo "== 6. reporneste bara"
pkill -x qs; sleep 0.5
QSG_RENDER_LOOP=basic QS_ICON_THEME=Papirus setsid -f qs >/dev/null 2>&1 </dev/null
sleep 6
L=$(command ls -td "$XDG_RUNTIME_DIR"/quickshell/by-id/*/ 2>/dev/null | head -1)
if pgrep -x qs >/dev/null; then
    n=$(grep -ciE 'error|is not a type|cannot assign|undefined' "${L}log.log" 2>/dev/null)
    echo "  qs ruleaza; erori in log: ${n:-?}"
    grep -iE 'error|is not a type|cannot assign|undefined' "${L}log.log" 2>/dev/null | head -10
else
    echo "  ATENTIE: qs NU ruleaza -> revin automat"; bash "$B/revino.sh"; exit 1
fi
# biti de executie (copierea de data trecuta i-a pierdut -> SUPER+SHIFT+S nu mergea)
nx=0; for f in $(cd "$D/merged" && find . -type f -perm -u+x); do [ -x "$C/$f" ] || { chmod +x "$C/$f"; nx=$((nx+1)); }; done
echo "  biti +x corectati: $nx"
echo; echo "GATA. Daca ceva nu-ti place:  bash $B/revino.sh"

