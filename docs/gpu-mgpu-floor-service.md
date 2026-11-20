---
name: gpu-mgpu-floor-service
description: Serviciul gpu-mgpu-floor (instalat 2026-10-17) tine Intel la 1450 MHz si NVIDIA >=900 MHz cat e conectat monitorul extern — a dublat fps-ul real pe Samsung (calea multi-GPU)
metadata:
  node_type: memory
  type: project
  originSessionId: c4cce747-bb74-444b-bb3b-6476c321c20b
  modified: 2026-10-17T10:17:27.141Z
---

**Ce face:** `/usr/local/sbin/gpu-mgpu-floor auto|apply|reset|status` — cand un monitor e conectat pe placa NVIDIA
(card1, Samsung pe HDMI-A-2): Intel `gt_min_freq_mhz` = RP0 (1450), `nvidia-smi -pm 1` + `-lgc 900,2100`; altfel reset
(RPn 350, `-rgc`, `-pm 0`) ca sa nu mance bateria fara monitor. Pornit de `gpu-mgpu-floor.service` (enabled, oneshot,
ExecStop=reset), re-aplicat de `/usr/lib/systemd/system-sleep/gpu-mgpu-floor` (post) si de
`/etc/udev/rules.d/99-gpu-mgpu-floor.rules` (drm change HOTPLUG=1; ruleaza doar daca serviciul e activ). Sursa in
scratchpad-ul sesiunii (efemer); fisierele instalate sunt sursa de adevar. **Oprire:** `pkexec systemctl disable --now gpu-mgpu-floor`.

**De ce:** pe calea Intel-randeaza → NVIDIA-afiseaza fiecare GPU asteapta dupa celalalt, deci guvernoarele le tin la
minim (Intel 350, NVIDIA 210 MHz P8) — vezi [[hyprland-lua-native-config]]. NVIDIA 900 ales prin calibrare (cea mai mica
cu >=90% din castigul de la 1200; 600 pierdea la damage mic: 129 vs 208 fps).

**Masurat cu `~/src/hzprobe` la 239.76Hz, inainte → dupa:** damage mic 62-118 → **171 fps** (63% cadre la fiecare vblank),
latenta 15-17 → 6 ms; redesenare completa 48-54 → **110 fps** (cadenta constanta 2 vblank-uri = 120); client randat pe
NVIDIA (ca un joc) 43 → **116 fps**, latenta 24 → 11 ms. Cost: NVIDIA in repaus ~17-18W la fel ca inainte (P5 900 MHz,
49°C); activ ~20.5W vs ~18W; pachet CPU +0-3W cand iGPU-ul lucreaza.

**Confirmat de user (2026-10-17):** „e foarte fluid dupa ultimele modificari” — fix-ul se simte si subiectiv, nu doar in
hzprobe. Nu-l scoate/nu-l slabi fara motiv; daca revine senzatia de sacadat, intai `gpu-mgpu-floor status`.

**Sleep pe boxa asta (2026-10-17):** pana atunci nu se suspendase niciodata (suspend_stats 0, nimic in jurnal 8 zile);
mem_sleep=deep; nvidia-suspend/resume/hibernate DISABLED si NVreg_PreserveVideoMemoryAllocations=0 (driver 550.163).
Test cu `pkexec sh -c 'rtcwake -m no -s 40 && systemctl suspend'` — nu `rtcwake -m mem`, care ocoleste
systemd-sleep si deci hook-ul. **Rezultat: TRECUT** — dupa resume Intel min=1450, NVIDIA persistence on, in repaus
P5 900 MHz (primele ~10 s P0 1425, cat aquamarine isi recrea rendererul NVIDIA); Hyprland acelasi PID, ambele monitoare
ok (Samsung 239.76). Nu se poate spune daca podeaua a supravietuit singura sau a refacut-o hook-ul; starea finala e corecta.
Ciudatenii: (1) s-a trezit dupa 10.3 s, inainte de alarma RTC (BOOTTIME-MONOTONIC); tastatura USB „Gaming Keyboard”
258a:010c (3-10.4) are wakeup=enabled — suspect, neconfirmat. (2) la resume `NVRM: Xid 13 ... Shader Program Header Error`
pe contextul GL NVIDIA al Hyprland = VRAM nepastrat (PreserveVideoMemoryAllocations=0). Hyprland si-a revenit, dar un
joc pe NVIDIA probabil nu. Fix oferit, NEAPLICAT: nvidia-suspend/resume/hibernate enable +
`NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp` + initramfs + reboot.

**Teste sleep 17 oct (TERMINATE):** regula udev hotplug TRECUT (la scos: Intel 350, NVIDIA pm off P8, 12.7 W vs ~20 W;
la bagat: totul inapoi, Samsung 239.76). S3/deep se trezea SINGUR dupa 6-10 s, si cu toate intrarile /proc/acpi/wakeup
oprite (ramas doar AWAC) -> sursa = EC/firmware, nu USB/PCIe (regula USB incercata, dovedita inutila, SCOASA).
s2idle (firmware are INT33A1/LPS0): a dormit 49.5 s pana la alarma, trezit de IRQ 9 (ACPI fixed event = RTC), fara Xid,
podeaua ok — dar S0ix residency 0 (platforma n-a atins S0ix; consum in sleep probabil mai mare decat S3).
**Aplicat permanent (userul: „rezolva daca mai este ceva si gata”):** `/etc/systemd/sleep.conf.d/10-s2idle.conf`
(MemorySleepMode=s2idle) + `/etc/modprobe.d/nvidia-power.conf` (`options nvidia-current` — pe Kali modulul e
nvidia-current, `options nvidia` NU se aplica — PreserveVideoMemoryAllocations=1 TemporaryFilePath=/var/tmp
EnableS0ixPowerManagement=1) + nvidia-suspend/resume/hibernate enabled + update-initramfs -k all. Scriptul era in scratchpad
(se sterge la reboot); **revenire:** `pkexec sh -c 'rm /etc/systemd/sleep.conf.d/10-s2idle.conf
/etc/modprobe.d/nvidia-power.conf; systemctl disable nvidia-suspend nvidia-resume nvidia-hibernate; update-initramfs -u
-k all'` + reboot. Modulul nvidia NU e in initramfs (se incarca de pe rootfs), deci si fara initramfs optiunile s-ar
aplica. **Verificat dupa reboot 17 oct 13:56:** params nvidia =1 (Preserve, S0ix, /var/tmp), podeaua pornita singura la boot (Intel 1450, NVIDIA P5 900), nvidia-suspend/resume/hibernate enabled, Samsung 239.76; avertismentele nvidia-drm de la plymouth existau si inainte. `/sys/power/mem_sleep` arata tot [deep] — normal, systemd 261 trece pe s2idle doar la suspend. **Suspend test 1 (s2idle, alarma 60 s):** fara Xid, Hyprland acelasi PID, Samsung 239.76, podeaua ok (dupa 15 s NVIDIA P3 1140, 21 W) — DAR s-a trezit dupa ~7 s din „ACPI non-EC GPE wakeup” (IRQ 9; EC = GPE 0x6e), S0ix residency tot 0. GPE-uri non-EC cu contor >0 dupa test: 0x66=7, 0x21=4, 0x6D=2, 0x61=2 (fara snapshot inainte, deci neidentificat). Inainte de fix-ul NVIDIA, s2idle dormea 49.5 s pana la alarma -> suspect EnableS0ixPowerManagement/nvidia-suspend, sau userul a atins tastatura (USB 3-10.4 258a:010c are wakeup=enabled). **TASK DESCHIS:** test 2 cu diff GPE inainte/dupa, maini jos; daca NVIDIA e cauza, varianta = scos NVreg_EnableS0ixPowerManagement=1 (Preserve ramane).
Daca dupa resume/hotplug fps-ul pare iar mic: `gpu-mgpu-floor status`. Reteta de suspend: [[sleep-resume-test-recipe]].
Vezi [[gaming-windows-steam-on-kali]], [[root-via-pkexec-not-sudo]].
**1 nov: NV_MAX 2100 -> 1500** in /usr/local/sbin/gpu-mgpu-floor (plafon anti-caldura, cauza = nvidia-powerd Dynamic Boost pe 610;
detalii [[nvidia-610-upgrade]]). Revenire: `pkexec /bin/bash ~/.config-backups/pre-gpu-cap-1500-2026-11-01_08-31-11/revino.sh`.
Podeaua Intel (1450 MHz) consuma din bugetul pachetului CPU (RAPL uncore) — de masurat la testul NVIDIA-primar.
**1 nov 2026:** regula udev rescrisa cu `if ...; then ...; fi; exit 0` (cu `&&` iesea cu 3 la boot, inainte sa porneasca serviciul,
de 7 ori in jurnal) — [[fix-erori-2026-11-01]].
**1 nov 14:04:** NV_MAX readus la 2100 (revino.sh din pre-gpu-cap-1500); in CS2 GPU 1949-1980 MHz, ~94 W, max 71°C. Cu NVIDIA-primar podeaua Intel 1450 costa 0 W (testat 1 nov).
