---
name: sleep-resume-test-recipe
description: "Cum testezi suspend/resume pe laptop fara sa ramai blocat — alarma RTC + systemctl suspend din pkexec, script in fundal, cum masori cat a dormit si cine l-a trezit"
metadata:
  node_type: memory
  type: reference
  originSessionId: 7a8ecda0-ab91-40f7-9769-7088436223a1
  modified: 2026-10-17T10:14:17.337Z
---

Folosit prima data 2026-10-17 pentru [[gpu-mgpu-floor-service]]; Din 17 oct default = s2idle (sleep.conf.d), fiindca S3/deep se trezea singur dupa 6-10 s (EC/firmware). In s2idle `/sys/power/pm_wakeup_irq` arata IRQ-ul; `echo 1 > /sys/power/pm_debug_messages` da „Triggering wakeup from IRQ N” in jurnal. `journalctl --since` da fals „No entries” (ceasul de la boot e decalat) — foloseste `-b -n N | awk`.

- **Pornire:** `pkexec sh -c 'rtcwake -m no -s 40 && systemctl suspend'`. NU `rtcwake -m mem`: scrie direct in
  /sys/power/state si sare peste systemd-sleep (hook-urile din /usr/lib/systemd/system-sleep si serviciile nvidia-*).
  rtcwake zice „assuming RTC uses UTC” (lipseste /etc/adjtime); cu `-s` relativ nu conteaza. pkexec, nu sudo
  ([[root-via-pkexec-not-sudo]]).
- **Ruleaza-l ca script cu `run_in_background`** si incheie tura: nu ramane un request API in zbor peste sleep, iar
  notificarea te re-invoca dupa resume. Scrie si un log cu `tee` (supravietuieste daca pica Hyprland/sesiunea).
- **Detectezi revenirea** cand se schimba `/sys/power/suspend_stats/success` sau `fail` (poll 0.2 s).
- **Cat a dormit:** CLOCK_BOOTTIME − CLOCK_MONOTONIC (cumulat pe boot). Timestamp-urile din jurnal pentru mesajele
  kernel de dinainte de sleep sunt cele de la revenire, deci nu te baza pe ele.
- **Cine l-a trezit:** `/sys/power/pm_wakeup_irq` e gol la S3 si `wakeup_count` ramane 0. Sorteaza
  `/sys/class/wakeup/*/last_change_ms` (MONOTONIC, nu uptime). Alarma rtc_cmos apare acolo chiar daca a sunat dupa
  revenire. Dispozitive cu trezire: `/proc/acpi/wakeup` si `power/wakeup` din USB.
- `journalctl --since @t0` prinde si linii de la boot cu ceasul decalat (+3h, RTC de la Windows); ignora-le.
- Fara hypridle, deci la revenire nu apare ecran de blocare.
