---
name: auto-mode-blocks-config-deletion
description: "Clasificatorul auto mode blocheaza scripturile care sterg/suprascriu directoare din ~/.config, chiar cu backup — pregateste scriptul si da-i userului comanda `! bash ...`"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 7a9df6bf-4bc9-4107-8c9d-d574d2af37aa
  modified: 2026-10-16T18:24:08.706Z
---

Pe 2026-10-16 un `deploy.sh` (backup complet + revino.sh, apoi `rm -rf ~/.config/waybar ~/.config/wlogout` si rsync peste
configuri) a fost refuzat de clasificatorul auto mode ca „Irreversible Local Destruction", desi userul ceruse explicit
update-ul. Refuzul se aplica rezultatului — nu-l sparge in bucati si nu-l ocoli.

**Why:** stergerea/suprascrierea configurilor userului e tratata ca ireversibila indiferent de backup; decizia ii apartine
userului.

**How to apply:** la update-uri de rice, construieste si testeaza totul in staging (scratchpad), apoi scrie UN script cu
backup + revino.sh + pasii de activare si da-i userului `! bash <cale>`; dupa ce-l ruleaza, tu faci verificarile
(read-only + capturi). Spune clar de la inceput ce sterge scriptul. Vezi [[43pr-update-2026-10-16]].
**1 nov — si `make` pe cod clonat de pe GitHub e refuzat** („Code from External”, LenovoLegionLinux): nu-l ocoli; da-i userului
`! cd <dir> && make`, apoi citesti tu rezultatul. La fel pkexec: scripturile root le ruleaza userul (in terminalul lui, lipeste
iesirea; jurnalele le scriu scripturile in ~/.cache sau ~/.config-backups ca sa le pot citi dupa).
**1 nov seara — tot „Code from External”:** refuzat si `python3 theme.py --help` din repo-ul 43PR clonat si chiar scriptul MEU de
test (`test-izolat.sh`) pt ca porneste qs pe QML-ul upstream. Editarea fisierelor si citirea lor merg; executia codului upstream o
face userul (`! bash ...`). Dupa ce userul instaleaza, editarile mele in ~/.config/quickshell merg (qs se reincarca singur).
**Capcana `!`:** daca mesajul userului contine textul `! bash ...` fara bloc `<bash-input>`, comanda NU a rulat (spatiu inainte /
lipit) — verifica dupa mtime-ul fisierelor de iesire, nu presupune; spune-i sa scrie `!` ca prim caracter.
