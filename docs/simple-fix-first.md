---
name: simple-fix-first
description: "Intai solutia banala (setarea din meniul jocului/aplicatiei), abia apoi investigatie adanca — userul s-a enervat cand am facut reverse-engineering pt o setare de controller din POE2"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 58a3d256-89f2-401b-9c3a-8a4d27379603
  modified: 2026-11-08T11:14:25.935Z
---

Cand ceva „arata ciudat” intr-un joc/aplicatie (UI de controller, overlay, rezolutie etc.), spune INTAI setarea din meniul lui
(ex. POE2: Options > Input -> tastatura/mouse / WASD) si abia daca nu merge sapi in loguri, config-uri, Proton, binar.

**Why:** 8 nov 2026, POE2 pornea cu UI de controller; am citit loguri, am dezasamblat exe-ul, am testat Proton/HideWineExports si am
pornit jocul de 2 ori singur — userul a schimbat pur si simplu controlul din controller in WASD in joc: „de ce nu te-ai gandit ca pur
si simplu e o setare asa de banala -_-”.

**How to apply:** primul raspuns = 1-2 randuri cu setarea din joc + „daca revine dupa repornire, sap mai adanc”. Investigatia lunga
doar daca setarea nu tine sau userul cere cauza. Legat: [[poe2-steamdeck-detection]], [[verify-before-instructing]].
