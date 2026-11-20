---
name: ls-is-eza-alias
description: "in zsh-ul userului `ls` = `eza --icons`; `ls <dir>` fara flag-uri crapa, iar globurile pot iesi goale"
metadata:
  node_type: memory
  type: reference
  originSessionId: 4c2a1f02-9dea-4fce-b2e1-ef8c39bc80d9
  modified: 2026-09-30T19:43:55.647Z
---

`~/.zshrc` linia 8: `alias ls='eza --icons'` (verificat 2026-09-30). Shell-ul Bash din Claude Code incarca profilul
userului, deci alias-ul e activ si in comenzile tale.

Capcana: `ls /cale1/ /cale2/` fara alte flag-uri devine `eza --icons /cale1/ ...`, iar eza ia calea drept valoare pentru
`--icons` -> `error: invalid value '/cale1/' for '--icons [<WHEN>]'`. `ls -lt *.jsonl` n-a afisat nimic.
`ls -la <dir>` merge (flag-ul dinaintea caii).

**How to apply:** in scripturi si comenzi foloseste `command ls`, `find ... -printf`, sau `stat`, nu `ls` gol.
Legat: [[parallel-claude-sessions]].
