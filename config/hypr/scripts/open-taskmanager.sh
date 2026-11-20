#!/usr/bin/env bash
# Click pe CPU / GPU / RAM in bara quickshell -> "Task Manager".
# 15 nov 2026: btop (tema 43pr generata de theme.py, fundal transparent, CPU/GPU/RAM/retea/procese) intr-o fereastra kitty
# plutitoare, clasa "taskmanager" (regula in rules.lua). Inainte: KDE System Monitor — ramane instalat, `plasma-systemmonitor`.
# Daca e deja deschis, il aduce in fata (si comuta pe workspace-ul lui).
CLASS="taskmanager"

addr="$(hyprctl clients -j 2>/dev/null | jq -r --arg c "$CLASS" '[.[] | select(.class == $c)][0].address // empty')"

if [[ -n "$addr" ]]; then
    hyprctl dispatch "hl.dsp.focus({window=\"address:$addr\"})" >/dev/null
else
    # setsid: sa nu moara odata cu quickshell cand bara e repornita
    setsid -f kitty --class "$CLASS" --title "Task Manager" -o confirm_os_window_close=0 btop >/dev/null 2>&1
fi
