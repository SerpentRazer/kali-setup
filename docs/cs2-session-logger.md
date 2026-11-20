---
name: cs2-session-logger
description: cs2-perf (wrapper din LaunchOptions CS2) + logger-ul automat log-joc.sh; de ce MangoHud nu vede GPU/putere; abort-ul gamescope la iesire
metadata:
  node_type: memory
  type: reference
  originSessionId: 8c0dbf1e-e741-44e5-934b-6f304d352913
  modified: 2026-11-01T10:02:29.675Z
---

**`~/.local/bin/cs2-perf`** (in LaunchOptions CS2, inaintea lui gamescope): din 1 nov 2026, inainte de exec:
`ulimit -c 0`; aplica [[cs2-panorama-fonts-fix]]; daca exista `~/.config/cs2-log-on` porneste `log-joc.sh` (setsid, fara
LD_LIBRARY_PATH/LD_PRELOAD de la Steam). Apoi powerprofilesctl launch -p performance. Backup inainte:
`~/.config-backups/pre-fix-erori-user-2026-11-01_11-46-28`. **Sterge flag-ul cand nu mai testam** (nvidia-smi la 1 s = cost mic).

**`~/src/legion/log-joc.sh`**: flock (o singura instanta), asteapta `cs2` max 15 min, apoi la 1 s pana se inchide jocul:
`log.csv` (nvidia-smi: temp, W, MHz, mem, pstate, util, clocks_event_reasons; CPU pachet °C, MHz medii, franari) +
`hypr.csv` (starea HDMI-A-2 din [[cs2-fullscreen-hyprland-linux]] + fullscreen/marimea ferestrei gamescope). Rezumate in
`~/.cache/joc-log-<data>/rezumat*.txt` (mediile doar pe secundele cu GPU >=40%). Biti motive NVIDIA: 0x4 SW power cap,
0x20 SW thermal, 0x40 HW thermal.

**MangoHud** (CSV in `~/.cache/mangohud-cs2`, HUD transparent, log 120 s dupa 60 s): gpu_* = 0 pt ca pachetul Debian e DFSG,
compilat `-Dwith_nvml=disabled` (jurnal: „NVML and NVCTRL are unavailable”); cpu_power = 0 pt ca `energy_uj` e root-only
(fix posibil: regula udev chgrp mastermind, compromis Platypus CVE-2020-8694 — NEaplicat). fps/frametime/cpu din MangoHud sunt
masurate IN gamescope, nu ce ajunge pe ecran.

**gamescope 3.16.24 SIGABRT la fiecare iesire** („terminate called without an active exception”, dupa `CSteam3Client::Shutdown`):
bug upstream reparat in commit 16a44df (3.16.25+), Kali/sid n-au versiunea. Inofensiv; powerprofilesctl moare sub el dupa
ReleaseProfile, profilul revine pe balanced. `ulimit -c 0` opreste core-urile de ~180 MB.
**Media ~130 fps la fps_max 144** = cuantizare pe tick-ul de 64 (2.03 cadre/tick), nu calea de afisare -> candidati 128 sau 0.
Vezi [[gaming-optimization-plan-2026-11-01]].
**1 nov ~15:15 — ecranul laptopului STINS cat ruleaza CS2** (userul: „fix now”, fara sa aleaga intre stins/60 Hz -> am ales stins): `~/src/legion/ecran-laptop-joc.sh` pornit de cs2-perf cat exista `~/.config/cs2-laptop-stins`; asteapta fereastra gamescope|cs2, stinge eDP-1 DOAR daca jocul e pe alt monitor, trap EXIT/INT/TERM/HUP aprinde la loc; flock. Comanda Hyprland 0.56 Lua: `hyprctl dispatch 'hl.dsp.dpms({action = "off", monitor = "eDP-1"})'` (action on/off/toggle; testat). Daca userul vrea Discord vizibil pe laptop in joc -> varianta 60 Hz.
**1 nov ~15:18 — USERUL NU VREA laptopul stins** („dar nu vreau sa fie stins monitorul laptopului”) -> flag ~/.config/cs2-laptop-stins STERS (functia ramane pe disc, inactiva). Nu mai propune stingerea; alternativa (doar daca o cere) = eDP-1 pe 60 Hz in joc.
**1 nov 18:57 — LOGGER OPRIT:** flag `~/.config/cs2-log-on` sters + MANGOHUD=1 scos din LaunchOptions (cerut de user). Codul din
cs2-perf ramane (porneste log-joc.sh doar daca recreezi flag-ul); MangoHud se repune adaugand `MANGOHUD=1` inainte de %command%.
