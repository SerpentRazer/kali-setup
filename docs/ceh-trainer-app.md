---
name: ceh-trainer-app
description: "Aplicatia CEH v13 Trainer (invatare examen CEH): 2 copii (~/Downloads + SSD STUFF), progres in fisier sincronizat prin server.py, repo GitHub privat, iconita rofi"
metadata:
  node_type: memory
  type: project
  originSessionId: b7b3b06e-f79f-4b96-8db6-4bbe207f87e5
  modified: 2026-10-25T10:50:37.175Z
---

Userul invata pentru **CEH 312-50v13** (examen setat 2026-11-14) cu o aplicatie web proprie (HTML/JS, FSRS, 1049 intrebari extrase din PDF-ul „Real Exam Questions”).

**Copii (din 2026-10-25):**
- `~/Downloads/ceh-trainer` = copia principala pe Kali, merge FARA SSD-ul extern (cerinta userului). E si repo git → `github.com/SerpentRazer/ceh-trainer` **PRIVAT** (banca de intrebari e material cu copyright; nu-l face public fara cererea lui explicita). Commit ca `H. Valentin <75014544+SerpentRazer@users.noreply.github.com>` (config local).
- `/mnt/stuff/Workplace/ceh-trainer` = copia de pe SSD-ul extern (Kingston USB, label STUFF), folosita pe Windows cu `start.bat`. Backup-uri `_backup_2026-09-27/`, `_backup_2026-10-25/` (originalele + exporturile extrase din Brave).

**Progres:** `progress/ceh13-progress.json` (NU e in git, `.gitignore`), backup zilnic in `progress/backups/` (30). `server.py` (stdlib, 127.0.0.1:8777..8787) il serveste si combina (merge pe uniune: jurnal, carduri dupa `mt`/`last`, epoch la reset/import) cu copiile din `sync-peers.txt` cand SSD-ul e montat (si /media/$USER/STUFF). localStorage = doar cache. Log cand e pornit din meniu: `~/.cache/ceh-trainer.log`.

**Pornire Kali:** iconita „CEH v13 Trainer” in rofi (`SUPER+D`, `~/.local/share/applications/ceh-trainer.desktop`) sau `start.sh`; serverul ramane pornit pana la logout.

**Capcana de istorie:** pe Windows userul deschidea `index.html` direct (origin `file://` in Brave), deci progresul real era acolo, nu pe `localhost:8777` (ramas la 14 oct). Am extras LevelDB-ul Brave cu un cititor propriu (snappy+table+log). Acum `file://` arata un banner ca progresul nu se sincronizeaza.

**Why:** userul vrea acelasi progres pe Windows si Kali si sa nu depinda de SSD.
**How to apply:** modificari de cod → in copia din Downloads, test, commit+push, apoi copiaza fisierele schimbate si pe SSD (fara `progress/`). Nu suprascrie niciodata `progress/` cu mana: lasa serverul sa combine. Vezi [[verify-before-instructing]], [[talks-romanian-windows-analogies]].
