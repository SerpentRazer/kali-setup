---
name: screenshots-crop-private
description: Pe sesiunea live a userului captureaza doar regiunea necesara (grim -g), nu ecranul intreg — o captura completa a prins un cod QR de login WhatsApp
metadata:
  type: feedback
---

Pe 2026-10-16 o captura `grim -o HDMI-A-2` facuta ca sa verific bara a prins si pagina de login WhatsApp Web cu codul QR
(cine il scaneaza isi poate lega telefonul la cont). Am sters-o imediat si i-am spus userului.

**Why:** ecranul userului contine date private (conturi, coduri, mesaje); pentru verificarea unei bare sau a unei
notificari nu e nevoie de tot ecranul.

**How to apply:** pe sesiunea reala foloseste `grim -g "x,y WxH"` doar pe zona testata (bara = `0,0 1920x34`, laptopul e
la x negativ `-1920,0`), iar testele vizuale complete fa-le in sesiunea izolata ([[nested-test-recipe-virtual-pointer]]).
Daca totusi prinzi ceva privat, sterge fisierul si spune-i.
