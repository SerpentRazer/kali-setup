---
name: cs2-c-copy-hidden-on-kali
description: "15 nov 2026: CS2 laggy pe Kali = Steam rula copia de pe C: (NTFS, actualizata din Windows); fix permanent: manifestul CS2 de pe C: e bind-uit GOL+ro in fstab doar pe Linux -> Kali joaca de pe /mnt/games, Windows de pe C:"
metadata:
  type: project
---

Userul joaca CS2 pe AMBELE sisteme. Dupa ce Windows Steam a actualizat CS2 pe C:, Steam-ul de pe Kali a ales `appmanifest_730.acf`
de pe C: (build mai nou) si a rulat jocul prin ntfs-3g => lag; copia ext4 ramasese la build-ul din 8 nov.

**Fix 15 nov 18:37** (`~/src/legion/cs2-doar-ext4-2026-11-15/aplica.sh`, rulat de user; backup+revino.sh `~/.config-backups/pre-cs2-ext4-2026-11-15_18-37-53`):
fstab `CS2-DOAR-EXT4`: `/etc/steam-ascuns/appmanifest-gol.acf` -> `.../Steam/steamapps/appmanifest_730.acf` `bind,ro,nofail,x-systemd.requires=/mnt/windows`.
Pe C: nu se scrie nimic; Windows vede manifestul real. Testat intai cu `unshare -rm` (bind peste fisier pe ntfs-3g merge).
**VERIFICAT 18:38:** libraryfolders: 730 doar pe /mnt/games; update delta 2.5 MB pe ext4 -> build 26598758.
**CONFIRMAT de user 15 nov: „mult mai fluid”.**
Acelasi truc pt orice alt joc instalat in ambele OS-uri. Legat: [[games-ext4-migration-plan]], [[cachy-bazzite-tuning]].
