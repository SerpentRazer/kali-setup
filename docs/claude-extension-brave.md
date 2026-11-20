---
name: claude-extension-brave
description: Extensia Claude (Claude in Chrome) e in Brave, instalata prin fisier de extensie externa; userul uraste Chrome — nu-i propune Chrome
metadata:
  type: project
---

2026-10-26, userul: „nu pot sa instalez claude addon pe nici un browser” -> pagina claude.ai ii cerea „instaleaza intai
Chrome” („urasc chrome”) -> „pai atunci instaleaza-l tu”. Browsere: Brave 156 (principal), Chromium 154 Debian, Firefox ESR
(nu exista extensie Claude pt Firefox). Web Store-ul da extensia oricarui Chromium (CRX v1.0.102, minimum Chrome 116).

**Instalat fara UI:** `/opt/brave.com/brave/extensions/fcoeoabgfenejglbffodgkkbkcdhcgfn.json` =
`{"external_update_url": "https://clients2.google.com/service/update2/crx"}` (pkexec) + restart Brave curat
(`kill -TERM` pe procesul principal, apoi `hl.exec_cmd("brave-browser --restore-last-session")`; restore_on_startup e
implicit = tab-urile s-ar pierde fara flag). Pe Linux extensiile externe se instaleaza ACTIVE, fara prompt (location 6,
from_webstore true, se actualizeaza din Web Store). Daca userul o dezinstaleaza, Brave nu o mai reinstaleaza din fisier.
NU folosi `/usr/share/chromium/extensions/` (Brave il citeste si el): Debian `/etc/chromium.d/extensions` da tot ce e
acolo la `--load-extension` -> eroare la fiecare pornire Chromium.
Pt Claude Code: `/chrome` (Claude Code isi pune singur native host-ul si pt Brave, in
`~/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts/`). Vezi [[root-via-pkexec-not-sudo]].
