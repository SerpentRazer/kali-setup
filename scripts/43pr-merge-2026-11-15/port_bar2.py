#!/usr/bin/env python3
# Porteaza adaugirile Kali (bara noastra de pe 1 nov) peste Bar.qml upstream e4b8fdf (14 nov 2026).
# Uz: python3 -I port_bar2.py <upstream Bar.qml> <Bar.qml local actual> <iesire>
import sys
src = open(sys.argv[1], encoding='utf-8').read()
loc = open(sys.argv[2], encoding='utf-8').read()
FAIL = []
def rep(old, new, count=1):
    global src
    c = src.count(old)
    if c != count:
        FAIL.append((c, old[:160])); return
    src = src.replace(old, new)

# 1. antet + importuri
src = '''// Bar.qml — upstream 43PR bar (e4b8fdf, 14 nov 2026) + Kali/laptop additions (merge 15 nov 2026):
//   • GPU stats from one long-lived `nvidia-smi -lms` (now in SystemStats.qml, shared with Settings)
//   • click on CPU / GPU / RAM opens the Task Manager (KDE System Monitor)
//   • GPU-smooth hover zoom on every module (scale transform, no reflow), capped inside its panel
//   • each bar shows only the workspaces of its own monitor (Bar settings → "Workspaces per monitor")
//   • CPU / GPU / RAM / temperature stats only on the main monitor (Bar settings → "Stats on main monitor only")
//   • media pill opens the MusicPreview card (sound waves); marquee scrolls pixel-smooth
//   • system tray (Discord, Steam...): app icons, menu in the bar's style (TrayMenu.qml)
//   • power button = wlogout; defaults = this machine's layout (top, floating, CPU/GPU/RAM as text)
''' + src
rep('import Quickshell.Services.UPower\n', 'import Quickshell.Services.UPower\nimport Quickshell.Widgets\nimport Quickshell.Services.SystemTray\n')

# 2. implicite Kali (starea salvata a userului le suprascrie oricum pe cele pe care le are)
rep('        position: "left", style: "islands", thickness: 22, margin: 4,',
    '        // Kali defaults (upstream: left / islands / 22 / barScale 0.75 / radius 34 / stats as rings)\n'
    '        position: "top", style: "floating", thickness: 24, margin: 4,')
rep('scale: 1, barScale: 0.75, bgOpacity: 0.2, border: true, borderOpacity: 0.15, radius: 34,',
    'scale: 1, barScale: 1, bgOpacity: 0.5, border: false, borderOpacity: 0.15, radius: 10,')
rep('modPad: 6, wsDot: 16, wsGap: 10, wsScroll: true, wsNumbers: true,',
    'modPad: 6, wsDot: 16, wsGap: 10, wsScroll: true, wsNumbers: false,')
rep('statsRing: true, statsNumbers: false, statsPercent: false,',
    'statsRing: false, statsNumbers: true, statsPercent: true,')
rep('        batNumber: false, batPercent: false, batRing: true, batLabel: false,\n',
    '        batNumber: false, batPercent: false, batRing: true, batLabel: false,\n'
    '        hoverZoom: true, wsPerMonitor: true, statsMainOnly: true,   // Kali\n')
rep('hidden: "wall,settings,bright,ws,tasks,gputemp,gpu,night",', 'hidden: "wall,settings,bright,tasks,night",')
rep('startMods: "notif,cpu,tasks,gpu,gputemp,ram,cputemp,ws",', 'startMods: "cpu,gpu,ram,cputemp,gputemp,ws",')
rep('endMods: "media,night,bright,volume,battery,wall,settings,bt,net,power"',
    'endMods: "media,tray,night,bright,volume,battery,bt,net,notif,wall,settings,power"')

# 3. adaptorul cfg
rep('property bool statsPercent: root.defaults.statsPercent; property bool statsIcons: root.defaults.statsIcons\n',
    'property bool statsPercent: root.defaults.statsPercent; property bool statsIcons: root.defaults.statsIcons\n'
    '            property bool hoverZoom: root.defaults.hoverZoom          // Kali: modules grow a bit under the pointer\n'
    '            property bool wsPerMonitor: root.defaults.wsPerMonitor    // Kali: each bar shows only its monitor\'s workspaces\n'
    '            property bool statsMainOnly: root.defaults.statsMainOnly  // Kali: CPU / GPU / RAM / temps only on the main monitor\n')

# 4. proprietati Kali
rep('    readonly property var config: cfg; Component.onCompleted: BluetoothState.init()\n',
    '    readonly property var config: cfg; Component.onCompleted: BluetoothState.init()\n'
    '    // Kali\n'
    '    readonly property real hoverScale: 1.15\n'
    '    // extra transparent room on the inner side of the bar so a zoomed module isn\'t clipped\n'
    '    readonly property int zoomPad: cfg.hoverZoom ? 4 : 0\n'
    '    readonly property string taskManager: Quickshell.env("HOME") + "/.config/hypr/scripts/open-taskmanager.sh"\n'
    '    readonly property var trayHidden: ["nm-applet"]   // tray icons the bar already has a module for\n')
rep('        return alongBar ? effGap : 0;\n',
    '        return alongBar ? effGap : zoomPad;   // Kali: inner side = room for the hover zoom\n')

# 5. module: tray + power = wlogout
rep('        { id: "media",    l: "Media" },\n',
    '        { id: "media",    l: "Media" },\n        { id: "tray",     l: "System tray" },\n')
rep('cmd: "qs ipc call powermenu toggle", g: "\\u23FB",',
    'cmd: "$HOME/.config/hypr/scripts/wlogout.sh", g: "\\u23FB",   // Kali: wlogout; qs: "qs ipc call powermenu toggle"\n                                             ')
rep('        ws: wsC, tasks: tasksC, media: mediaC, volume: volumeC,',
    '        ws: wsC, tasks: tasksC, media: mediaC, tray: trayC, volume: volumeC,')
rep('''        case "bt":      return hasBt;
        default:        return true;
        }
    }
''', '''        case "bt":      return hasBt;
        case "tray":    return trayModel.count > 0;
        default:        return true;
        }
    }
    // Kali: the resource stats live only on the main monitor = the screen at 0,0 (Samsung in monitors.lua;
    // the laptop sits at -1920,0). Laptop alone → it is the only screen → stats there.
    readonly property string mainScreen: {
        const l = Quickshell.screens;
        const m = l.find(sc => sc.x === 0 && sc.y === 0) ?? l[0];
        return m ? m.name : "";
    }
    function modVisibleOn(id, screenName) {
        if (cfg.statsMainOnly && statIds.indexOf(id) >= 0 && Quickshell.screens.length > 1
                && screenName !== "" && screenName !== mainScreen) return false;
        return modVisible(id);
    }
''')

# 6. run detasat + modelul tray (copiat din bara locala)
a = loc.index('    // ───────────────────────── System tray (Kali)')
b = loc.index('    // Kali: detached — two quick clicks never drop a command', a)
rep('    Process { id: runner }\n    function run(cmd) { runner.command = ["sh", "-c", cmd]; runner.running = true; }\n',
    loc[a:b] + '    // Kali: detached — two quick clicks never drop a command (a single shared Process would)\n'
    '    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }\n')

# 7. tooltip opac (popup-urile n-au blur)
rep('anchors.fill: parent; radius: Math.min(cfg.radius, height / 2); color: root.bgColor\n',
    'anchors.fill: parent; radius: Math.min(cfg.radius, height / 2)\n'
    '                    color: Qt.alpha(Theme.bg, Math.max(cfg.bgOpacity, 0.88))   // Kali: popups get no blur, text bled through\n')

# 8. hover zoom in Interactive
a = loc.index('        // Kali — hover zoom: a scale transform')
b = loc.index('        Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }', a)
zoom = loc[a:b] + '        Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }\n'
rep('''        opacity: disabled ? 0.4 : 1
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Rectangle {
            anchors.fill: parent; anchors.margins: 1; anchors.verticalCenterOffset: 3; radius: Theme.radius''',
'''        opacity: disabled ? 0.4 : 1
        Behavior on opacity { NumberAnimation { duration: 120 } }
''' + zoom + '''        Rectangle {
            anchors.fill: parent; anchors.margins: 1; anchors.verticalCenterOffset: 3; radius: Theme.radius''')

# 9. Slot: vizibil per monitor + modulul marit deasupra vecinilor
rep('visible: root.modVisible(modelData); Layout.alignment: Qt.AlignCenter; z: dragging ? 100 : 0',
    'visible: root.modVisibleOn(modelData, QsWindow.window && QsWindow.window.screen ? QsWindow.window.screen.name : "")\n'
    '        Layout.alignment: Qt.AlignCenter\n'
    '        z: dragging ? 100 : (item && item.hovered === true ? 1 : 0)   // Kali: a zoomed module draws over its neighbours')

# 10. marquee lin
rep('renderType: root.vertical ? Text.QtRendering : Text.NativeRendering',
    'renderType: Text.QtRendering   // Kali: subpixel positioning, the smooth marquee glides instead of snapping')

# 11. click pe CPU / RAM / GPU = Task Manager
TM = '\n            interactive: true; primaryHint: "Open Task Manager"   // Kali: click = Task Manager\n            onPrimary: Quickshell.execDetached(["bash", root.taskManager])'
rep('''            label: "CPU"; icon: "\\uEF8E"; iconFont: Theme.tablerFont; pct: root.cpuUsage''',
    '''            label: "CPU"; icon: "\\uEF8E"; iconFont: Theme.tablerFont; pct: root.cpuUsage''' + TM)
rep('''            label: "RAM"; icon: "\\uD800\\uDEB7"; iconFont: Theme.tablerFont; pct: root.memPercent''',
    '''            label: "RAM"; icon: "\\uD800\\uDEB7"; iconFont: Theme.tablerFont; pct: root.memPercent''' + TM)
rep('''            label: "GPU"; icon: "\\uD800\\uDE99"; iconFont: Theme.tablerFont; known: root.gpuHasUsage''',
    '''            label: "GPU"; icon: "\\uD800\\uDE99"; iconFont: Theme.tablerFont; known: root.gpuHasUsage''' + TM)

# 12. workspace-uri per monitor
rep('''        id: wsC
        Item {
            implicitWidth: root.vertical ? root.panelThick : wsLane.implicitWidth + 12''',
'''        id: wsC
        Item {
            id: wsRoot
            // Kali: which monitor this bar instance lives on. With "Workspaces per monitor" each bar shows only
            // its own monitor's workspaces, and the wide dot is the workspace that monitor is showing.
            readonly property string monName: QsWindow.window && QsWindow.window.screen ? QsWindow.window.screen.name : ""
            readonly property var hlMon: Hyprland.monitors.values.find(m => m.name === monName) ?? null
            readonly property var wsList: {
                const all = Hyprland.workspaces.values.filter(w => w.id > 0);
                const mine = cfg.wsPerMonitor ? all.filter(w => w.monitor && w.monitor.name === monName) : all;
                return mine.sort((a, b) => a.id - b.id);
            }
            function isCurrent(ws) {
                if (!cfg.wsPerMonitor) return ws.focused;
                return !!(hlMon && hlMon.activeWorkspace && hlMon.activeWorkspace.id === ws.id);
            }
            // per monitor: the laptop's 11-20 read as 1-10, matching SUPER+1..0 on that screen
            function shownId(ws) { return cfg.wsPerMonitor ? (ws.id - 1) % 10 + 1 : ws.id; }
            implicitWidth: root.vertical ? root.panelThick : wsLane.implicitWidth + 12''')
rep('''                    model: Hyprland.workspaces
                    delegate: Rectangle {
                        id: dot
                        required property var modelData
                        readonly property bool wide: modelData.focused && !cfg.wsNumbers; visible: modelData.id > 0''',
'''                    model: wsRoot.wsList
                    delegate: Rectangle {
                        id: dot
                        required property var modelData
                        readonly property bool current: wsRoot.isCurrent(modelData)
                        readonly property bool wide: current && !cfg.wsNumbers''')
rep('''                             : modelData.focused ? Qt.alpha(Theme.accent2, 0.5)''',
    '''                             : current ? Qt.alpha(Theme.accent2, 0.5)''')
rep('''                                text: dot.modelData.id; color: Theme.text; font.family: Theme.iconFont
                                font.pixelSize: Math.round(root.wsBoxPx * 0.62); font.bold: dot.modelData.focused''',
    '''                                text: wsRoot.shownId(dot.modelData); color: Theme.text; font.family: Theme.iconFont
                                font.pixelSize: Math.round(root.wsBoxPx * 0.62); font.bold: dot.current''')
rep('''                            title: "Workspace " + dot.modelData.id
                                   + (dot.modelData.urgent ? " · urgent" : dot.modelData.focused ? " · focused" : "")''',
    '''                            title: "Workspace " + wsRoot.shownId(dot.modelData)
                                   + (dot.modelData.urgent ? " · urgent" : dot.modelData.focused ? " · focused"
                                      : dot.current ? " · shown" : "")''')
rep('''                onWheel: e => root.run("hyprctl dispatch 'hl.dsp.focus({workspace=\\"e"
                                       + (e.angleDelta.y > 0 ? "+1" : "-1") + "\\"})'")''',
'''                // Kali: previous / next workspace of THIS bar's monitor (wraps around); upstream e+1 / e-1 jumped
                // to the next open workspace on ANY monitor.
                onWheel: e => {
                    const l = wsRoot.wsList;
                    if (l.length === 0) return;
                    const cur = l.findIndex(w => wsRoot.isCurrent(w));
                    const i = cur < 0 ? 0 : (cur + (e.angleDelta.y > 0 ? 1 : -1) + l.length) % l.length;
                    root.run("hyprctl dispatch 'hl.dsp.focus({workspace=" + l[i].id + "})'");
                }''')

# 13. media: click = cardul MusicPreview
rep('''        id: mediaC
        Interactive {
            readonly property bool playing: Marquee.player !== null && Marquee.player.isPlaying === true
            readonly property real len: Math.min(Marquee.textW, Marquee.maxW)
            implicitWidth: root.vertical ? root.panelThick : len + 20; implicitHeight: root.vertical ? len + 20 : 18
            tip: Marquee.text; primaryHint: playing ? "Pause" : "Play"; secondaryHint: "Next track"
            tertiaryHint: "Previous track"; onPrimary: root.mediaAct("toggle"); onSecondary: root.mediaAct("next")
            onTertiary: root.mediaAct("prev")''',
'''        id: mediaC
        // Kali — media: left click drops the MusicPreview card under the pill; right = next, middle = play / pause.
        Interactive {
            readonly property bool playing: Marquee.player !== null && Marquee.player.isPlaying === true
            readonly property real len: Math.min(Marquee.textW, Marquee.maxW)
            readonly property var barWin: QsWindow.window
            implicitWidth: root.vertical ? root.panelThick : len + 20; implicitHeight: root.vertical ? len + 20 : 18
            tip: Marquee.text; secondaryHint: "Next track"
            active: barWin ? barWin.musicOpen === true : false
            primaryHint: active ? "Close player" : "Open player"
            tertiaryHint: playing ? "Pause" : "Play"
            onPrimary: {
                if (!barWin) return;
                const c = mapToItem(barWin.contentItem, width / 2, height / 2);
                barWin.musicAnchor = Qt.point(c.x, c.y);
                barWin.trayItem = null;
                barWin.musicOpen = !barWin.musicOpen;
            }
            onSecondary: root.mediaAct("next")
            onTertiary: root.mediaAct("toggle")''')

# 14. componenta tray (copiata din bara locala)
a = loc.index('    // System tray (StatusNotifierItem): one icon per app that offers one')
b = loc.index('    Component {\n        id: volumeC', a)
rep('    Component {\n        id: volumeC', loc[a:b] + '    Component {\n        id: volumeC')

# 15. fereastra barei: zoomPad, masca, MusicPreview + TrayMenu
rep('''            implicitWidth: root.vertical ? root.panelThick + root.effEdge : 0
            implicitHeight: root.vertical ? 0 : root.panelThick + root.effEdge
            exclusionMode: cfg.reserveSpace ? ExclusionMode.Auto : ExclusionMode.Ignore; color: "transparent"
            visible: root.barVisible
''', '''            // Kali — zoomPad: transparent room on the inner side for the hover zoom. It is not part of the
            // exclusive zone (windows don't move) and the input mask keeps it click-through.
            implicitWidth: root.vertical ? root.panelThick + root.effEdge + root.zoomPad : 0
            implicitHeight: root.vertical ? 0 : root.panelThick + root.effEdge + root.zoomPad
            exclusionMode: cfg.reserveSpace ? ExclusionMode.Normal : ExclusionMode.Ignore; color: "transparent"
            exclusiveZone: root.panelThick + root.effEdge
            mask: Region { item: frame }
            visible: root.barVisible
            // Kali: MusicPreview card for this screen (opened by the media module)
            property bool musicOpen: false
            property point musicAnchor: Qt.point(0, 0)
            MusicPreview {
                host: bar
                screen: bar.screen
                player: Marquee.player
                position: cfg.position
                barThick: root.panelThick + root.effEdge
            }
            // Kali: menu of a tray icon on this screen (opened by the tray module)
            property var trayItem: null
            property point trayAnchor: Qt.point(0, 0)
            TrayMenu {
                host: bar
                screen: bar.screen
                position: cfg.position
                barThick: root.panelThick + root.effEdge
            }
''')

open(sys.argv[3], 'w', encoding='utf-8').write(src)
print("Bar.qml portat:", src.count('\n'), "linii;", len(FAIL), "ancore ratate")
for c, o in FAIL: print(f"  gasit {c}x: {o!r}")
sys.exit(1 if FAIL else 0)
