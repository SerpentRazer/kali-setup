---
name: repaste-mx4-thermal-results
description: "1 nov 2026 userul a curatat laptopul + pasta Arctic MX-4 — inainte/dupa la stres si in CS2, cum re-masori (pasta poate pompa in luni)"
metadata:
  node_type: memory
  type: project
  originSessionId: 8c0dbf1e-e741-44e5-934b-6f304d352913
  modified: 2026-11-01T10:01:57.273Z
---

**Cauza dovedita inainte (1 nov 09:37):** pachetul sarea 58->96°C in prima secunda la ~54 W; cu ventilatoarele deja la maxim
(~6800 RPM, curba EC atinge plafonul) racirea ducea doar ~48 W la 97°C (TCC offset 3 = franare la 97). Ventilatoarele NU erau
parghia (fan_fullspeed WMI fara efect, test A/B identic) -> pasta uscata.

**Dupa MX-4 (1 nov 11:08, `~/.cache/legion-dupa-pasta-2026-11-01_11-08-26`), 16 fire 90 s, balanced, la priza:**
- primele ~56 s (PL2): 67 W la 86°C, 4.1 GHz, 0 franari (inainte 48-54 W, 96-98°C, 3.4 GHz, ~200 franari/s)
- dupa tau 56 s (PL1 45 W): 67-69°C, 3.5 GHz, ventilatoarele coboara spre 5000 RPM
- la aceeasi putere (~46 W): 96°C -> ~68°C (-28°C); racire dupa sarcina 16 s pana la 53°C (inainte 150 s si tot 60°C)
- acum limita = RAPL 45/65 W, nu temperatura. Rezumatul „ultimele 45 s” al scriptului amesteca PL2+PL1 -> citeste CSV-ul pe bucati.

**In CS2 (1 nov 11:13-11:19):** CPU 68°C med / 76 max, 4.2 GHz constant, package_throttle_count 0 de la boot
(30 oct: 95.6°C med, 100 max, 3.2 GHz, franari in fiecare secunda). GPU nemasurat inca (MangoHud fara NVML) -> [[cs2-session-logger]].

**Re-masurare:** `pkexec /bin/bash ~/src/legion/dupa-pasta-test.sh` (incarca singur legion_laptop read-only, compara cu referinta
09:37). MX-4 poate „pompa” pe laptop in cateva luni: re-test peste ~2-3 luni; daca la ~45 W urca iar spre 80-90°C -> PTM7950.
Plafonul GPU 1500 MHz si fps_max 144 au fost puse DIN CAUZA caldurii -> de reevaluat dupa retest. Vezi [[gaming-optimization-plan-2026-11-01]].
