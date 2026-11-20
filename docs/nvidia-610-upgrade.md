---
name: nvidia-610-upgrade
description: "29 oct — driver NVIDIA 550 (Kali) -> 610.57.04 din repo-ul oficial NVIDIA debian13 (module open), pt CS2/Hyprland fluid ca pe Windows; scripturi de instalare/revenire, checklist dupa reboot"
metadata:
  node_type: memory
  type: project
  originSessionId: cd495141-1b19-47cf-b3d1-87d4b5b8df5d
  modified: 2026-10-30T19:58:00.000Z
---

**De ce (29 oct, userul: „de ce nu ruleaza la fel de smooth ca pe windows, let's achieve that”, a ales „Driver NVIDIA nou”):**
pe Windows cadrul CS2 merge NVIDIA -> Samsung direct; aici CS2 -> gamescope -> Xwayland -> Hyprland compune pe Intel -> copie
pe NVIDIA (~116 fps reali pe Samsung, [[gpu-mgpu-floor-service]]). Driverul 550 n-are explicit sync, deci Hyprland nu poate
rula pe NVIDIA (crash la login 30 sep, [[hyprland-43pr-on-kali]]). Userul confirma ca si pe Windows CPU-ul e 90°C+ in CS2
=> caldura NU e diferenta dintre sisteme. Kali/Debian au maxim 550 (experimental 555); repo-ul NVIDIA debian13 are 590-615.

**Pregatit in `~/src/nvidia-610-upgrade/`** (fara root): `sim-env.sh` (apt privat Kali+NVIDIA, vezi
[[system-update-2026-10-18]]), simulare `sim2.txt` = 36 upgrade + 9 noi (nvidia-kernel-open-dkms, nvidia-powerd,
libnvidia-egl-wayland21...) + EXACT 12 eliminari Debian (`expected-remv.txt`: nvidia-alternative, nvidia-kernel-dkms,
nvidia-suspend-common etc.); pachetele i386 (Steam) exista si in repo-ul NVIDIA. Cheia: `Kitmaker (Debian 13 Trixie)`
fpr 02182E60104FCDC26EAE1B8597A5D4CB8793F200, cuda-keyring_1.1-1 sha256 d0d4ef98... Modulele open 610.57.04 compilate de
test pe 7.1.5 ca user: exit 0, 55 s (`dkms-test/`). Secure Boot oprit. `rollback-550/` = 48 deb-uri 550 + SHA256SUMS.

**Capcane gestionate in `install-610.sh`:** modulul se numeste `nvidia` (Debian: `nvidia-current`) -> fisierele din
/etc/modprobe.d cu nvidia-current (symlink-urile alternatives + nostru nvidia-power.conf) mutate in backup; nvidia.conf din
pachetul 610 are deja PreserveVideoMemoryAllocations/TemporaryFilePath/S0ix + blacklist nouveau si nova-core; serviciile
nvidia-suspend/resume/hibernate vin acum din pachetul nvidia-driver (aceleasi nume). policy-rc.d pe durata instalarii (fara
pornire de servicii pe modulul 550 incarcat). Fixare exacta `nvidia-driver-pinning-610.57.04` (pt update-uri: inlocuieste cu
`nvidia-driver-pinning-610`). gamemode NU merge oricum (polkit). Backup + log: `~/.config-backups/pre-nvidia610-<data>/`.
**Revenire:** `pkexec bash ~/src/nvidia-610-upgrade/rollback-550.sh` (din TTY Ctrl+Alt+F3 daca grafica nu porneste) + reboot;
NETESTAT efectiv (doar sintaxa + deb-uri verificate).

**Checklist dupa reboot:** `nvidia-smi` = 610.57.04; Hyprland porneste (tot Intel-primar implicit), Samsung 239.76 fara
patrate violet (patch-ul mgpuwait din libaquamarine13 ramane); `gpu-mgpu-floor status`; nvidia-powerd/persistenced active;
Steam + CS2 (monitor `~/src/gpu-nested-test/watch-cs2.sh`). **Apoi pasul mare:** test Hyprland NVIDIA-primar cu flag-ul
one-shot `touch ~/.config/hypr/nvidia-primary` + logout/login (reboot = revenire automata la Intel). Daca merge: Samsung
randat direct pe NVIDIA ca pe Windows; de reevaluat gamescope (backend wayland interzis doar pe Intel-primar,
[[grim-nvidia-window-crashes-hyprland]]) si `AQ_MGPU_NO_EXPLICIT=1` din hyprland.lua (610 are explicit sync).
Vezi [[gaming-windows-steam-on-kali]], [[root-via-pkexec-not-sudo]].

**INSTALAT 29 oct 20:34-20:41** (a doua rulare; prima s-a oprit corect la pasul 3 din cauza unui bug al MEU: `cmd | grep -q` cu
pipefail = SIGPIPE = fals negativ -> scos peste tot). Backup `~/.config-backups/pre-nvidia610-2026-10-29_20-34-43`. dkms
nvidia/610.57.04 pt 6.16.8/7.0.12/7.1.5; libGLX/EGL/cuda/gbm/i386 -> 610.57.04, ICD-uri ok, fara symlink-uri rupte; modprobe.d =
nvidia.conf (610) + nvidia-drm-modeset.conf (nvidia-power.conf mutat in backup/modprobe-scoase); nvidia.conf.dpkg-new identic,
inofensiv. Servicii: suspend/resume/hibernate/powerd enabled, persistenced disabled, gpu-mgpu-floor enabled. Pachetele Debian
scoase raman `rc`. **PENDING: REBOOT + checklist de mai sus.**

**30 oct — DUPA REBOOT: ecranul de login blocat (2 porniri la rand, userul a ramas pe TTY).** Cauza masurata: cu 550
nvidia-drm era gata ~1 s INAINTE de X-ul lui SDDM; cu 610 apare la ~0.7 s DUPA -> X il adauga din mers ca GPU
secundar (modesetting+glamor) -> `modeset(G0): Failed to create pixmap` -> greeter-ul se blocheaza dupa citirea
sesiunilor (nu apare „Connected to the daemon”), X crapa la oprire (SIGSEGV FreeClientResources). Greeter-ul merge
pe Xvfb (tema/Qt ok). Fix = `~/src/nvidia-610-upgrade/fix-sddm-610.sh` (sudo din TTY3, pkexec n-are agent fara
sesiune grafica): /etc/X11/sddm-xorg.conf (AutoAddGPU false) + /etc/sddm.conf.d/x11-intel-only.conf
(ServerArguments ... -config); greeter-ul era oricum doar pe eDP-1. **nvidia-smi LIPSEA**: pachetul `nvidia-smi` din
repo-ul NVIDIA e gol, binarul e in `nvidia-driver-cuda` (+10 lib-uri) -> gpu-mgpu-floor esua la boot. Scriptul il
instaleaza.

**30 oct 21:54 — fix-sddm-610.sh RULAT din TTY, MERGE:** backup `~/.config-backups/sddm-nvidia610-fix-2026-10-30_21-54-22`
(+ revino.sh). X-ul nou al greeter-ului: „Using config file /etc/X11/sddm-xorg.conf”, AutoAddGPU false, doar modeset(0)
pe card0 Intel, 0 linii G0, fara coredump la oprire (coredump-ul de la 21:54:53 = X-ul VECHI blocat, PID 1197). Login
Hyprland din SDDM la 21:55:03 ok. nvidia-smi = 610.57.04 (nvidia-driver-cuda + 10 lib-uri instalate, nvidia-smi gol scos),
gpu-mgpu-floor activ (Intel 1450, NVIDIA P5 900 MHz), nvidia-powerd activ, Samsung HDMI-A-2 239.76 + eDP-1 144, fara Xid.
Log Hyprland: aquamarine vede „Explicit sync supported” si pe nvidia-drm (card1). Testul a fost prin restart sddm (nu boot),
dar AutoAddGPU false opreste si sondarea initiala, nu doar hotplug-ul -> ar trebui sa tina si la boot.
PENDING: reboot de confirmare, patrate violet pe Samsung (ochiul userului), CS2, apoi testul NVIDIA-primar.

**31 oct — reboot de confirmare (boot complet, nu restart sddm): OK.** Login SDDM la boot merge, nvidia-smi 610.57.04,
gpu-mgpu-floor + nvidia-powerd active, 0 Xid NVIDIA (singura linie „XID” din jurnal = cipul placii de retea r8169, inofensiv).
Ramase: patrate violet (ochiul userului), testul NVIDIA-primar. Caldura GPU in CS2 pe 610: 83°C medie (vs 60°C pe 550), vezi
[[gaming-windows-steam-on-kali]].
**1 nov — cauza 83°C in CS2 gasita (agent, date din ~/.cache/mangohud-cs2 sensors CSV):** primele 3 min pe 610 = 59°C ca pe 550;
pe toata rularea de 56 min: 83/89°C, 74.5 W medie, varf 127 W, 1793 MHz la 67% incarcare (fps_max 144). nvidia-powerd (NOU cu 610,
Dynamic Boost) ridica limita 80 -> 95 W; din minutul 15 GPU-ul sta la tinta termica 87°C (SW thermal slowdown 90-100%). Aplicat:
plafon 1500 MHz ([[gpu-mgpu-floor-service]]); nvidia-powerd lasat pornit (de oprit doar daca plafonul nu ajunge:
`pkexec systemctl disable --now nvidia-powerd`). Confirmare: CS2 20+ min cu watch-cs2.sh, comparat de la minutul 15.
Repo NVIDIA are 615.71.10 — nu acum (castig mic pt POE DX11/CS2 nativ, risc DKMS/SDDM).
**1 nov:** NVIDIA-primar functioneaza pe 610 (supportsTimelines true pe card1) — vezi [[nvidia-primary-test]].
