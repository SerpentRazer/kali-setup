---
name: apps-teams-neofetch
description: Cum sunt instalate „Microsoft Teams” si „neofetch” pe Kali (2026-10-17) — nu sunt pachetele pe care le-ai banui
metadata:
  type: project
---

Cerute de user pe 2026-10-17 („instaleaza neofetch si microsoft teams”).

- **Teams:** Microsoft nu mai are client Linux din 2022 → `teams-for-linux` 2.24.0 (2.25.0 din 2026-10-18, acelasi mod) (IsmaelMartinez, neoficial,
  Electron) instalat din .deb-ul de pe GitHub releases, sha256 verificat cu digest-ul din API. **Fara repo apt**, deci nu
  se actualizeaza cu `apt upgrade`; pentru update: .deb nou de pe GitHub sau repo-ul lor (repo.teamsforlinux.de).
  Lanseaza `teams-for-linux` / „Teams for Linux” in meniu.
- **neofetch:** abandonat upstream, scos din Kali → instalat `neowofetch` (fork-ul intretinut, din pachetul hyfetch) +
  symlink `~/.local/bin/neofetch` → `/usr/bin/neowofetch`. `fastfetch` era deja instalat.

Instalat prin pkexec ([[root-via-pkexec-not-sudo]]), fara `apt update` inainte ([[no-chaining-off-apt-update]]).

**2026-10-26 „nu merge teams si nici spotify”** (prima pornire dupa boot): Teams blocat pe ecranul mov („Waiting for
network...”), Spotify „Something went wrong — Reload page”; reteaua, ceasul si keyring-ul erau OK. Repornite (Spotify
ignora SIGTERM -> `kill -9`) au mers imediat. La acel boot upower + power-profiles-daemon + timedated au dat timeout
pana la ~226s (singurul boot cu asta, din 6), iar ambele cer UPower la start — cauza probabila, nedovedita.
Daca se repeta: `systemctl status upower` si reporneste aplicatiile dupa ce UPower e activ. Ca sa vezi ferestrele:
`grim -T` + lstl ([[window-capture-grim-t-lstl]]); log: `systemd-run --user --property=StandardOutput=file:...`.
Din 26 oct seara ruleaza din nou pornite normal (prin Hyprland), nu din unitatile de test `spotify-debug`/`teams-debug`.
