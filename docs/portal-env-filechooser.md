---
name: portal-env-filechooser
description: Brave file dialog (insert image/upload) errored = xdg-desktop-portal had no WAYLAND_DISPLAY in systemd user env; fixed 20 nov via dbus-update-activation-environment line in hyprland.lua
metadata:
  type: project
---
20 nov 2026: „browserul da eroare cand inserez imagine” = dialogul Open al Brave trece prin xdg-desktop-portal; in mediul systemd --user
lipseau WAYLAND_DISPLAY/DISPLAY/XDG_CURRENT_DESKTOP -> portal-gtk „cannot open display”, portal timeout 2 min (Hyprland 0.57 construit
local nu le mai exporta singur). Fix: hyprland.lua linia `dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY
XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE DCONF_PROFILE XCURSOR_*` + restart portaluri;
FileChooser raspunde (v4). Backup ~/.config-backups/hyprland.lua.pre-portal-env-*. **Reaplica la merge 43PR** (upstream nu are linia).

**Why:** fara ea orice upload/salvare din Brave, Discord, Teams etc. esueaza. **How to apply:** simptom „cannot open display” in
`journalctl --user | grep portal` -> verifica `systemctl --user show-environment`. Vezi [[gtk-theme-dbus-dconf-profile]], [[hyprland-057-local-build]].
