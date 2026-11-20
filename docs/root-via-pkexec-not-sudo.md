---
name: root-via-pkexec-not-sudo
description: Pe boxa asta sudo nu poate cere parola dintr-o sesiune Claude Code — pkexec e calea care functioneaza
metadata:
  node_type: memory
  type: project
  originSessionId: 4e626cfb-471b-46a5-b495-f5d290b16736
  modified: 2026-10-30T19:51:44.569Z
---

`sudo` cere parola (nu e NOPASSWD) si nu are tty in sesiunile Claude Code, deci esueaza cu
`sudo: a terminal is required to read the password`. **Nici modul `!` din Claude Code nu
rezolva** — nu ofera nici el terminal pentru prompt. La fel orice alta comanda cu parola interactiva (30 oct: `! passwd` -> „Authentication token manipulation error”):
pentru `passwd` & co. trimite userul intr-un terminal kitty real, nu la `!`.

Ce functioneaza: **`pkexec`**. Agentul polkit KDE ruleaza permanent in sesiunea grafica
(`/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1`) si autorizeaza.
Verificat: `pkexec /usr/bin/id -u` intoarce `0`.

Ce NU functioneaza: `SUDO_ASKPASS=/usr/bin/ksshaskpass sudo -A` — ksshaskpass stie sa
parseze doar prompt-uri de passphrase SSH si raspunde `Unable to parse phrase` la cele
de sudo, fara sa autentifice.

**Exceptie — din TTY (fara sesiune grafica, ex. 30 oct cu SDDM blocat):** nu ruleaza niciun agent polkit,
deci nici pkexec nu merge. Singura cale = userul ruleaza `sudo ...` direct in shell-ul unui TTY liber
(Ctrl+Alt+F4), NU prin Claude/`!`. Verifici cu `echo $XDG_SESSION_TYPE` (= tty) + `pgrep -af polkit.*agent` (gol).

**Why:** de doua ori la rand utilizatorul a incercat sa ruleze el scriptul cu sudo si a
esuat pe acelasi mesaj, o data din chat si o data din modul `!`. Pierdere de timp care
se evita stiind de la inceput care e calea buna.

**How to apply:** pentru orice are nevoie de root, scrie comenzile intr-un script si
ruleaza-l cu `pkexec /bin/bash /cale/catre/script.sh`. pkexec curata environment-ul,
deci seteaza inauntru ce ai nevoie (`DEBIAN_FRONTEND=noninteractive`, `PATH`). Ruleaza-l
in background ca sa nu existe riscul de a taia `dpkg` la mijloc printr-un timeout.
Vezi si [[no-chaining-off-apt-update]] si [[broken-third-party-apt-repos]].

**1 nov 2026 — nu porni tu o comanda pe care i-ai dat-o userului:** i-am dat `! pkexec ... fix-erori-root.sh`, apoi am pornit-o si
eu prin pkexec; userul a refuzat apelul meu („am rulat scriptul de mai sus”) — il rulase deja singur. Odata ce comanda e la user,
asteapta sa raporteze, apoi VERIFICA rezultatul (fisiere, sysctl, backup) in loc sa o rulezi din nou.
