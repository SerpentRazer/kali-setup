---
name: wants-local-html-copy
description: "Cand fac o pagina/tool HTML ca artifact, userul vrea si fisierul .html local standalone, nu doar link-ul claude.ai"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 68f5c2bf-1d5e-4c35-a1b2-e813d05188bf
  modified: 2026-10-03T13:31:29.325Z
---

Pe 2026-10-03, imediat dupa ce am publicat o pagina ca artifact, userul a intrebat „fisier html?” — voia fisierul in sine, pe disc.

**Why:** vrea deliverable-ul la el (il deschide local/offline, il pastreaza), nu doar un link claude.ai.

**How to apply:** la orice pagina/tool HTML, ofera din prima copia locala sau salveaz-o direct in `~/Documents/` si spune calea + `! xdg-open <cale>`. Atentie la conversie (verificat atunci):
- sursa de artifact NU are doctype/head/body (le adauga skeleton-ul la publish) → copia locala are nevoie de wrapper cu `<!doctype html>`, `<html lang="ro">`, `<meta charset="utf-8">` (diacriticele sigur corecte) si viewport;
- skeleton-ul artifactului aduce si `[hidden]{display:none!important}`; fara ea in CSS-ul paginii, un element cu `display:grid` ramane vizibil desi are `hidden`.
- verificare fara a fura focusul in Hyprland: `chromium --headless=new --no-sandbox --disable-gpu --virtual-time-budget=5000 --dump-dom file://...` (+ `--screenshot=... --window-size=1000,4600` pt o captura; iese in tema intunecata). Vezi [[verify-before-instructing]].
