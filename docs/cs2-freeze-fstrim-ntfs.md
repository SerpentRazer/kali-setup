---
name: cs2-freeze-fstrim-ntfs
description: "16 nov 2026: CS2 agatat la iesirea din meci (oprit fortat) = fstrim.service saptamanal pornit in joc (20:50), blocat >6 min pe C: ntfs-3g -> Steam stall; fix X-fstrim.notrim pe /mnt/windows"
metadata:
  type: project
---

Simptom: dupa un meci CS2 jocul a inghetat, userul l-a oprit fortat si a repornit (boot -1 s-a terminat 20:56:04).
Dovezi (journalctl -b -1): fstrim.service „Starting” 20:50:22, FARA „Finished” pana la 20:56; Steam 20:54:26 „CSteamEngine::BMainLoop appears to
have stalled > 15 seconds”; gamescope „Compositor released us but we were not acquired” la 20:43:52 si 20:51:16 (probabil secundar); 0 erori kernel/NVIDIA/OOM.
Cauza probabila: fstrim --listed-in /etc/fstab trimeaza si C: (ntfs-3g, FUSE, 532G) = foarte lent si blocheaza C:; Steam are biblioteca + Proton pe C:.
Timer-ul (luni 00:00, Persistent) a rulat la primul boot = in timpul jocului. Jurnalul Hyprland al sesiunii pierdut (last-session.log suprascris la login).
Fix: `~/src/legion/fstrim-fix-2026-11-16/aplica.sh` (pkexec) adauga `X-fstrim.notrim` pe /mnt/windows si pe bind-ul fisierului appmanifest_730 (testat pe
copie: 2 linii); Windows face TRIM pe C: singur. **APLICAT 16 nov 23:13** (backup+revino.sh ~/.config-backups/pre-fstrim-fix-2026-11-16_23-13-36); `fstrim -n` acum = doar /mnt/games, /boot/efi, / (C: exclus). De confirmat la urmatorul meci lung ca nu mai ingheata.
Tray Discord „fara meniu”: dupa reboot Discord nu rula (doar nm_applet in StatusNotifierWatcher) -> de retestat cu Discord pornit.
Legat: [[cs2-c-copy-hidden-on-kali]], [[cachy-bazzite-tuning]], [[games-ext4-migration-plan]].
