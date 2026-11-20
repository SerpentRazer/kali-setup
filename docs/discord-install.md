---
name: discord-install
description: "Cum e instalat Discord pe Kali (2026-10-28): .deb oficial nou (bootstrap) + aplicatia reala in ~/.config/discord, se actualizeaza singura"
metadata:
  node_type: memory
  type: project
  originSessionId: 632d84fc-4498-49f8-8219-6bfe00c82d00
  modified: 2026-10-28T16:56:12.585Z
---

Cerut 2026-10-28 („instaleaza te rog discord”). `.deb` oficial de la `discord.com/api/download?platform=linux&format=deb`
(1.0.167), instalat cu `apt-get install --no-install-recommends` prin pkexec ([[root-via-pkexec-not-sudo]]); a sarit libunity9.

**Pachetul e doar un bootstrap de 2.3 MB:** `/usr/bin/discord` e un script sh care, daca lipseste `~/.config/discord/Discord`,
ruleaza `/usr/share/discord/updater_bootstrap` si descarca aplicatia reala (~486 MB, `app-1.0.x`, Electron 42) in
`~/.config/discord`. Updater-ul se ocupa singur de versiuni; nu mai exista promptul vechi „descarca .deb-ul nou”, deci
nici repo apt nu trebuie. Bootstrap-ul crapa cu `installer.db ... Error code 14` daca folderul nu exista (scriptul face mkdir).
Postinst-ul da `apparmor.service is not active` = inofensiv (apparmor oprit aici).

Pornit din meniu (rofi/.desktop) ruleaza **nativ Wayland** (xwayland False, gpu-process `--ozone-platform=wayland`) si
foloseste portalul GlobalShortcuts pentru scurtaturi globale. Pornit prin `systemd-run --user` a mers pe X11/XWayland
(mediul userului systemd e diferit), deci nu trage concluzii despre Wayland dintr-un test cu systemd-run.

**Capcana (28 oct):** regula de test `workspace="19 silent"` pe class discord a prins si fereastra pe care userul a deschis-o
el in acelasi timp. Mutata inapoi cu `hyprctl dispatch 'hl.dsp.window.move({ workspace = 1, window = "address:0x..." })'`
(argumentul `window=` merge). Data viitoare potriveste regula si dupa PID / scoate-o imediat dupa ce apare fereastra de test.
Ecranul de login are cod QR, deci sterge capturile ([[screenshots-crop-private]]). Vezi [[window-capture-grim-t-lstl]].
