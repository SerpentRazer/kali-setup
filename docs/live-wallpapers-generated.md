---
name: live-wallpapers-generated
description: "15 nov 2026: 4 wallpapere live facute local cu ffmpeg (bucla fara cusatura) in ~/Pictures/Wallpapers/live-*.mp4; site-urile (MotionBGs etc.) au Cloudflare challenge -> NU le ocoli; wallpaper-restore.sh patch-uit sa reporneasca videoul la login"
metadata:
  type: project
---

Fisiere (1920x1080 h264 30fps, in ~/Pictures/Wallpapers, picker-ul SUPER+W le vede): live-cyborg-ploaie (din 1790942365.png = wallpaper-ul
curent, personaj cyborg + ploaie, 20s), live-oras-neon (neon-gaming-background 8000px, panoramare tip drona + ploaie fina, 24s),
live-kali-glitch (kali-glitch, sclipiri RGB+zgomot la 0/2.4/5/7.1s, 20s, 47 MB), live-plasma-teal-magenta (geq plasma 960x540 -> 1080p, 30s).
Scripturi in /tmp/claude-1000/livewall/render-*.sh (dispar la reboot): zoompan pe imagine marita 4x (7680) cu sin(2*PI*on/N) = bucla perfecta;
ploaie = SVG 1920x2160 (2 copii) + crop y=1080-mod(t*v,1080) cu v*T multiplu de 1080. Capcana: in zsh `$F[bg]` = indice array -> randare in bash.
MotionBGs = Cloudflare „challenge-platform” -> nu descarc automat de acolo.
**Fix tema:** `~/.config/hypr/scripts/wallpaper-restore.sh` nu repornea videoul la login (commands.sh scrie ~/.cache/43pr/last-live, nimeni nu-l citea)
-> adaugat bloc mpvpaper la final (backup wallpaper-restore.sh.pre-live-* in ~/.config-backups; copiat in staging merged/). REAPLICA la merge 43PR.
Atentie: commands.sh cu video ruleaza si theme.py => recoloreaza tema dupa primul cadru; revenire = commands.sh pe imaginea veche.
Legat: [[hyprland-057-local-build]] (mpvpaper), [[43pr-update-2026-10-16]].

**15 nov 20:25 — userul: cele generate de mine sunt „jalnice” -> descarcate 13 reale de pe GitHub (fara Cloudflare):** repo-uri
`usman-369/wallpapers` (animated/{scenery,misc,cars,characters}) si `adityastomar67/Wallpapers` (Live/), via raw.githubusercontent.com,
in ~/Pictures/Wallpapers/net-*.mp4|mkv (toate 1920x1080 h264, 10-60 s; bmw-m4-rain-night STERS de user 15 nov -> 12 ramase): cyberpunk-city, night-city-2077.mkv, cyberpunk-bedroom, stray-midtown,
nissan-r31-cyberpunk, itachi-kisame-rain, night-railway, dark-souls-campfire, cyberpunk-apartment, apartment-rain-window,
lofi-vending-machines, underground-pass. Listare rapida: `gh api repos/<r>/git/trees/main?recursive=1`. Cele 4 live-* generate: STERSE la cererea userului 15 nov (+ thumbs, gif-frames, /tmp/claude-1000/livewall).
**Ales de user (15 nov 20:30, „foarte faina”): net-apartment-rain-window.mp4** (last-live + tema recolorata din primul cadru). Capcana: `pgrep -af mpvpaper |
grep <x>` prinde si linia de comanda a propriului shell -> am omorat din greseala wallpaper-ul userului; foloseste `pgrep -x mpvpaper` + /proc/<pid>/cmdline.
