---
name: qt-dolphin-43pr-kvantum
description: Dolphin/aplicatiile KDE urmeaza paleta 43PR prin tema Kvantum generata "43PR" (tinta theme.py); qt6ct = Papirus-Dark + Adwaita Sans; kdeglobals icons Papirus-Dark
metadata:
  type: project
---

**Problema (2026-10-17):** sub Hyprland, Dolphin avea bara laterala si bara de stare albe, „nu se potriveste cu tematica”.
Lantul real: `QT_QPA_PLATFORMTHEME=qt5ct` (din `/etc/profile.d/kali-themes.sh`, cand desktopul nu e KDE) — pluginul Qt6
`libqt6ct.so` accepta si cheia `qt5ct`, deci se incarca qt6ct (Fusion + Kali-Dark); DAR aplicatiile KDE suprascriu stilul cu
`kdeglobals [KDE] widgetStyle=kvantum`, iar Kvantum era pe `BlurGlassyKvantum` = tema DESCHISA (base #ffffff, text negru).
Iconitele aplicatiilor KDE vin din `kdeglobals [Icons]`, NU din qt6ct (verificat: qt6ct icon_theme n-a schimbat nimic).

**Fix aplicat:** motorul 43PR nu avea tinta Qt. Adaugate in `~/.config/43pr/targets.toml` tintele `kvantum` + `kvantum-svg`:
`templates/kvantum.kvconfig` si `templates/kvantum.svg` = fork-ul CyberGlass cu culorile inlocuite de token-uri din paleta
(text->fg, cyan->accent, cyan inchis/itemview/menuitem->selection_bg, albastrele->bg/bg_panel/bg_card/bg_hover) ->
`~/.config/Kvantum/43PR/`. `window.color` = bg opac + `reduce_window_opacity=30` => alfa 0.70 masurat (=GTK `alpha(@gtk_bg,0.70)`);
base = bg 0x33. `kvantum.kvconfig theme=43PR` (global, deci si in Plasma). qt6ct: `icon_theme=Papirus-Dark`, font general
`Adwaita Sans 11` (ca GTK); qt5ct doar icon_theme. `kdeglobals [Icons] Theme=Papirus-Dark` (folderele Papirus-Dark de aici
sunt ALBE, ca in Thunar) — afecteaza si sesiunea Plasma. Se schimba singur cu wallpaperul (theme.py apply); kvconfig live,
SVG-ul doar in aplicatiile pornite dupa. Toate aplicatiile KDE (System Monitor din bara etc.) iau aceeasi tema.
**Backup/revenire:** `~/.config-backups/pre-dolphin-43pr-2026-10-17_14-15-44` (kvantum.kvconfig, kdeglobals, qt5ct/qt6ct,
targets.toml fara tintele noi). Test vizual: [[window-capture-grim-t-lstl]]. Vezi [[gtk-theme-dbus-dconf-profile]],
[[kali-glass-kde-setup]], [[43pr-update-2026-10-16]].
