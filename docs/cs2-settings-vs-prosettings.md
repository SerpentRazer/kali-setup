---
name: cs2-settings-vs-prosettings
description: Setarile CS2 ale userului comparate cu prosettings.net/guides/cs2-options (8 nov 2026) — ce e deja ok, ce difera, maparea convar->meniu, ce nu se aplica pe Linux
metadata:
  type: project
---

**Analiza 8 nov 2026** (ghid „Last modified Sep 25, 2026”; fisiere in `~/.steam/debian-installation/userdata/461618270/730/local/cfg/`:
`cs2_video.txt`, `cs2_user_convars_0_slot0.vcfg`, `cs2_machine_convars.vcfg`, `cs2_user_keys_0_slot0.vcfg`). CS2 rescrie fisierele la iesire
=> editari doar cu jocul inchis (sau din meniu).

**Deja ca la ghid:** toate setarile video (1280x960 4:3 stretched, vsync off, CMAA2, umbre low + dynamic All, texturi medium, aniso 4x,
shader/particule low, AO off, HDR Quality = hdr_detail -1, FSR off, Reflex on = r_low_latency 1), Boost Player Contrast
(r_player_visibility_mode 1), Color mode Computer Monitor (r_fullscreen_gamma 2.2), retea (rate 786432, cl_net_buffer_ticks 0, maxping 45),
damage prediction toate off, consola on, avatare animate off, push-to-talk + VOIP 100%, mute in background, round start/action 0,
grenade pe taste separate (z flash, x smoke, c HE, v molotov), mouse 1000 Hz.

**Diferente gasite (propuse userului, NEAPLICATE):** First Person Tracers ON (r_drawtracers_firstperson true -> off); EQ Natural
(snd_headphone_eq 0 -> Crisp 1); Round End / MVP / Death Camera 40% (0.16), Bomb 20% (snd_mapobjective_volume 0.04) -> 0;
Mute MVP music cand ambele echipe traiesc OFF -> on; zoom_sensitivity_ratio 1.1 (ghid 1.0, preferinta); radar implicit
(cl_radar_scale 0.7, hud 1, centrat) -> zoom out / dynamic radar; crosshair fara contur, follow recoil off (optionale).
eDPI necunoscut: sensitivity 1.45 x DPI (Basilisk V3, DPI neintrebat inca); mediana pro 830.
**Userul VREA sa auda music kit-ul** (8 nov): NU propune muzica la 0; compromis = MVP/Round End/Death Cam raman,
„Mute MVP music when both teams alive” ON, doar Bomb/Hostage (canta in timpul jocului, post-plant) la 0 sau ~5-10%.
Valorile volum in vcfg = (procent/100)^2 (0.16 = 40%).

**Nu se aplica pe Linux:** Fullscreen exclusiv (CS2 Linux n-are -> [[cs2-fullscreen-hyprland-linux]]), `-high` (ulimit -e = 0,
nu poate cobori nice fara root; cs2-perf pune deja profilul performance), setari Windows/NVIDIA Control Panel.

Legat: [[gaming-optimization-plan-2026-11-01]], [[steam-shader-precache-downloads]].

**16 nov:** userul a cerut fps limitat la 244 -> i-am dat randul de LaunchOptions cu `+fps_max 244` in loc de `+fps_max 0` (Steam era pornit; schimbare din UI).
Neconfirmat ca l-a aplicat. In LaunchOptions userul a adaugat si `-high` (fara efect pe Linux, ulimit -e 0).
