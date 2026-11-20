---
name: cs2-fullscreen-hyprland-linux
description: "Ce inseamna „exclusive fullscreen” pt CS2 pe Kali (gamescope sdl + Hyprland multi-GPU), ce e setat, ce blocheaza scanout-ul direct, cum verifici cu hyprctl"
metadata:
  node_type: memory
  type: project
  originSessionId: 8c0dbf1e-e741-44e5-934b-6f304d352913
  modified: 2026-11-01T10:02:19.222Z
---

**Cerere 1 nov 2026:** „pune jocul in fullscreen, nu windowed fullscreen, stiu sigur ca se pierde performanta”. Pe Linux userul
avea partial dreptate: modul coop („Fullscreen Windowed”) randeaza intr-o imagine intermediara + copie (string-uri din
librendersystemvulkan); exclusivul o scoate. **Aplicat:** cs2_video.txt (`~/.steam/debian-installation/userdata/461618270/730/
local/cfg/`, local = fara cloud) `setting.fullscreen` 0->1, `setting.coop_fullscreen` 1->0; revenire:
`~/.config-backups/pre-cs2-fullscreen-2026-11-01_11-26-33/revino.sh`. CS2 n-are `-fullscreen` ca optiune de lansare.

**Echivalentul real pe Wayland** = in `hyprctl -j monitors` pe HDMI-A-2: `solitary` != "0", `activelyTearing` true,
`directScanoutTo` != "0". Hyprland 0.56.2 arata si motivul: `solitaryBlockedBy` / `tearingBlockedBy` / `directScanoutBlockedBy`
(JSON: liste ca USER, SW, CANDIDATE, WINDOWED, NOT_TORN; devin **null** cand nu blocheaza nimic -> jq `// []`).
- tearing: posibil (card1 `supportsAsyncCommit: true`), cere regula `immediate` + fullscreen (rules.lua gamescope-competitive) + allow_tearing.
- direct scanout: blocat de USER (`render:direct_scanout = 0`) si SW (cursor software: `no_hardware_cursors = 2` auto pe NVIDIA
  multi-GPU). NU pune `no_hardware_cursors = 0`: cursorul transparent din joc (SDL3 ascunde cu un cursor gol 1x1) ar deveni HW si
  ar bloca tearing-ul. `direct_scanout = 2` + `content = "game"` in regula are sens DOAR daca hypr.csv arata ca SW nu blocheaza in
  joc; pe iesirea mgpu aquamarine tot copiaza pe NVIDIA si poate cadea pe copie prin CPU (`allocating intermediate buffer` — dar
  `debug:disable_logs=true`, logul Hyprland e gol dupa pornire).
- gamescope `--backend sdl`: swapchain FIFO, `--immediate-flips` NU face nimic (SupportsTearing false). Pastreaza
  `SDL_VIDEODRIVER=x11` (pe wayland = aceeasi clasa de crash ca [[grim-nvidia-window-crashes-hyprland]]).
- **Experiment cu cel mai mare castig teoretic (netestat):** CS2 FARA gamescope — Xwayland are 1440x1080 in modurile emulate si
  intinde pe ecran prin viewport (4:3 stretched nativ); risc: XWM-ul Hyprland poate ignora modul emulat (imagine in colt).
Verificare in joc: `~/.cache/joc-log-*/hypr.csv` din [[cs2-session-logger]]. Vezi [[gaming-optimization-plan-2026-11-01]].

**Retest 1 nov 13:27 (hypr.csv):** solitary 99%, gamescope fullscreen=2, tearing 0%: singurul motiv NOT_TORN. **Bug Hyprland 0.56.2
(verificat in sursa):** Window.cpp:2764 porneste tearing-ul doar daca `!isTearingBlocked()`, iar isTearingBlocked() intoarce
TC_NOT_TORN cand nextRenderTorn e fals — adica exact inainte sa-l seteze => tearing-ul nu porneste NICIODATA (onFrame il seteaza
doar daca e deja activ). hyprctl foloseste isTearingBlocked(true), de aceea arata doar NOT_TORN. **Reparat in v0.57.0** (28 oct 2026,
conditia devine `HADDAMAGE`, src/desktop/view/window/Window.cpp:1805). Kali: 0.56.2+ds-1 instalat, candidat 0.56.2+ds-3, HOLD.
Castig asteptat la 240 Hz: <= ~4 ms latenta, nu fps. Optiuni: asteapta 0.57 in Kali (+ portat mgpuwait) sau patch de o linie +
rebuild 0.56.2. **In joc scanout-ul direct e blocat DOAR de USER** (SW dispare cand jocul ascunde cursorul) => experimentul
direct_scanout=2 + content=game are acum sens (risc: copie prin CPU pe iesirea mgpu; logger-ul arata directScanoutTo + fps).

**1 nov 14:06 — APLICAT direct_scanout = 2** (look.lua) + `content = "game"` in regula gamescope-competitive (rules.lua) +
**TEMPORAR `debug:disable_logs = false`** (de scos dupa test; logul avea 5721 linii inainte de test). Backup + revino.sh:
`~/.config-backups/pre-direct-scanout-2026-11-01_14-06-07`. Userul a insistat din nou „FULLSCREEN, nu windowed fullscreen”
desi cs2_video.txt era deja fullscreen=1/coop=0 (neschimbat de joc) -> pe Linux asta inseamna Hyprland sa nu mai compuna.
De verificat dupa sesiune: hypr.csv directScanoutTo != 0, grep 'intermediate buffer|failed to commit|scanout' in log, senzatia userului.

**1 nov 14:07 — userul a rulat revino.sh pt scanout direct** (fara sa joace intre timp; direct_scanout iar 0, logurile iar oprite).
**CAUZA REALA a plangerii „nu e fullscreen”** (logger 13:32-14:02, 29 min): gamescope a fost fullscreen=2 doar 22 s, apoi
fullscreen=0, tiled 948x1039 (ecran impartit cu alta fereastra) / 1904x1039 (cu bara si gap-uri) pana la final -> scalat + compus.
`misc:on_focus_under_fullscreen` implicit 2 (exit_fullscreen): o fereastra tiled noua care cere focus (probabil notificare/dialog
Steam — clasa neidentificata, logul Hyprland era oprit) scoate jocul din fullscreen, iar regula `fullscreen = true` se aplica doar
la map. La 13:33:14 si 13:33:51 gamescope a refacut swapchain-ul (= redimensionare). **FIX 14:09:** `on_focus_under_fullscreen = 0`
in hyprland.lua (misc) — backup `~/.config-backups/pre-fullscreen-ramane-2026-11-01_14-09-12`. Cost: cat timp ceva e fullscreen
nu poti focaliza alta fereastra de pe acelasi workspace fara SUPER+F. De confirmat: hypr.csv gs_fullscreen=2 toata sesiunea.
Sesiunea lunga la plafon 1500: GPU 60.5°C med / 65 max, 54.9 W; CPU 73.9 med / 92 max, 10 franari intr-un singur varf (s=212).

**1 nov 14:10 (sesiune 34 s):** fix-ul on_focus a tinut (gamescope fullscreen=2 31/34 s); plafon 2100 merge (GPU 1978 MHz, 84 W,
58°C). Userul exasperat („ma dispera”, captura): **in gamescope meniul CS2 arata „FULLSCREEN WINDOWED” si Display = „MONITOR 1 -
GAMESCOPE”, desi cs2_video.txt are fullscreen=1/coop=0 (neschimbat)** -> jocul ignora fisierul in gamescope. Variante de
optiuni de lansare salvate in `~/src/legion/cs2-launch-options.txt`: A = gamescope (actual), B = FARA gamescope (`-w 1440 -h 1080`,
in meniu Fullscreen + Stretched; Xwayland emuleaza 1440x1080 si intinde; risc: imagine in colt). log-joc.sh urmareste si clasa cs2.
**1 nov 14:15 — CS2 trecut pe varianta B (FARA gamescope)** cu `~/src/legion/cs2-fara-gamescope.sh fara` (asteapta iesirea Steam, schimba doar LaunchOptions 730; testat dus-intors identic). Backup: `~/.config-backups/cs2-launch-2026-11-01_14-15-23/localconfig.vdf`. Revenire: `bash ~/src/legion/cs2-fara-gamescope.sh cu` + Steam > Exit. De verificat: Display = Samsung in meniu, Fullscreen exclusiv, 4:3 intins sau cu benzi.
**1 nov 14:18 — varianta B, prima pornire:** CS2 a ales MONITOR 1 = eDP-1 (laptop, 144 Hz) si a ramas Fullscreen Windowed (fereastra 1440x1080, nu fullscreen). Cauza: in Xwayland (DISPLAY=:1) eDP-1 era primul si nimic nu era primary -> `xrandr --output HDMI-A-2 --primary` (live + hl.exec_cmd la hyprland.start, bucla 30 s; backup pre-xwayland-primary-2026-11-01_14-18-11) + `fullscreen = true` in regula cs2-competitive. Userul trebuie sa aleaga O DATA in meniu Display Mode = Fullscreen + Apply.
**1 nov 14:21 — CONCLUZIE: CS2 pe Linux NU ARE fullscreen exclusiv.** Fara gamescope, Display = HDMI-A-2 240 Hz (dupa primary),
dar meniul Display Mode ofera doar Fullscreen Windowed / Windowed (captura userului: „no fullscreen option”). Fara gamescope 4:3
NU se intinde: 1440x1080 desenat in stanga, restul negru (in FW, -w/-h fixeaza fereastra; Xwayland intinde doar la schimbare de mod
exclusiv, pe care CS2 Linux n-o face). => 4:3 stretched pe Linux = DOAR gamescope -S stretch. Revenit la varianta A
(`cs2-fara-gamescope.sh cu`, asteapta Steam > Exit). Raman utile: Samsung primary in Xwayland, fullscreen=true in regula cs2.
Nu mai propune „fullscreen exclusiv” pt CS2 pe Linux; alternativa fara gamescope = doar 16:9 nativ (1920x1080).
**1 nov ~16:58:** userul a cerut CS2 pe workspace 2: mutat live (focus address -> hl.dsp.window.move({workspace=2}) -> hl.dsp.window.fullscreen({mode=0})); gamescope ws=2 fullscreen=2 1920x1080. Regula permanenta workspace 2: neintrebata inca.
**1 nov 19:00 — userul: „dupa un anumit timp unele butoane nu functioneaza sau reactioneaza cu intarziere”.** Date: termic OK
(CPU ~3.9 GHz / ~73°C constant 1h50), fara deconectari USB (BY-Tech Gaming Keyboard + Razer Basilisk V3, ambele 1000 Hz).
GASIT in hypr.csv (sesiunea 16:29): la 2056 s (17:03, cand AM MUTAT EU fereastra pe ws 2 la cererea userului) gamescope a iesit
din fullscreen (948x1039 langa alta fereastra, apoi 1904x1039) si a ramas asa 75 min; sesiunea 14:52 (63 min) a stat fullscreen tot
timpul. FIX: regula `workspace = "2"` pe cs2-competitive + gamescope-competitive (sintaxa testata: `workspace = "19 silent"` pe o
fereastra de proba). Backup `~/.config-backups/pre-cs2-ws2-2026-11-01_19-02-17`. NU muta jocul de mana cu dispatch (fullscreen se
pierde; `hl.dsp.window.fullscreen` comuta). Suspect 2 neconfirmat: input prin 2 Xwayland (gamescope --backend sdl + x11) cu
mouse 1000 Hz -> urmatorul test: gamescope --backend wayland (acum Hyprland e pe NVIDIA; crash-ul din 28 oct era pe Intel-primar;
testeaza IZOLAT intai) sau mouse la 500 Hz.
**1 nov 19:12 — userul: se blocheaza WASD + click-urile** -> suspectul 2 (input prin Xwayland-ul Hyprland + SDL al gamescope, mouse
1000 Hz) TESTAT IZOLAT: `~/src/gpu-nested-test/harness-nv.sh` (ca harness.sh dar FARA override Mesa -> Hyprland de test pe
renderD129/NVIDIA): `gamescope --backend wayland` + vkcube (si vkcube --wsi xcb fara WSI, ca CS2) 25-30 s, randat intins 4:3,
0 erori kernel, ambele Hyprland vii; doar „Compositor released us but we were not acquired” (cosmetic) + abort la iesire (stiut).
APLICAT: LaunchOptions `--backend wayland` (Steam oprit) prin `~/src/legion/cs2-gamescope-backend.sh wayland|sdl` (asteapta Steam
inchis, backup `~/.config-backups/cs2-backend-*`). Risc ramas: Hyprland real e multi-GPU (eDP pe Intel prin copie CPU) — daca
pica sesiunea la pornirea CS2: relogin + `bash ~/src/legion/cs2-gamescope-backend.sh sdl`. DE VERIFICAT dupa sesiune: userul
mai simte WASD/click intarziate? (logger-ul e oprit; intreaba-l).
