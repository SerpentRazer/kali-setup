---
name: cs2-panorama-fonts-fix
description: CS2 pe Linux cauta litere prin toate cele ~3800 de fonturi de sistem (filtrul <fontpattern> e doar Windows) -> sacadari la text nou; fix aplicat automat de cs2-perf
metadata:
  node_type: memory
  type: project
  originSessionId: 8c0dbf1e-e741-44e5-934b-6f304d352913
  modified: 2026-11-01T10:02:07.074Z
---

**Problema (gasita 1 nov 2026):** `game/csgo/panorama/fonts/fonts.conf` include `/usr/share/fonts`, `~/.fonts`,
`/usr/local/share/fonts`, xdg fonts si incearca sa filtreze cu `<fontpattern>` (extensie Valve, merge doar pe Windows).
Fontconfig-ul din runtime o respinge (jurnal 11:13:29: `unknown element "fontpattern"`) -> Panorama cauta litere prin ~3787
fonturi (2380 Noto). Fallback-ul cadea pe FreeSerif (cu serife). Dovezi: 5 din ~21 cadre >40 ms vin la 4-150 ms dupa o rafala
`Pango-CRITICAL pango_layout_line_get_x_ranges` (care vine din CS2 insusi, libpanorama_text_pango), plus un
`FcPattern ... "Regular"` la 11:15:02.196 urmat de o sacadare de 55 ms la .30. Grupul mare 11:15:55-59 (451 ms) NU e de la
fonturi -> presiune de memorie ([[fix-erori-2026-11-01]], swappiness).

**Fix:** `~/src/legion/cs2-fonts-fix.sh apply|revert|status` comenteaza cele 4 dir-uri de sistem (marker `KALI-FONTS-FIX`);
raman cele 25 de fonturi ale jocului (Noto Sans latin/chirilic/grec, JP/KR/SC/TC, Thai, simboluri, serif, mono; Stratum2 e
.uifont, nu trece prin fontconfig) = ce vede si pe Windows; fallback Noto Sans. Original: `~/.config-backups/cs2-fonts-original.conf`.
Steam reface fisierul la update/verify -> `~/.local/bin/cs2-perf` il re-aplica la fiecare pornire (idempotent).
Risc acceptat: nume de jucatori in araba/ebraica/devanagari/emoji = patratele.

**Capcana la testare:** fontconfig-ul de SISTEM nu poate incarca direct fonts.conf-ul jocului (include relativ
`../../../core/panorama/fonts/conf.d` rezolvat altfel -> „Cannot load config file” -> fallback pe tot sistemul). Testeaza cu o
copie in care include-ul si `<dir prefix="default">` sunt cai absolute: original 3787 fonturi, cu fix 25.
Vezi [[cs2-session-logger]], [[gaming-optimization-plan-2026-11-01]].
