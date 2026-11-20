#!/bin/bash
# Stinge ecranul laptopului (eDP-1) cat ruleaza CS2 si il aprinde la iesire (1 nov 2026). Cu Hyprland pe NVIDIA, fiecare cadru
# spre laptop (placa Intel) e copiat prin procesor (~33% dintr-un nucleu cu Spotify/animatii) -> procesorul scapa de asta in joc.
# Siguranta: stinge DOAR daca fereastra jocului e pe alt monitor decat eDP-1 (fara Samsung nu stinge nimic); trap -> aprinde la loc.
# Pornit de ~/.local/bin/cs2-perf cat exista ~/.config/cs2-laptop-stins (sterge fisierul ca sa opresti functia).
set -u
CLASS=${CLASS:-gamescope|cs2}
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/ecran-laptop-joc.lock"; flock -n 9 || exit 0
dpms() { hyprctl dispatch "hl.dsp.dpms({action = \"$1\", monitor = \"eDP-1\"})" >/dev/null 2>&1; }
game_monitor() { # numele monitorului pe care e fereastra jocului (gol daca nu exista inca)
    local id; id=$(hyprctl -j clients 2>/dev/null | jq -r --arg c "^($CLASS)\$" '[.[] | select(.class|test($c))][0].monitor // empty')
    [ -n "$id" ] && hyprctl -j monitors 2>/dev/null | jq -r --argjson i "$id" '.[] | select(.id==$i) | .name'
}
w=0; until pgrep -x cs2 >/dev/null; do sleep 2; w=$((w+2)); [ $w -gt ${ASTEAPTA:-900} ] && exit 0; done
m=""; w=0; until [ -n "$m" ]; do sleep 2; m=$(game_monitor); w=$((w+2)); [ $w -gt 120 ] && exit 0; pgrep -x cs2 >/dev/null || exit 0; done
[ "$m" = "eDP-1" ] && exit 0
trap 'dpms on' EXIT INT TERM HUP
dpms off
while pgrep -x cs2 >/dev/null; do sleep 2; done
