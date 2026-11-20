---
name: sound-pro-audio-muffled
description: Sunet infundat pe Kali/PipeWire = placa blocata pe profilul Pro Audio; fix = Analog Stereo
metadata:
  node_type: memory
  type: reference
  originSessionId: 17dd387c-74ae-4463-bff5-e819ad4954c1
  modified: 2026-10-03T06:20:02.506Z
---

Pe acest laptop (Kali, PipeWire/WirePlumber), **sunet „infundat" / subtire / fara bas = placa audio built-in e pe profilul „Pro Audio"**. Pro Audio expune canalele ALSA brute (`aux0,aux1`, fara UCM/rutarea difuzoarelor) → iese pe o cale gresita a DAC-ului. Semn: in `wpctl status` toate sink-urile apar ca „...Pro", iar stream-urile ies pe `ALC287 Analog:playback_AUX0/AUX1`.

**Fix** (verificat 2026-10-01, se face o singura data, WirePlumber tine minte profilul per device):
```
pactl set-card-profile alsa_card.pci-0000_00_1f.3 output:analog-stereo+input:analog-stereo
NEW=$(pactl list sinks short | grep 'pci-0000_00_1f.3.*analog-stereo' | awk '{print $2}' | head -1)
pactl set-default-sink "$NEW"; pactl set-sink-volume "$NEW" 100%
```
Placa built-in = `alsa_card.pci-0000_00_1f.3` (Realtek ALC287). Placa NVIDIA `alsa_card.pci-0000_01_00.1` ramane pe pro-audio (e HDMI spre monitor). Nimic nu forta Pro Audio din config — fusese o alegere salvata in `~/.local/state/wireplumber/default-profile`, acum suprascrisa. Atentie si la volum: era la 170% (supra-amplificat, distorsioneaza) — adus la 100%.

**RECIDIVA 2026-10-03 — cauza reala + fix permanent:** sunetul „iar naspa" vine declansat de **orice schimbare de mod pe Samsung** (ex. testul de 240Hz): HDMI-ul se re-enumeara → WirePlumber poate muta rutarea pe un sink „Pro" brut al placii NVIDIA. Placa NVIDIA `alsa_card.pci-0000_01_00.1` statea pe `pro-audio` (sink-uri 54-57 „GA106 ...Pro", canale brute). Monitorul LC27RG50 n-are boxe utile → audio HDMI acolo e inutil. **Fix forever aplicat:** `pactl set-card-profile alsa_card.pci-0000_01_00.1 off` + `pactl set-default-sink alsa_output.pci-0000_00_1f.3.analog-stereo`. Au ramas DOAR difuzoarele laptop; WirePlumber a salvat `alsa_card.pci-0000_01_00.1=off` in `~/.local/state/wireplumber/default-profile` → rezista reboot. **Revert** daca se vrea audio pe HDMI: `pactl set-card-profile alsa_card.pci-0000_01_00.1 output:hdmi-stereo`. Leg de [[hyprland-lua-native-config]] (schimbarea de mod monitor e triggerul).

**Analogie Windows:** ca si cum ai schimba „formatul implicit"/driver-ul de iesire din Sound settings cand boxele suna metalic. Vezi [[verify-before-instructing]].
