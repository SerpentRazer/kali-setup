#!/bin/bash
# migreaza-stare.sh [HOME] — adapteaza bar-state.json la bara 43PR din 19 nov (merge 20 nov 2026). Idempotent.
#  - vremea: modulul "weather" langa ceas, oras fix Oradea (fara localizare dupa IP)
#  - wsNumbers (scos upstream) -> wsStyle: "numbers" daca era pornit, altfel "dots" (aspectul de acum)
#  - modPad: inainte = padding de fiecare parte a iconitei (2*modPad intre iconite); acum = golul dintre module, iar
#    iconitele au deja 8 px de fiecare parte -> acelasi aspect cu modPad_nou = max(0, 2*modPad_vechi - 16). O singura data.
set -u
H=${1:-$HOME}; f=$H/.config/quickshell/state/bar-state.json
[ -s "$f" ] || { echo "bar-state.json lipsa -> se folosesc implicitele"; exit 0; }
jq 'def all: [(.startMods // ""), (.midLeftMods // ""), (.centerMods // ""), (.midRightMods // ""), (.endMods // ""), (.hidden // "")] | join(",") | split(",");
    .weatherCity = (if (.weatherCity // "") == "" then "Oradea" else .weatherCity end)
    | .wsStyle = (.wsStyle // (if .wsNumbers == true then "numbers" else "dots" end)) | del(.wsNumbers)
    | if (all | index("weather")) then . else
        .centerMods = ((.centerMods // "clock") | split(",") | (index("clock") // -1) as $i
                       | if $i < 0 then . + ["weather"] else .[:$i+1] + ["weather"] + .[$i+1:] end | join(",")) end' \
    "$f" > "$f.tmp" && mv "$f.tmp" "$f" && echo "bar-state.json: $(jq -c '{centerMods, wsStyle, weatherCity}' "$f")"
m=$(dirname "$f")/.migrat-modpad-2026-11-20
if [ ! -e "$m" ]; then
    jq '.modPad = ((((.modPad // 6) * 2) - 16) | if . < 0 then 0 else . end)' "$f" > "$f.tmp" && mv "$f.tmp" "$f" && touch "$m" \
        && echo "modPad convertit: $(jq .modPad "$f")"
fi
