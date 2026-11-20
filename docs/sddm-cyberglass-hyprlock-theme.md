---
name: sddm-cyberglass-hyprlock-theme
description: "Tema SDDM de login = replica minimalista a hyprlock (Super+L), scrisa de la zero; cum o testezi fara lockout"
metadata:
  node_type: memory
  type: project
  originSessionId: 15f1bc88-3e65-4bc8-a418-d1520583a777
  modified: 2026-10-03T13:43:50.103Z
---

Login-ul SDDM pe Kali/Hyprland e tema **`cyberglass`** din `/usr/share/sddm/themes/cyberglass`, activata prin `Current=cyberglass` in `/etc/sddm.conf.d/kde_settings.conf` (backup: `.bak-cyberglass`). Greeter-ul e **sddm-greeter-qt6** (Qt6).

**2026-10-03:** userul a cerut login-ul **identic cu lock screen-ul hyprlock** (fundal blurat, Roboto Mono alb, ceas+data, pastila de parola transparenta cu contur alb), **plus** selectie sesiune + butoane power, **fara avatar**, **fara neon albastru** (alb). Vechea abordare (overlay peste breeze / `theme.conf.user`) a fost inlocuita: `Main.qml` e acum **rescris de la zero**, pur `QtQuick` + `QtQuick.Controls` + `Qt5Compat.GraphicalEffects` (FastBlur), FARA componente `org.kde.breeze` — deci nu depinde de plugin-uri Plasma. Fisierele breeze ramase in dir (Login.qml/Background.qml/SessionButton.qml) sunt inerte. Detalii: font **Roboto Mono impachetat in tema** (`RobotoMono.ttf` + `FontLoader`, fiindca userul `sddm` NU vede `~/.local/share/fonts`); fundal = wallpaper-ul curent copiat ca `login-bg.png` in dir (`background=login-bg.png` relativ, `type=image`), blurat cu FastBlur; userul de login rezolvat cu `userModel.lastUser` + fallback `Instantiator` pe `userModel`; power via `sddm.hibernate/suspend/reboot/powerOff`; sesiune via `ComboBox{model:sessionModel;textRole:"name"}`.

**2026-10-03 (animatii):** userul a cerut tema „sa nu ramana asa robust" → adaugate animatii fine in `Main.qml` (deployed, backup orig in `/var/backups/sddm/Main.qml.pre-anim-20261003-164318`): intrare in cascada la load (fundal fade+scale 1.06→1.0, apoi ceas/pastila/controale esalonat via `ParallelAnimation`+`PauseAnimation`, cu `Translate` pt glisare si `opacity:0` initial); halou `RectangularGlow` sub pastila (alb la focus 0.30, magenta la esec 0.5, prin binding+`Behavior`); `shake` (SequentialAnimation pe `anchors.horizontalCenterOffset`) la `onLoginFailed`; puls `msg.opacity` cat `busy`; micro-hover scale 1.1 pe butoanele power + hover/`Behavior` pe ComboBox sesiune + fade enter/exit pe popup + rotatie indicator ▾. Verificat: `/usr/lib/qt6/bin/qmllint` 0 erori; test-mode off-screen (reguli `workspace special:sddmtest silent`+`noinitialfocus`+`nofocus` pe `sddm-greeter-qt6`, apoi `hyprctl reload`) → Main.qml incarcat curat pe ambele view-uri, fara erori QML in stderr.

**Reteta de test FARA a fura tastatura (verificat):** greeter-ul in `--test-mode --theme <dir>` deschide **cate o fereastra pe FIECARE ecran** (clasa `sddm-geeter-qt6`). Lanseaza cu windowrules temporare: `monitor HDMI-A-2` + `fullscreen` + `noinitialfocus`; muta fereastra de pe laptop (monitor==0) pe un workspace special silent intr-un loop scurt; apoi `grim -o HDMI-A-2 shot.png`; la final `pkill -9 -f sddm-greeter-qt6`, re-focus fereastra anterioara, `hyprctl reload` (sterge windowrules temp). `qmllint` corect = `/usr/lib/qt6/bin/qmllint` (NU `/usr/bin/qmllint`, care e wrapper Qt5 rupt). Context properties injectate (sddm/userModel/sessionModel/config/keyboard) nu se rezolva in qmllint — ignora-le.

**Deploy** (dir e root): un singur `pkexec bash deploy.sh` care copiaza fisierele + `sed Current=breeze->cyberglass`. Agent polkit prezent (polkit-kde) → pkexec pune dialog GUI. **Revert:** `Current=cyberglass`->`breeze`.

**GOTCHA MARE (2026-10-03, userul a prins ca login-ul „nu-i schimbat deloc"):** NU lasa backup-ul config in `/etc/sddm.conf.d/`. `man sddm.conf` pe boxa asta zice textual „loads **all files** in the configuration directories" — adica SDDM citeste ORICE fisier din conf.d, nu doar `*.conf`. Backup-ul `kde_settings.conf.bak-cyberglass` (continea `Current=breeze`) sorta alfabetic DUPA `kde_settings.conf` → citit ultimul → suprascria `Current` inapoi pe breeze, deci tema noua nici nu era selectata (desi fisierele temei erau corect instalate). Fix: `pkexec mv /etc/sddm.conf.d/kde_settings.conf.bak-cyberglass /var/backups/sddm/kde_settings.conf.breeze-backup`. Acum backup-ul traieste in **`/var/backups/sddm/`** (afara din calea de citire). Orice revert/backup viitor pt SDDM: NU in conf.d. Verificat: `qmllint` (`/usr/lib/qt6/bin/qmllint`) pe Main.qml nu da erori fatale, doar Info + context injectat; fontul si login-bg.png valide. Aplicare: la urmatorul login/reboot — NU reporni sddm acum (omoara sesiunea + [[parallel-claude-sessions]]).

**Tastatura virtuala pe jumatate de ecran la login (2026-10-03):** era default-ul compilat `InputMethod=qtvirtualkeyboard` (nesuprascris nicaieri in `/etc`, confirmat cu `sddm --example-config`; modulul `qt6-virtualkeyboard-plugin` instalat). Fix = `InputMethod=` gol in `[General]` din `/etc/sddm.conf.d/kde_settings.conf` (nu dezinstalat pachetul). Backup pre-fix in `/var/backups/sddm/kde_settings.conf.pre-nokbd-*`. Se aplica la urmatorul login (NU reporni sddm).

Config hyprlock sursa: `~/.config/hypr/hyprlock.conf` (font Roboto Mono pana pe 17 oct — de atunci GeistMono NF + ceasul TIME in
Geist Pixel Square, [[font-geist-overall]]; SDDM a RAMAS pe Roboto Mono, deci replica nu mai e identica. Ca s-o aliniezi: fonturile
in /usr/local/share/fonts (userul sddm nu vede ~/.local/share/fonts) + font in Main.qml, prin pkexec; oferit, neaplicat; background path=screenshot blur_passes=3, input-field 20%x5% rounding 25 outline alb 3px, TIME 60px, DATE "%A, %d %B %Y"). Super+L ruleaza `hyprlock` (bind in hyprland.lua). Vezi [[hyprland-lua-native-config]], [[kali-glass-kde-setup]], [[verify-before-instructing]], [[root-via-pkexec-not-sudo]].

**11 nov 2026 — login doar pe monitorul principal (cerut de user, dupa Hybrid Mode OPRIT => X-ul de login vede ambele ecrane pe NVIDIA:
DFP-5 laptop + DFP-4 Samsung, laptopul era primar):** Main.qml: `showUi = primaryScreen` (context property SDDM, confirmat in binar)
pe ceas/pastila/glow/msg/controale/blur + baza neagra => celelalte ecrane negre; focus doar daca showUi. Plus `/etc/sddm/Xsetup-primary`
(DisplayCommand prin `/etc/sddm.conf.d/x11-primary.conf`; ruleaza Xsetup-ul original apoi `xrandr --output <primul HDMI conectat> --primary`,
log `/var/log/sddm-xsetup.log`). Testat FARA ecran: `QT_QPA_PLATFORMTHEME=generic QT_QPA_PLATFORM="offscreen:configfile=screens.json"
sddm-greeter-qt6 --test-mode --theme <copie>` (2 ecrane simulate; fara PLATFORMTHEME crapa pe GTK „cannot open display”) => primar showUi=true,
al doilea false. Deploy: `pkexec bash ~/src/legion/sddm-primary-2026-11-11/aplica.sh` (backup+revino.sh in /var/backups/sddm/pre-primary-*).
APLICAT de user 11 nov 20:57 (verificat: fisierele instalate = cele testate; backup+revino.sh /var/backups/sddm/pre-primary-2026-11-11_20-57-31).
DE VERIFICAT la urmatorul logout: /var/log/sddm-xsetup.log („primar: HDMI-0”?) si ce vede userul.
