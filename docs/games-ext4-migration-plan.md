---
name: games-ext4-migration-plan
description: "Planul de atac din 1 nov 2026 — chkdsk C: + Shrink in Windows, jocurile pe partitie ext4 nativa (faza2-jocuri-ext4.sh), C: pe ntfs-3g, retest CS2; starea fiecarei faze"
metadata:
  node_type: memory
  type: project
  originSessionId: 8c0dbf1e-e741-44e5-934b-6f304d352913
  modified: 2026-11-01T10:02:52.705Z
---

**De ce:** C: (p4) pe driverul kernel `ntfs` a trecut singur read-only pe 1 nov 10:59 ([[cachy-bazzite-tuning]]); containerul
CS2 (`/mnt/windows/LinuxGames/kali-games.ext4`, 120 GiB, eticheta kali-games, loop dio=0) sta pe C:. Partitie ext4 nativa =
fara NTFS in calea jocului, fara cache dublu, fara loop.

**Faze (userul a cerut „plan clar si trecem la treaba”):**
- **F0 Kali — GATA 1 nov:** [[fix-erori-2026-11-01]] rulat si verificat; scriptul F2 scris si testat in modul proba.
- **F1 Windows (user) — GATA 1 nov ~13:15:** chkdsk + Shrink facute; C: 532 GiB, 0 erori ntfs la boot 13:17, used 290->260 GB (chkdsk a eliberat ~30 GB orfani). Pasii au fost: iesire din Steam -> Windows -> cmd admin `chkdsk C: /f` -> Y -> Restart (verificarea ruleaza la
  pornire) -> Disk Management -> Shrink C: **307200 MB** (minim 150 GB), lasat Unallocated -> **Restart (NU Shut down)** -> Kali ->
  `claude --continue` + „am revenit”.
- **F2 Kali — GATA 1 nov 13:24** (backup/revino `~/.config-backups/pre-faza2-jocuri-ext4-2026-11-01_13-20-50`, backup GPT inainte in `..._13-19-04`): p11 (din 2 nov = p6, renumerotat de Windows) UUID 27279f6c-241f-49e0-af62-27c7f42187fb, 295G; rsync 86666474005 octeti / 3440 intrari identic, 449 MB/s, 3 min; C: pe fuseblk rw, divert scos, scriere ok; LANG/swappiness/udev/sslh confirmate dupa reboot. **Prima rulare s-a oprit fals:** `blkid -p` iese 0 pe o partitie GOALA (raporteaza PART_ENTRY_* din GPT) -> verificarea corecta = `blkid -p -D` (exit 2) + `wipefs -n` gol. Plan initial: intai verific: `findmnt /mnt/windows` rw, 0 erori ntfs in `journalctl -k -b`, spatiu nealocat dupa p4.
  Apoi userul: `! pkexec /bin/bash /home/mastermind/src/legion/faza2-jocuri-ext4.sh aplica` (fara argument = proba, fara root).
  A: p11 ext4 „jocuri” intre p4 si p5 (zona din sysfs, `sgdisk -v` „No problems found”, verificare suprapunere, backup GPT,
  `blkid -p` gol inainte de mkfs, refoloseste partitia la re-rulare); B: rsync -aHAXS 80.7 GiB / 3441 intrari + verificare 1:1
  (rsync -n, octeti, numar intrari, appmanifest_730.acf); C: fstab `UUID=... /mnt/games ext4 defaults,noatime,nofail,...  0 2`,
  linia containerului comentata `KALI-JOCURI-VECHI` (aceeasi cale => Steam nu observa); D: C: pe ntfs-3g
  (`uid=1000,gid=1000,umask=022,windows_names,big_writes,exec,noatime,nofail`), scos dpkg-divert mount.ntfs; la esec revine DOAR D.
  Log + `revino.sh` in `~/.config-backups/pre-faza2-jocuri-ext4-*`.
- **F3 retest CS2 — FACUT 1 nov 13:27-13:29 (doar ~2.5 min, nu 15-20):** doar joc (88 s, fara iesirea de la 13:29:42): 0 cadre >50 ms (dimineata 14), max 28 ms (451), p99.9 16 ms (48.9), 1% low (medie 1% cele mai lente) 78 (36), fps 139 (130); swap max 0.55 GB (3.42), 0 page allocation failure; cele 6 sacadari >50 ms din log = secventa de iesire. GPU 55°C/58 max, 46.5 W, MEREU la plafonul 1500, util 73%, 17/137 s >=95% => plafonul limiteaza uneori; temperaturile dupa 2 min NU sunt regim stabil. CPU 71°C/80, 0 franari. coredump gamescope: COREFILE none (ulimit merge). Initial: userul joaca 15-20 min cu Brave/Spotify inchise; logger automat ([[cs2-session-logger]]);
  compar cu `cs2_2026-11-01_11-14-28.csv` (1% low 69, 14 cadre >50 ms, max 451 ms).
- **F4 decizii (propuse userului 1 nov 13:35):** (1) plafon GPU 1500 -> 2100 cu `pkexec /bin/bash ~/.config-backups/pre-gpu-cap-1500-2026-11-01_08-31-11/revino.sh` + sesiune lunga 15-20 min (daca GPU >~85°C sau CPU franeaza -> 1800); (2) fps_max abia dupa, o variabila pe rand; (3) tearing = Hyprland 0.57 ([[cs2-fullscreen-hyprland-linux]]); (4) direct_scanout=2 APLICAT 14:06 (cerut implicit: „FULLSCREEN”). Plafon GPU 2100 APLICAT de user 14:04 (verificat NV_MAX=2100). URMEAZA sesiunea lunga. Lista initiala: fps_max (144/128/0), plafon GPU 1500 MHz, sterg containerul de 120 GB **din Windows** (nu din Linux: driverul
  kernel lasa MFT agatate la stergeri), eventual CS2 fara gamescope ([[cs2-fullscreen-hyprland-linux]]).

**Layout NVMe VECHI (din 2 nov renumerotat de Windows: jocuri p6, Kali p7 -> [[gpt-primary-lba2016-windows]]):** p1 300M EFI(Win) | p2 1G boot | p3 16M MSR | **p4 C: 832G** (start 2748416, se termina
la 1748453375) | p5 859M WinRE (start 1748453376) | p6 Kali / 101G (21G liberi) | p7 swap | p8 EFI Kali | p9 16G NTFS | p10 977M.
Shrink de fix 300 GiB => p11 = sectoarele 1119307776-1748453375, aliniat la 2048.

CONFIRMAT dupa reboot 1 nov ~16:25: p11 la /mnt/games, C: ntfs-3g + 4 bind-uri, CS2 gasit.
**1 nov 19:00 — containerul de 120 GiB STERS** (din Kali, ntfs-3g, rulat de user): C: 269 -> 389 GB liberi, fara erori in kernel; linia KALI-JOCURI-VECHI din fstab ramane comentata (inofensiva).
**1 nov seara: biblioteca Steam IMPLICITA = „Kali games (ext4)” (/mnt/games/SteamLibrary, 210 GB liberi), setata de user.** Recomandare pt jocuri noi: mereu acolo (NU / = 18 GB liberi, NU C: NTFS). Enshrouded urma sa fie instalat acolo.
