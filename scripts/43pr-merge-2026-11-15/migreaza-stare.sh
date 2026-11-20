#!/bin/bash
# migreaza-stare.sh [HOME] — adapteaza bar-state.json la bara 43PR din 14 nov (merge 15 nov 2026). Idempotent.
#  - "temp" (vechi) -> "cputemp,gputemp" (upstream l-a impartit)
#  - modulele noi bright / night: ascunse (ca la upstream); bt (Bluetooth): pus inaintea lui net, altfel ar aparea dupa power
set -u
H=${1:-$HOME}; f=$H/.config/quickshell/state/bar-state.json
[ -s "$f" ] || { echo "bar-state.json lipsa -> se folosesc implicitele"; exit 0; }
jq 'def fix: split(",") | map(if . == "temp" then ("cputemp", "gputemp") else . end) | map(select(. != "")) | join(",");
    def all: [(.startMods // ""), (.midLeftMods // ""), (.centerMods // ""), (.midRightMods // ""), (.endMods // ""), (.hidden // "")] | join(",") | split(",");
    .startMods = ((.startMods // "") | fix) | .centerMods = ((.centerMods // "") | fix) | .endMods = ((.endMods // "") | fix)
    | .hidden = ((.hidden // "") | fix)
    | (all) as $a
    | .hidden = ((.hidden | split(",")) + ([ "bright", "night" ] | map(select(. as $m | $a | index($m) | not))) | map(select(. != "")) | join(","))
    | if (all | index("bt")) then . else
        .endMods = (.endMods | split(",") | (index("net") // length) as $i | .[:$i] + ["bt"] + .[$i:] | join(",")) end' \
    "$f" > "$f.tmp" && mv "$f.tmp" "$f" && echo "bar-state.json: $(jq -c '{startMods, endMods, hidden}' "$f")"
