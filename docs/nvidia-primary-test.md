---
name: nvidia-primary-test
description: Testul Hyprland NVIDIA-primar (1 nov 2026) — de ce (pe ecran ajung ~100 fps din 240 Hz), referinta hzprobe, pasii, ce verifici dupa login, cum il faci permanent / revii
metadata:
  type: project
---

**De ce (1 nov 2026):** userul: „vreau 144 DE CADRE PE SECUNDA” pe ecran. Cu Intel-primar (AQ_DRM_DEVICES=card0:card1) fiecare cadru
Samsung = randare pe Intel + blit pe NVIDIA; hzprobe 14:25 (`~/src/hzprobe/rezultat-2026-11-01-intel-primar.txt`): full 93 fps,
**client pe NVIDIA (ca un joc) 101 fps**, small 177 fps; la full niciodata 1 cadru/refresh (2x-3x). Pe 17 oct era 110/116/171.
**Premise verificate:** env-ul din Lua ajunge inainte de aquamarine (log: `drm: Explicit device list /dev/dri/card0:/dev/dri/card1`);
NVIDIA 610 raporteaza `supportsTimelines: true` (pe 550 lipsea -> crash 30 sep in recreateBlitSync / Mesa dri_create_fence_fd la
blit-ul spre eDP-1); crearea unui fisier in ~/.config/hypr NU declanseaza reload (testat cu socket2) => flag-ul supravietuieste.
**Pasi:** `touch ~/.config/hypr/nvidia-primary` -> logout -> login. Flag ONE-SHOT: hyprland.lua il sterge la parsare si pune
AQ_DRM_DEVICES=card1:card0. Daca Hyprland crapa/negru: inapoi la SDDM, login din nou = Intel-primar; blocaj total = reboot.
Logout-ul omoara sesiunile Claude -> userul revine cu `claude --continue`.
**Dupa login verifica:** `grep 'Explicit device list' $XDG_RUNTIME_DIR/hypr/*/hyprland.log` (card1 primul), ambele monitoare
(hyprctl monitors, Samsung 239.76), apoi `cd ~/src/hzprobe; ./hzprobe HDMI-A-2 full 6`, varianta cu
`__NV_PRIME_RENDER_OFFLOAD=1 __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json`, si small 5 -> compara.
Apoi CS2 (logger automat). Atentie: gpu-mgpu-floor tine Intel la 1450 MHz degeaba in modul asta (de revazut daca ramane).
**Permanent (doar daca merge):** in hyprland.lua ramura `else` sa puna NVIDIA .. ":" .. INTEL (sau flag persistent); de ganditi
bateria (NVIDIA mereu activ cu monitorul extern) si laptopul fara Samsung.
Vezi [[hyprland-lua-native-config]], [[nvidia-610-upgrade]], [[gpu-mgpu-floor-service]], [[cs2-fullscreen-hyprland-linux]].

**REZULTAT 1 nov 14:28 — NVIDIA-PRIMAR MERGE** (login ok, log: `Explicit device list /dev/dri/card1:/dev/dri/card0`, ambele monitoare,
Samsung 239.76). hzprobe (`~/src/hzprobe/rezultat-2026-11-01-nvidia-primar.txt`): Samsung full **235 fps** (93), client NVIDIA
**233** (101), small 236 (177); 97-98% cadre la fiecare refresh (0% inainte); latenta p50 7.8 ms (10-12). Laptop eDP-1 (Intel,
secundar) tot 98% din 144 Hz, latenta 10.6 ms, DAR blit-ul spre Intel cade pe copie prin CPU: log `EGL (blit): Failed to create
image from source buffer directly, allocating intermediate buffer` (eglCreateImageKHR EGL_BAD_MATCH). Cost: Hyprland ~33% dintr-un
nucleu in „repaus” cu Spotify pornit (animatia barei/cava redeseneaza continuu ambele ecrane), 38% full pe Samsung, 44% full pe laptop.
Mitigari posibile: laptopul stins/60 Hz in timpul jocului. Flag-ul e ONE-SHOT: la urmatorul login revine Intel-primar (nefacut
permanent inca). Urmeaza: CS2 (gamescope prin Xwayland acum pe acelasi GPU), apoi permanent conditionat de Samsung conectat.
**Dupa comutare (14:32):** Steam a recalculat bucket-urile de shadere („Current buckets changed! Pruning old entries”, a sters replay_cache.*.foz si cache-ul Mesa anv_9a60) -> replay fossilize COMPLET 730 (~1.5M pipeline-uri, ~1.2%/min => ~80 min, 3 procese la 99% CPU). Cache-ul driverului NVIDIA pt CS2 (shadercache/730/nvidiav1, 1.5 GB) ramane valid (acelasi GPU+driver) -> sfat: Skip; Steam opreste replay-ul cat ruleaza jocul si il reia in fundal. Se va repeta la fiecare comutare Intel<->NVIDIA -> inca un motiv pt NVIDIA-primar permanent.

**1 nov 14:49 — FACUT PERMANENT, AUTOMAT** (userul: „acum se simte bine claaaar” dupa CS2 pe NVIDIA-primar). hyprland.lua:
`nvidia_has_monitor()` citeste `/sys/class/drm/<cardNVIDIA>-*/status`; orice „connected” la login => AQ_DRM_DEVICES=NVIDIA:INTEL,
altfel Intel:NVIDIA. URGENTA: `touch ~/.config/hypr/intel-primary` (PERSISTENT, nu one-shot: Intel la fiecare login pana il stergi;
merge si din TTY). `nvidia-primary` ramane one-shot (forteaza NVIDIA si fara monitor). Logica testata cu lua5.4 pe 3 cazuri.
Backup + revino.sh: `~/.config-backups/pre-nvidia-primar-auto-2026-11-01_14-49-47`. Sesiunea CS2 14:47 (66 s): fullscreen 64/66 s,
GPU 1949 MHz / 94 W / max 71°C (plafon putere 19 s, termic 3 s), CPU 67°C. DE FACUT: gpu-mgpu-floor tine Intel la 1450 MHz degeaba
in NVIDIA-primar (mananca din bugetul pachetului CPU) -> sa sara podeaua Intel cand Hyprland e NVIDIA-primar; optional laptopul
stins/60 Hz in joc (copie CPU); confirmare la urmatorul login (log: Explicit device list card1:card0).
**1 nov ~15:05 — pregatit (ruleaza userul DUPA joc):** `pkexec /bin/bash ~/src/legion/test-podea-intel.sh` = 20 s RAPL pachet + uncore cu podeaua Intel 1450 vs 20 s fara (RPn 350), pune la loc (trap). Daca diferenta e mica (<~1-2 W) podeaua ramane; daca nu: gpu-mgpu-floor sa sara podeaua Intel cand Hyprland e NVIDIA-primar (detectie: `Explicit device list /dev/dri/card1` in /run/user/*/hypr/*/hyprland.log; problema: la boot serviciul ruleaza inainte de login -> ar trebui re-declansat dupa login). Userul intreaba daca putem optimiza cat joaca: DA pt analiza/scripturi, NU pt schimbari Hyprland/GPU/apt/Steam.

**1 nov ~16:10 — CAPCANA GRAVA NVIDIA-primar: DPMS off/on pe eDP-1 (laptop, Intel secundar) il lasa NEGRU pana la relogin.**
Testul meu `hl.dsp.dpms` off/on (15:15) -> hyprctl arata dpms=true, backlight 100%, dar hzprobe eDP-1 = 0 cadre (blocaj); userul:
„da monitorul nu-l aprinzi?”. Incercate fara efect: dpms on, dpms off/on, `hl.dsp.force_renderer_reload()`, `hyprctl eval
'hl.monitor({output="eDP-1", mode="1920x1080@60"...})'` si inapoi, disable + re-enable (re-enable prin eval NU l-a readus; doar
`hyprctl reload` l-a readus in lista, tot 0 cadre); log (eval disable_logs=false): Hyprland nici nu mai incearca cadre pe eDP-1.
=> fix doar logout/login sau restart. NU mai stinge eDP-1 cat Hyprland e pe NVIDIA. RISC: acelasi lucru dupa suspend/resume s2idle
sau capac -> DE TESTAT dupa restart (reteta [[sleep-resume-test-recipe]]); daca da, NVIDIA-primar automat trebuie regandit.
Lectie: verifica imaginea reala (hzprobe pe iesire), nu doar dpmsStatus din hyprctl.

**1 nov ~16:25 — DUPA REBOOT, TOTUL CONFIRMAT:** NVIDIA-primar pornit AUTOMAT (log `Explicit device list /dev/dri/card1:/dev/dri/card0`),
laptop eDP-1 142/144 fps (revenit dupa blocajul DPMS), Samsung 235.6/239.76, Xwayland primar HDMI-A-2, bara qs ok,
/mnt/games = p11 ext4, C:/STUFF fuseblk + 4 bind-uri, gpu-mgpu-floor activ, swappiness 100, LANG=C.UTF-8. RAMANE: testul de
suspend (eDP-1 dupa resume pe NVIDIA-primar — risc negru ca la DPMS), cand vrea userul.
**1 nov ~16:30:** podeaua Intel testata (`test-podea-intel.sh`): 45.04 vs 45.03 W, iGPU doarme 100%, 0 MHz -> costa nimic, gpu-mgpu-floor
ramane neschimbat (cei 45 W erau fossilize_replay de la Steam, oprit de user din Settings > Shader Pre-Caching > background processing).
Userul dupa reboot: „pai acum merge displayul” -> testul de sleep amanat (optional); daca dupa capac/sleep laptopul ramane negru: logout.
**1 nov 18:57 — testul de sleep: RENUNTAT** (userul: „lasa testul de sleep daca nu-i nevoie de el”). Nu-l mai propune; daca dupa
capac/sleep un ecran ramane negru -> logout/relogin (sau `touch ~/.config/hypr/intel-primary`).
