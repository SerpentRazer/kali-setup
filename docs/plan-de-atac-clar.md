---
name: plan-de-atac-clar
description: Cand munca are multe bucati si pasi facuti de user (Windows, reboot), userul vrea intai un plan de atac clar pe faze, apoi executie imediata
metadata:
  type: feedback
---

1 nov 2026, dupa un raport lung (agenti + reparatii + o problema noua cu C:): „deci, fa un plan de atac clar, si trecem la treaba”.
Am dat un tabel Faza | Cine | Ce | Timp (F0 Kali acum, F1 Windows de catre user, F2 eu dupa revenire, F3 retest, F4 decizii) si am
inceput F0 imediat; userul a mers mai departe pe el (a rulat scriptul F0, apoi „update memory”).

**Why:** cand se aduna multe constatari, userul pierde firul; vrea sa stie ordinea, ce face el si ce fac eu, si sa se treaca la fapte.

**How to apply:** la sarcini cu mai mult de ~3 pasi sau cu pasi pe care ii face userul (Windows, BIOS, reboot, hardware), incheie cu un
plan scurt pe faze (cine/ce/cat dureaza), da comenzile exacte pt pasii lui, si porneste imediat prima faza care e a ta. Pasii din
Windows scrie-i cu numele meniurilor in engleza + romana (Disk Management / Gestionare disc). Vezi [[games-ext4-migration-plan]].

**1 nov — „fix now” fara sa aleaga o varianta NU inseamna „alege tu pe cea mai agresiva”:** am stins ecranul laptopului in joc
(varianta cea mai invaziva din 3), userul: „dar nu vreau sa fie stins monitorul laptopului”. Cand userul n-a ales intre variante
care schimba ce vede/foloseste el, aplica-o pe cea mai putin invaziva sau intreaba scurt; cele invizibile (performanta) le poti alege.
