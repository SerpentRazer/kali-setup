---
name: quickshell-bar-replaced-waybar
description: "Bara Hyprland = Bar.qml din upstream 43PR (93b68a4) + patch-urile noastre (GPU, Task Manager, zoom hover, ws per monitor, MusicPreview); setari la click dreapta, stare in quickshell/state/bar-state.json"
metadata:
  node_type: memory
  type: project
  originSessionId: 7a9df6bf-4bc9-4107-8c9d-d574d2af37aa
  modified: 2026-10-18T18:28:34.345Z
---

Din 2026-10-16 bara de sus e **Bar.qml-ul upstream 43PR** (si ei au trecut de pe waybar pe quickshell) peste care am
re-adaugat ce ceruse userul in bara noastra veche (2026-10-01). Vezi [[43pr-update-2026-10-16]].

**Structura:** `Bar.qml` e un `Scope` cu `Variants` pe `Quickshell.screens` (bara pe fiecare monitor); modulele sunt
`Component`-e (statsC, wsC, mediaC, volumeC, batteryC, iconC) puse in 3 `Panel`-uri (start/center/end). Click dreapta pe
orice modul (sau pe ceas) = **Bar settings** (pozitie, stil, module, Hover zoom, Workspaces per monitor, GPU usage).
Starea: `~/.config/quickshell/state/bar-state.json`; defaults-urile din cod = layout-ul userului (top, floating, stats
vizibile) ca „Reset all" sa nu-l mute in stanga (default-ul upstream e stanga/vertical).

**Adaugirile noastre:** GPU din UN `nvidia-smi --query-gpu=utilization.gpu,temperature.gpu -lms 2000` persistent
(SplitParser; ~0.1% CPU fata de ~1% spawn la 1.5s); click CPU/GPU/RAM -> `~/.config/hypr/scripts/open-taskmanager.sh`
(plasma-systemmonitor --page-id overview); zoom = `scale` pe componenta Interactive + `zoomPad` pe latura interioara +
`exclusiveZone` explicit + `mask: Region { item: frame }`; workspace-uri per monitor prin `QsWindow.window.screen.name`
si `hlMon.activeWorkspace` (punctul curent solid, upstream il facea accent 0.2 = aproape invizibil; scroll-ul cicleaza doar
workspace-urile monitorului barei, cu wrap — upstream `e+1` sarea pe celalalt ecran; tooltip-ul numeste 11-20 ca 1-10); media: click stanga
= `MusicPreview.qml` (card cu cover/seek/butoane, pozitionat dupa latura barei, blur prin layer rule `qs-music`), dreapta
= next, mijloc = play/pause. `Marquee.qml` (singleton): NumberAnimation smooth + alegere player cu scor (playing, apoi cu
cover art: Brave expune tab-ul de 2 ori). `BarPill.qml` ramane doar pt butoanele din MusicPreview.

**Bara arata doar workspace-urile cu id > 0** (`Bar.qml:927`, `filter(w => w.id > 0)`): cele cu nume (`gaming` = -1337) si
special nu au punct. Daca monitorul sta pe unul din ele, niciun punct nu e activ si ferestrele de acolo par „disparute”
(asa s-a intamplat pe 18 oct, vezi [[hyprland-lua-native-config]]).

**Gotcha-uri pastrate:** dispatch in config Lua = `hl.dsp.focus({workspace=N})` (Hyprland.dispatch cu sintaxa veche
esueaza; in schimb `HyprlandWorkspace.activate()` din Quickshell MERGE — click-ul pe puncte, testat 2026-10-16); pornire qs din afara Hyprland: `hyprctl dispatch 'hl.dsp.exec_cmd("QSG_RENDER_LOOP=basic qs")'` (mosteneste
env-ul sesiunii: DCONF_PROFILE etc.). Schimbarea Variants/screen pe un PanelWindow deja afisat cere restart complet qs.
waybar/dunst nu mai pornesc (configurile lor sunt doar in backup-ul din 16 oct). **Meniul de power e iar wlogout din 2026-10-17** (cerut: „cum a fost inainte"): SUPER+` si butonul ⏻ din bara (`cmd` in moduleDefs) ruleaza `~/.config/hypr/scripts/wlogout.sh`; `~/.config/wlogout` restaurat din backup (acum 4 butoane: shutdown/reboot/suspend/logout; hibernate SCOS pe 17 oct la cererea userului — n-a mers niciodata, CanHibernate=na; backup `~/.config-backups/pre-no-hibernate-2026-10-17_14-00-12`; wlogout.sh numara singur butoanele din layout). PowerMenu.qml ramane incarcat in shell.qml, dar nu-l mai deschide nimic. Backup: `~/.config-backups/pre-wlogout-240hz-2026-10-17_11-53-26`. Bar.qml editat NU s-a reincarcat singur (fara „Reloaded" in `qs log`) — am repornit qs cu `hyprctl dispatch 'hl.dsp.exec_cmd("QSG_RENDER_LOOP=basic qs")'`. Test wlogout pe sesiunea reala DOAR cu un layout copie cu actiuni `true`: layout-ul real are taste s/r/z/e (shutdown/reboot...) si userul poate tasta in acel moment.

**17 oct (dupa-amiaza): playerul din bara + OSD-ul de volum.** `MusicPreview.qml` RESCRIS in stilul cardului de media din
`VolumeOsd.qml` (upstream), cerut de user („imi place mult... in special soundwaves"): coperta mare, titlu centrat, valuri cava
(proces propriu, `/tmp/quickshell-cava-preview.conf`, doar cat e deschis) care sunt si bara de progres (click/drag = seek),
glyph-uri prev/play/next; construit la 260px si scalat 0.8 ca OSD-ul. Proprietatea `cluster` scoasa (si din Bar.qml).
`VolumeOsd.triggerOsd`: volumul arata MEREU bara de volum (upstream arata cardul de media cat canta muzica => „nu se vede bara de
volum"); exceptie card fixat/mutat/setari deschise. `Marquee.previewOpen` (setat de MusicPreview cu Binding): cat e deschis
playerul din bara, VolumeOsd nu mai da popup-ul de melodie noua in mijloc si il inchide pe cel deschis („arata ciudat daca
deschid din dreapta"). Testat izolat: qs separat pe D-Bus privat + `mpv --no-video --ao=null` cu ogg-uri ffmpeg; CAPCANA:
mpv nu e in `musicPlayers`, deci in test `VolumeOsd { musicOnly: false }`. Backup: `~/.config-backups/pre-musicpreview-osd-2026-10-17_14-05-11`.

**17 oct: zoom-ul la hover nu mai iese din chenarul negru.** Userul: piesa din bara „iese din chenarul negru... se vede urat”
(media e primul modul din sectiunea din dreapta, ~200px; 1.15x il impingea ~12px afara; la fel CPU, putin). `Interactive.fitZoom()`
in Bar.qml: la inceputul hover-ului scala = min(1.15, cat loc are modulul pana la marginea Panel-ului, +1px marginea state-layer-ului;
pe joined/strip fundalul e frame-ul intreg). Modulele din mijloc raman 1.15x, cele late de la capete cresc doar cat incap (media ~1.03).
Testat cu `~/src/qs-bartest` (hover fortat prin IPC, ws ascuns 19). Backup: `~/.config-backups/pre-hoverzoom-fit-2026-10-17_14-34-03`.

**28 oct: SYSTEM TRAY in bara** (cerut: „tray in bara... sa apara ca iconite si restul de aplicatii care au optiunea asta”).
Modul `tray` in `Bar.qml` (moduleDefs + trayC) + `TrayMenu.qml` (meniul, PanelWindow ca MusicPreview: urmeaza latura barei,
centrat pe iconita, `HyprlandFocusGrab` cu bara in lista -> click pe alta iconita schimba meniul, layer `qs-traymenu` cu
blur din `hypr/rules.lua`). Ordinea ceruta de user: **mereu intre piesa si sunet** (`endMods: media,tray,volume,...`, si in
defaults). `trayHidden: ["nm-applet"]` — bara are deja modulul Network; nm-applet RAMANE pornit (parole Wi-Fi/VPN). Itemii
`Passive` se arata (Spotify e mereu Passive). Click stanga = activate (sau meniul daca onlyMenu), dreapta = meniu, mijloc =
secondaryActivate. Meniul: bife/radio desenate din Rectangle, iconite, dezactivate la 0.4, submeniuri IN LOC (rand „inapoi”).
**Bug prins:** QsMenuOpener pe un submeniu, daca meniul parinte nu mai e referit, iese GOL (quickshell elibereaza intrarile
parintelui) -> un QsMenuOpener pe meniul radacina + `Variants` cu cate un opener pe fiecare nivel din `stack`.
**Animatie** (ceruta „smooth ca restul temei”): Repeater pe `trayModel` (ListModel key/leaving), NU pe SystemTray.items —
un item care pleaca e marcat `leaving`, slotul se strange (vecinii alunecă), iconita fade+scale, `trayGc` il scoate dupa
animMed+80; `lastIcon` pastreaza poza dupa ce obiectul SNI a murit. Masurat pe captura: marginea panoului 1626->1638->1643->1656.
**Electron (Discord) isi inregistreaza iconita DOAR daca watcher-ul exista la pornire** -> pornit inainte de tray = fara iconita,
trebuie repornit. qs face hot-reload la salvarea Bar.qml/TrayMenu.qml (de data asta DA, „Configuration Loaded” in `qs log`).
Unelte test: `~/src/qs-bartest/mktraytest.py` (dupa mkbartest: meniul ca fereastra fixa 420x560, IPC `bttray open/list`,
`btmenu rows/click/hover/back`) + aplicatie falsa `~/src/fake-sni/fake_sni.py` (agent; meniu cu bifa/radio/submeniu/Quit).
Ruleaza copia sub `dbus-run-session` (qs devine watcher pe magistrala privata). Backup + `revino.sh`:
`~/.config-backups/pre-tray-2026-10-28_19-09-53`.

**1 nov 2026 — Bar.qml RESCRIS din upstream c998d6d + portare Kali** (detalii [[43pr-update-2026-10-16]]): module separate
cpu/gpu/ram/temp/tasks (StatBadge, click = Task Manager), mutare prin tragere pe bara, setarile barei in Settings > Bar (BarPage.qml,
starea in state/bar-state.json — cheile lipsa din `defaults` ale BarPage se pierd la salvare, deci orice optiune Kali noua intra si
acolo). Optiuni Kali: hoverZoom, wsPerMonitor, statsMainOnly (statistici doar pe ecranul de la 0,0). GPU = `nvidia-smi -lms 2000`
persistent. Tray/MusicPreview/TrayMenu/Marquee neschimbate. SUPER+S = QuickActions (Wheel scos), scurtaturile = kb_* din
state/binds.lua (Settings > Keybinds), implicite Kali in keybinds.lua + KeybindsPage. Transparenta qs = state/hub.json (bgAlpha),
SUPER+O o schimba live prin `qs ipc call theme setBgAlpha`.

**15 nov 2026:** bara = upstream e4b8fdf + portare (vezi [[43pr-update-2026-10-16]]); nvidia-smi persistent MUTAT in SystemStats.qml; click CPU/GPU/RAM -> btop ([[task-manager-btop]]); SidePanel (SUPER+S) in dreapta, se inchide la click in afara.
