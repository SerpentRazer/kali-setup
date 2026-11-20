---
name: window-capture-grim-t-lstl
description: Capturezi O fereastra (cu alfa, chiar pe workspace ascuns) cu `grim -T <id>`; id-ul il da ~/src/lstl; reteta Dolphin de test izolat + capcana pkill -f
metadata:
  type: reference
---

`grim` 1.5 are `-T <identifier>` (ext-image-copy-capture, Hyprland il suporta) = captura unei singure ferestre, cu canal alfa,
fara restul ecranului (respecta [[screenshots-crop-private]]) si **merge si pe un workspace ascuns**. Identificatorul
ext_foreign_toplevel il listeaza `~/src/lstl/lstl` (client C scris 2026-10-17, `build.sh` alaturi): `id<TAB>app_id<TAB>title`.
Aspect final = compui PNG-ul RGBA peste wallpaper incetosat (PIL GaussianBlur ~10; Hyprland blur size 5 passes 1).

**Reteta aplicatie de test fara sa misti ferestrele userului:** folder cu nume unic (titlul ferestrei) +
`hyprctl eval 'hl.window_rule({ name="t43-x", match={ title="^numeunic.*" }, workspace="19 silent", float=true, size="1100 700" })'`
(dispare la urmatorul reload) + `dbus-run-session -- dolphin --new-window <folder>` (instanta noua, nu refoloseste Dolphin-ul
userului; `--select <fisier>` arata si selectia). **CAPCANA:** `pkill -f '<text din comanda>'` omoara si shell-ul Bash care
contine acelasi text (exit 144); si `[d]olphin` potriveste daca restul liniei apare literal. Omoara dupa PID:
`for p in $(pgrep -x dolphin); do grep -q numeunic /proc/$p/cmdline && kill $p; done`.
Vezi [[nested-test-recipe-virtual-pointer]], [[qt-dolphin-43pr-kvantum]].
**Capcana (17 oct):** o fereastra pe ws ascuns deseneaza starea noua abia DUPA ce o captura ii cere un cadru -> fiecare captura arata
starea precedenta. Captureaza de 2 ori (prima in /dev/null). Unelte pt bara quickshell: `~/src/qs-bartest` (README acolo).
**Cursorul nu apare in capturi** (plan hardware): pune temporar `cursor:no_hardware_cursors = 1`, vezi [[cursor-breeze-18]].
**INTERZIS pe ferestre randate pe NVIDIA** (gamescope, vkcube, jocuri cu PRIME offload): `grim -T` a omorat Hyprland pe 28 oct,
vezi [[grim-nvidia-window-crashes-hyprland]].
