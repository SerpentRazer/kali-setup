---
name: hyprland-057-local-build
description: "15 nov 2026: Hyprland 0.57 construit LOCAL din sursele Debian sid (Kali avea doar 0.56) pe aquamarine 0.16 + patch mgpuwait portat; gpu-screen-recorder 5.13.8 (.deb) + mpvpaper 1.9; teste izolate; F4 = instalare cu sesiune de rezerva 0.56"
metadata:
  type: project
---

Totul in `~/src/legion/hypr-057/` (src/ = surse Debian verificate sha256 din .dsc + .deb-uri; rollback/ = dpkg-repack al stack-ului 0.56:
hyprland 0.56.2+ds-1, hyprland-guiutils, libaquamarine13 0.14.0-2+mgpuwait1, libhyprutils13/-dev 0.14.2).
- **aquamarine 0.16.0-1+mgpuwait1** (libaquamarine15, soname nou, coexista cu .so.13): patch-ul mgpuwait reconstruit ca diff fata de 0.14.0 orig
  (doar DRM.cpp + Renderer.cpp, 66 linii), portat (hunk-ul cu explicitInFence adaptat de mana) -> `debian/patches/mgpu-blit-wait.patch`.
  Construit de mine (aquamarine a fost permis); Hyprland/gsr/mpvpaper: auto mode a REFUZAT compilarea ([Unauthorized Access]) -> `f3-compileaza.sh` rulat de user.
- **F2** `f2-dependinte.sh` (rulat 15 nov): dependinte build; ATENTIE libmpv-dev trage libjack-dev care STERGE libjack-jackd2-0 -> adaugat libjack-jackd2-dev.
- **Hyprland 0.57.0+ds-1+local1**: `--verify-config` pe config-ul userului = ok. Test nested (kwin --virtual pe NVIDIA + bwrap): CRASH bad_any_cast in
  CMonitorResources::initFB DOAR pt ca hyprland.lua seteaza AQ_DRM_DEVICES=/dev/dri/card0 -> instanta nested deschidea si DRM-ul real fara master; cu
  hl.env stub pt AQ_DRM_DEVICES config-ul complet porneste curat (0 configerrors). Bara qs pe 0.57 (test-izolat-057.sh) = identica cu 0.56.
- gpu-screen-recorder: doar `-cli` (NU `-mod`: NVreg_PreserveVideoMemoryAllocations=1 era deja setat) + `setcap cap_sys_admin+ep /usr/bin/gsr-kms-server`.
- **F4** `f4-instaleaza.sh`: sesiune SDDM „Hyprland 0.56 (rezerva)” = binarul 0.56 copiat in /usr/local/lib/hyprland-0.56-rezerva; revino.sh in
  ~/.config-backups/pre-hyprland-057-*; hold dupa: hyprland, hyprland-guiutils, libaquamarine15, libaquamarine-dev. mpvpaper -> ~/.local/bin.
STARE: **F4 RULAT 15 nov 19:54** (backup+revino.sh `~/.config-backups/pre-hyprland-057-2026-11-15_19-54-54`; rezerva 0.56 verificata ca user: --version + config ok; „CRIT” vazut in script = Hyprland refuza root, inofensiv). **VERIFICAT dupa relogin 15 nov 19:56**: Hyprland 0.57.0 ruleaza (watchdog), HDMI-A-1 239.76 + eDP-1 144, 0 configerrors, 0 EBUSY, „Found 1 GPUs”; qs ok + 1 nvidia-smi; gpu-screen-recorder -w HDMI-A-1 inregistreaza 60 fps fara parola (setcap); mpvpaper in PATH-ul qs. mpvpaper TESTAT 15 nov 20:03 (video de test, ambele monitoare pe stratul de wallpaper, NVDEC 11%, CPU 15%, userul l-a vazut) — direct, fara commands.sh (care ruleaza si theme.py). OCR TESTAT 15 nov 20:06 cap-coada (slurp fals cu zona fixa): text normal citit exact; text mic din bara = gunoi -> adaugat `grim -s 2` in ~/.config/hypr/scripts/ocr-area.sh (backup ocr-area.sh.pre-scale-* in ~/.config-backups; copiat si in staging merged/) => „CPU 6% GPU 18% RAM 32% CPUT 47°C GPUT 44°C” exact. Reaplica `-s 2` la merge 43PR. Ramas netestat: CS2 tearing pe 0.57 (activelyTearing in hyprctl monitors cat ruleaza jocul). ATENTIE terminologie: userul zice „tearing” la sacadari/lag — 15 nov: „tearingul a disparut cand l-am mutat pe ext4” = sacadarile; i-am explicat diferenta, test oferit la urmatoarea pornire CS2. (vechi: relogin + verificat (hyprctl version, bara, OCR, SUPER+R inregistrare, wallpaper video, CS2 tearing).
Legat: [[43pr-update-2026-10-16]], [[system-update-2026-10-18]], [[hyprland-43pr-on-kali]], [[hybrid-mode-off-dgpu-only]].
