---
name: gpt-primary-lba2016-windows
description: "Kali nu porneste (initramfs, nu gaseste root) dupa ce Windows modifica partitii — header GPT cu tabela la sectorul 2016, Windows scrie la 2; REPARAT 3 nov cu sgdisk -j 2 + plasa `gpt` permanenta; VERIFICAT ok 8 nov"
metadata:
  node_type: memory
  type: project
  originSessionId: 58a3d256-89f2-401b-9c3a-8a4d27379603
  modified: 2026-11-03T20:20:08.062Z
---

**Simptom (de 2 ori):** dupa Shrink in Windows (1 nov ~12:30) si dupa update-ul WinRE (2 nov 21:52, `C:\Windows\Logs\WinREAgent\setupact.log`
„Repartition to extend WinRE partition”: C: -923 MiB, WinRE noua dupa C:, cea veche stearsa) Kali ramane in initramfs
(nu gaseste root), GRUB vede numerotare veche / grub rescue. Pornea doar cu `gpt` adaugat manual (`e` in GRUB, dupa
`quiet splash`, Ctrl+X); din initramfs se iese cu `reboot -f`. Userul a depanat asta intr-un chat Claude separat (telefon)
si a lipit conversatia aici — sfatul de acolo „grub-install pt ca Kali e pe p7” NU e necesar (fstab + GRUB merg pe UUID).

**Cauza (dovedita 3 nov din dump-uri):** header-ul GPT primar avea PartitionEntryLBA=**2016** (origine necunoscuta).
Windows scrie tabela noua la **sectorul 2** + pune CRC-ul ei in header, lasa 2016 neatins -> CRC mismatch. Kernelul,
fara `gpt`, NU incearca backup-ul daca primarul e invalid -> zero partitii. GRUB nu verifica CRC -> citeste tabela veche de la 2016.
Partitia noastra „jocuri” NU e de vina: dupa sgdisk-ul din 1 nov 13:19, 4 boot-uri fara `gpt` ok pana 2 nov 15:53
(verificat cu `journalctl -k -b N`: linia „Command line” + „Primary GPT is invalid”).
Numerotarea s-a schimbat (Windows sorteaza): acum p4 C:, p5 WinRE noua, **p6 jocuri, p7 Kali /**, p8 swap, p9 ESP
(are si Windows Boot Manager), p10 NTFS 16G, p11 swap nefolosit; fstab e pe UUID -> fara efect. 862 MiB liberi unde era WinRE veche.
Sectorul 48 (in golul 34-2047) are 512 octeti necunoscuti — lasati neatinsi.

**REPARAT 3 nov 21:43 (rulat de user, toate verificarile ok):** `~/src/legion/gpt-fix-2026-11-03/repara-gpt.sh` =
garzi (disc identic cu dump-ul `/mnt/stuff/gpt-2026-11-03/`) + `sgdisk -j 2` (schimba DOAR sectorul 1 si ultimul;
first usable 2048->34, standard) + verificare byte cu byte vs `asteptat-*.img` + `sgdisk -v` „No problems found” + plasa
`GRUB_CMDLINE_LINUX="gpt"` + update-grub (7 intrari cu gpt). Backup + `revino.sh` (scoate doar plasa) in
`~/.config-backups/pre-gpt-fix-2026-11-03_21-43-41`.
**VERIFICAT 8 nov:** boot-urile din 7 nov 20:15 si 8 nov 09:29 = 0 mesaje „Primary GPT is invalid” (primarul e valid; plasa `gpt` in cmdline). Pornirea
singura NU dovedeste nimic: plasa `gpt` porneste Kali si cu primarul stricat.

**Reteta de test fara root (refolosibila):** dump cap (2048 sectoare) + coada (33) prin pkexec pe STUFF, apoi
`truncate -s $((N*512)) disc.img` + dd cap la 0 + coada la N-33 (`conv=notrunc`) => sgdisk/gdisk ruleaza pe fisier ca user;
compari sectoarele schimbate. Parser header/CRC/intrari: `python3 -I ~/src/legion/gpt-fix-2026-11-03/gptparse.py head|tail|sgdisk <fisier>`.
Dump-uri: incident 1 = `/mnt/stuff/nvme-head.img` (1 nov 12:59), incident 2 = `/mnt/stuff/gpt-2026-11-03/`.

Legat: [[games-ext4-migration-plan]], [[root-via-pkexec-not-sudo]].
