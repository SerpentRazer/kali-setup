-- Docs: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- To check class name, open the app and run:
-- hyprctl clients

hl.layer_rule({
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = 0.15,
})

-- blur behind the notification toasts/panel (quickshell Notifications.qml, namespace "notifications")
hl.layer_rule({
    match = { namespace = "notifications" },
    blur = true,
    ignore_alpha = 0.2,
})

-- blur behind the quickshell music preview card (MusicPreview.qml)
hl.layer_rule({
    match = { namespace = "qs-music" },
    blur = true,
    ignore_alpha = 0.1,
})

-- blur behind the quickshell weather card (WeatherPreview.qml, Kali 20 nov)
hl.layer_rule({
    match = { namespace = "qs-weather" },
    blur = true,
    ignore_alpha = 0.1,
})

-- blur behind the quickshell tray icon menus (TrayMenu.qml)
hl.layer_rule({
    match = { namespace = "qs-traymenu" },
    blur = true,
    ignore_alpha = 0.1,
})

-- Opacity rules for all windows except fullscreen
-- SUPER+O (scripts/opacity.sh) rewrites the value in the FIRST opacity line of this file (the rule below).
-- Kali 1 nov: this comment used to quote that line literally, so sed rewrote the comment instead of the rule.
hl.window_rule({
    match = { class = ".*" },
    opacity = "1.0 override",
})
-- Hyprland 0.56 (config Lua): in `match`, `fullscreen = true` prinde ferestrele NE-fullscreen
-- (masurat 2026-10-02); doar `fullscreen = 1` le prinde pe cele fullscreen. Cu `true`, regula asta
-- forta 1.0 pe toate ferestrele normale si SUPER+O nu avea efect asupra lor.
hl.window_rule({
    match = { class = ".*", fullscreen = 1 },
    opacity = "1.0 override",
})

-- Video players: always opaque, even when SUPER+O makes the other windows
-- translucent. Classes of every player installed here:
-- mpv, VLC (XWayland), Dragon Player, Parole + its separate "GStreamer"
-- video window, ffplay. content = "video" catches any app that reports
-- video via wp-content-type.
hl.window_rule({
    name = "opaque-video-players",
    match = { class = "^(mpv|vlc|org\\.kde\\.dragonplayer|parole|GStreamer|ffplay)$" },
    opacity = "1.0 override",
})

hl.window_rule({
    name = "opaque-video-content",
    match = { content = "video" },
    opacity = "1.0 override",
})

hl.layer_rule({
    match = { namespace = "quickshell|sidepanel" },
    blur = true,
    ignore_alpha = 0.01,
})
--hl.window_rule({
--    name = "brave",
--    match = { class = "^brave-browser$" },
--    opacity = "1.0 override",
--})

hl.window_rule({
    match = { class = "kitty" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "file-picker-float",
    match = { class = "^(xdg-desktop-portal-gtk)$" },
    float = true,
    center = true,
    size = "900 600",
})

-- 15 nov: Task Manager (btop, clasa "taskmanager") era plutitor; 20 nov scos la cererea userului -> se aranjeaza in tiling ca restul ferestrelor.

hl.window_rule({
    name = "float-pavucontrol",
    match = { class = "^(pavucontrol)$" },
    float = true,
})

hl.window_rule({
    name = "float-nm-connection-editor",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
})

hl.window_rule({
    name = "float-blueman-manager",
    match = { class = "^(blueman-manager)$" },
    float = true,
})

hl.window_rule({
    name = "float-open-file",
    match = { title = "^(Open File)$" },
    float = true,
})

hl.window_rule({
    name = "float-save-file",
    match = { title = "^(Save File)$" },
    float = true,
})

-- Jocuri Steam/Proton (toate au class steam_app_<appid>): fortate OPACE.
-- Regula globala .* le facea 0.9 -> se vedea desktopul blurat prin joc.
-- O fereastra opaca nu mai are blur in spate => dispare efectul si costul lui.
hl.window_rule({
    name = "games-opaque",
    match = { class = "^steam_app_[0-9]+$" },
    opacity = "1.0 override",
})

-- CS2 nativ (class "cs2", XWayland: Valve forteaza SDL x11): opac + tearing (immediate) = cadrul ajunge pe ecran
-- imediat, fara sa astepte vsync-ul compozitorului -> latenta mai mica. Hyprland face tearing doar in fullscreen
-- si doar cu general.allow_tearing = true (look.lua). 2026-10-28
hl.window_rule({
    name = "cs2-competitive",
    match = { class = "^cs2$" },
    opacity = "1.0 override",
    immediate = true,
    fullscreen = true,   -- 1 nov 2026: CS2 fara gamescope (varianta B) - fereastra mereu fullscreen pe Samsung
    -- 1 nov 2026: mereu pe workspace-ul 2 (Samsung). Mutat de mana pe un workspace cu alta fereastra, jocul a iesit din
    -- fullscreen la 17:03 si a ramas fereastra 1904x1039 inca 75 min (sesiunea 16:29); asa porneste direct acolo, fullscreen.
    workspace = "2",
})

-- gamescope (CS2 4:3 stretched: 1440x1080 intins pe 1920x1080, vezi optiunile de lansare din Steam): la fel ca mai sus.
-- fullscreen = true: `-f` din gamescope nu ajungea mereu (28 oct a doua rulare: fereastra tiled 1904x1039 sub bara,
-- deci scalata si fara tearing). Testat pe o fereastra de proba: fullscreen 2, 1920x1080. 2026-10-28
hl.window_rule({
    name = "gamescope-competitive",
    match = { class = "^gamescope$" },
    opacity = "1.0 override",
    immediate = true,
    fullscreen = true,
    -- 1 nov 2026: mereu pe workspace-ul 2 (Samsung). Mutat de mana pe un workspace cu alta fereastra, jocul a iesit din
    -- fullscreen la 17:03 si a ramas fereastra 1904x1039 inca 75 min (sesiunea 16:29); asa porneste direct acolo, fullscreen.
    workspace = "2",
})

hl.layer_rule({
    match = { namespace = "wallpaper-picker" },
    blur = true,
    ignore_alpha = 0.95,
})
