---
name: spicetify-43pr-theme
description: Tema Spotify din 43PR (Spicetify „text”/darkthemer, Monochrome) instalata 28 oct; ACL pe /usr/share/spotify, font GeistMono, se pierde la update-ul spotify-client
metadata:
  type: project
---

Cerut 2026-10-28 („instaleaza tematica asta de spotify de aici https://github.com/43PR/dotfiles”). `~/.config/spicetify`
exista deja din portarea din septembrie (identic cu upstream); clona upstream in `~/src/43pr-dotfiles-upstream`.
- Spicetify CLI **2.46.4** in `~/.spicetify` (tar.gz de pe GitHub, sha256 verificat cu digest-ul din API), symlink `~/.local/bin/spicetify`.
- Spotify = `.deb` 1.2.95 in `/usr/share/spotify` (root). Drept de scriere DOAR pt mastermind prin ACL (`setfacl -R -m u:mastermind:rwX`
  + default ACL pe folder si Apps), NU `chmod a+w` din ghid.
- `config-xpui.ini`: `spotify_path` /opt/spotify/ -> /usr/share/spotify/, sectiunea `[Backup]` golita (avea starea autorului:
  1.2.92 / 2.45.0). Tema `text`, schema `Monochrome`, custom app `marketplace`. `spicetify backup apply -n` OK.
- Font: `user.css` `--font-family` "Roboto Mono" -> **"GeistMono Nerd Font", "Roboto Mono"** ([[font-geist-overall]]). Backup in
  `~/.config-backups/pre-spicetify-2026-10-28_19-33-41`. Revenire totala: `spicetify restore`.
- **Prima pornire dupa patch pare GOALA** (doar casetele Nav/Main) cateva secunde — nu e bug, asteapta. Diagnoza facuta prin
  `--remote-debugging-port=9229 --remote-allow-origins=http://127.0.0.1` + scripturi CDP in `~/.cache/qs-traytest/cdp_*.py`
  (websocket-client e instalat). Spotify ignora SIGTERM -> kill -9.
- **Update spotify-client (apt) sterge tema** (reapare `Apps/xpui.spa`) -> `spicetify backup apply`. Hook-ul apt automat a fost
  REFUZAT de auto mode („Unauthorized Persistence”) — propus userului, nefacut.
