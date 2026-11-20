---
name: system-update-2026-10-18
description: "Update complet Kali 2026-10-18 — reteta sigura (simulare fara root pe liste private + script pkexec cu garzi), ce e tinut pe loc (hold Hyprland) si ce a ramas"
metadata:
  node_type: memory
  type: project
  originSessionId: b3281538-7b9f-4b05-a750-9ffaf7cff688
  modified: 2026-10-18T17:57:44.443Z
---

2026-10-18, userul: „search for updates for my os and also all the programs and let's do it safely”. Facut, STATUS OK:
601 pachete (systemd 261->262, libc6 2.43-6, Plasma 6.6.5->6.7.4, python3.14 3.14.7-4, setuptools 84 = fara
pkg_resources), nodejs 20 -> **24.22.0 NodeSource** (npm 11.19.1, userul a ales asta), Spotify 1.2.95, sysmonforlinux
1.5.3, Teams 2.25.0 (.deb GitHub), starship 1.27.0, GE-Proton11-9 (langa 11-7, POE ramane pe 11-7), rustc 1.99.1.
Firmware (fwupd/LVFS): nimic nou. Kernel 7.1.5 si NVIDIA 550 NU s-au schimbat. Backup + log + `revino-apt.sh`:
`~/.config-backups/pre-update-2026-10-18_20-51-55/`; starship vechi in `~/.config-backups/pre-update-user-2026-10-18/`.

**Reteta (refoloseste-o):** simulare FARA root pe liste private — in zsh `${=APTOPT}` (zsh nu sparge variabilele!),
cheile sunt `Dir::State::lists` (litera mica), `Dir::Cache`, `Dir::Cache::pkgcache`, `Debug::NoLocking=1`,
`APT::Sandbox::User=$USER`, plus `Dir::Etc::sourcelist/sourceparts/preferences/preferencesparts` ca sa simulezi exact
starea finala. Apoi UN script pkexec in fundal: preflight (fuser lock, dpkg --audit, spatiu, sha256+amprente chei) ->
backup /etc + lista pachete -> modificari -> `apt-get -s` de control care opreste daca eliminarile difera de cele verificate
sau apare kernel/nvidia/kitty/aquamarine/quickshell/grub -> `full-upgrade` cu `--force-confdef --force-confold` ->
sha256 pe fisierele patch-uite de noi. Fara autoremove.

**HOLD activ: `hyprland` + `hyprland-guiutils`.** Kali 0.56.2+ds-3 e acelasi upstream, doar recompilat pe
`libaquamarine14` 0.15.1, FARA patch-ul mgpuwait -> ar reveni patratele violet pe Samsung ([[hyprland-43pr-on-kali]]).
Pentru unhold: porteaza `mgpu-blit-wait.patch` pe aquamarine 0.15.1, construieste libaquamarine14 +mgpuwait, abia apoi
`apt-mark unhold`. Verificat dupa upgrade: Hyprland -> libaquamarine.so.13 (sha256 neschimbat), `ldd -r` 0 simboluri
nedefinite (Hyprland, hyprlock, qs, portal, hyprland-dialog) cu libhyprutils 0.14.2, `LD_BIND_NOW=1 --verify-config` ok.

**Ramase / observate:** `openssh-client-gssapi` 10.3 tinut inapoi de apt (upgrade-ul ar scoate openssh-client — lasat asa);
Postgres „collation version mismatch 2.38 vs 2.43” (preexistent, apare la postinst faraday; fix = REINDEX + `ALTER
DATABASE ... REFRESH COLLATION VERSION`, neaplicat); kernel-uri vechi 6.16.8/7.0.12 + llvm 16-18 = candidati autoremove,
neatinsi; dotnet 6 (Microsoft) e EOL fara update; restart recomandat (libc/systemd/dbus/Plasma). Osiris testat pe Node 24
doar la rulare (server standalone 200 + css 200), nu `npm run build`. Kitty/aquamarine patch-uri intacte, hook opt-2 a rulat.
**De verificat la urmatoarea sesiune (dupa restart):** sesiunea Hyprland porneste si Samsung-ul e fara patrate violet (hold-ul tine
libaquamarine13); Spotify repornit pe 1.2.95; sesiunea Plasma 6.7 cu CyberGlass ([[kali-glass-kde-setup]]).
Vezi [[broken-third-party-apt-repos]], [[no-chaining-off-apt-update]], [[root-via-pkexec-not-sudo]].
**1 nov ~16:05 simulare:** 730 upgrade, 19 noi, 7 eliminari (libblosc2-7, libfalcosecurity0t64, libpyside6/libshiboken6 6.10, postgresql-16/17-pg-gvm, libgvm22t64 -> gvmd afectat), quickshell 0.3.1->0.3.2, libc6 2.43-7; liste private in scratchpad apt-sim.
**1 nov 2026 ~16:20 — update pregatit, userul a ales „update + un restart”** (restartul readuce si ecranul laptopului blocat de
DPMS, vezi [[nvidia-primary-test]]). Script `~/src/legion/update-sistem.sh` (ruleaza userul in kitty: `pkexec /bin/bash ...`):
verificari, backup /etc+selectii+sha aquamarine/kitty, **hold quickshell** (0.3.2 netestat cu bara 43PR) + hold-urile existente,
apt-get update (exit != 0 doar avertizeaza), simulare de control: opreste daca apar eliminari in afara celor 7 asteptate sau
Inst pe linux-image/nvidia/kitty/aquamarine/quickshell/grub/hyprland; full-upgrade cu confdef/confold, NEEDRESTART_MODE=l.
Logica testata in BASH (in zsh testul da fals STOP: zsh nu sparge variabilele). Dupa restart de verificat: NVIDIA-primar automat,
ecran laptop (hzprobe eDP-1), /mnt/games pe p11, C: ntfs-3g + bind-uri, bara quickshell, apoi test suspend cu NVIDIA-primar.
**1 nov 16:14 — rularea reala s-a OPRIT corect la verificare** (nimic instalat): oglinda kali.download diferita de simularea de la
16:05 -> 350 upgrade, 382 KEPT BACK (tranzitie Qt/KDE in curs: dolphin, kate, konsole, kwin, libkf6*...), 6 eliminari incl.
**virtualbox-qt** (virtualbox 7.2.16 -> 7.2.20, GUI 7.2.20 lipsa; virtualbox-dkms e deja 7.2.20 = deja nepotrivit cu userland 7.2.16).
Recomandat: asteapta 1-2 zile sa se termine tranzitia, apoi acelasi script (reutilizabil). quickshell RAMANE pe hold (pus de script).
Log: ~/.config-backups/pre-update-2026-11-01_16-13-54. Restart separat pt ecranul laptopului.
**1 nov ~16:40 re-simulare:** identic (350 upgrade, 382 retinute Qt/KDE, virtualbox-qt tot ar fi sters) -> tot neinceput, de reincercat peste 1-2 zile.
**1 nov ~16:50 — CORECTURA: NU era tranzitie Kali.** Cauza celor 382 retinute + virtualbox-qt sters = HOLD-ul MEU pe quickshell:
quickshell 0.3.1 cere `qt6-base-private-abi (= 6.10.2)` + declarative; 0.3.2 e recompilarea pt Qt 6.11.2 (deja pe server).
Hold-ul tinea tot Qt pe 6.10 => KDE kept back, virtualbox-qt 7.2.20 (Qt 6.11) imposibil. Dovada: simulare pe copie a
/var/lib/dpkg/status fara hold (atentie: copiaza si /var/lib/dpkg/arch langa status, altfel apt pierde i386 -> steam-installer
„not installable”) = 730 upgrade, 19 noi, exact cele 7 eliminari, virtualbox-qt UPGRADE, 3 retinute (hyprland x2 + openssh-gssapi).
**Lectie: NU pune hold pe pachete legate de ABI-ul privat Qt (quickshell, kwin, etc.) — blocheaza tot Qt.** `--ignore-hold` NU a schimbat
rezultatul simularii (nu te baza pe el). Scriptul corectat: `apt-mark unhold quickshell`, quickshell scos din GUARD (v1 in update-sistem.sh.v1).
**1 nov 16:25 — UPDATE APLICAT CU SUCCES** (log/backup `~/.config-backups/pre-update-2026-11-01_16-25-06`): 730 upgrade, 19 noi,
exact cele 7 eliminari; dpkg --audit curat; sha aquamarine + kitty NESCHIMBATE; hold ramas: hyprland, hyprland-guiutils.
Versiuni: quickshell 0.3.2-1, Qt 6.11.2, virtualbox + virtualbox-qt 7.2.20 (Extension Pack 7.2.20 usable; erorile VBoxManage =
dezinstalarea pachetului vechi cu numele „Oracle VM ...”, inofensiv), libc6 2.43-7. Avertisment Postgres collation mismatch =
preexistent. RESTART cerut. Dupa restart de verificat: bara qs 0.3.2/Qt 6.11, NVIDIA-primar, regula microfon (pipewire-pulse nou
porneste cu block-source-volume), montari, modul vboxdrv.
**1 nov 18:24 — RESTART VERIFICAT:** kernel 7.1.5, Hyprland pe NVIDIA (`Explicit device list card1:card0`), hzprobe: Samsung
~240 cadre/s 100% la timp (latenta 8 ms), laptop 144 100% (10.3 ms); bara qs 0.3.2/Qt 6.11 randeaza, log fara erori QML; montari
/mnt/games ext4 + C:/STUFF ntfs-3g + bind-uri Steam ok; vboxdrv/ntsync/zram/kyber incarcate; NVIDIA 610 P5 900 MHz (podeaua);
erorile de boot (PAM pam.d, gkr-pam keyring, ACPI AE_NOT_FOUND, kvm_amd) = preexistente in boot-urile vechi.

**20 nov 2026: update nou pregatit** — ~/src/legion/update-sistem-2026-11-20.sh (simulare fara root: 532 upgrade, 34 noi, 0 eliminari).
NOU: kernel 7.2.15 (langa 7.1.5; mai sunt 6.16.8 si 7.0.12) -> dupa upgrade verifica nvidia.ko DKMS (610.57.04, nvidia-kernel-open-dkms)
pt kernelul nou + initrd; daca lipseste: dkms autoinstall o data, altfel GRUB_DEFAULT="submenu>intrarea $OLDK" + update-grub.
libaquamarine14 (cerut de libhyprtoolkit6) se instaleaza LANGA libaquamarine15 (al nostru) — permis; GUARD: nvidia|libnvidia|kitty|
libaquamarine15|libaquamarine-dev|grub|hyprland|quickshell. / la 91% (9G liberi). APLICAT 20 nov 20:22-20:4x (backup pre-update-2026-11-20_20-22-44): dpkg curat, aquamarine15+kitty neschimbate, hyprland 0.57 local + hold ok, NVIDIA 610 + VirtualBox compilate pt 7.2.15, initramfs ok; liber pe / 4.9G (de curatat: kernel 6.16.8, apt cache). RESTART 20:30 VERIFICAT: kernel 7.2.15, NVIDIA 610 P0, Hyprland 0.57, 2 monitoare 239/144 Hz, bara 0 erori, audio (Buds), nftables activ, sysctl hardening + xrdp/docker oprite persistente. Avertisment nou inofensiv: „PAM (systemd-user) /usr/lib/pam.d is not supported” — systemd 262/polkitd 128 pun PAM in /usr/lib/pam.d, libpam 1.7.0-8 il ignora -> fallback /etc/pam.d/other (common-*), functioneaza. Curatenie oferita: ~/src/legion/curatenie-disc-2026-11-20.sh (apt clean 8.1G + kernel 6.16.8/7.0.12), / la 95%.
