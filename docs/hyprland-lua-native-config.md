---
name: hyprland-lua-native-config
description: Hyprland 0.56 citeste nativ hyprland.lua; GUI-urile de display (nwg) scriu monitors.conf INERT; editeaza monitors.lua; Samsung pe 239.76 cu masuratori fps reale pe calea multi-GPU
metadata:
  node_type: memory
  type: reference
  originSessionId: 17dd387c-74ae-4463-bff5-e819ad4954c1
  modified: 2026-10-18T18:28:31.492Z
---

Acest Hyprland (0.56.2) **citeste nativ `~/.config/hypr/hyprland.lua`** (log: „Using lua config found at .../hyprland.lua"). `hl` e API-ul Lua built-in al Hyprland — NU un plugin, NU un transpiler. `hyprland.lua` face `require("monitors"/"keybinds"/"look"/"rules")` → acele `*.lua` sunt sursa reala.

**Consecinta importanta:** uneltele GUI de display (nwg-displays etc.) scriu `~/.config/hypr/monitors.conf` cu sintaxa `monitor=...`, dar **NIMENI nu-l sursuieste** → modificarile din GUI n-au efect. La fel, `hyprctl reload` re-citeste lua. Deci **orice schimbare de monitor/workspace se face in `monitors.lua`**, apoi `hyprctl reload` (fara restart de sesiune, nu fura tastatura).

**Layout monitoare (2026-10-01, Samsung = principal):**
- `HDMI-A-2` (Samsung LC27RG50, 240Hz) = **PRINCIPAL**, la **origine `0x0`**, tine workspace-urile **1-10** (persistente 1-3) + `name:gaming`.
- `eDP-1` (laptop, 144Hz) = secundar, la `-1920x0` (fizic in stanga; coordonata negativa ca sa nu se inverseze mouse-ul), tine ws **11-20** (persistente 11-12).
- **Din 2026-10-16 workspace-urile sunt PER MONITOR** (cerut de user: „sa se schimbe ferestrele de pe display-ul respectiv, nu alandala"):
  SUPER+1..0 / SUPER+SHIFT+1..0 lucreaza pe monitorul de SUB MOUSE (`wsOnCursorMonitor` in keybinds.lua: MONITOR1 -> n,
  MONITOR2 -> 10+n, alt ecran -> 20+n); ALT+Tab = functie Lua care trece prin ferestrele workspace-ului afisat pe monitorul de
  sub mouse (`hl.get_monitor_at_cursor().active_workspace` + `hl.get_workspace_windows`) — `cycle_next()` pleca de la fereastra
  cu focus, care putea fi pe alt monitor/workspace ascuns. Bara: scroll doar pe workspace-urile monitorului ei, tooltip 11-20 -> 1-10.
  Animatia workspace = `slidefade` (laterala; upstream pusese `slidefadevert`). API Lua util: hl.get_monitor_at_cursor, get_windows,
  get_workspace_windows, get_active_window (obiecte userdata: m.name, m.active_workspace, w.address, w.monitor, w.workspace).
- **Capcana `default = true` (rezolvata 2026-10-18):** Hyprland porneste monitorul pe PRIMA regula `default` care il potriveste.
  `name:gaming` (id -1337) avea `default = true` si statea inaintea buclei 1-10 → Samsung-ul pornea pe „gaming”; toate ferestrele
  de dupa login (kitty, brave) aterizau acolo, bara il ascunde (`w.id > 0`) si n-are tasta → la primul SUPER+1 terminalul „disparea”.
  Fix: scos `default` de pe gaming (backup `monitors.lua.bak-gaming-default-2026-10-18`); intra in vigoare la urmatorul login.
  **NEVERIFICAT inca la un login real:** dupa login `hyprctl monitors` trebuie sa arate `activeWorkspace` 1 pe HDMI-A-2.
  Dovada: logul qs `/run/user/1000/quickshell/by-id/*/log.qslog` (`strings | grep openwindow`) arata pe ce ws a aparut fiecare fereastra.
  Recuperare fereastra: `hyprctl dispatch 'hl.dsp.window.move({ workspace = 1, window = "address:0x...", follow = false })'` (testat).
- In `monitors.lua`: `MONITOR1="HDMI-A-2"`, `MONITOR2="eDP-1"`, `PRIMARY_MONITOR="HDMI-A-2"` (globale Lua; le foloseste si keybinds.lua).

**Refresh Samsung = `1920x1080@239.76` din 2026-10-17 (MASURAT; intre 1 si 17 oct a stat pe 120).** Laptop hibrid — Intel UHD (card0) randeaza, NVIDIA RTX 3060 (card1) conduce fizic Samsung-ul, `AQ_DRM_DEVICES=card0:card1` (Intel-primar) → fiecare cadru Samsung = randare Intel + blit pe NVIDIA + `poll` pe fence-ul blit-ului (patch-ul mgpuwait, SINCRON pe main thread). „240" rotund nu exista in availableModes, doar 239.76.
Masurat cu `~/src/hzprobe` (layer-surface transparent, fara input, + wp_presentation = cand ajunge cadrul pe ecran; vezi BUILD.txt acolo): la redesenare continua Samsung-ul primeste doar **42-47 fps la 120Hz** si **48-68 fps la 239.76** (latenta commit→ecran ~30 ms vs 17-22 ms); eDP-1 (Intel nativ) face 130 din 144. Un cadru costa ~17-20 ms ORICARE ar fi Hz-ul, iar 240 il aliniaza pe o grila mai fina → **240 > 120 la toate metricile**. Testul din 3 oct (glxgears/XWayland „111 fps la 240") era imprecis: glxgears nu numara cadrele prezentate.
**CAUZA = ping-pong intre GPU-uri:** fiecare asteapta dupa celalalt, deci guvernoarele nu urca frecventa — Intel sta la 350 MHz (din 1450), NVIDIA la 210 MHz/P8/PCIe gen1. Test A/B ca root cu auto-revert (`~/src/hzprobe/clocks-test.sh`), full/small fps: neschimbat 48/68; Intel `gt_min_freq_mhz=1450` → 80/112; NVIDIA `nvidia-smi -lgc 1200,2100` singur → 49/78; **ambele → 99/184** (+~4W NVIDIA, +1-4W pachet CPU). Blur oprit (ceasuri normale): 48→63. `render:new_render_scheduling=true` e MAI PROST (44/31) — nu-l activa. Client randat pe NVIDIA (ca un joc, PRIME offload) afisat pe Samsung: **43 fps** → jocurile pe Samsung sunt plafonate de aceeasi cale, oricat randeaza jocul.
**Why:** userul a cerut „vezi daca 240 functioneaza optim"; Hz-ul nu era problema, calea multi-GPU e. **How to apply:** podeaua de frecventa GPU e parghia ieftina — INSTALATA 17 oct (userul a ales „ambele GPU"), detalii si rezultate in [[gpu-mgpu-floor-service]]. Nu propune NVIDIA-primar orbeste — flag-ul one-shot `~/.config/hypr/nvidia-primary` (citit+sters la login in hyprland.lua) **crapa in `recreateBlitSync` pe driverul 550.163.01**; 240 real (fara blit) = driver NVIDIA >=555 (explicit sync) sau NVIDIA-primar reparat.

**Analogie Windows:** nu exista buton „Make this my main display" — e impartit in reguli (ce ecran e la 0,0, ce workspace aterizeaza unde, unde e bara/taskbar-ul). Pt refresh e ca un monitor de 240Hz bagat in iesirea placii de baza (Intel) in loc de direct in RTX — Optimus cara cadrele si nu prinzi fluiditatea plina. Vezi [[hyprland-43pr-on-kali]], [[verify-before-instructing]].
