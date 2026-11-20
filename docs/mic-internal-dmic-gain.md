---
name: mic-internal-dmic-gain
description: "Microfonul intern al laptopului (DMIC pe ALC287, nod 0x12) — era pe mute + 100% (+60 dB = doar zgomot); pus pe 20% din 28 oct; harta procent -> boost/ADC"
metadata:
  node_type: memory
  type: project
  originSessionId: 632d84fc-4498-49f8-8219-6bfe00c82d00
  modified: 2026-10-28T17:02:13.036Z
---

2026-10-28, „nu mi se aude microfonul in discord”: Discord captura corect de pe `alsa_input.pci-0000_00_1f.3.analog-stereo`
(port Internal Microphone), dar sursa era **Mute: yes** si volumul **100%**. Dupa unmute, la 100% intra doar sasait
(RMS -12 dBFS, nivel constant, ~5000 treceri prin zero/s = zgomot, nu voce).

Cauza zgomotului: microfonul intern e **digital** (pin 0x12, `Conn = Digital`) iar ACP-ul PipeWire leaga slider-ul de
Boost (0x12, 3 trepte x 10 dB) + ADC 0x08 (0 dB la 0x17, +30 dB la 0x3f). 100% = +60 dB. Harta masurata:
10% = 0 dB (zgomot -70 dBFS) · 20% = ADC +18 dB, fara boost (-53 dBFS) · 40% = ADC maxim · 50%+ incepe boost-ul.
**Aplicat 20%** (`pactl set-source-volume alsa_input.pci-0000_00_1f.3.analog-stereo 20%`), salvat de WirePlumber in
`~/.local/state/wireplumber/default-routes` (channelVolumes 0.008 = 0.2^3, mute false). Discord nu-l mai schimba (12 s urmarit).
Nu era tastata userului: nu exista bind `XF86AudioMicMute` in Hyprland si `alsa-utils`/`amixer` nu sunt instalate
(codecul se citeste din `/proc/asound/card0/codec#0`). Daca vocea e prea slaba, urca la 25-30%, nu peste 40%.

Masurare fara salvare audio: `parec --latency-msec=30 -d <sursa> --raw | python3 -I` (fara `--latency-msec` parec
intarzie si o fereastra scurta iese goala). Buds FE pe A2DP n-au microfon (ar cere HFP, sunet mai prost). Vezi
[[audio-fidelity-setup]], [[sound-pro-audio-muffled]], [[discord-install]].

**Confirmat de user 28 oct** (Discord „Let's Check”): „merge ok” la 20% — nu mai umbla la nivel decat daca se plange ca e incet.

**30 oct 22:48 — REVENIT la 100%** in timpul unui apel Discord (CS2 pornit): userul „ma aud intrerupt”. default-routes
rescris la 22:48 cu channelVolumes 1.0 -> podea zgomot -7.4 dBFS (saturat), filtrul Discord taia vocea. Suspect principal:
**Automatic Gain Control din Discord** (WebRTC urca volumul sursei in sistem). Readus la 20% (podea -48.5 dBFS, stabil 20 s).
De facut de user: Discord > Voice & Video > Automatic Gain Control OFF. Daca revine iar: urmareste
`pactl get-source-volume` in apel ca sa prinzi momentul. Restul a fost exclus (PipeWire ERR 0, retea 0% pierderi,
Discord ~5 MB in zram).

**1 nov 2026 14:50 — REVENIT la 100% A TREIA OARA** („se aude groaznic inputul… prea tare pt altii”, in Steam/CS2 + Discord pornit).
`SteamVoiceSettings` din localconfig.vdf avea `"autoGainControl":true` (+ noise/echo cancellation, selectedMic default). Readus la
20% (podea -47.8 dBFS) -> userul: „acum e mult mai bine”. `~/src/legion/steam-voice-agc-off.sh` (asteapta Steam > Exit, schimba
DOAR autoGainControl -> false, backup in ~/.config-backups/steam-voice-agc-*) pornit in fundal. Paznicul permanent (serviciu
systemd --user care readuce la 20% peste 40%) a fost REFUZAT de auto mode („Unauthorized Persistence”) -> pregatit
`~/src/legion/mic-guard-install.sh` (instalare `bash ...`, scoatere `... scoate`) pt user. Discord AGC: tot userul (Voice & Video).
Exista si casca Razer Barracuda X 2.4 (card USB, profil off) — microfon mai bun daca o foloseste.
**1 nov ~16:25:** dupa reboot microfonul era iar 100% (default-routes scris la 16:01:57 cu 1.0, inainte ca scriptul sa opreasca AGC-ul Steam la iesirea din Steam; sau Discord AGC) -> readus 20%. Steam AGC acum false (confirmat in vdf). Discord AGC: de confirmat de user; mic-guard tot neinstalat.
**1 nov ~17:00 — FIX DEFINITIV scris (userul: „rezolva microfonul asta odata”, „fa-l sa functioneze la calitate mare”):**
`~/.config/pipewire/pipewire-pulse.conf.d/20-blocheaza-agc-microfon.conf` = pulse.rules cu quirk `block-source-volume` pt
application.process.binary ~ Discord|steam|steamwebhelper|cs2|brave|chrome|chromium|teams-for-linux|zoom|firefox|electron si
application.name ~ ^WEBRTC (PipeWire 1.6.9 are chiar exemplu comentat pt Discord in /usr/share/pipewire/pipewire-pulse.conf).
ACTIV abia dupa `systemctl --user restart pipewire-pulse` (sau relogin) — neaplicat inca: CS2 rula (restartul poate lasa jocul
fara sunet). Prins in flagrant: Discord (WEBRTC VoiceEngine) inregistra si microfonul era iar 100%. Readus 20%.
Razer Barracuda X: card absent acum (dongle scos). Test dupa restart: copie pactl numita „Discord” care incearca 100% -> trebuie blocat.
**1 nov 16:32 — punte activa:** `~/src/legion/mic-20-pana-la-regula.sh` (fundal in sesiunea Claude) readuce la 20% orice schimbare cat ruleaza CS2 (testat 50%->20% in <1 s); la inchiderea CS2 reporneste pipewire-pulse (incarca regula block-source-volume) si testeaza cu o copie pactl numita Discord. Userul: „fixeaza-l sa stea mereu la 20%”.
**1 nov 18:25 — DUPA RESTART: regula ACTIVA si VERIFICATA.** Copii pactl numite Discord/steam/steamwebhelper/brave care cer 100%
-> „Access denied”, microfonul ramane 20% (jurnal pipewire-pulse: SET_SOURCE_VOLUME Operation not permitted). Puntea NU a apucat
sa reporneasca pipewire-pulse (a murit cu sesiunea Claude veche), asa ca inainte de restart ceva a urcat iar la 100% si
WirePlumber a salvat 1.0 in ~/.local/state/wireplumber/default-routes (analog-input-internal-mic) -> la boot era 100%. Readus 20%
cu pactl normal (pactl/quickshell/pavucontrol NU sunt blocate = control manual ramane), salvat 0.008 (=0.2^3, cubic). Lectie:
puntile din fundal mor cu sesiunea Claude — nu te baza pe ele peste un restart/iesire.
