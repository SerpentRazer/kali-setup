---
name: kitty-smooth-wheel-patch
description: "Scroll animat (inertial) la rotita mouse-ului in kitty 0.48.2 — patch propriu INSTALAT in sistem (mouse.c->.so + window.py); model exponential, reglabil cu KITTY_SMOOTH_WHEEL_MS"
metadata:
  node_type: memory
  type: project
  originSessionId: a0c338ac-edf4-4193-9f6c-659f180459ad
  modified: 2026-10-02T07:40:24.957Z
---

2026-10-02: userul (Razer Basilisk V3) voia scroll „smooth” cu mouse-ul in kitty. Fapte masurate:
- Descriptorul HID al Basilisk V3 (hid-generic, 1532:0099) NU are Resolution Multiplier -> rotita trimite doar clicuri
  intregi (value120 = 120/clic). kitty 0.48.2 avea `pixel_scroll`/`momentum_scroll` DOAR pt touchpad; la rotita sarea
  instant `wheel_scroll_multiplier` (5) randuri, fara animatie. Un watcher Python nu ajunge: scroll_event e in C si aplica
  saltul inainte de orice hook.

**Patch** (`~/src/kitty-smoothwheel/`, sursa `apt-get source kitty`, originale in `orig/`): `mouse.c` trimite clicurile
V120 (fara mouse tracking, main screen, fara selectie) la `Window.smooth_wheel_scroll(lines, current)`; `window.py`
glisaeaza cu **amortizare exponentiala critic-damped** (`current += (target-current)*(1-exp(-dt/tau))`, tick 1/240 s) —
viteza continua, deci clicurile rapide se leaga intr-o singura glisare fluida (userul a cerut explicit „mai fluid”, dupa
ce varianta initiala cu durata fixa i s-a parut nefluida/invizibila la 150ms). `KITTY_SMOOTH_WHEEL_MS` = timp de asezare
~95% in ms (tau=ms/3000), **default 100** (rapid, cerut „cel mai rapid”); 0 = salt stock. Unit test cu ceas fals:
`test_wheel.py`, 13/13 OK (monoton, fara overshoot, clamp sus/jos, scroll extern castiga, finish sare la target).

**INSTALAT in sistem 2026-10-02** (NU prin .deb — ar fi tras ~20 pachete golang-* doar sa recompileze `kitten` neschimbat):
inlocuire directa a 2 fisiere in `/usr/lib/kitty/kitty/` via `pkexec ~/src/kitty-smoothwheel/install.sh`:
`fast_data_types.so` (rebuild din mouse.c, strip ca originalul; ABI OK — build pe Python **3.14**, la fel ca sistemul) +
`window.py` (difera de stock DOAR prin cele 87 linii adaugate + shebang python3 pus de dh_python3). Build in-tree:
`python3 setup.py build --skip-building-kitten`, kitten = symlink la /usr/bin/kitten. Build-deps instalate cu pkexec:
librsync-dev, libsimde-dev (golang-go instalat dar NEfolosit pt install — ramane, inofensiv). **Regenerat `.opt-2.pyc`**
pt window.py nou (kitty ruleaza -OO; altfel revine lag-ul din [[kitty-slow-start-opt2-pyc]]) — verificat pyc newer than py.
Verificat pe `/usr/bin/kitty` real: porneste curat, remote control merge, 0 erori.

**Folosire:** deschide un kitty NOU (ferestrele deja pornite tin codul vechi pana le redeschizi; single_instance e off, deci
SUPER+T porneste proces nou -> ia patch-ul). Reglare permanenta: `env KITTY_SMOOTH_WHEEL_MS=100` in `~/.config/kitty/kitty.conf`.
**Revenire:** `pkexec sh ~/.config-backups/kitty-smoothwheel-2026-10-02/revert.sh` (backup `.orig` acolo).
**Un upgrade Kali al kitty suprascrie fisierele -> revine la salt (nu se strica); reaplica `install.sh`.** `README.txt` in ~/src/kitty-smoothwheel.
Vezi [[kitty-slow-start-opt2-pyc]], [[verify-before-instructing]].
