-- ~/.config/hypr/hyprland.lua
-- Docs: https://wiki.hypr.land/Configuring/Start/

---- MY PROGRAMS ----

mainMod    = "SUPER"
terminal   = "kitty"
menu       = "rofi -show drun"
fileManager = "thunar"
browser    = "brave-browser"

-- Overrides written by Quickshell (Settings > Configs): mainMod, browser.
-- Must load before keybinds.lua, which reads these globals when binding.
do
    local f = os.getenv("HOME") .. "/.config/quickshell/state/prefs.lua"
    local fh = io.open(f, "r")
    if fh then
        fh:close()
        local ok, err = pcall(dofile, f)
        if not ok then print("state/prefs.lua failed: " .. tostring(err)) end
    end
end

---- AUTOSTART ----

hl.on("hyprland.start", function()
    hl.exec_cmd("tail -F -n +1 $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log > ~/.cache/hyprland/last-session.log")
    -- waybar si dunst sunt inlocuite de quickshell (Bar.qml, Notifications.qml). Meniul de power e iar wlogout
    -- (hypr/scripts/wlogout.sh, cerut 17 oct); PowerMenu.qml ramane incarcat, dar nu-l mai deschide nimic.
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("rfkill unblock bluetooth") -- IdeaPad boots BT soft-blocked; unblock so the toggle works
    -- 1 nov 2026: Samsung (HDMI-A-2) = monitor PRINCIPAL pt Xwayland, altfel jocurile X11 (CS2 fara gamescope) aleg laptopul
    -- (eDP-1 e primul in lista Xwayland). Asteapta pana porneste Xwayland si e conectat Samsung-ul (max 30 s).
    -- 11 nov: conectorul vine din monitors.lua (HDMI-A-2 in Hybrid, HDMI-A-1 cu Hybrid Mode oprit)
    hl.exec_cmd("sh -c 'for i in $(seq 30); do DISPLAY=${DISPLAY:-:1} xrandr --output " .. (MONITOR1 or "HDMI-A-2") .. " --primary 2>/dev/null && exit 0; sleep 1; done'")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1")

    -- Pe Wayland, GTK3 (Thunar, nwg-look...) citeste tema din gsettings, NU din settings.ini.
    -- Fara asta Thunar lua Kali-Purple-Dark/Flat-Remix ramase de la Xfce/Plasma.
    -- Scrie in baza dconf proprie Hyprland (vezi DCONF_PROFILE mai jos), nu in cea a Xfce/Plasma.
    -- gtk-theme + color-scheme vin din motorul de teme 43pr (theme.py apply), ca un preset deschis
    -- (white, light-gray...) sa nu fie fortat inapoi pe Adwaita-dark la fiecare login.
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark; gsettings set org.gnome.desktop.interface font-name 'Geist 11'; gsettings set org.gnome.desktop.interface document-font-name 'Geist 11'; gsettings set org.gnome.desktop.interface monospace-font-name 'GeistMono Nerd Font 10'; python3 ~/.config/43pr/bin/theme.py apply >/dev/null")

    -- D-Bus/systemd nu mostenesc DCONF_PROFILE, deci aplicatiile activate prin D-Bus
    -- (ex. daemonul Thunar / org.freedesktop.FileManager1) citeau profilul dconf IMPLICIT
    -- (Kali-Purple-Dark + iconite albastre) in loc de cel Hyprland (Adwaita-dark + Papirus).
    -- Impinge DCONF_PROFILE in env-ul de activare => Thunar arata ca restul desktop-ului.
    -- Kali (20 nov): + variabilele ecranului, altfel xdg-desktop-portal (dialogul Open din Brave etc.) nu stie unde sa deseneze
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE DCONF_PROFILE XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_SIZE")

    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper-restore.sh") -- wallpaper-ul salvat de theme.py (picker-ul SUPER+W)
    hl.exec_cmd("~/.config/hypr/scripts/live-wallpaper-pause.sh") -- upstream 19 nov: pauza mpvpaper cat e o fereastra fullscreen
    hl.exec_cmd("sleep 2 && QSG_RENDER_LOOP=basic QS_ICON_THEME=Papirus qs")
    -- Notificarile le tine acum quickshell. Pe Kali D-Bus poate porni singur dunst / xfce4-notifyd
    -- daca vine o notificare in cele 2s de dinainte de qs; qs ar astepta atunci la nesfarsit.
    -- Le oprim dupa ce qs a pornit -> qs preia numele automat (testat: "Registration will be
    -- attempted again if the active service is unregistered").
    hl.exec_cmd("sh -c 'sleep 6; pkill -x dunst; pkill -x xfce4-notifyd'")
end)

---- ENVIRONMENT VARIABLES ----

-- Baza dconf separata (~/.config/dconf/hyprland): tema GTK a Hyprland nu se mai scurge in Xfce/Plasma.
-- Testat: cu profilul asta GTK pe Wayland vede Adwaita-dark/Papirus-Dark, fara el Kali-Purple-Dark.
hl.env("DCONF_PROFILE", os.getenv("HOME") .. "/.config/hypr/dconf-profile")

-- Cursor: Breeze 18 peste tot (ales de user dintre Adwaita/Breeze 12-24). Marimea trebuie sa existe
-- NATIV in tema: Hyprland scaleaza la orice marime, dar aplicatiile care isi deseneaza singure cursorul
-- (XWayland: Teams, Spotify, Steam; GTK3) iau cea mai apropiata varianta -> cu Adwaita 14 cursorul
-- isi schimba marimea la hover intre ferestre. breeze_cursors are 12/18/24/30/...
hl.env("XCURSOR_THEME", "breeze_cursors")
hl.env("XCURSOR_SIZE", "18")
hl.env("HYPRCURSOR_SIZE", "18")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Laptop hibrid: Intel UHD (card0) conduce eDP-1, NVIDIA RTX 3060 (card1) conduce HDMI-A-2.
-- Hyprland are nevoie de ambele GPU-uri ca sa mearga si ecranul intern si cel extern.
-- Numerotarea card0/card1 se poate schimba intre boot-uri, deci rezolvam caile by-path.
-- NU punem caile by-path direct: contin ":" iar AQ_DRM_DEVICES e separat tot prin ":".
-- (ordinea GPU-urilor: vezi mai jos)
-- 11 nov 2026: cu Hybrid Mode OPRIT in Lenovo Vantage (MUX = doar NVIDIA) Intel dispare din PCI. Fallback-ul vechi "card0"
-- era atunci chiar NVIDIA => AQ_DRM_DEVICES=card0:card0 => fiecare monitor de 2 ori, commit EBUSY, flicker, mouse mort.
-- Acum un GPU care nu exista = nil (readlink -e esueaza); fallback-ul ramane doar daca popen insusi crapa.
local function drm_card(by_path, fallback)
  local ok, dev = pcall(function()
    local f = io.popen("readlink -e " .. by_path .. " 2>/dev/null")
    local out = f:read("*l")
    f:close()
    return out
  end)
  if ok and dev and dev:match("^/dev/dri/card%d+$") then return dev end
  if not ok then return fallback end
  return nil
end
-- lista AQ_DRM_DEVICES: primul = cel care randeaza; sare peste GPU-urile lipsa si peste dubluri
local function set_gpus(first, second)
  local v = first
  if second and second ~= first then v = v and (v .. ":" .. second) or second end
  if v then hl.env("AQ_DRM_DEVICES", v) end
end
-- Primul GPU din lista = cel care randeaza. Implicit Intel.
-- Incercat pe 2026-09-30: NVIDIA primul (ca sa scap de patratele care palpaie pe Samsung)
-- -> Hyprland crapa la PORNIRE (ABRT in Mesa dri_create_fence_fd, din Aquamarine
-- CDRMRenderer::recreateBlitSync, la copia spre eDP-1) = login imposibil. Nu reactiva orbeste.
-- 2026-11-01: NVIDIA-primul TESTAT pe driverul 610 = merge (vezi blocul de mai jos, automat cand Samsung-ul e conectat).
local INTEL  = drm_card("/dev/dri/by-path/pci-0000:00:02.0-card", "/dev/dri/card0")
local NVIDIA = drm_card("/dev/dri/by-path/pci-0000:01:00.0-card", "/dev/dri/card1")
-- 1 nov 2026: NVIDIA-primar AUTOMAT cand la login e conectat un monitor pe NVIDIA (Samsung pe HDMI): Hyprland compune pe NVIDIA
-- si Samsung-ul primeste cadrele direct -> hzprobe: 93/101 -> 235/233 fps reali (98% din 239.76 Hz), latenta 10-12 -> 7.8 ms.
-- Laptopul (eDP-1, Intel) primeste copii prin CPU (aquamarine „intermediate buffer”). Fara monitor pe NVIDIA (ex. pe baterie)
-- ramane Intel-primar (consum mic). URGENTA (ex. un update de driver strica login-ul): din TTY `touch ~/.config/hypr/intel-primary`
-- => Intel-primar la FIECARE login pana stergi fisierul. Flag-ul vechi `nvidia-primary` (one-shot) forteaza NVIDIA si fara monitor.
local HOME = os.getenv("HOME")
local function file_exists(p) local f = io.open(p, "r"); if f then f:close(); return true end; return false end
local function nvidia_has_monitor()
  if not NVIDIA then return false end
  local card = NVIDIA:match("(card%d+)$")
  if not card then return false end
  local ok, out = pcall(function()
    local p = io.popen("cat /sys/class/drm/" .. card .. "-*/status 2>/dev/null")
    local s = p:read("*a"); p:close(); return s
  end)
  return ok and out ~= nil and ("\n" .. out):find("\nconnected") ~= nil
end
if file_exists(HOME .. "/.config/hypr/intel-primary") then
  set_gpus(INTEL, NVIDIA)
elseif file_exists(HOME .. "/.config/hypr/nvidia-primary") then
  os.remove(HOME .. "/.config/hypr/nvidia-primary")
  set_gpus(NVIDIA, INTEL)
elseif nvidia_has_monitor() then
  set_gpus(NVIDIA, INTEL)
else
  set_gpus(INTEL, NVIDIA)
end

-- Patrate violet/roz pe Samsung (HDMI-A-2, NVIDIA): Intel randeaza in buffere COMPRIMATE
-- (Y_TILED_GEN12_RC_CCS_CC), iar la copia spre NVIDIA blocurile comprimate ajung ca gunoi colorat.
-- 1) copia intre GPU-uri in format liniar (necomprimat)
hl.env("AQ_FORCE_LINEAR_BLIT", "1")
-- 2) fara explicit sync pe copia multi-GPU: NVIDIA 550 nu-l suporta la KMS
hl.env("AQ_MGPU_NO_EXPLICIT", "1")
-- 3) plan B, doar daca 1+2 nu ajung: `touch ~/.config/hypr/intel-noccs` (opreste compresia Intel peste tot)
local noccs = io.open(os.getenv("HOME") .. "/.config/hypr/intel-noccs", "r")
if noccs then
  noccs:close()
  hl.env("INTEL_DEBUG", "noccs")
end

-- Brave / VSCodium (Electron) sa porneasca nativ pe Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

---- INPUT ----

hl.config({
    input = {
        kb_layout = "us,latam",
        follow_mouse = 1,
        sensitivity = 0.5,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },
})

-- LAYOUT
hl.config({
    dwindle = { preserve_split = true },
})
hl.config({
    master = { new_status = "master" },
})

-- MISC
hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        -- 1 nov 2026: 0 = o fereastra noua (ex. notificare Steam) NU mai scoate jocul din fullscreen; se deschide in spate.
        -- Implicit era 2 = scotea din fullscreen: CS2 a stat 29 min in fereastra 1904x1039 (logger 13:32). Cost: cat timp ceva e
        -- fullscreen, nu poti focaliza alta fereastra de pe ACELASI workspace fara sa iesi din fullscreen (SUPER+F).
        on_focus_under_fullscreen = 0,
    },
})

local f = os.getenv("HOME") .. "/.config/quickshell/state/devices.lua"
if io.open(f, "r") then dofile(f) end

---- SPLIT-OUT FILES ----

require("monitors")
require("keybinds")
require("look")
do
    local f = os.getenv("HOME") .. "/.config/quickshell/state/look.lua"
    local fh = io.open(f, "r")
    if fh then
        fh:close()
        local ok, err = pcall(dofile, f)
        if not ok then print("state/look.lua failed: " .. tostring(err)) end
    end
end
require("rules")

-- HyprMod managed settings
require("hyprland-gui")

-- Let applications follow the same XDG choice as Super+B.
hl.env("BROWSER", "python3 " .. os.getenv("HOME") .. "/.config/hypr/scripts/default-browser.py")
