---
name: gaming-optimization-plan-2026-11-01
description: "Hub gaming Legion 5 17ITH6H (1 nov 2026) — fapte masurate, ce s-a aplicat, ce e placebo, decizii in asteptare; detaliile pe subiecte sunt in memoriile legate"
metadata:
  node_type: memory
  type: project
  originSessionId: 8c0dbf1e-e741-44e5-934b-6f304d352913
  modified: 2026-11-01T10:03:12.983Z
---

Cerere 1 nov: „documenteaza-te sa implementam cele mai optimizate solutii de gaming si de performanta”, apoi „fullscreen, nu
windowed fullscreen” + „rezolva toate erorile” + „plan clar si trecem la treaba”.

**Unde e fiecare lucru:** pasta noua si rezultatele termice -> [[repaste-mx4-thermal-results]]; fullscreen/tearing/scanout ->
[[cs2-fullscreen-hyprland-linux]]; sacadari din fonturi -> [[cs2-panorama-fonts-fix]]; cs2-perf, logger, MangoHud, abort gamescope
-> [[cs2-session-logger]]; reparatii de sistem -> [[fix-erori-2026-11-01]]; **planul de atac in curs (chkdsk + Shrink + partitie
ext4 + retest)** -> [[games-ext4-migration-plan]].

**Masurat pe boxa:** 82JM, BIOS H1CN58WW; TCC offset 3 => franare la 97°C; RAPL MSR 45/65 W (PL2 ~56 s); platform_profile =
lenovo-wmi-gamezone (custom nereglabil: lenovo-wmi-other lipseste); EPP balance_performance, preempt lazy, HZ 250, sched_ext oprit.
**MUX hardware EXISTA** (card1-eDP-2, „Advanced Optimus”). Samsung pe HDMI = **fara VRR** (EDID); monitorul are DP 1.2 G-SYNC
Compatible, card1-DP-6/7 nefolosite. ReBAR on, GSP on. Repo NVIDIA are 615.71.10 (pin pe 610).

**Aplicat 1 nov 08:38** (backup `~/.config-backups/pre-cs2-msaa-mangolog-2026-11-01_08-38-09`): cs2_video.txt msaa 8->4,
r_low_latency 2->1; MangoHud cs2.conf `no_display` -> `alpha=0.0`+`background_alpha=0.0` (0.8.4: no_display opreste si
autostart_log) => CSV in ~/.cache/mangohud-cs2. Plafon GPU 1500 MHz ([[gpu-mgpu-floor-service]]).

**LenovoLegionLinux 0.1.5** (`~/src/legion/LenovoLegionLinux`, userul a rulat make; NEinstalat, dispare la reboot): insmod
`ec_readonly=1 enable_platformprofile=0` (`~/src/legion/faza1-citire.sh`), hwmon `legion_hwmon`, fan1/2_input = RPM. Curba EC
atinge deja ~6800 RPM peste CPU 82°C / GPU 79°C (identic balanced/performance); `fan_fullspeed` WMI acceptat dar fara efect.
=> NU instala DKMS-ul (zero castig). Test A/B: `~/src/legion/faza2-test-ventilatoare.sh`.

**POE1+POE2 NU SUNT INSTALATE** (Steam UI, 28 oct 19:27 `Installs.OpenUninstallWizard`, nu Claude). La reinstalare: pe partitia
ext4 noua, GE-Proton11-11 (NU 11-8/11-9: issue #862), device_type Vulkan vs DX11, framerate_limit era 60, fara gamemoderun.

**Decizii in asteptare (dupa [[games-ext4-migration-plan]]):** fps_max (144/128/0, media 130 = tick 64); plafon GPU 1500 (dupa
datele GPU din logger); CS2 fara gamescope; test NVIDIA-primar (flag one-shot, logout omoara sesiunile Claude; ipoteza: podeaua
Intel 1450 MHz din gpu-mgpu-floor mananca din bugetul pachetului); MUX dGPU-only (SDDM X e Intel-only, eDP-2, initramfs); cablu
USB-C->DP pt VRR; gamemode (lipseste grupul `gamemode` din regula polkit Debian).
**Placebo/respins:** HZ 1000, nohz_full/isolcpus, irqbalance, THP, mitigations=off, thermald, TCC offset mai mare, undervolt
(blocat pe 11th gen), scx_lavd, driver 615 acum, Wine-Wayland, DXVK_ASYNC, nvidia-powerd off (doar daca plafonul nu ajunge),
`+engine_low_latency_sleep_after_client_tick true` (e deja implicit), __GL_SHADER_DISK_CACHE_* (OpenGL; cache Vulkan per joc 291 MB),
gamescope `--immediate-flips` cu backend sdl, gamescope CAP_SYS_NICE (risc bwrap, neaplicat).
Vezi [[gaming-windows-steam-on-kali]], [[nvidia-610-upgrade]].
**1 nov 18:57 — DECIS de user: fps_max FARA LIMITA** („scoate limita de tot”): LaunchOptions `+fps_max 0` (localconfig.vdf, Steam
oprit) + `cs2_machine_convars.vcfg` fps_max "0" + cs2-launch-options.txt (A si B). gamescope ramane -r 240 (afiseaza max 240).
Tot atunci, la cererea „sterge testul ala ce tot monitorizeaza”: flag `~/.config/cs2-log-on` STERS (log-joc.sh nu mai porneste) si
`MANGOHUD=1` SCOS din LaunchOptions (HUD-ul era invizibil, doar loga 120 s la fiecare pornire). Backup:
`~/.config-backups/cs2-fps-max-0-2026-11-01_18-57-21` (vdf original, vcfg, txt). Logurile vechi raman in ~/.cache.
**DESCHIS pt 2 nov 2026 (userul: „testez maine”):** prima sesiune CS2 cu `gamescope --backend wayland` + regula ws 2 + fps_max 0
([[cs2-fullscreen-hyprland-linux]]). Intreaba: (1) a pornit fara sa pice sesiunea? (daca a picat: `bash ~/src/legion/cs2-gamescope-backend.sh sdl`);
(2) mai intarzie/se blocheaza WASD si click-urile dupa un timp? Daca DA -> pasul urmator mouse 500 Hz (`usbhid mousepoll=2` prin
pkexec + replug, sau din Synapse in Windows; Basilisk V3 + tastatura BY-Tech sunt la 1000 Hz). Logger-ul e oprit (flag sters) ->
pt date obiective verifica `hyprctl -j clients` cat ruleaza jocul (fullscreen 2, ws 2) sau propune o sesiune cu logger.
