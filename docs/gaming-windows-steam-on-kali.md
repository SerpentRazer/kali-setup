---
name: gaming-windows-steam-on-kali
description: "Rularea POE1/POE2/CS2 (instalate pe Steam Windows, dual-boot) pe Kali; locatii, blocaj Fast Startup, plan, launch options"
metadata:
  node_type: memory
  type: project
  originSessionId: 15f1bc88-3e65-4bc8-a418-d1520583a777
  modified: 2026-10-03T08:33:56.780Z
---

Inceput 2026-10-03. User (Steam Linux logat: **vhododi / Raizin**) vrea POE1, POE2, CS2 pe Kali **fara reinstalare**, la **performanta maxima fara bottlenecks**. Laptop dual-boot Windows+Kali, hibrid Intel UHD + **RTX 3060 Laptop (driver 550.163.01)**; Vulkan merge pe NVIDIA.

**Locatii jocuri (NTFS):**
- `nvme0n1p4` (Windows C:) → `Program Files (x86)/Steam/steamapps/common`: **Path of Exile** (appid 238960, ~70GB), **Path of Exile 2** (appid 2694490, ~150GB).
- `sda1` (disc separat, label **STUFF**) → `SteamLibrary/steamapps/common`: **CS2** (appid 730, build Windows ~74GB), + No Man's Sky, AoE2DE, NFS Heat etc.
- Linux `/` = `nvme0n1p6` ext4, 100GB, **doar ~43GB liberi** → jocurile (~294GB) NU incap pe ext4; nu se pot copia local.

**Decizii user:** POE1+POE2 = ruleaza **in-place de pe NTFS prin Proton** (reutilizeaza fisierele Windows, zero redownload — sunt build Windows). CS2 = **redownload nativ Linux** (fisierele Windows nu se reutilizeaza pe Linux), instalat **pe STUFF** intr-un **container ext4** (fisier-imagine loop, ~120GB, la `/mnt/stuff/games`) — fiindca un joc nativ Linux NU merge fiabil direct pe NTFS (exec/case-sensitivity; Steam refuza). NU face repartitionare (a ales varianta "rapid").

**BLOCAJ REZOLVAT (2026-10-03):** user a dezactivat Fast Startup in Windows. Ambele NTFS acum curate: `ntfs-3g.probe --readwrite` → exit 0 pe p4 SI sda1. Montate rw (uid=1000,gid=1000,windows_names,big_writes,exec) la `/mnt/windows` (p4) si `/mnt/stuff` (sda1); fisiere apar ca mastermind, scriibile. Lectie: dupa Fast Startup off + Restart complet, NU forta montarea — doar `ntfs-3g.probe` confirma curatenia.

**PERSISTENTA (facut 2026-10-03):** adaugat in `/etc/fstab` prin UUID (backup `/etc/fstab.bak-*`): `UUID=060A49400A492DCD /mnt/windows` + `UUID=2ECC00CDCC0090EF /mnt/stuff`, ambele `ntfs-3g uid=1000,gid=1000,windows_names,big_writes,exec,nofail,x-systemd.device-timeout=10 0 0`; `daemon-reload` facut. `findmnt --verify` da warning fals-pozitiv "ntfs-3g unsupported by kernel" (lipsa ntfs3 kernel) — inofensiv, ntfs-3g FUSE monteaza ok.

**Ce e deja facut:** `gamemode` + `mangohud` instalate. Biblioteca C: (`/mnt/windows/Program Files (x86)/Steam`) inregistrata in `libraryfolders.vdf` Linux (backup `.bak-*`); Steam a scanat-o. **Confirmat installed (StateFlags 4):** POE1 (238960), POE2 (2694490, 150G), Proton Experimental (1493710), Steam Linux Runtime 4.0 (4183110) — toate pe C:. **Steam Play ACTIVAT** (config.vdf CompatToolMapping: default "0"→proton_experimental; "730"/CS2→proton_9). **ntfs3 kernel LIPSESTE** → doar ntfs-3g.

**SCHIMBARE plan CS2:** CS2 (730) e installed pe STUFF (build Windows, 74G) si mapat pe Proton 9 → se ruleaza DIRECT prin Proton de pe NTFS, containerul ext4 ABANDONAT (nu mai e nevoie). Revino la varianta nativa doar daca FPS prost.

**CONFIRMAT + REZOLVAT (2026-10-03):** primul launch POE1/POE2 a crapat exact cum prezis — `OSError: [Errno 22] Invalid argument: '../drive_c' -> '.../compatdata/238960/pfx//dosdevices/c:'`. Cauza: Proton creeaza symlink `dosdevices/c:` cu `:` in nume = ILEGAL pe NTFS (plus blocat de `windows_names`). **Un prefix Proton NU poate sta pe NTFS, niciodata.** FIX aplicat: mutat `compatdata` pe ext4 (`/home/mastermind/.local/share/steam-compat-c`) + **bind mount** inapoi la `<C:>/steamapps/compatdata` (bind, nu symlink pe NTFS). Persistent in fstab: `/home/mastermind/.local/share/steam-compat-c  <cale C: escaped \040>/compatdata  none  bind,nofail,x-systemd.requires=/mnt/windows 0 0`. Prefixuri stricate 238960/2694490 sterse (se refac); runtime 1493710+2180100 mutate, nu sterse. Test `ln -s ../drive_c "x:"` pe noua locatie = OK. Fisierele jocului RAMAN pe NTFS; doar prefixul (~GB) pe ext4 (43GB liberi, destul). **Acelasi fix va trebui si pt CS2 (acelasi bind acopera tot compatdata de pe C:, dar CS2 e pe STUFF → va avea nevoie de bind separat pe `/mnt/stuff/SteamLibrary/steamapps/compatdata` cand il pornesti.)**

**Gotcha minor (neblocant):** in log `gamemodeauto: dlopen failed - libgamemode.so` desi libgamemode0 (i386+amd64) e instalat — containerul pressure-vessel al Proton nu vede libul host. Jocul merge, dar gamemode nu se activeaza. De investigat dupa ce POE porneste.

**TUNING APLICAT (2026-10-03):** POE1 a pornit cu succes dupa fix (prefix 238960 creat pe ext4). Editat `production_Config.ini` (in prefix: `.../compatdata/238960/pfx/drive_c/users/steamuser/Documents/My Games/Path of Exile/`): device_type DirectX12→**DirectX11** (DXVK>VKD3D pt POE1), texture_quality Low→**High**, vsync Adaptive→**Off**, use_dynamic_resolution true→**false**, use_dynamic_particle_culling→**true**, framerate_limit 60→**120** (=Samsung Hz), dynamic_resolution_fps→120. PASTRAT borderless_windowed_fullscreen=true (NU exclusive — pe Hyprland/Wayland exclusive da black-screen/alt-tab issues; borderless+cap+vsync off = fara tearing, latenta mica). engine_multithreading deja enabled. Launch options NESCHIMBATE — cele existente sunt deja bune; adaosurile (__GLX_VENDOR_LIBRARY_NAME, DXVK_STATE_CACHE) marginale si ar cere Steam inchis.

**Governor CPU:** era `powersave` → setat `performance` + serviciu systemd persistent `/etc/systemd/system/cpu-performance.service` (enabled). Reversibil: `systemctl disable --now cpu-performance` + rm. Inlocuieste beneficiul gamemode (care crapa in container).

**DIAGNOSTIC PERF/CRASH (2026-10-03) — important:**
- **Hardware:** i7-11800H (16GB RAM, doar 15 utilizabil), laptop cu Samsung HDMI-A-2 1080p@120 (joci acolo) + eDP 1080p@144. GPU 3060 confirmat ca randeaza (nu Intel).
- **CAUZA stutter = THERMAL THROTTLING.** Log MangoHud: avg 89 FPS dar **1% min=27**, CPU **96°C avg / 99°C peak**. Laptopul avea **PL1=90W / PL2=135W** (absurd pt 11800H pe racire de laptop) → 99°C → throttle → spike-uri. FIX aplicat: `powercap intel-rapl:0` **PL1=55W, PL2=75W** + governor inapoi pe `powersave` (am sters serviciul meu gresit `cpu-performance.service` care forta `performance` = mai multa caldura). RAPL **nu persista la reboot** — de facut serviciu daca vrea permanent. GPU/VRAM citite 0 in MangoHud (NVML nu merge prin offload in container) — VRAM real ~2.2GB, texturile High NU-s problema.
- **CRASH-uri POE1 = watchdog "Deadlock detected with timeout 10000ms; running graph nodes: RecordUI, RecordMetaPasses".** Apare la **prima incarcare a unei scene 3D** (oras): streaming asset de pe ntfs-3g (latenta FUSE) + compilare shadere DXVK > 10s → POE se auto-omoara. 2 cauze reale; una (deadlock-ul initial 11:00) a fost **vina mea** — am rulat `drop_caches`+citit 575MB din bundle sub jocul care RULA (nu mai fac drop_caches cu joc pornit). A doua (11:06) e pur first-load lent. Steam Overlay deja OFF (nu e el). STRATEGIE: **retry de 2-3 ori** (fiecare incercare incalzeste page cache cu asset-urile orasului ~1-3GB in cei 10GB liberi → a 2-a/3-a incarca din RAM <10s) + DXVK state cache pe ext4 se umple. Setari deja Low. Daca tot crapa dupa 3 → **Proton-GE** (download+extract in `~/.steam/.../compatibilitytools.d/`). ntfs3 kernel lipseste (altfel ar fi fix definitiv prin latenta mica); mutarea pe ext4 imposibila (POE1 70GB vs 43GB liberi).

**THERMAL PROTECTION PERSISTAT (2026-10-03):** `/etc/systemd/system/cpu-thermal-protect.service` (enabled) re-aplica la boot **PL1=45W, PL2=65W** (coborat de la 55W fiindca era 89°C chiar in oras). RAPL nu persista altfel. Daca firmware reseteaza in timp → de adaugat timer periodic.

**CRASH ROOT CAUSE confirmat + decizie pending (2026-10-03):** crash-urile repetate POE1 ("Deadlock detected 10000ms" la load oras/stash/map nou) = **ntfs-3g FUSE** (latenta mare + citiri agatate ocazional) sub watchdog-ul strict de 10s al POE. Jocul uneori "Recovered from deadlock", alteori moare. La un crash a ramas proces agatat `PathOfExileSteam.exe` la 250% CPU (greu de omorat, posibil D-state pe FUSE) → omorat cu SIGKILL pe arbore (dar Steam/user il relanseaza). **`ntfs3` kernel CONFIRMAT ABSENT** (`modinfo ntfs3`=not found, `/proc/filesystems` doar fuse; nu exista in /lib/modules — kernel 7.1.5+kali custom fara CONFIG_NTFS3). Deci NTFS=doar ntfs-3g FUSE. Steam Overlay deja OFF (nu e el). Spatiu: ext4 `/` doar **41GB liberi** vs POE1 **66GB** → nu incape pe ext4. C: 517GB liberi, STUFF 272GB liberi, dar ambele NTFS/FUSE. **OPTIUNI prezentate userului:** A) Proton-GE (stopgap, risc mic, recomandat intai) B) kernel cu ntfs3 (fix definitiv, dar risc NVIDIA DKMS la reboot) C) repartitionare ext4 pt jocuri (reinstalare). **Astept alegerea** (recomandat A).

**GE-Proton INSTALAT + MAPAT (2026-10-03, optiunea A aleasa):** `GE-Proton11-7-x86_64` (x86_64, NU aarch64 — API-ul "latest" da intai ARM, atentie) extras in `~/.steam/root/compatibilitytools.d/`. POE1 (238960) era mapat pe `proton_7` (vechi) → schimbat in config.vdf la `GE-Proton11-7-x86_64` (backup config.vdf.bak-*). Procedura: omorat POE agatat, `steam -shutdown` (merge din shell cu env grafic WAYLAND_DISPLAY=wayland-1 DISPLAY=:1), editat config.vdf cu Steam inchis, repornit Steam (`setsid steam &` din shell — env grafic prezent). Maparea a tinut dupa restart = GE detectat valid. Prefixul 238960 ramane (GE face upgrade la primul launch; filtrele persista). **Astept rezultatul testului** (oras + stash = locurile care crapau). Daca tot crapa → kernel ntfs3 (optiunea B).

**2026-10-18:** `GE-Proton11-9-x86_64` adaugat langa 11-7 (sha256+sha512 verificate); maparea POE ramane pe 11-7 pana o schimba userul.

**De facut (pending):** 1) user da Play POE1 cu GE-Proton, testeaza oras+stash, raporteaza. 2) daca crapa → kernel cu ntfs3 (risc NVIDIA DKMS). 3) CS2 → bind separat compatdata pe STUFF. 4) POE2 → copiaza cele 7 filtre NeverSink 2 + bind compatdata. 5) dmesg `nv_drm_revoke_modeset_permission` (nvidia 550+Wayland) — doar WARNING, de urmarit.

**Afisare pe Samsung (masurat 2026-10-17):** chiar si un joc randat pe NVIDIA trece prin compozitarea pe Intel + blit inapoi pe NVIDIA → era afisat la ~43 fps oricat randa jocul; cu [[gpu-mgpu-floor-service]] ~116 fps (se potriveste cu framerate_limit 120 din POE). Monitorul e acum pe 239.76Hz.

**Launch options (ambele jocuri):** `__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only gamemoderun mangohud %command%`. **Perf max:** joaca fullscreen pe **Samsung HDMI-A-2** (cablat la RTX 3060 — dar compozitarea tot pe Intel + blit inapoi, deci NU e fara penalitate; vezi paragraful „Afisare pe Samsung" si [[hyprland-lua-native-config]]). Scripturi pregatite in scratchpad sesiune (efemer). Vezi [[verify-before-instructing]], [[root-via-pkexec-not-sudo]], [[no-chaining-off-apt-update]].

**28 oct: CS2 NATIV in container ext4 pe C:** (userul a ales „Nativ, container ext4”). Gasit: Linux Steam descarca CS2 **build
Windows** (maparea `proton_9` pt 730 din 3 oct) in biblioteca Steam a WINDOWS-ului de pe C: — ar fi incurcat Steam-ul din Windows,
care are deja CS2 pe STUFF. STUFF NU mai e biblioteca in Linux Steam. `/` are doar ~31 GB liberi (CS2 Linux ~66 GB).
Facut: `/mnt/windows/LinuxGames/kali-games.ext4` (120 GiB, umplut cu dd — ntfs-3g NU suporta fallocate), mkfs.ext4 label
`kali-games` root_owner 1000, montat la **`/mnt/games`** prin fstab (`loop,noatime,nofail,x-systemd.requires-mounts-for=/mnt/windows`,
backup `/etc/fstab.bak-cs2-*`). Biblioteca Steam „2” = `/mnt/games/SteamLibrary` (label „Kali games (ext4)”, ambele
libraryfolders.vdf, backup `.bak-pre-cs2-native-*`); maparea 730 SCOASA din config.vdf (backup idem); descarcarea partiala
Windows de pe C: stearsa (manifest in `~/.config-backups/pre-cs2-native-*`). Instalarea pornita cu un appmanifest_730
StateFlags 1026 pus in noua biblioteca -> Steam a luat depot **2347773 (Linux)** + 2347770 comun, ~61 GB, ~400 Mbps.
`steam -shutdown` merge din shell (WAYLAND_DISPLAY/DISPLAY prezente), pornire `hyprctl dispatch 'hl.dsp.exec_cmd("steam")'`.
**PENDING:** dupa download userul cere „setarile optime pt cea mai buna performanta” -> launch options (offload NVIDIA,
fara Proton), video settings CS2, fps cap vs 240Hz Samsung, gpu-mgpu-floor, thermal (PL1 45W), mangohud verificare.

**28 oct seara (sesiunea CS2 intrerupta de crash-ul Hyprland, vezi [[grim-nvidia-window-crashes-hyprland]]):** gamescope 3.16.24
instalat (`/usr/games/gamescope`); test caldura: PL1 35 W -> 97°C medie, 2926 MHz; PL1 40 W -> 96°C, 2952 MHz, throttle la
ambele -> ramas PL1 45 / PL2 65 (cpu-thermal-protect.service). Adaugat regula `gamescope-competitive` in rules.lua; MangoHud
cs2.conf `autostart_log=60` + `log_duration=120`. **28 oct ~20:53 APLICAT** (dupa test izolat, vezi [[grim-nvidia-window-crashes-hyprland]]): LaunchOptions 730 =
`__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only __GL_SHADER_DISK_CACHE_SIZE=12000000000 __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
SDL_VIDEODRIVER=x11 /usr/games/gamescope --backend sdl -w 1440 -h 1080 -W 1920 -H 1080 -r 240 -S stretch -f --force-grab-cursor
--immediate-flips -- env MANGOHUD=1 %command% -nojoy` (fereastra gamescope prin Xwayland, ca CS2 inainte). NICIODATA backend-ul wayland
(implicit!) -> crash Hyprland. Backup `~/.config-backups/pre-cs2-gamescope-2026-10-28_20-52-*`. Prima rulare 22:38: CS2 SIGSEGV in libnvidia-glcore 550 dupa ~30 s (Hyprland VIU, 0 sg_table) = bug driver declansat de stratul Gamescope WSI (CS2 prezenta prin Vulkan-Wayland NVIDIA + maintenance1 fortat). **22:52 APLICAT** `-- env DISABLE_GAMESCOPE_WSI=1 MANGOHUD=1 %command%` (calea jocului = ca nativ, X11 WSI; test izolat vkcube OK, imagine nu neagra); backup `~/.config-backups/pre-cs2-nowsi-2026-10-28_22-52-12`; monitor `~/src/gpu-nested-test/watch-cs2.sh`. PENDING: rularea 2 + impresia. Daca tot crapa: MangoHud afara (README: neacceptat in gamescope; `--mangoapp`), apoi nativ Wayland cu `SDL_VIDEO_WAYLAND_MODE_SCALING=stretch`; driver nou = ultima varianta (Debian are doar 550/555 exp).

**29 oct (reluat dupa limita de cost din 28 oct 23:40):** rularea 2 (28 oct 22:59-23:35, 36 min) = FARA crash in joc, 0 sg_table,
Hyprland viu; gamescope SIGABRT doar LA IESIRE („terminate called without an active exception”, bug cunoscut, inofensiv). Impresia
userului: fps bun DAR stutter, butoane care nu raspund prompt, spike-uri de ms; fereastra gamescope era TILED 1904x1039 (fara
fullscreen => fara tearing), CPU pachet 97°C cu throttle, GPU motive 0x4C (HW slowdown + termic HW). Aplicat 28 oct 23:39: regula
`gamescope-competitive` + `fullscreen = true` (rules.lua) si `+fps_max 240`; rularea 3 (23:41-23:43) fara feedback. **29 oct 18:09
APLICAT** (backup `~/.config-backups/pre-cs2-lowlat-2026-10-29_18-09-23`): `LD_PRELOAD=` in fata (scoate overlay-ul Steam din joc,
sfat ProtonDB anti-stutter; Shift+Tab nu mai merge), `/home/mastermind/.local/bin/cs2-perf` inaintea gamescope (tine
`powerprofilesctl` pe performance doar cat ruleaza jocul = ventilatoare EC mai tari + EPP performance; PL ramane 45/65 W, verificat;
ascunde LD_LIBRARY_PATH-ul Steam de python), `+engine_low_latency_sleep_after_client_tick true` la final. **gamemoderun NU
merge aici**: polkit-ul Debian are allow_active=no pt cpugovctl („Not authorized”), deci nu l-am pus. Monitor v2
`~/src/gpu-nested-test/watch-cs2.sh` (fullscreen/tearingBlockedBy, MangoHud/overlay incarcate in cs2, CSV senzori 1/s in
~/.cache/mangohud-cs2/sensors-*.csv + rezumat). **PENDING:** rularea 4 + impresie. Daca tot sacadeaza: cauza structurala =
compozitarea pe Intel + blit pe NVIDIA (~116 fps reali pe Samsung, vezi mai sus) => urmatorul pas e CS2 nativ Wayland fara
gamescope (`SDL_VIDEO_DRIVER=wayland` + `SDL_VIDEO_WAYLAND_MODE_SCALING=stretch`), DOAR dupa test izolat in harness (risc crash
Hyprland ca la gamescope wayland); alternativ fps_max 120 (cadenta 2 vblank-uri) daca prefera fluiditate vs latenta.
**Rularea 4 (29 oct 18:23-18:26, 3 min):** fullscreen 2 OK (1920x1080), overlay Steam absent, MangoHud incarcat (dar tot fara CSV),
profil performance tinut si revenit singur la balanced; 0 sg_table, Hyprland viu; abort gamescope la iesire (python-ul
powerprofilesctl doar re-ridica semnalul copilului = coredump python3.14 inofensiv). Tearing: regula `immediate` SE APLICA
(`hyprctl getprop address:X immediate` = true), motivul ramas `NOT_TORN` = „next frame is not torn” (stare de moment, nu blocaj de
configurare). **Cauza dovedita a spike-urilor: CPU** — pachet 94°C medie dupa primul minut, 98°C des, ~100 evenimente throttle/s
(12813 in 3 min), MHz medie scade la ~2650-2900 in varfuri; GPU ok (60°C, 1259 MHz). Chiar si la PL1 35 W era 97°C (28 oct) =>
racire degradata (praf/pasta, laptop 2021). Propus: fps_max mai mic (calea Samsung arata oricum ~116 fps) + curatare/repasta.
**29 oct 19:57:** userul a ales `+fps_max 144` (era 240) ca sa scada caldura CPU; backup `~/.config-backups/pre-cs2-fps144-2026-10-29_19-57-08`; Steam repornit, optiunea a ramas. Monitor v2 pornit pt rularea 5 (comparatie temperaturi vs rularea 4).

**30 oct — CORECTIE:** `ntfs3` lipseste, dar kernelul 7.1.5 are driverul NOU `ntfs` read-write (`modinfo ntfs`: Namjae Jeon, fs/ntfs/ntfs.ko) -> varianta „kernel NTFS” pt crash-urile POE nu mai cere alt kernel; netestat inca, vezi [[cachy-bazzite-tuning]].

**30 oct 22:37: C: (/mnt/windows) ruleaza pe driverul KERNEL `ntfs`, nu ntfs-3g** — POE si containerul CS2 citesc acum fara FUSE (test STUFF: 2x citiri paralele, +43% secvential, fara blocajele de ~100 ms). De urmarit daca dispar crash-urile POE „Deadlock 10000ms”. Detalii + revenire: [[cachy-bazzite-tuning]].
**1 nov: POE1 + POE2 NU MAI SUNT INSTALATE** (Steam Linux, 28 oct 19:27 wizard de uninstall din UI, starea era deja „Files
Missing”; userul inca n-a raspuns daca a fost el). CS2: msaa 4, r_low_latency 1, MangoHud log reparat (alpha=0 in loc de
no_display), fps_max ramas 144 (propus 120). Tot planul + ce e placebo: [[gaming-optimization-plan-2026-11-01]].
- **1 nov 2026:** containerul de pe C: se inlocuieste cu o partitie ext4 nativa (C: a trecut read-only) -> [[games-ext4-migration-plan]].
