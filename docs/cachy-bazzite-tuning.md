---
name: cachy-bazzite-tuning
description: 30 oct — tweak-uri din CachyOS-Settings + Bazzite aplicate pe Kali (zram zstd, sysctl, ntsync, kyber, jurnal, coredump, NVIDIA); ce s-a respins si de ce; optiunile mari ramase (driver ntfs kernel, scx_lavd, Timeshift)
metadata:
  type: project
---

**Cerere (30 oct):** „nu putem tweak-ui kali precum cachy os sau bazzite... sa gasim ceva folositor si sa optimizam”.
Surse citite direct (nu din memorie): CachyOS-Settings f79b237 (22 oct 2026), Bazzite ef7938c (30 oct 2026), in
scratchpad-ul sesiunii. Script: `~/src/kali-tune/apply-cachy-bazzite.sh`; backup + `revino.sh`:
`~/.config-backups/pre-cachy-bazzite-2026-10-30_22-05-39/` (`pkexec /bin/bash .../revino.sh` + reboot).

**Aplicat + verificat live 30 oct 22:05:** zram0 zstd 7.7G prio 100 (`/etc/systemd/zram-generator.conf`, pachet
systemd-zram-generator 1.2.1), swap disc 977M ramane la -1; swappiness 150 doar cu zram activ (`/etc/udev/rules.d/30-zram.rules`);
`/etc/sysctl.d/70-cachy-bazzite.conf` (vfs_cache_pressure 50, dirty 256M/64M, page-cluster 0, watermark boost 0/scale 125,
split_lock_mitigate 0, nmi_watchdog 0, sysrq 1, inotify 8192/524288); `/etc/modules-load.d/cachy-bazzite.conf` (ntsync,
kyber-iosched) -> /dev/ntsync 0666, GE-Proton11 pune WINENTSYNC=1 singur; NVMe pe kyber (`60-ioschedulers.rules`, sda ramane
mq-deadline); jurnal 500M; coredump 3d (erau 1.8G/33 fisiere); `/etc/modprobe.d/nvidia-cachyos.conf`
InitializeSystemMemoryAllocations=0 (doar dupa reboot; nvidia nu e in initramfs).
**Capcana:** postinst-ul systemd-zram-generator face daemon-reload si systemd PORNESTE zram0 pe loc cu implicitul
(/usr/lib: 4G lz4) -> config-ul + regula udev trebuie scrise INAINTE de apt install (reparat in script; live refacut cu
`fix-zram-restart.sh`: stop dev-zram0.swap + stop setup + daemon-reload + start).

**Masurat inainte (onest = asigurare, nu reparatie):** 0 evenimente split lock in 14 boot-uri, 0 OOM, PSI memorie 0;
shutdown-uri de 1-2 s (de aceea NU am scurtat DefaultTimeoutStopSec). Deja la fel ca la ei: THP defer+madvise, MGLRU,
max_map_count 1048576, preempt lazy. Respins: BBR (afecteaza doar upload-ul), systemd-oomd (risc sa omoare jocul),
kernel CachyOS/BORE (nu exista pt Debian + recompilare NVIDIA 610 abia stabilizat), pachete x86-64-v3 (tot Kali recompilat).
`apt` `scx` 1.9.4.0 = agentul Microsoft SCOM, NU sched_ext!

**PENDING dupa reboot:** zram tot zstd 7.7G + swappiness 150, kyber, ntsync incarcat, `/proc/driver/nvidia/params`
InitializeSystemMemoryAllocations: 0. La primul POE: `ls -l /proc/<pid>/fd | grep ntsync`.
**Optiuni mari, nedecise:** (1) driverul kernel `ntfs` read-write (Namjae Jeon) EXISTA in 7.1.5 -> posibil fix pt
crash-urile POE pe ntfs-3g FUSE ([[gaming-windows-steam-on-kali]]); test intai ro pe STUFF, apoi rw. (2) scx_lavd: kernelul
are SCHED_CLASS_EXT=y + BTF, binarul se compileaza din sursa (rust 1.99 instalat). (3) Timeshift instalat dar 0 snapshot-uri;
sistemul ~36G vs 26G liberi pe / -> nu incape fara curatenie (kernel-uri 6.16.8/7.0.12, autoremove).
Vezi [[root-via-pkexec-not-sudo]], [[nvidia-610-upgrade]].

**30 oct 22:13-22:15 — test ro driver kernel `ntfs` vs ntfs-3g pe STUFF (sda1, SSD SATA), 3 rulari fiecare, ordine
alternata, cache golit (umount + blockdev --flushbufs):** scripturi + JSON in `~/src/kali-tune/ntfs-test/` (bench.py =
AoE2DE 21540 fisiere + VPK-urile CS2 Windows 43.8 GB). Mount kernel: `mount -i -t ntfs` (FARA `-i` porneste ntfs-3g:
/sbin/mount.ntfs -> mount.ntfs-3g!). Zero erori kernel, volum curat la probe. Mediane kernel vs ntfs-3g: 8 fire random 64K
**177 vs 88 MB/s** (p50 2.7 vs 5.5 ms), secvential **408 vs 285 MB/s**, fara blocajele ntfs-3g (walk max 6.5 vs **115 ms**,
reproductibil; fisiere mici max 2.7 vs 43 ms); DAR metadate mai lente: walk 21540 stat 1.76 vs 1.24 s, open+read 3000
fisiere mici 2.93 vs 2.24 s (p99 2.3 vs 1.4 ms); CPU total mai mic (ntfs-3g +0.7 s daemon/rulare). Niciun driver n-a avut
blocaje de secunde -> testul NU dovedeste fix-ul POE (acela a fost pe C: NVMe sub joc). Pasul urmator propus: rw pe STUFF
intr-un folder de test (checksum-uri recitite cu ntfs-3g, chkdsk la urmatorul Windows), abia apoi C: cu errors=remount-ro.

**30 oct 22:20 — test SCRIERE kernel `ntfs` pe STUFF: TRECUT** (`run-rw-test.sh` + `stress.py`, rezultate in
`~/src/kali-tune/ntfs-test/rw-results-2026-10-30_22-20-26`): 4547 fisiere (unicode/emoji, 3000 intr-un dir, sparse alloc 12K
din 300M, trunc, mmap, fallocate, rename/replace, hardlink, symlink WSL) -> sha256 identic recitit cu kernel ro SI ntfs-3g ro;
probe=0 dupa fiecare umount, `ntfsfix -n` ok, 0 erori kernel, fara remount-ro; stergere bulk ok, spatiu -175 MiB = keep/ +
MFT. **`/mnt/stuff/_kali-ntfs-test/keep` (~150 MiB) LASAT pt `chkdsk <litera STUFF>: /scan` in Windows — PENDING.** Scriere:
fara fsync 1 GiB 2.3 s; writebench 1 GiB+fsync = 20.4 s (kernel, imediat dupa stergerea a 1.6 GB in ACELASI mount) vs 2.5 s
ntfs-3g. Re-test pe mount proaspat (`fsync-results-2026-10-30_22-23-19`, `fsyncprobe.py`): kernel = ntfs-3g (1G+fsync 5.4 vs
5.3 s, 256M 1.33 vs 1.30, fsync la 64M 2.55 vs 2.50) -> cei 20 s nu se repeta pe mount curat; suspect flush de metadate dupa
stergeri mari, nereprodus. NVMe kyber vs none la fsync = identic dupa prima rulare (kyber OK). C: inca pe ntfs-3g.

**30 oct 22:27-22:40 — verificare structura STUFF FARA Windows:** `ntfsck -n` (ntfsprogs-plus 1.0.0-5 EXTRAS in
`~/src/kali-tune/ntfsprogs-plus/`, NU instalat: pachetul Conflicts ntfs-3g -> ar scoate ntfs-3g+testdisk!) rulat pe
`losetup -r` (0 scrieri pe sda): exit 4, 188 erori = TOATE PREEXISTENTE: 81 inregistrari MFT sterse cu bitul ramas setat =
fisiere Civilization VI din 15 mai 2026; 1 orfan `Easy way to quit smoking- Allen Carr.pdf` (394 KB, 12 mar 2025, apartine
/mnt/stuff/Books, invizibil). Contabilitate clustere proprie (`bitmap-audit.py` pe dump `ntfscat` prin loop ro -> NB: ntfscat
livreaza inregistrarile cu fixup-urile deja aplicate): **0 clustere folosite-dar-libere, 0 cross-link** pe 160440 fisiere vii
(inclusiv cele scrise de kernel); 41.8 GiB ocupati fara proprietar (preexistent: du ntfs-3g 167.41M clustere vs audit 167.53M =
metafisiere; keep/ 174.6 MiB vs 175.3 MiB disparuti in test). De oferit userului: `chkdsk /f` pe STUFF din Windows (recupereaza
~42 GiB + PDF-ul). fstab NU are echivalent pt `mount -i` -> pt C: pe driverul kernel: `dpkg-divert` pe /usr/sbin/mount.ntfs
(atunci `-t ntfs` = kernel si pt udisks/USB; ntfs-3g ramane ca `-t ntfs-3g`).

**30 oct 22:37 — C: MUTAT pe driverul kernel `ntfs`** (userul: „da, mergi pe C:”). `switch-c-kernel.sh`; backup fstab +
`revino.sh`: `~/.config-backups/pre-c-kernel-ntfs-2026-10-30_22-36-56/` (`pkexec /bin/bash .../revino.sh` cu Steam inchis).
`dpkg-divert --local --rename` /usr/sbin/mount.ntfs -> mount.ntfs.ntfs-3g (deci `-t ntfs` = kernel, si pt stick-uri USB prin
udisks; STUFF ramane `ntfs-3g` explicit). fstab C: = `ntfs uid=1000,gid=1000,umask=022,windows_names,noatime,errors=remount-ro,
nofail,x-systemd.device-timeout=10`. Bind compatdata + /mnt/games (loop ext4 CS2) remontate peste el, ok.
**Capcana:** `fuser -m` pe bind-ul compatdata (bind din root ext4) listeaza TOATE procesele sistemului -> prima rulare s-a
oprit la preflight fara schimbari; verifica doar /mnt/games si /mnt/windows.
**Referinta C: inainte (volum demontat, loop ro, 0 scrieri):** `~/.cache/c-ntfs-baseline-2026-10-30_22-36-56/` (mft.bin 724 MB,
bitmap.bin, ntfsck.txt). bitmap-audit: 534277 fisiere vii, clustere folosite = ocupate = 76055104 EXACT (0 pericol, 0 pierdut).
ntfsck -n exit 4 / 373 „erori” = 345 marimi $FN lenese in indexuri (normal Windows) + 51 inregistrari in uz FARA $FILE_NAME
(0x10/0x50/0x80, sterse-cat-erau-deschise de Windows) + 48 diferente bitmap din cauza lor. **NU rula ntfsck cu reparare pe
C:** — curatenie doar cu chkdsk din Windows. PENDING: userul joaca POE (oras/stash/harti) + CS2; apoi re-audit C: (Steam
inchis, demontare) si comparare cu referinta; reboot de confirmare (montare la boot prin fs-ntfs autoload).

**31 oct — reboot de confirmare:** kyber, ntsync (/dev/ntsync 0666), InitializeSystemMemoryAllocations 0, C: montat la boot
pe kernel `ntfs` (0 erori) = OK. **zram NU a pornit** (swappiness 60, doar swap disc): generatorul a rulat la boot dar n-a
scris unitati (iesirile „No devices”/„Running in a container” sunt debug = invizibile; zstd neincarcat, zram incarcat abia de
modules-load => a iesit inainte de handle_device); manual (user) merge. Fix pregatit `~/src/kali-tune/fix-zram-boot.sh`
(unitati statice in /etc/systemd/system + diagnostic + revino.sh) — auto mode a refuzat pkexec-ul, dat userului cu `!`.
**Re-audit C: dupa CS2 (30 oct 23:40, `~/.cache/c-ntfs-after-2026-10-30_23-40-21`):** 0 pericol/0 cross-link, DAR 79
inregistrari MFT noi „in uz fara $FILE_NAME” (seq neschimbat) = BUG driver kernel `ntfs` la stergere: toate atinse la 22:40:39
cand pressure-vessel a sters `SteamLinuxRuntime_soldier/var/tmp-MJAUW3` (creat de ntfs-3g pe 3 oct). 56/141 fisiere cu
$ATTRIBUTE_LIST au ramas agatate (header links 3 -> 1, nume sterse), 0/1945 rezidente simple; dirs si hardlink-uri multiple ok.
Analiza: `~/src/kali-tune/ntfs-test/orphan-paths.py`, `orphan-traits.py`. Inofensiv pt alte fisiere (chkdsk le curata), dar
se repeta la fiecare pornire de joc (var/tmp-* ~600 MB/runtime). Propus userului: SteamLinuxRuntime_{4,sniper,soldier} pe ext4
(bind ca compatdata) / inapoi pe ntfs-3g / chkdsk periodic. PENDING decizia.

**31 oct — userul a ales varianta 1: runtime-urile Linux Steam de pe C: pe ext4 (in curs).** Copiate ca user cu
`rsync -aH --exclude='/var/tmp-*'` in `~/.local/share/steam-runtimes-c/SteamLinuxRuntime_{4,sniper,soldier}` (2.1 GB,
12 s); sha256 identic pe 24082 fisiere, 0 erori. Pe C: NU sterg nimic (stergerea = bug-ul); originalele raman sub bind
(fallback daca bind-ul pica, nofail). var/tmp-* = doar hardlink-uri spre *_platform_*/files, refacute de pressure-vessel.
**Bug 2 driver kernel `ntfs`:** symlink-urile create de ntfs-3g in format Interix (`IntxLNK` + tinta UTF-16) apar ca
FISIERE NORMALE (~100 B) — cele 6 `type=link` din `mtree.txt.gz` per runtime (pressure-vessel{,-arm64}/bin/srt-logger,
srt-logger-0.bash, steam-runtime-launcher-service). Symlink-urile create de driverul kernel (1832 in var/tmp-MV2BY3) sunt ok.
In copie le refac din mtree, apoi `pressure-vessel/bin/pv-verify <dir>` (verifica tot runtime-ul fata de mtree).
**Ramas:** script root (fstab: 3 linii bind ca la compatdata, `none bind,nofail,x-systemd.requires=/mnt/windows`, spatii =
\040; mount; revino.sh) dat userului cu `!` (auto mode refuza pkexec); test pornire joc + verificat ca var/tmp-* noi apar pe
ext4. Runtime-uri NOI instalate de Steam pe C: (ex. _5) ar ajunge iar pe NTFS. Originalele de pe C: de sters doar cu
ntfs-3g sau din Windows. Capcana: `fuser -m` pe bind din / listeaza tot sistemul.
**31 oct (continuare):** cele 6 Interix refacute ca symlink-uri reale in copie (tinta decodata = mtree), platformele vechi
`*_platform_*20260805` (neincluse in mtree, nereferite) mutate in `~/.local/share/steam-runtimes-c/.platforme-vechi/` ->
`pv-verify` exit 0 pe toate 3 copiile; pe originalul C: pica (cele 6 „not a symlink”). Script root GATA
`~/src/kali-tune/bind-steam-runtimes.sh` (garzi Steam/pressure-vessel/fstab dublat, backup fstab + revino.sh in
`~/.config-backups/pre-steam-runtimes-ext4-*`, revenire automata daca un bind nu iese ext4; fstab scris cu printf — `echo`
din zsh transforma `\040` in spatiu = parse error). Liniile noi trec `findmnt --verify` (cele 3 avertismente = preexistente).
PENDING: userul ruleaza cu `!` fix-zram-boot.sh + bind-steam-runtimes.sh, apoi test joc (var/tmp-* noi pe ext4) si reboot.
**31 oct 23:55 — AMBELE RULATE de user, OK.** zram: diagnostic ca root = detect-virt „none”, generatorul la daemon-reload
SCRIE unitatea (deci problema e doar la boot, cauza necunoscuta); unitati statice active (FragmentPath /etc), zram0 zstd 7.7G
prio 100, swappiness 150, zswap N; backup `~/.config-backups/pre-zram-static-2026-10-31_23-54-57`. Runtime-uri: 3 mount-uri
systemd active (ext4 din nvme0n1p6), pv-verify exit 0 prin calea de pe C:; backup
`~/.config-backups/pre-steam-runtimes-ext4-2026-10-31_23-55-25`. PENDING: pornire joc (var/tmp-* noi trebuie sa apara pe
ext4, 0 mesaje ntfs) + reboot (zram + bind-uri singure la boot).
**31 oct 23:59 — test CS2 (scurt, 23:59:09-23:59:26) OK:** var/tmp-* noi DOAR pe ext4 (_4: 4 la pornirea Steam 23:56,
sniper: 1 pt CS2 = sniper), 0 mesaje kernel ntfs/ext4, 0 Xid/sg_table; abort gamescope + python la iesire = cunoscute;
„basename: extra operand 'Offensive/game/cs2.sh'” = si pe 30 oct (scriptul Valve, cale cu spatii), inofensiv. Ramane: reboot.
De urmarit: un re-audit C: (reaudit-c.sh) dupa cateva sesiuni ar trebui sa arate 0 inregistrari agatate NOI fata de 30 oct.
**1 nov 08:16 — REBOOT DE CONFIRMARE: TOTUL OK singur la boot.** zram0 zstd 7.7G prio 100 (dev-zram0.swap din /etc; de data
asta si generatorul a scris unitatea in /run/systemd/generator, /etc are prioritate), swappiness 150, disc 977M la -1; NVMe
kyber, sda mq-deadline; /dev/ntsync 0666; InitializeSystemMemoryAllocations 0 (610.57.04); C: pe kernel `ntfs` fara erori; cele
3 bind-uri SteamLinuxRuntime_* + compatdata pe ext4 (nvme0n1p6), /mnt/games loop ext4; 0 unitati failed, 0 Xid. Erorile din
jurnal = cunoscute (ACPI \_SB.PCI0, kvm_amd pe Intel, gkr-pam, BT HFP „Host is down”).
Ramase: la primul POE `ls -l /proc/<pid>/fd | grep ntsync`; reaudit-c.sh dupa cateva sesiuni de joc; chkdsk pe STUFF din Windows.
**1 nov ~08:30 — ntsync VERIFICAT fara POE:** GE-Proton11-7 prin SteamLinuxRuntime_4 `_v2-entry-point --verb=run` (headless,
prefix de unica folosinta, sters) -> „ntsync: up and running”, wineserver cu fd /dev/ntsync + ~460 obiecte, 7/7 procese
Windows, WINENTSYNC=1 in container. Singurul lucru care l-ar opri: PROTON_NO_NTSYNC=1 (nesetat). Verificare la un joc real:
`~/src/kali-tune/check-ntsync.sh` (rc 0 activ / 1 nefolosit / 2 niciun joc).
**1 nov — pregatit, un singur pkexec:** `~/src/kali-tune/ruleaza-tot-2026-11-01.sh` = (1) `gpu-cap-1500.sh`: NV_MAX 2100->1500
in /usr/local/sbin/gpu-mgpu-floor (backup+revino.sh in ~/.config-backups/pre-gpu-cap-1500-*); (2) `stuff-schedule-chkdsk.sh`:
ntfsfix pe sda1 = bit dirty -> autochk repara STUFF la URMATORUL BOOT WINDOWS; ntfs-3g refuza rw pe volum dirty -> STUFF ro
pana atunci (backup/log/revino.sh = ntfsfix -d in ~/.config-backups/stuff-chkdsk-*); dupa Windows: verifica keep/ cu
rw-results-2026-10-30_22-20-26/manifest.json, sterge `_kali-ntfs-test`, ntfsck -n + bitmap-audit; (3) `ntfs-test/reaudit-c.sh`
v2 (demonteaza/remonteaza toate cele 4 bind-uri; v1 pastrat .v1-2026-10-30). Compararea: orphan-paths.py <ref 30 oct 22:36>
<dupa> + fata de c-ntfs-after-2026-10-30_23-40-21.
**1 nov 08:31 — ruleaza-tot RULAT de user, toate exit 0.** GPU: lgc 900,1500 aplicat. **Re-audit C: (`c-ntfs-after-2026-11-01_08-31-12`):
0 inregistrari agatate NOI fata de 30 oct 23:40** (128 = 51 Windows + 77 din bug; numarate cu scratchpad nofn.py = in uz,
baza, fara $FILE_NAME si $ATTRIBUTE_LIST), bitmap-audit 218213119 clustere: 0 pericol, 0 cross-link, 0 pierdut; probe 0, 0
scrieri, e2fsck container CS2 curat => runtime-urile pe ext4 au oprit bug-ul. orphan-paths.py cere new-orphans.txt (pas
manual, nu-l rula direct pe un dump nou). **STUFF: CONFIRMAT de user 1 nov: `Volume Flags: 0x0001 DIRTY`** (ntfsfix a scos si bitul 0x0080 nedocumentat — ntfs-3g scrie flags & 0xC03F; Windows rescrie flag-urile la montare). Istoric: — ntfsfix 2026.7.7 nu afiseaza
nimic despre flag, ntfsinfo dupa n-a scos nimic (grep), ntfs-3g a montat rw; flags inainte 0x0080. Verificare:
`pkexec ntfsinfo -f -m /dev/sda1 | grep -i flags` (asteptat 0x0081).
**PENDING dupa primul boot Windows:** autochk repara STUFF (nu apasa nicio tasta) -> in Kali: flags fara DIRTY, keep/ vs manifest.json, sterge /mnt/stuff/_kali-ntfs-test, ntfsck -n + bitmap-audit pe STUFF.
**1 nov 2026 10:59:09 — C: (p4) pe driverul kernel `ntfs` a trecut singur in READ-ONLY** (errors=remount-ro): `map_mft_record():
Failed with error code 4` + `Marking corrupt inode 0x3fd15 as bad. Run chkdsk.` + stale reference (consecinta). -4 = EINTR
(probabil un proces omorat in mijlocul citirii MFT, tratat de driver drept coruptie) — nedovedit; boot-urile -1..-4 fara erori ntfs.
Imaginea /mnt/games (loop0, dio=0) a continuat sa scrie (contoare sectoare loop0 = p4), ext4 fara erori; biblioteca Steam 1 nescriibila.
Plan: `chkdsk C: /f` din Windows, intoarcere cu Restart. Al doilea semn rau pt driver (dupa MFT-urile agatate din 30 oct) ->
daca se repeta: ntfs-3g (revino.sh, + readauga bind-urile SteamLinuxRuntime_* in fstab) sau partitie ext4 nativa pt jocuri.
swappiness 150 -> 100 APLICAT 1 nov ([[fix-erori-2026-11-01]]). Planul pt C: + jocuri: [[games-ext4-migration-plan]] (F2 trece C: pe ntfs-3g si scoate dpkg-divert).
- **1 nov 13:24: C: inapoi pe ntfs-3g** (faza2-jocuri-ext4.sh D; dpkg-divert mount.ntfs scos -> si stick-urile USB merg iar pe ntfs-3g); linia veche comentata KALI-C-KERNEL-NTFS in fstab. Jocurile nu mai sunt pe C: -> [[games-ext4-migration-plan]].
