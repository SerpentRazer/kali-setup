---
name: journal-flood-nvtop-nvidia
description: Jurnalul systemd ajunsese la 1.6 GB din cauza nvtop — fiecare rulare declanseaza un WARNING de ~50 linii in nvidia-drm 550; curatat 2026-10-16 (vacuum 7d)
metadata:
  type: project
---

2026-10-16: `journalctl --disk-usage` = 1.6 GB adunati in 3 saptamani (28 sep - 3 oct + 16 oct). 97% erau linii de kernel:
69.084 x `WARNING: nvidia-drm/nvidia-drm-drv.c:1226 at nv_drm_revoke_modeset_permission [nvidia_drm]` cu stack trace complet
(~50 linii fiecare). **67.098 dintre ele le declansa `nvtop`** (deschide device-ul DRM NVIDIA la fiecare citire; interactiv
~3 avertismente/s). Sursele periodice erau scripturile vechi ale temei (`nvtop -s` in gpu_usage.sh / SystemPage); dupa
update-ul 43PR bara si SystemPage folosesc `nvidia-smi` (NVML, fara avertisment) — vezi [[43pr-update-2026-10-16]].
Restul declansatorilor (Hyprland, kitty, qs, kwin nested, Xorg, brave) sunt rari: la deschiderea/inchiderea DRM.

**Facut:** `pkexec journalctl --vacuum-time=7d` -> eliberat 1.5 GB, ramas 48 MB (doar boot-ul curent; intre 3 si 16 oct nu
fusese pornit). Analiza rapida: `journalctl -o json --output-fields=SYSLOG_IDENTIFIER,MESSAGE` + numarare pe identificator;
pt kernel pe toate boot-urile `journalctl _TRANSPORT=kernel` (`-k` inseamna doar boot-ul curent).

**Oferit, neaplicat:** plafon `SystemMaxUse=500M` in `/etc/systemd/journald.conf.d/` (pkexec); in loc de nvtop -> btop 1.4.7
are NVML (adauga `gpu0` in `shown_boxes` din ~/.config/btop/btop.conf). Driver NVIDIA >= 555 ar repara probabil avertismentul,
dar Kali are doar 550 ([[hyprland-lua-native-config]]).

**Observat in treacat:** la boot ceasul pornea cu +3h (intrari la 23:29 inainte de sincronizarea NTP): Windows (dual boot)
tine RTC-ul pe ora locala, Kali il citeste ca UTC. Fix recomandat in Windows: `RealTimeIsUniversal=1` in
HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation (alternativa Linux `timedatectl set-local-rtc 1` e descurajata).
Vezi [[gaming-windows-steam-on-kali]].
