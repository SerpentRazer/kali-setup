---
name: no-chaining-off-apt-update
description: "`apt update` exited 100 here for months (broken repos, fixed 2026-10-18 — now 0); still never chain the real work after it with &&"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5dcfc3e1-24c2-49f7-8c0b-02b320274d17
  modified: 2026-08-09T12:30:26.326Z
---

`sudo apt update && sudo apt full-upgrade -y && sudo apt install X` silently did nothing on this machine: `apt update` returns exit code **100** whenever any configured repo fails signature verification, so `&&` short-circuits and the real work never runs. Verified directly — `apt-get update -qq; echo $?` → `100`.

**Why:** Three third-party repos fail verification here (see [[broken-third-party-apt-repos]]), and that is the normal steady state, not a transient error. Kali's own repo updates fine, so installs work perfectly well — but any `&&` hung off `apt update` will always break.

**Update 2026-10-18:** repo-urile au fost reparate ([[broken-third-party-apt-repos]]), `apt-get update` iese acum cu 0. Regula ramane ca precautie: un repo third-party care pica din nou readuce exit 100.

**How to apply:** Hand over apt steps as separate commands, or join them with `;`. Don't re-run `apt update` just to "make sure" — check whether `http.kali.org` shows `Hit:` and move on. This produced a visibly failed handover once already; it should not happen twice.
