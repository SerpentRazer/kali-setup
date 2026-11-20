---
name: hybrid-mode-off-dgpu-only
description: "11 nov 2026: userul a OPRIT Hybrid Mode in Lenovo Vantage (MUX = doar NVIDIA, Intel dispare din PCI) -> Kali flicker + mouse mort; cauza AQ_DRM_DEVICES=card0:card0 (monitoare dublate); fix in hyprland.lua/monitors.lua, merge in ambele moduri"
metadata:
  node_type: memory
  type: project
  originSessionId: 58a3d256-89f2-401b-9c3a-8a4d27379603
  modified: 2026-11-11T18:08:29.563Z
---

**Simptom (11 nov, boot 20:04):** flicker pe ambele ecrane + mouse-ul nu mergea. `hyprctl monitors` arata FIECARE monitor de 2 ori
(HDMI-A-1 ID 0 si ID 2, eDP-1 de 2 ori), log aquamarine: 210x „atomic drm request: failed to commit: Device or resource busy”.
Samsung pe 60 Hz, ws 1 pe laptop.

**Cauza:** cu Hybrid Mode oprit exista doar `/dev/dri/card0` = NVIDIA (pci-0000:01:00.0), fara Intel pci-0000:00:02.0.
`drm_card()` din hyprland.lua cadea pe fallback-ul "card0" pt Intel => `AQ_DRM_DEVICES=/dev/dri/card0:/dev/dri/card0` => acelasi GPU
deschis de 2 ori. In plus conectorul Samsung devine **HDMI-A-1** (in Hybrid era HDMI-A-2) => regula 239.76 Hz + ws 1-10 nu se aplicau.

**Fix 20:08 (backup + revino.sh: `~/.config-backups/pre-dgpu-only-2026-11-11_20-07-45`):**
- hyprland.lua: `drm_card` cu `readlink -e` -> GPU lipsa = nil; `set_gpus(a,b)` sare peste nil si dubluri; `nvidia_has_monitor` tolereaza nil;
  xrandr --primary foloseste `MONITOR1`.
- monitors.lua: `SAMSUNG` = primul `/sys/class/drm/card*-HDMI-A-*` conectat (implicit HDMI-A-2) -> MONITOR1/PRIMARY_MONITOR + regula 239.76.
- Testat cu lua5.4 + `hl` fals: AQ_DRM_DEVICES=/dev/dri/card0, HDMI-A-1@239.76, ws 1/gaming pe HDMI-A-1, ws 11 pe eDP-1; set_gpus ok si pt hybrid.
- Se aplica doar dupa relogin (AQ_DRM_DEVICES se citeste la pornirea Hyprland): userului i s-a spus SUPER+SHIFT+E -> login.
  **VERIFICAT dupa relogin 20:10:** 2 monitoare (HDMI-A-1@240 la 0,0 + eDP-1@144), aquamarine „Found 1 GPUs”, 0 EBUSY.
  Mouse-ul Razer tot nu mergea: NU tine de Hyprland — kernelul nu-l vede deloc (lipsa din lsusb/dmesg, 0 deconectari) => cablu/port fizic.

**De stiut in modul doar-NVIDIA:** gpu-mgpu-floor (Intel+NVIDIA) porneste fara erori; NVIDIA-primar automat devine irelevant (un singur GPU);
bateria tine mai putin (iGPU oprit). Revenire la Hybrid in Vantage = config-ul merge ca inainte (by-path Intel exista din nou).

Legat: [[nvidia-primary-test]], [[hyprland-lua-native-config]], [[gpu-mgpu-floor-service]], [[gaming-optimization-plan-2026-11-01]] (MUX exista).
