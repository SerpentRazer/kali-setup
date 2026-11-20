---
name: gtk-theme-dbus-dconf-profile
description: "O aplicatie GTK cu alta tema (ex. Thunar deschis/albastru) = activata prin D-Bus, citeste profilul dconf IMPLICIT nu cel Hyprland"
metadata:
  node_type: memory
  type: reference
  originSessionId: 17dd387c-74ae-4463-bff5-e819ad4954c1
  modified: 2026-10-01T18:06:01.394Z
---

**Simptom:** o aplicatie GTK (tipic **Thunar**) apare cu **alta tema** decat restul desktop-ului Hyprland — iconite albastre Flat-Remix + Kali-Purple-Dark in loc de Papirus-Dark + Adwaita-dark („tematica deschisa").

**Cauza:** Hyprland foloseste un profil dconf separat (`DCONF_PROFILE=~/.config/hypr/dconf-profile`, baza `~/.config/dconf/hyprland`) unde tema e Adwaita-dark. DAR **activarea prin D-Bus / systemd NU mosteneste `DCONF_PROFILE`** → aplicatiile pornite asa (daemonul Thunar via `org.freedesktop.FileManager1`, portaluri etc.) citesc profilul dconf **IMPLICIT** (`user`), unde ramasese `Kali-Purple-Dark` + `Flat-Remix-Blue-Dark` de la Xfce/Plasma. Reproduci exact cu: `env -u DCONF_PROFILE setsid thunar ~`.

**Fix (2026-10-01, ambele aplicate):**
1. Aliniat profilul dconf implicit la restul: `env -u DCONF_PROFILE gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark` (+ `icon-theme Papirus-Dark`, `color-scheme prefer-dark`).
2. Impins profilul in env-ul de activare D-Bus + adaugat in autostart Hyprland (`hyprland.lua`): `hl.exec_cmd("dbus-update-activation-environment --systemd DCONF_PROFILE")`.
3. `pkill -9 thunar` ca daemonul sa re-activeze cu env-ul nou.

Verificare: `env -u DCONF_PROFILE thunar ~` trebuie sa arate iconite gri Papirus, nu albastre. Nota: schimbarea profilului implicit poate fi resetata de KDE la urmatorul login in Plasma (kde-gtk-config scrie in profilul `user`) — de-aia fix-ul #2 (D-Bus env) e cel robust pt Hyprland. Vezi [[hyprland-lua-native-config]], [[kali-glass-kde-setup]].

**Din 2026-10-16 (motorul de teme 43PR):** autostart-ul nu mai forteaza `gtk-theme Adwaita-dark`/`color-scheme`; le seteaza
`python3 ~/.config/43pr/bin/theme.py apply` la login dupa presetul activ (dark -> Adwaita-dark, light -> Adwaita), iar
icon-theme Papirus-Dark + fontul raman gsettings directe (din 17 oct font-name/document-font-name `Geist 11`,
monospace-font-name `GeistMono Nerd Font 10`, vezi [[font-geist-overall]]). theme.py scrie prin gsettings -> ajunge in profilul Hyprland DOAR
daca procesul are `DCONF_PROFILE` (pornit din Hyprland / qs; verificat: profilul `user` comun cu Xfce/Plasma ramane neatins).
Culorile GTK vin din `~/.config/gtk-3.0|4.0/43pr-colors.css` (NU colors.css — pe acela il rescrie kde-gtk-config), importat
de gtk.css-ul translucid (`alpha(@gtk_bg, 0.70)`, `color: @gtk_fg`). Thunar tine CSS-ul in proces: `thunar -q` dupa o tema noua.
Vezi [[43pr-update-2026-10-16]].
