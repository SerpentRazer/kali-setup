---
name: cursor-breeze-18
description: Cursor = Breeze 18 peste tot (ales de user 26 oct dintr-un meniu live); marimea trebuie sa existe NATIV in tema, altfel sare intre ferestre
metadata:
  type: project
---

2026-10-26. Plangere initiala: „sa nu se tot schimbe marimea la cursor in functie de pe ce fereastra e pe hover”.
Cauza: `XCURSOR_SIZE=14` fara tema -> Adwaita, care n-are 14 (minim 24): Hyprland (si clientii cu cursor-shape: kitty,
Qt 6.10, GTK4, Chromium Wayland) o micsora la 14, dar aplicatiile care isi deseneaza singure cursorul (XWayland: Teams,
Spotify, Steam; GTK3) luau varianta de 24. Am trecut intai pe Adwaita 24; userul a vrut varianta „mai mica, varf mare,
coada scurta”, n-a putut alege din descrieri („as vrea sa le vad separat”) -> meniu rofi cu previzualizare live
(`hyprctl setcursor`, iconite randate din fisierele xcursor) -> **„clar 5” = breeze_cursors 18** (nativ, fara scalare).

Setat (backup `~/.config-backups/cursor-breeze18-2026-10-26/`, + `hyprland.lua.bak-cursor-2026-10-26` = starea cu 14):
- `hyprland.lua`: `XCURSOR_THEME=breeze_cursors`, `XCURSOR_SIZE=18`, `HYPRCURSOR_SIZE=18`; exec-ul
  `dbus-update-activation-environment --systemd DCONF_PROFILE XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_SIZE` (D-Bus/systemd).
- dconf Hyprland (prin `cursor:sync_gsettings_theme`) SI dconf implicit (`env -u DCONF_PROFILE gsettings set ...`) = breeze 18;
  portalul raporteaza tot breeze 18.
- `~/.config/gtk-{3,4}.0/settings.ini`, `~/.gtkrc-2.0`: size 24 -> 18; `~/.config/kcminputrc [Mouse]`
  cursorTheme/cursorSize (ca Plasma sa nu le rescrie la 24).
- qs repornit (`QSG_RENDER_LOOP=basic qs` prin `hl.exec_cmd`) ca sa ia env-ul; pool-ul lui `memfd:wayland-cursor` =
  breeze 18 (left_ptr/pointer/text/xterm), verificat.
- Teams + Spotify (XWayland) pastreaza cursorul de la pornire -> repornite prin `hl.exec_cmd("spotify")` /
  `hl.exec_cmd("/opt/teams-for-linux/teams-for-linux --ozone-platform=x11")` (Spotify ignora SIGTERM -> kill -9), apoi
  mutate inapoi pe ws 11 cu `hl.dsp.window.move({ workspace = 11, window = "address:0x...", follow = false })`
  (au aparut pe ws-ul activ; Spotify isi pune clasa tarziu, deci o regula de workspace nu-l prinde la pornire).
- **Userul a confirmat „perfect”** (26 oct) dupa ce a mers cu mouse-ul pe bara laptopului, Spotify si Teams.
  Orice aplicatie XWayland deschisa inainte de o schimbare de cursor trebuie repornita.

Capcane: `grim -c` NU prinde cursorul hardware -> `hyprctl eval 'hl.config({ cursor = { no_hardware_cursors = 1 } })'`,
captura pe zona mica, apoi inapoi la `2`. Dupa ce comuti pe `1` asteapta ~1s si pune `sleep 0.3` intre o captura de
incalzire si cea buna — altfel iese goala (asa au iesit capturile pe zone din 26 oct). kitty ASCUNDE cursorul cat tastezi
(captura goala daca mouse-ul e peste kitty).
Pool-ul de cursoare al unui client Wayland = `memfd:wayland-cursor` in `/proc/<pid>/maps`, citibil din `/proc/<pid>/mem`
(ptrace_scope 0) -> compari pixelii cu temele. Bara qs are `cursorShape: Qt.PointingHandCursor` pe 23 de elemente (mana).
Breeze NU era activ nicaieri inainte; descrierea userului se potrivea cu Breeze, dar pe ecran avea Adwaita.
Vezi [[hyprland-lua-native-config]], [[gtk-theme-dbus-dconf-profile]], [[visual-coherence-delegated-choices]].
