---
name: hyprland-43pr-on-kali
description: Portarea temei Hyprland 43PR/dotfiles (scrisa pentru Arch) pe Kali — patch-urile necesare si starea instalarii
metadata:
  node_type: memory
  type: project
  originSessionId: 4c2a1f02-9dea-4fce-b2e1-ef8c39bc80d9
  modified: 2026-10-01T18:43:42.449Z
---

Pe 2026-09-28 am portat https://github.com/43PR/dotfiles (rice Hyprland, scris pentru
Arch) pe Kali 2026.3. Nu e o tema KDE — e un desktop intreg, instalat **alaturi** de
Plasma+CyberGlass ([[kali-glass-kde-setup]]), ca sesiune separata in SDDM.

43 din 49 de pachete upstream exista in repo-urile Kali. Restul, rezolvate fara root:
`awww` 0.12.1 compilat din sursa (codeberg.org/LGFae/awww — nu e in AUR ca pachet
stabil, doar `awww-git`; e swww rebranded de acelasi autor), `starship` + `papirus-folders`
ca binare in `~/.local/bin`, Nerd Fonts in `~/.local/share/fonts`.

**Hardware, descoperit cu `/sys/class/drm`:** laptop hibrid — card0 (Intel i915) conduce
`eDP-1`, card1 (NVIDIA RTX 3060) conduce **`HDMI-A-2`** (nu `HDMI-A-1`, cum ar sugera
intuitia). Ambele GPU-uri trebuie date lui Hyprland prin `AQ_DRM_DEVICES`, pe cai
`by-path` fiindca numerotarea card0/card1 se poate schimba intre boot-uri.
**CAPCANA (a crapat prima pornire):** `AQ_DRM_DEVICES` e separat prin `:`, iar caile by-path
contin `:` -> Aquamarine le taie, "Found no gpus", ABRT, inapoi in SDDM. `--verify-config` NU
prinde asta. Fix (2026-09-28): `hyprland.lua` rezolva by-path -> `/dev/dri/cardN` cu
`io.popen("readlink -f")` (verificat ca merge in Lua-ul Hyprland), fallback card0/card1.
Test fara logout (merge): `kwin_wayland --x11-display $DISPLAY --socket wl-nest` + `WAYLAND_DISPLAY=wl-nest Hyprland`.
ATENTIE: Hyprland ia atunci si HDMI-A-2 prin NVIDIA (Xorg tine doar card0) -> monitorul extern trece pe el;
grim se blocheaza in acest mod amestecat. eDP-1/Intel se poate testa doar la login real.
Crash-urile Hyprland sunt in `~/.cache/hyprland/hyprlandCrashReport*.txt` (cu log tail).
`nvidia_drm.modeset=1` era deja setat de Kali in `/etc/modprobe.d/nvidia-drm-modeset.conf`
— GRUB nu trebuie atins.

**Why:** diferentele Arch->Debian nu sunt evidente si niciuna nu da eroare clara la
pornire; ar fi aparut ca "merge, dar arata prost" sau ca un desktop care nu porneste.

**How to apply:** patch-urile aplicate in `~/.config` (toate verificate pe boxa, nu
presupuse): polkit e la `/usr/lib/x86_64-linux-gnu/libexec/`, nu `/usr/lib/`; binarul
e `brave-browser`, nu `brave`; plugin-urile zsh sunt in `/usr/share/zsh-autosuggestions/`,
nu `/usr/share/zsh/plugins/...`; `xed` -> `mousepad`; scriptul GPU rescris pe `nvidia-smi`.
Doua bug-uri upstream, valabile si pe Arch: `MONITOR1/MONITOR2/PRIMARY_MONITOR` nu erau
definite nicaieri (nil in Lua), iar rofi cerea familia "Iosevka" simpla, care nu exista
nici macar in Nerd Fonts — cade pe Noto Sans proportional.

Backup inainte de orice: `~/.config-backups/pre-hyprland-2026-09-28_22-00-12/`
(zshrc, zshenv, zprofile, gtk-3.0, gtk-4.0, kitty).
**Stare: instalat si verificat complet (78/78 checks).** `Hyprland --verify-config`
raporteaza `config ok`; `qs -p ~/.config/quickshell/shell.qml` raporteaza
`Configuration Loaded` pe Quickshell 0.3.1. Sesiunea `hyprland.desktop` apare in SDDM.

`apt update` a adus Hyprland **0.56.2** (de la 0.55.4) — exact versiunea pentru care
e scrisa tema.

**sudo nu are parola cached si nu are tty in sesiunea asta**, iar nici modul `!` din
Claude Code nu ofera terminal pentru prompt-ul de parola. Ce a mers: `pkexec` —
agentul polkit KDE ruleaza si autorizeaza fara prompt. `ksshaskpass` NU merge pentru
sudo (stie doar prompt-uri SSH).

Efecte secundare care ating SI sesiunea Plasma (acceptate, cu backup): `~/.zshrc`,
`~/.config/gtk-3.0`, `~/.config/gtk-4.0` inlocuite, gsettings `color-scheme=prefer-dark`.
Plasma, kwinrc, kdeglobals si CyberGlass.colors — neatinse.

**Runda de bugfix 2026-09-28 (dupa prima folosire reala), toate testate pe comportament:**
- Popup-uri + „cere parola”: `quickshell/SettingsCornerTrigger.qml` punea 5 benzi invizibile de 10px pe marginea
  de sus care lansau la HOVER hyprlock (0-1%, deci parola), setari, rofi, wallpaper, wlogout. Dezactivat in `shell.qml`.
- Thunar netematizat: pe Wayland GTK3 citeste gsettings, nu settings.ini (upstream presupune pasul manual nwg-look).
  **gsettings e COMUN cu Xfce** (testat: schimbarea a trecut si in Xfce X11 — am revenit). Fix: `hl.env("DCONF_PROFILE",
  ~/.config/hypr/dconf-profile)` -> baza separata `~/.config/dconf/hyprland`, plus gsettings Adwaita-dark/Papirus-Dark
  la start. Papirus foldere albe (pkexec), fonts-adwaita, Roboto Mono (in ~/.local/share/fonts, cerut de hyprlock), pipewire-audio.
- `waybar/scripts/mpris-marquee.sh` ramanea orfan dupa iesire (parintele e `sh -c`, nu waybar) -> `|| exit 0` dupa jq.
- DrKonqi crapa in bucla la orice crash in afara Plasma (360 dump-uri) -> `systemctl --user mask drkonqi-coredump-launcher.socket`.
- Hyprland segfault la IESIRE (destructori aquamarine/EGL) — inofensiv, nerezolvat. hyprmod (AUR) neinstalat.
Backup: `~/.config-backups/pre-bugfix-2026-09-28_22-40-50/`.

**TESTARE FARA SA-I IEI TASTATURA:** un Hyprland nested (chiar si in `kwin_wayland --virtual`) deschide /dev/input
prin libinput/logind si FURA tastatura userului (i-a ajuns textul intr-un kitty ascuns). User-ul e in grupul `input`.
Reteta sigura, verificata (0 fd-uri /dev/input): `kwin_wayland --virtual --socket X` apoi
`WAYLAND_DISPLAY=X LIBSEAT_BACKEND=noop AQ_DRM_DEVICES=/dev/dri/nope bwrap --dev-bind / / --tmpfs /dev/input Hyprland -c <copie config fara AQ_DRM_DEVICES>`,
si verifica `ls -l /proc/<pid>/fd | grep /dev/input` = 0. Thunar in test: `dbus-run-session thunar` (daemonul Xfce altfel
deschide fereastra pe X11). grim merge in acest mod. Nu folosi `pkill -f <pattern>` — omoara propriul shell al tool-ului.

Utilizatorul a cerut si un plan de migrare Kali -> Arch (inventar al celor 619 pachete
manuale + configurari de securitate). Nefacut inca — a ales intai instalarea temei pe Kali.

**Runda 2026-09-30:** `hyprland-guiutils` 0.2.2 instalat (pkexec; binare hyprland-dialog/run/welcome, verificat ldd+--help).
Samsung LC27RG50 (HDMI-A-2) = monitorul PRINCIPAL; EDID-ul lui zice 60Hz "preferred" -> `monitors.lua` are acum moduri
explicite: eDP-1 1920x1080@144 la 0x0, HDMI-A-2 1920x1080@**239.76** la 1920x0 (verificat live si dupa `hyprctl reload`).
`PRIMARY_MONITOR` = HDMI-A-2. `monitors.conf` (nwg-displays) NU e citit de configul Lua. `hyprctl keyword` nu merge pe
configul Lua — foloseste `hyprctl eval 'hl.monitor({...})'`.
Patrate violet/roz care palpaie pe Samsung: Intel randa, iar Aquamarine copia fiecare cadru pe NVIDIA; driverul
NVIDIA **550.163.01** (cel mai nou din repo Kali) n-are explicit sync la KMS. Fix aplicat: `AQ_DRM_DEVICES` = NVIDIA:Intel
(NVIDIA randeaza). **ESUAT la login real (2026-09-30 22:08):** Hyprland ABRT la pornire in Mesa `dri_create_fence_fd`
(Aquamarine `CDRMRenderer::recreateBlitSync`, blit spre eDP-1/Intel) -> SDDM te arunca inapoi, login imposibil. REVENIT:
implicit iar Intel:NVIDIA; NVIDIA-primul doar opt-in cu `touch ~/.config/hypr/nvidia-primary` (fisierul `intel-primary` nu mai conteaza).
Patratele care palpaie pe Samsung raman NEREZOLVATE. Lectie: orice schimbare de AQ_DRM_DEVICES se poate verifica DOAR la login real.
Backup: `~/.config-backups/pre-240hz-2026-09-30_22-04-01/`.

**Pătrate Samsung, runda 2 (2026-09-30, NETESTAT la login real):** ipoteza = Intel randeaza in buffere comprimate
CCS (`Y_TILED_GEN12_RC_CCS_CC` vazut in log), gunoi colorat la copia spre NVIDIA. In `hyprland.lua`: `AQ_FORCE_LINEAR_BLIT=1`
+ `AQ_MGPU_NO_EXPLICIT=1` (ambele confirmate cu `strings` in libaquamarine.so.13); plan B opt-in `touch ~/.config/hypr/intel-noccs`
-> `INTEL_DEBUG=noccs` (flag confirmat in libgallium 26.1.5). Log-ul sesiunii se salveaza acum in `~/.cache/hyprland/last-session.log`
(cel din $XDG_RUNTIME_DIR/hypr dispare la iesire). Ultima solutie ramasa: driver NVIDIA >=555 (Kali are doar 550).

**Pătrate Samsung, runda 3 (2026-09-30, live):** runda 2 aplicata si verificata in log (copia multi-GPU e LINEAR,
`Buffer is marked as multigpu, forcing linear`) — patratele AU RAMAS. Test live `hyprctl eval hl.monitor(...@60)`:
la 60Hz apar MAI RAR; userul zice ca apar ORIUNDE, SI PE ECRAN STATIC. Pe ecran static compozitorul nu randeaza
si nu copiaza nimic -> nu e Hyprland/Aquamarine, ci legatura HDMI (cablu/mufa/port). Recomandat: alt cablu HDMI
"Premium High Speed"/18Gbps, mufa reasezata, sau USB-C->DisplayPort (card1 are DP-6/DP-7; Samsung-ul are DP 1.2).
De confirmat: apar si in Plasma? Flag-urile AQ_FORCE_LINEAR_BLIT/AQ_MGPU_NO_EXPLICIT pot fi scoase daca se confirma cablul.

**Pătrate Samsung, runda 4 (2026-09-30) — CAUZA GASITA, ipoteza „cablu” din runda 3 era GRESITA:** in Plasma X11
nu apar, desi si acolo Samsung e la 239.76Hz. Cauza e in Aquamarine `CDRMRenderer::blit` (Renderer.cpp): copia pe NVIDIA
face intai `glClearColor(0.77,0,0.74)` (violet!) + glClear, apoi deseneaza. NVIDIA 550 n-are IN_FENCE_FD la KMS
(`Explicit sync unsupported` pe HDMI-A-2) si nici implicit sync -> scanout-ul prinde bufferul pe jumatate desenat.
Mai multe cadre (240Hz, text care curge in kitty pe Samsung) = mai multe patrate. Nereparat nici in upstream 0.15.1.
Fix: patch propriu (poll pe fence-ul blit-ului cand nu ajunge la KMS + glFinish daca nu exista fence; si la blit-ul
de cursor) -> pachet `libaquamarine13 0.14.0-2+mgpuwait1` instalat cu pkexec. ABI verificat: 0 simboluri lipsa pentru
Hyprland/hyprtoolkit, `LD_BIND_NOW=1 Hyprland --verify-config` ok. Sursa: `~/src/aquamarine-0.14.0-mgpuwait`
(rebuild: `dpkg-buildpackage -b -uc -us`; au trebuit `hyprwayland-scanner` + `libhyprutils-dev`; NU `libegl1-mesa-dev`,
trage upgrade de Mesa). Backup + revenire: `~/.config-backups/pre-aqfix-2026-09-30_22-28-39/revino-la-original.sh` (cu pkexec).
Un upgrade Kali al libaquamarine13 va suprascrie fix-ul -> reaplica patch-ul `mgpu-blit-wait.patch` de acolo.
AQ_FORCE_LINEAR_BLIT e oricum implicit activ in 0.14.0 (`!envExplicitlyDisabled`) — flag-ul nostru e no-op.
STARE: **CONFIRMAT la login real 2026-09-30 22:31** — userul: „perfect, a disparut”. Patratele sunt rezolvate.

**NVIDIA-primar, test one-shot PENDING (2026-10-01):** userul vrea 240Hz pe Samsung sa se *simta* real
(cu Intel-primar, fiecare cadru Samsung e randat pe Intel + copiat pe NVIDIA -> plafoneaza fluiditatea).
NVIDIA-primar ar randa Samsung nativ pe RTX 3060. Crash-ul de login din 2026-09-30 22:08 a fost INAINTE de
patch-ul mgpuwait (runda 4) care atinge exact `recreateBlitSync`/blit -> poate booteaza acum. Modificat
`hyprland.lua`: flag-ul `~/.config/hypr/nvidia-primary` e acum **ONE-SHOT** — citit si `os.remove`-uit in
parsarea configului (INAINTE de init-ul backend-ului DRM), deci daca login-ul crapa, un REBOOT revine automat
la Intel-primar (fara blocare). Flag CREAT 2026-10-01, test NEEFECTUAT inca (necesita logout/login real, care
omoara sesiunea Claude). De verificat dupa login: (1) booteaza? (2) eDP-1 (laptop) are artefacte acum? (copia
se muta Intel<-NVIDIA) (3) Samsung mai fluid? Daca bun si vrei permanent: schimba logica din one-shot in fix.
Daca prost: reboot (auto-recovery) sau TTY Ctrl+Alt+F3 + `rm -f ~/.config/hypr/nvidia-primary`.

**Task Manager (2026-09-30, mutat 2026-10-16; din 15 nov = btop tematizat, vezi [[task-manager-btop]]):** click pe CPU/GPU/RAM in bara quickshell ruleaza
`~/.config/hypr/scripts/open-taskmanager.sh` (inainte in waybar/scripts, folder sters la update) = KDE
`plasma-systemmonitor --page-id overview`, sau aduce in fata fereastra existenta cu
`hyprctl dispatch 'hl.dsp.focus({window="address:0x..."})'` (selector verificat; merge si `class:^(...)$`). Fereastra se
deschide tiled (fara regula de float). Doua sesiuni Claude in paralel pe acelasi rice: anunta-te cu SendMessage inainte sa
editezi quickshell/Bar.qml, hypr/keybinds.lua, monitors.lua, rules.lua sau look.lua.

**2026-10-18: `hyprland` + `hyprland-guiutils` sunt pe HOLD** — Kali 0.56.2+ds-3 trece pe libaquamarine14 0.15.1 nepatch-uit; detalii si conditia de unhold in [[system-update-2026-10-18]].

**2026-10-16: baza port-ului e acum upstream 93b68a4** (merge 3-way cu toate patch-urile de mai sus; waybar/wlogout/dunst
inlocuite de quickshell; motor de teme theme.py + matugen). Detalii si capcane: [[43pr-update-2026-10-16]].
