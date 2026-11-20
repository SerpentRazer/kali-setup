---
name: broken-third-party-apt-repos
description: Repo-urile NodeSource/Microsoft/Spotify picau pe politica SHA1 (din 2026-02) — REPARATE 2026-10-18 cu cheile reemise de vendori
metadata:
  node_type: memory
  type: project
  originSessionId: b3281538-7b9f-4b05-a750-9ffaf7cff688
  modified: 2026-10-18T17:57:52.271Z
---

Din **2026-02-01** `sqv` respinge semnaturile SHA1, iar trei repo-uri picau la `apt update` (exit 100). **REPARAT 2026-10-18**
([[system-update-2026-10-18]]), `apt-get update` iese acum cu **0**:

- Microsoft (`microsoft-prod.list`): aceeasi cheie BC528686…29CF, reemisa de Microsoft cu legaturi SHA256 —
  `packages.microsoft.com/keys/microsoft.asc` dearmorat peste `/usr/share/keyrings/microsoft-prod.gpg` (fisier al
  pachetului packages-microsoft-prod: o reinstalare a lui poate readuce cheia veche).
- NodeSource: aceeasi cheie 6F71F525…E0B4 reemisa (`deb.nodesource.com/gpgkey/nodesource-repo.gpg.key`) ->
  `/usr/share/keyrings/nodesource.gpg`; lista mutata pe **node_24.x**. Pin-ul `/etc/apt/preferences.d/nodejs` (600, origin
  deb.nodesource.com) exista deja — fara el apt ar lua nodejs 24 din Kali, care NU include npm (npm din Kali = 423 pachete node-*).
- Spotify: cheie noua E1096BCB…C83A (`download.spotify.com/debian/pubkey_5384CE82BA52C83A.gpg`) ->
  `/usr/share/keyrings/spotify.gpg`, lista = `deb [signed-by=...] https://repository.spotify.com stable non-free`
  (postinst-ul Spotify nu rescrie lista daca e deja pe HTTPS; isi copiaza singur chei in trusted.gpg.d).

Verificare inainte de instalare: `sqv --keyring K --cleartext --output out InRelease` (out nu are voie sa existe deja).
Revenire config apt: `pkexec /bin/bash ~/.config-backups/pre-update-2026-10-18_20-51-55/revino-apt.sh`.
