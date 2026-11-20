---
name: nested-test-recipe-virtual-pointer
description: "Cum testezi quickshell/Hyprland izolat CU mouse (hover/click) fara sa atingi sesiunea reala — pointer virtual wlr, magistrala D-Bus privata, capcane"
metadata:
  node_type: memory
  type: reference
  originSessionId: 7a9df6bf-4bc9-4107-8c9d-d574d2af37aa
  modified: 2026-10-16T18:24:02.990Z
---

Extinde reteta din [[hyprland-43pr-on-kali]] (kwin --virtual + Hyprland in bwrap cu /dev/input ascuns, 0 fd-uri input).

- Fara dispozitive de input, seat-ul nested n-are capabilitate pointer => `hl.dsp.cursor.move` muta cursorul dar
  aplicatiile NU primesc hover. `wlrctl` (apt-get download + dpkg -x, fara root) nu ajunge: isi distruge device-ul imediat.
  Merge un client mic C `vptr` (zwlr_virtual_pointer_v1, XML din `apt-get source wlrctl`, gcc + wayland-scanner) care tine
  device-ul viu: warp cu `hyprctl -i <sig> dispatch 'hl.dsp.cursor.move({x=..,y=..})'`, nudge relativ, apoi click/scroll.
  Click-ul trimis imediat dupa warp poate rata (focus-ul pointerului inca nu e pe suprafata) — asteapta ~300-600ms.
- `hyprctl -i <sig_nested>` INTOTDEAUNA (wrapper script), altfel lovesti sesiunea reala; in zsh `$H dispatch` nu se
  imparte in cuvinte -> foloseste script wrapper. `qs ipc` filtreaza dupa display -> `WAYLAND_DISPLAY=wayland-2`.
- `hyprctl -i <sig> output create headless NUME` da al doilea monitor (pt workspace-uri per monitor); grim pe headless
  da timeout, dar layerele se vad in `hyprctl layers`.
- qs de test sub `dbus-run-session` (notificari/MPRIS izolate). CAPCANA: adresa magistralei private e in environ-ul
  procesului `qs` (copilul), NU al wrapper-ului `dbus-run-session` (acela are magistrala reala) — am trimis odata o
  notificare de test la dunst-ul userului asa. Player MPRIS de test: `mpv --no-video --ao=null` (mpv-mpris instalat).
- theme.py din test: reload hook-ul `pkill -USR1 -x kitty` atinge si kitty-urile reale (doar reincarca config, inofensiv);
  gsettings pe magistrala privata + XDG_CONFIG_HOME sandbox scrie dconf in sandbox (verificat pe mtime).
Vezi [[verify-before-instructing]], [[43pr-update-2026-10-16]].

**Capcane noi (2026-10-16, runda 2):**
- `kwin_wayland --virtual` porneste dupa cateva minute **kscreenlocker_greet** (setarea KDE de lock la idle) -> ascunde Hyprland-ul
  nested, nu mai vin cadre (grim timeout, clickuri moarte). Porneste-l cu `--no-lockscreen --no-global-shortcuts`.
- `wlrctl keyboard type X modifiers SUPER` NU loveste tastele cerute: keymap-ul lui difera, iar binds-urile Hyprland au tras
  ALTE combinatii (au deschis Todo si PowerMenu in qs-ul de test). PERICULOS: PowerMenu din qs-ul de test ruleaza `systemctl`
  real -> pune mereu `systemctl/loginctl/hyprlock/poweroff/reboot` false in PATH-ul qs-ului de test. Testeaza functiile legate de
  taste expunandu-le in copia nested (`TEST_x = functie` la finalul keybinds.lua) si `hyprctl -i <sig> eval 'TEST_x()'`.
- Un layer qs cu focus exclusiv (PowerMenu/Todo deschis) blocheaza ORICE `focus` pe ferestre — verifica `hyprctl layers` intai.
- Iesirile `output create headless` nu deseneaza (grim timeout, fara input pe layere) -> pentru al doilea ecran inverseaza rolurile
  MONITOR1/MONITOR2 in copia nested. `pgrep -x qs` intoarce si qs-ul de test -> foloseste PID-uri explicite.

**28 oct (tray):** o copie qs sub `dbus-run-session` porneste prin activare D-Bus portaluri pe magistrala privata, INCLUSIV un al
doilea `xdg-desktop-portal-hyprland` conectat la Hyprland-ul real -> nu-l lasa in viata. Oprind qs-ul de test (PID explicit)
moare magistrala si toate ies singure (verificat). Auto mode a REFUZAT `kill` pe o lista construita dinamic din environ — da
PID-uri explicite. Fereastra FloatingWindow de test ramane la prima marime pe ws ascuns (Hyprland) -> marime fixa + crop pe alfa.

**28 oct (teste GPU, `~/src/gpu-nested-test` + README):** `kwin_wayland --virtual` IESE (exit 1, GTK „cannot open display”) cu
`QT_QPA_PLATFORMTHEME=qt5ct` din sesiune -> unset. kwin virtual alege EGL NVIDIA -> Hyprland-ul de test randa pe renderD129;
`__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json` pe kwin => test pe Intel ca sesiunea reala.
bwrap (userns) arata /tmp/.X11-unix ca nobody -> Xwayland nu porneste -> `--tmpfs /tmp/.X11-unix`; SDDM Xorg tine socket-ul
abstract @X0 -> clientii X ajungeau la SDDM -> `--unshare-net` + porneste clientii DIN Hyprland-ul de test
(`hyprctl -i <sig> dispatch 'hl.dsp.exec_cmd("...")'`, mostenesc namespace-ul). `dbus-run-session` porneste-l cu
WAYLAND_DISPLAY/DISPLAY scoase (prima data un xdg-desktop-portal-hyprland activat pe magistrala privata s-a legat de Hyprland-ul
real si a dat SIGSEGV). Dupa teste: sterge /tmp/.X*-lock cu PID mort (nu .X1-lock). gamescope ignora uneori SIGTERM (KILL);
2 gamescope in acelasi compozitor -> al doilea crapa (gamescope-0.lock). Hyprland-ul de test lasa hyprlandCrashReport in ~/.cache/hyprland.

**1 nov (tema 43PR noua): script reutilizabil `~/src/legion/43pr-merge-2026-11-01/test-izolat.sh`** — HOME fals (copie
~/.config/quickshell + overlay, fonturi/iconite prin symlink) => qs nu scrie in ~/.config; kwin virtual + Hyprland bwrap
(xwayland oprit) + qs pornit cu `hl.dsp.exec_cmd`; capturi `grim` din interior; comenzi false in PATH. Capcane: `pgrep -f "qs -p X"`
prinde `sh -c`-ul parinte -> `pgrep -f "^qs -p X"`; IPC tinteste cu `qs ipc --pid <pid> call ...`; `call settings show` din CLI
nu deschide nimic (toggle/bar merg). Iesirea kwin virtual apare 1280x720 la scale 2 (layer 640 lat).
