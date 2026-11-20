---
name: task-manager-btop
description: "15 nov 2026: Task Manager (click CPU/GPU/RAM in bara) = btop in kitty plutitor, tema 43pr (theme.py genereaza btop.theme), in loc de KDE System Monitor (userul: „meh”)"
metadata:
  type: project
---

Userul voia un system monitor care sa se potriveasca temei. Ales: btop 1.4.7 (deja instalat, `color_theme = "43pr"` din templates/btop.theme
generat de theme.py => se recoloreaza cu wallpaper-ul). Schimbari (backup+revino.sh `~/.config-backups/pre-taskmanager-btop-2026-11-15_20-34-26`):
- `~/.config/btop/btop.conf`: shown_boxes "cpu gpu0 mem net proc" (GPU NVIDIA prin NVML), theme_background False, update_ms 1000, net_iface "wlan0"
  (auto alegea eth0 deconectat).
- `~/.config/hypr/scripts/open-taskmanager.sh`: `kitty --class taskmanager --title "Task Manager" -o confirm_os_window_close=0 btop` (16 nov: opacitatea 0.93 SCOASA la cererea userului -> 0.80 ca restul temei, din kitty.conf)
  daca e deschis -> focus.
- `rules.lua`: regula "float-taskmanager" (float, center, 1500x880) — **SCOASA 20 nov** la cererea userului: Task Manager-ul se aranjeaza in tiling ca restul ferestrelor.
KDE System Monitor ramane instalat (`plasma-systemmonitor`). Alternativa GUI oferita: `resources` (GTK4, repo Kali 51.0, preia gtk-4.0/gtk.css).
Mission Center NU e in Kali. **CONFIRMAT de user 15 nov: „looks cool af”** -> ramane btop. Legat: [[43pr-update-2026-10-16]], [[quickshell-bar-replaced-waybar]].
**20 nov:** userul vrea meniu pe click dreapta. btop n-are; i-am aratat varianta existenta (click pe proces -> click din nou = panou detalii cu butoane
terminate/kill/signals/nice). Patch click dreapta posibil (btop_input.cpp: decodare `[<2;` + SignalChoose), dar RISC: selected_pid se actualizeaza abia la
urmatorul Proc::draw -> ar putea semnala procesul selectat anterior; + fork btop cu hold. Oferit, nefacut.
