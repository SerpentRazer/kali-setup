---
name: no-diacritics-tty
description: Scrie romana FARA diacritice — pe TTY fontul consolei (Lat15) nu are a-breve/s/t cu virgula si userul a crezut ca e spaniola
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9985b59a-11b4-465e-a849-cf5e64db8ba4
  modified: 2026-10-30T19:47:23.165Z
---

Scrie in romana fara diacritice (a, i, s, t simple in loc de ă, î, ș, ț, â).

**Why:** 30 oct 2026, dupa ce SDDM nu mai pornea, userul lucra cu Claude Code din TTY (consola text).
`/etc/default/console-setup` are CODESET="Lat15", care nu contine ă/ș/ț, deci textul cu diacritice s-a afisat
cu simboluri stricate si userul a intrebat „de ce ai scris in spaniola mai sus??”. Toate notitele vechi sunt deja
fara diacritice.

**How to apply:** mereu, nu doar pe TTY (nu stii dinainte de unde ruleaza sesiunea). Vezi
[[talks-romanian-windows-analogies]].
