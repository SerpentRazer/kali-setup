---
name: parallel-agents-ok-for-speed
description: userul accepta agenti paraleli (fork) cand grabesc o lista de task-uri independente; cum i-am folosit pe 1 nov
metadata:
  type: feedback
---

1 nov: „rezolva pe toate cu agenti daca e nevoie pt. rapiditate”, apoi „documenteaza-te” => am pornit fork-uri in fundal: 2 de
analiza (caldura GPU din CSV-uri, test ntsync headless) + 3 de cercetare pe domenii separate (CPU/termic, GPU/afisare,
setari pe joc). Rezultatele au fost bune si userul n-a obiectat.

**Why:** userul vrea viteza; fork-urile mostenesc contextul boxei (memoria e mare), deci nu trebuie re-explicat nimic.

**How to apply:** cand sunt mai multe bucati independente si userul cere viteza, imparte pe domenii fara suprapunere, interzice
explicit schimbarile de sistem / pkexec / ferestre pe ecran in brief, iar afirmatiile mari dintr-un raport (ex. „POE nu e
instalat”) verifica-le singur inainte sa le spui userului. Vezi [[gaming-optimization-plan-2026-11-01]].

**1 nov, a doua oara — cerut explicit („si foloseste si agenti”)** in mijlocul unui task mare: 3 fork-uri (afisare/fullscreen,
inventar erori, sacadari/fps), ~11-13 min fiecare, rezultate mari (C: read-only gasit de doua fork-uri independent, cauza
fonturilor, tick-ul de 64). Verificarea mea a corectat un raport: legatura fonturi-sacadari era doar partiala (5/21 cadre), nu
totala. Un fork a rulat din greseala `touch -c /dev/null` desi brief-ul zicea zero schimbari (inofensiv) -> in brief scrie
explicit „nici touch/mkdir in afara scratchpad-ului”. Cat lucreaza fork-urile, fa partea ta care nu se suprapune (eu: fullscreen + logger).
