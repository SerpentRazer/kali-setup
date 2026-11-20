---
name: audio-fidelity-setup
description: Calitate audio maxima rezonabila (26 oct) — DAC-ul laptopului merge DOAR la 48 kHz/24 bit, 2 difuzoare pe pinul 0x14; singura ajustare utila = resample.quality 10
metadata:
  type: project
---

2026-10-26, userul: „verifica sa fie la cat de mare fidelitate posibil, fara sa exagerezi tehnic” + „ma refer mai mult la
difuzoarele laptopului”.

**Hardware (verificat):** Realtek ALC287 (PCI SSID 17aa:3811, codec 17aa3854) — toate DAC-urile (0x02/0x03/0x06) suporta
DOAR 48000 Hz, 16/20/24 bit („Default PCM” cu 44.1/96/192 e doar generic). PipeWire deschide S32_LE 48 kHz = maximul.
`clock.allowed-rates` NU are sens aici. Difuzoare: Legion 5 17ITH6H = 2x2W, pinul 0x14 (Speaker); 0x17 (bas la alte
Lenovo) e N/A din BIOS — nu lipseste nimic. Profil corect `output:analog-stereo` ([[sound-pro-audio-muffled]]).
`alsa-utils` (amixer/alsamixer) NU e instalat; pinii se citesc din `/proc/asound/card0/codec#0`.

**Aplicat:** `resample.quality = 10` (implicit 4, max 14 = exagerat) in `stream.properties`, fisiere
`~/.config/pipewire/pipewire-pulse.conf.d/10-resample-quality.conf` + `~/.config/pipewire/client.conf.d/...` (Spotify
foloseste protocolul NATIV PipeWire, nu Pulse -> client.conf; se aplica la pornirea aplicatiei). Restart doar
`pipewire-pulse`. Verificat: paplay -> 10, mpv --ao=pipewire -> 10. `pw-play` isi impune singur `-q` (implicit 4) -> nu
e test valid; gstreamer n-are pipewiresink.

**Spotify:** Premium, `audio.play_bitrate_non_metered_enumeration=5` = Lossless (44.1 kHz/24 bit -> convertit la 48k),
normalizare implicita (Normal, fara limitator) — lasat asa.
**Bluetooth Buds FE:** SBC/AAC/SSC; pe Kali PipeWire n-are AAC (fara fdk-aac), SSC nu exista pe Linux -> cel mai bun =
SBC-XQ (activ implicit daca nu e in lista de quirks). Codecul negociat nu l-am vazut (castile erau in carcasa).
Optional nefacut: EQ/corectie pt difuzoare (EasyEffects/filter-chain) = schimba caracterul sunetului, nu fidelitatea.
Vezi [[bt-dualboot-key-sync]].
