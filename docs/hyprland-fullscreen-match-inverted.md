---
name: hyprland-fullscreen-match-inverted
description: "In Hyprland 0.56 Lua, window_rule match `fullscreen = true` prinde ferestrele NE-fullscreen; foloseste `fullscreen = 1`. Playere video facute opace; reteta de test pe ws ascuns"
metadata:
  node_type: memory
  type: project
  originSessionId: a0c338ac-edf4-4193-9f6c-659f180459ad
  modified: 2026-10-02T06:51:03.344Z
---

**Bug masurat 2026-10-02 (Hyprland 0.56.2, config Lua):** in `hl.window_rule({ match = {...} })`, `fullscreen = true`
(si `= "true"`, si chiar `= false`) prinde ferestrele **NE-fullscreen**; doar `fullscreen = 1` (cifra) prinde corect pe cele
fullscreen. O cheie necunoscuta (`bogus_key = true`) e ignorata, deci se potriveste oricum. Exemplul upstream din
`/usr/share/hypr/hyprland.lua` foloseste booleeni, dar nu functioneaza asa.

Consecinta in `~/.config/hypr/rules.lua`: regulile „0.9 pt toate + 1.0 la fullscreen” sunt INVERSATE: ferestrele normale
iau 1.0, cele fullscreen 0.9. Iar SUPER+O (`scripts/opacity.sh`, sed pe PRIMA linie `opacity = "... override"`) schimba
practic doar opacitatea ferestrelor fullscreen. **NEREPARAT intentionat:** userul a cerut sa schimb „doar la playere”;
repararea ar face toate ferestrele normale 90% transparente. I s-a oferit, nu s-a aplicat.

**Ce s-a facut:** dupa regula fullscreen, doua reguli noi. `opaque-video-players` are clasele TUTUROR playerelor
instalate (userul: „doar playerele video full opace”, inclusiv cele „instalate pe kali”): `mpv`, `vlc` (VLC 3.0.23 prin
XWayland), `org.kde.dragonplayer`, `parole` + **`GStreamer`** (Parole pe Wayland deschide video-ul intr-o fereastra
SEPARATA cu clasa GStreamer, title „parole”; aparea pe ws 4 si lua focus-ul la test), `ffplay`. A doua regula este
`opaque-video-content` (`content = "video"`; doar mpv raporteaza contentType=video). Verificat in fullscreen pe toate 5:
0.9 -> 1.0; kitty fullscreen ramane 0.9. Daca userul instaleaza alt player -> adauga-i clasa in regula. Brave/YouTube
NETESTAT. Backup: `~/.config-backups/rules.lua.pre-video-opacity-2026-10-02_09-50-18`.

**Reteta de test fara sa deranjezi userul:** `hyprctl -j getprop address:0x.. opacity` arata opacitatea efectiva
(reflecta regulile). Regulile temporare cu `hyprctl eval 'hl.window_rule({...})'` dispar la `hyprctl reload`. Fereastra de
test pe `workspace = "9 silent"`; fullscreen fara focus: `hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "fullscreen",
action = "set", window = "address:0x.." })'`. **CAPCANA:** mpv pe un workspace ascuns se blocheaza (nu primeste cadre)
-> Hyprland arata „Application Not Responding” pe ecranul userului. Fix: `hl.config({ misc = { enable_anr_dialog = false } })`
prin eval + `render_unfocused = true` in regula + `mpv --wayland-disable-vsync=yes`, totul sub `timeout`.
Vezi [[hyprland-lua-native-config]], [[verify-before-instructing]].

**UPDATE 2026-10-16:** upstream a pus regula globala `.*` pe `1.0 override`, deci repararea nu mai face ferestrele
translucide -> in rules.lua regula 2 e acum `fullscreen = 1` (comentata). SUPER+O schimba efectiv ferestrele normale,
fullscreen + playere + jocuri raman 1.0. Verificat live: Brave fullscreen = opacitate 1 (inainte 0.9). Vezi [[43pr-update-2026-10-16]].
