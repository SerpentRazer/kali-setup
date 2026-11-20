---
name: visual-coherence-delegated-choices
description: "Userul vrea totul „one to one” cu tema (paleta 43PR, font Geist, nimic iesit din chenar) si delega alegerile estetice — alegi tu dupa o comparatie vizuala, aplici peste tot, arati inainte/dupa"
metadata:
  node_type: memory
  type: feedback
  originSessionId: ede7c5ab-04ee-42c9-a641-c5fda592e728
  modified: 2026-10-17T11:52:56.575Z
---

Userul judeca rice-ul vizual si vrea coerenta totala: o aplicatie care arata altfel decat restul e un bug pentru el
(„dolphin nu prea se potriveste cu tematica overall, fa-o sa fie one to one cu tot”), la fel un element care iese din
chenarul lui la hover („iese din chenarul negru... se vede urat”) sau un amestec de fonturi („nu-mi place fontul overall”).
Cand zice „cauta unul si aplica” isi deleaga alegerea: nu-l intreba intai ce prefera.

**Why:** 2026-10-17, trei cereri la rand de felul asta (Dolphin, hover-ul piesei din bara, fontul); „imi place mult cum se vede”
a venit pe un element deja coerent (cardul OSD de media), nu pe o optiune propusa.

**How to apply:**
- Orice element nou sau schimbat: aceleasi surse ca restul — culori din paleta 43PR (tinta noua in `~/.config/43pr/targets.toml`
  daca aplicatia n-are una, ca la Kvantum), font Geist / GeistMono NF ([[font-geist-overall]]), translucid ca GTK (alfa 0.70).
- Alegeri estetice: compara 3-4 variante randate pe wallpaperul si paleta lui (plansa PIL), alege, aplica in TOATE locurile,
  verifica pe ecran (capturi pe ws ascuns, [[window-capture-grim-t-lstl]]), arata inainte/dupa, ofera alternativele intr-o fraza.
- Backup in `~/.config-backups/pre-<ce>-<data>` + comanda de revenire in raspuns.
- Cauta si efectele secundare vizuale (zoom/hover, decupaje, glife), nu doar culoarea de baza. Vezi [[verify-before-instructing]].
