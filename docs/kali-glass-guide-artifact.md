---
name: kali-glass-guide-artifact
description: Published artifact holding the corrected Kali/KDE glass theme guide — update this URL rather than creating a new page
metadata: 
  node_type: memory
  type: reference
  originSessionId: 5dcfc3e1-24c2-49f7-8c0b-02b320274d17
  modified: 2026-08-09T12:30:41.722Z
---

https://claude.ai/code/artifact/b840ca9d-761c-40f9-a46d-a44e772bb49e

The machine-verified rewrite of the user's original `~/Downloads/kali_glass_setup.txt`, covering Steps 0–9 plus troubleshooting and rollback for [[kali-glass-kde-setup]]. Source file: `kali-glass-kde.html` in the session scratchpad.

To revise it from a later conversation, pass this URL as `url` to the Artifact tool — otherwise a new page and URL are minted and the user loses the link they already have.

One detail that must stay accurate on any edit: the Blur-Glassy download link from `api.kde-look.org/ocs/v1/content/data/1364705` is JWT-signed and expires in roughly 48 hours, so the guide resolves a fresh link through the OCS API instead of hardcoding one. Never replace that with a literal URL.
