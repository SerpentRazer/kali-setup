#!/bin/bash
# migreaza-stare.sh [HOME] [Theme.qml vechi] — adapteaza starea barei/hub-ului la tema 43PR noua (1 nov 2026).
#  bar-state.json: vechiul modul "stats" (CPU/GPU/RAM al nostru) -> module separate cpu,gpu,ram; temp + tasks (noi) ascunse;
#                  statsMode/showGpu scoase (nu mai exista). Se face o singura data (doar daca fisierul e in formatul vechi).
#  hub.json (nou): bgAlpha = valoarea din Theme.qml-ul vechi (upstream ar porni cu 0.7), ca qs sa arate la fel.
set -u
H=${1:-$HOME}; OLD=${2:-$HOME/.config/quickshell/Theme.qml}; ST=$H/.config/quickshell/state
mkdir -p "$ST"
f=$ST/bar-state.json
if [ -s "$f" ] && jq -e 'has("statsMode") or has("showGpu") or ((.startMods // "") + "," + (.endMods // "") | test("(^|,)stats(,|$)"))' "$f" >/dev/null 2>&1; then
    jq 'def fix: split(",") | map(if . == "stats" then ("cpu", "gpu", "ram") else . end) | map(select(. != "")) | join(",");
        .startMods = ((.startMods // "") | fix) | .centerMods = ((.centerMods // "") | fix) | .endMods = ((.endMods // "") | fix)
        | .hidden = ((.hidden // "") | fix | split(",") + ["temp", "tasks"] | map(select(. != "")) | unique | join(","))
        | del(.statsMode, .showGpu)' "$f" > "$f.tmp" && mv "$f.tmp" "$f" && echo "bar-state.json migrat: $(jq -c '{startMods, endMods, hidden}' "$f")"
else
    echo "bar-state.json: deja in formatul nou (sau lipsa) -> neatins"
fi
h=$ST/hub.json
if [ ! -s "$h" ]; then
    a=$(grep -oE 'property real bgAlpha: *[0-9.]+' "$OLD" 2>/dev/null | grep -oE '[0-9.]+$')
    [ -n "$a" ] && printf '{\n  "bgAlpha": %s\n}\n' "$a" > "$h" && echo "hub.json creat: bgAlpha=$a"
fi
