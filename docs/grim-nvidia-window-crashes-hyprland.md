---
name: grim-nvidia-window-crashes-hyprland
description: "gamescope --backend wayland pe NVIDIA omoara Hyprland-ul (Intel-primar) chiar FARA captura (SIGABRT Mesa, erori kernel sg_table); --backend sdl e sigur; captura pe CS2 a mers"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 1fb2b3e8-68e1-40e1-90db-8a6d6a2ed11d
  modified: 2026-10-28T18:53:59.794Z
---

**28 oct 20:22:** crash Hyprland 0.56.2 (SIGABRT in libgallium 26.1.6, `CScreenshareFrame::copyShm -> readPixels`) cand sesiunea
de tuning CS2 a facut `grim -T` pe un `gamescope ... -- vkcube` cu PRIME offload. Inainte: kernel `nvidia-drm ... Cannot create
sg_table for NvKmsKapiMemory` (Intel nu poate citi un buffer din VRAM-ul NVIDIA).

**Cauza reala (testat izolat 28 oct, [[nested-test-recipe-virtual-pointer]], scripturi `~/src/gpu-nested-test`):** backend-ul
**wayland** al gamescope (xdg_backend, implicit in mod nested) trimite compozitorului buffere din VRAM NVIDIA. Hyprland randeaza pe
Intel ([[hyprland-lua-native-config]], AQ_DRM_DEVICES Intel primul) -> import esuat -> Mesa abort in ~15 s, **si fara captura**
(alta data in `CEGLSync::create`). Reprodus de 2 ori. Nici omorarea imediata a gamescope (paznic pe journalctl) NU salveaza
compozitorul: bufferul stricat e deja importat -> paznicul a fost sters.
**Sigur:** `gamescope --backend sdl` (SDL prin Wayland sau `SDL_VIDEODRIVER=x11`): 0 erori sg_table, capturi OK, minute intregi.
Captura `grim -T` pe CS2 nativ (NVIDIA prin Xwayland) la 20:09 a mers fara erori.

**Why:** un crash de compozitor = sesiune pierduta + toate sesiunile Claude paralele ([[parallel-claude-sessions]]).
**How to apply:** orice gamescope/app NVIDIA noua -> intai in testul izolat, cu detectorul `journalctl -k | grep -c sg_table`;
daca apar erori sg_table pe sesiunea reala, nu captura nimic si inchide sursa. Context: [[gaming-windows-steam-on-kali]],
[[window-capture-grim-t-lstl]].

**Si jocul insusi (28 oct 22:38):** sub gamescope cu stratul implicit Gamescope WSI, CS2 a crapat in driverul NVIDIA 550 (fir intern al driverului, dump analizat); Hyprland a supravietuit. Fix: `DISABLE_GAMESCOPE_WSI=1` in env-ul copilului (dupa `--`; castiga fata de ENABLE_GAMESCOPE_WSI=1 pus de gamescope, verificat in /proc/<pid>/maps). Analiza core dump din containerul Steam: sysroot cu symlink-uri, overrides pressure-vessel -> /usr/lib/x86_64-linux-gnu al host-ului.
