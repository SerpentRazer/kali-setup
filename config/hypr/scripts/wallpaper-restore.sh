#!/usr/bin/env bash
# Draw the wallpaper recorded by theme.py (set by the installer or the picker).
state="${XDG_STATE_HOME:-$HOME/.local/state}/43pr/state.json"

img="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("wallpaper",""))' "$state" 2>/dev/null)"
[[ -f "$img" ]] || exit 0

# Wait for the awww daemon to be ready (up to ~5s)
for _ in {1..20}; do
    awww query >/dev/null 2>&1 && break
    sleep 0.25
done

awww img "$img" -t none

# Kali (15 nov 2026): wallpaper video (ales din picker -> commands.sh scrie ~/.cache/43pr/last-live). Upstream nu-l
# repornea la login; awww de mai sus a desenat deja primul cadru (theme.py), mpvpaper porneste peste el.
live="$(cat "$HOME/.cache/43pr/last-live" 2>/dev/null)"
if [[ -n "$live" && -f "$live" ]] && command -v mpvpaper >/dev/null; then
    pkill -x mpvpaper
    setsid -f mpvpaper -o "no-audio loop hwdec=auto --panscan=1.0" '*' "$live" >>"$HOME/.cache/43pr/mpvpaper.log" 2>&1
fi
