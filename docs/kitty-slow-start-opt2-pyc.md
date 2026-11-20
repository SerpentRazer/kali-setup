---
name: kitty-slow-start-opt2-pyc
description: kitty pornea in ~1.7s pe Kali — Python intern cu -OO cauta *.opt-2.pyc pe care Debian nu le genereaza; fix cu hook apt
metadata:
  type: project
---

2026-10-01: userul a raportat lag la deschiderea terminalului (kitty 0.48.2-1.1 din repo Kali, Python 3.14).
Masurat cu evenimentul `openwindow` pe socket2 Hyprland: **~1.7 s** de la lansare la fereastra mapata.
NU era zsh (~80 ms), nici kitty.conf, nici EGL/NVIDIA (kitty randeaza pe Intel renderD128), nici portalul.

Cauza (gasita cu `gdb -p` in timpul pornirii -> `Py_CompileStringObject` din import): kitty ruleaza Python-ul
intern cu `optimize=2`, deci cauta `__pycache__/*.cpython-314.opt-2.pyc`. postinst-ul Debian (`py3compile`)
face doar `.pyc` simple, iar /usr/lib/kitty si /usr/lib/python3.14 sunt ale lui root -> ~130 module
(kitty + stdlib, cam jumatate-jumatate) recompilate la FIECARE pornire. Simulat fixul: **~335 ms**.

Fix pregatit in `~/.config-backups/kitty-opt2-pyc/`: `kitty-opt2-pyc` (-> /usr/local/sbin, compileall -o 2
pe /usr/lib/kitty + stdlib-ul versiunii din `ldd /usr/bin/kitty`) + hook `99kitty-opt2-pyc` (-> /etc/apt/apt.conf.d,
DPkg::Post-Invoke). Instalare: `pkexec /bin/bash ~/.config-backups/kitty-opt2-pyc/install.sh`; anulare: `revino-la-original.sh`.
Prerm-urile Debian sterg `__pycache__/<modul>.*.py[co]`, deci si fisierele opt-2 — nu raman orfane.
Clasificatorul de permisiuni a BLOCAT instalarea hook-ului de catre Claude ("Unauthorized Persistence");
userul l-a instalat el cu `! pkexec ...` (2026-10-01 17:12, 826 fisiere opt-2).
**STARE: INSTALAT si VERIFICAT pe kitty-ul real: ~280 ms (de la ~1715 ms), hook vizibil in `apt-config dump`.**

**Why:** fara hook, orice upgrade de kitty/python3.14 readuce lag-ul tacut.

**How to apply:** daca kitty e iar lent, verifica intai `find /usr/lib/kitty -name '*.opt-2.pyc' | wc -l`
(0 = hook-ul lipseste sau n-a rulat). Capcana la testare cu PYTHONPYCACHEPREFIX: kitty importa din
`/usr/bin/../lib/kitty`, deci in prefix trebuie sa existe `<prefix>/usr/bin`, altfel pare ca fixul nu merge (1080 ms).
