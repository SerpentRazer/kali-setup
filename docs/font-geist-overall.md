---
name: font-geist-overall
description: Din 2026-10-17 tot desktopul pe Geist (sans) + GeistMono Nerd Font (mono) + Geist Pixel Square (ceasul hyprlock); unde e setat fiecare font si cum revii
metadata:
  type: project
---

Userul: „nu-mi place fontul overall... cauta unul si aplica care se potriveste cu tema”. Inainte erau 5 familii amestecate
(bara/qs JetBrains Mono, kitty JetBrainsMono NF, rofi Iosevka NF, hyprlock Roboto Mono, GTK/Qt Adwaita Sans, OSD/implicit Noto Sans).
Ales dupa o plansa comparativa (`~/src/qs-bartest/fontsheet.py`): **Geist + Geist Mono** (Vercel, o superfamilie) — mai curat
decat JetBrains, Space Grotesk/Mono prea ciudat in terminal, Iosevka prea ingust ca UI. Accent: **Geist Pixel Square** doar pt
ceasul mare din hyprlock (afisaj LED; la 12px in bara e prea subtire).

**Instalate (user, fara root):** `~/.local/share/fonts/Geist/{Geist,GeistPixel}` (v1.7.2 din vercel/geist-font, NU v1.8.1 publicat
cu o zi inainte) + `~/.local/share/fonts/NerdFonts/GeistMono/` (GeistMono Nerd Font v3.5.1, varianta NF non-Mono, cu italice).
**Setat in:** `quickshell/Theme.qml` (fontFamily + iconFont = "GeistMono Nerd Font"), `SettingsPages/NetworkPage.qml` monoFont,
`SettingsPages/SystemPage.qml` mono, `kitty/kitty.conf`, `rofi/config.rasi` (4x), `hypr/hyprlock.conf` ($font + TIME = Geist Pixel
Square), gsettings font-name/document-font-name 'Geist 11' + monospace-font-name 'GeistMono Nerd Font 10' SI linia din
`hyprland.lua` (blocul hyprland.start) care le pune la login, `gtk-3.0|4.0/settings.ini`, `qt6ct.conf` general Geist 11 / fixed
GeistMono NF 10, `~/.config/fontconfig/fonts.conf` (NOU: sans-serif -> Geist, monospace -> GeistMono NF).
**Capcana:** textele qs fara font.family (VolumeOsd, MusicPreview) iau fontul din qt6ct (qs ruleaza cu QT_QPA_PLATFORMTHEME=qt5ct
=> plugin qt6ct), citit DOAR la pornirea procesului -> dupa schimbare `kill <qs>` + `hyprctl dispatch 'hl.dsp.exec_cmd("QSG_RENDER_LOOP=basic qs")'`.
Verificat 17 oct: bara reala, OSD volum, yad (GTK3), kitty (italic/bold/diacritice), Dolphin, pango-view pt hyprlock.
**NESCHIMBAT:** SDDM (replica hyprlock, tot Roboto Mono) — cere fonturi in /usr/local/share/fonts + editare tema prin pkexec; oferit.
**Revenire:** `~/.config-backups/pre-font-geist-2026-10-17_14-42-15` (toate fisierele + valorile gsettings vechi in
gsettings-fonts.txt; fontconfig/fonts.conf nu exista inainte -> sterge-l). Vezi [[quickshell-bar-replaced-waybar]],
[[qt-dolphin-43pr-kvantum]], [[sddm-cyberglass-hyprlock-theme]].
