#!/usr/bin/env python3
# Porteaza adaugirile Kali peste Bar.qml upstream 31245c8 (19 nov 2026). Derivat din port_bar2.py (merge 15 nov).
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
src = '''// Bar.qml — upstream 43PR bar (31245c8, 19 nov 2026) + Kali/laptop additions (merge 20 nov 2026):
//   • GPU stats from one long-lived `nvidia-smi -lms` (now in SystemStats.qml, shared with Settings)
//   • click on CPU / GPU / RAM opens the Task Manager (KDE System Monitor)
//   • GPU-smooth hover zoom on every module (scale transform, no reflow), capped inside its panel
//   • each bar shows only the workspaces of its own monitor (Bar settings → "Workspaces per monitor")
//   • CPU / GPU / RAM / temperature stats only on the main monitor (Bar settings → "Stats on main monitor only")
//   • media pill opens the MusicPreview card (sound waves); marquee scrolls pixel-smooth
//   • system tray (Discord, Steam...): app icons, menu in the bar's style (TrayMenu.qml)
//   • power button = wlogout; defaults = this machine's layout (top, floating, CPU/GPU/RAM as text)
''' + src
rep('import Quickshell.Services.UPower\n', 'import Quickshell.Services.UPower\nimport Quickshell.Widgets\n')

# 2. implicite: blocul Kali din bara locala + cheile noi upstream (19 nov)
la=loc.index('    readonly property var defaults: ({'); lb=loc.index('\n    })\n', la)
ua=src.index('    readonly property var defaults: ({'); ub=src.index('\n    })\n', ua)
d=loc[la:lb]
for o,n in [('margin: 4,', 'margin: 4, insetH: 11, insetV: 4,'),
            ('modPad: 6,', 'modPad: 6, islandGap: 4,'),
            ('wsNumbers: false,', 'wsStyle: "dots",'),
            ('        lightIcons: "normal",', '        trayArrow: false, lightIcons: "normal",'),
            ('clockPadHour: true,', 'clockPadHour: true, clockAmPm: true,'),
            ('weekMonday: true,\n', 'weekMonday: true,\n        weatherIcon: false, weatherF: false, weatherCity: "Oradea", weatherCase: "upper", weatherSymbol: true,   // Kali: oras fix (fara localizare dupa IP)\n        mediaMaxW: 180, mediaScroll: true,\n'),
            ('centerMods: "clock",', 'centerMods: "clock,weather",')]:
    if d.count(o)!=1: FAIL.append((d.count(o),'defaults: '+o)); continue
    d=d.replace(o,n)
import re
ku=set(re.findall(r'(\w+):', src[ua:ub])); kl=set(re.findall(r'(\w+):', d))
miss=ku-kl
if miss: FAIL.append((0,'chei upstream lipsa din implicitele Kali: '+','.join(sorted(miss))))
src=src[:ua]+d+src[ub:]

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
rep('        return alongBar ? alongMargin : 0;\n',
    '        return alongBar ? alongMargin : zoomPad;   // Kali: inner side = room for the hover zoom\n')

# 5. module: tray + power = wlogout
rep('cmd: "qs ipc call powermenu toggle", g: "\\u23FB",',
    'cmd: "$HOME/.config/hypr/scripts/wlogout.sh", g: "\\u23FB",   // Kali: wlogout; qs: "qs ipc call powermenu toggle"\n                                             ')
rep('''        case "bt":      return hasBt;
        case "tray":    return cfg.trayArrow ? SystemTray.items.values.length > 0 : hasTray;
        default:        return true;
        }
    }
''', '''        case "bt":      return hasBt;
        case "tray":    return trayModel.count > 0;   // Kali: our tray (TrayMenu.qml), nm-applet hidden
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
rep('                        renderType: root.vertical ? Text.QtRendering : Text.NativeRendering',
    '                        renderType: Text.QtRendering   // Kali: subpixel positioning, the smooth marquee glides instead of snapping')

# 11. click pe CPU / RAM / GPU = Task Manager
TM = '\n            interactive: true; primaryHint: "Open Task Manager"   // Kali: click = Task Manager\n            onPrimary: Quickshell.execDetached(["bash", root.taskManager])'
rep('''            label: "CPU"; icon: "\\uEF8E"; iconFont: Theme.tablerFont; pct: root.cpuUsage''',
    '''            label: "CPU"; icon: "\\uEF8E"; iconFont: Theme.tablerFont; pct: root.cpuUsage''' + TM)
rep('''            label: "RAM"; icon: "\\uD800\\uDEB7"; iconFont: Theme.tablerFont; pct: root.memPercent''',
    '''            label: "RAM"; icon: "\\uD800\\uDEB7"; iconFont: Theme.tablerFont; pct: root.memPercent''' + TM)
rep('''            label: "GPU"; icon: "\\uD800\\uDE99"; iconFont: Theme.tablerFont; known: root.gpuHasUsage''',
    '''            label: "GPU"; icon: "\\uD800\\uDE99"; iconFont: Theme.tablerFont; known: root.gpuHasUsage''' + TM)

# 12. workspace-uri per monitor
rep('''        id: wsDotsC
        Item {
            implicitWidth: root.vertical ? root.panelThick : wsLane.implicitWidth + 12''',
'''        id: wsDotsC
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
                        readonly property bool wide: modelData.focused && !root.wsNumbers
                        visible: modelData.id > 0''',
'''                    model: wsRoot.wsList
                    delegate: Rectangle {
                        id: dot
                        required property var modelData
                        readonly property bool current: wsRoot.isCurrent(modelData)
                        readonly property bool wide: current && !root.wsNumbers''')
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
rep('''            WheelHandler {
                enabled: cfg.wsScroll; acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: e => root.wsWheel(e.angleDelta.y)
            }
        }
    }
Component {
    id: wsC''',
'''            WheelHandler {
                enabled: cfg.wsScroll; acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                // Kali: previous / next workspace of THIS bar's monitor (wraps around); upstream e+1 / e-1 jumped
                // to the next open workspace on ANY monitor.
                onWheel: e => {
                    const l = wsRoot.wsList;
                    if (l.length === 0) return;
                    const cur = l.findIndex(w => wsRoot.isCurrent(w));
                    const i = cur < 0 ? 0 : (cur + (e.angleDelta.y > 0 ? 1 : -1) + l.length) % l.length;
                    root.run("hyprctl dispatch 'hl.dsp.focus({workspace=" + l[i].id + "})'");
                }
            }
        }
    }
Component {
    id: wsC''')

# 13. media: click = cardul MusicPreview (glyph-ul si banda noua upstream raman)
rep('''        id: mediaC
        Interactive {
            readonly property bool playing: mq.player !== null && mq.player.isPlaying === true
            readonly property real len: strip.totalW
            implicitWidth: root.vertical ? root.panelThick : len + 20; implicitHeight: root.vertical ? len + 20 : 18
            tip: mq.text; primaryHint: playing ? "Pause" : "Play"; secondaryHint: "Next track"
            tertiaryHint: "Previous track"; onPrimary: root.mediaAct("toggle"); onSecondary: root.mediaAct("next")
            onTertiary: root.mediaAct("prev")''',
'''        id: mediaC
        // Kali — media: left click drops the MusicPreview card under the pill; right = next, middle = play / pause.
        Interactive {
            readonly property bool playing: mq.player !== null && mq.player.isPlaying === true
            readonly property real len: strip.totalW
            readonly property var barWin: QsWindow.window
            implicitWidth: root.vertical ? root.panelThick : len + 20; implicitHeight: root.vertical ? len + 20 : 18
            tip: mq.text; secondaryHint: "Next track"
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

# 13b. mq: acelasi player ca MusicPreview / VolumeOsd (singletonul nostru Marquee) + defilare lina
rep('''        readonly property var player: {
            const ps = Mpris.players.values;
            return ps.find(p => p.isPlaying) ?? ps[0] ?? null;
        }
        readonly property bool playing: player !== null && player.isPlaying''',
'''        // Kali: same player as MusicPreview / VolumeOsd (Marquee.qml prefers the instance with cover art)
        readonly property var player: Marquee.player
        readonly property bool playing: player !== null && player.isPlaying''')
rep('''        property int x: 0
        property bool hold: true
''', '''        property real x: 0   // Kali: real, glides every frame
        readonly property int speed: 40   // px per second
''')
rep('''        onAnimatingChanged: { x = 0; hold = true; }
        onTitleChanged: { x = 0; hold = true; }
        onMaxWChanged: { x = 0; hold = true; }

        Timer {
            interval: mq.holdMs
            repeat: false
            running: mq.animating && mq.hold
            onTriggered: mq.hold = false
        }
        Timer {
            interval: mq.interval
            repeat: true
            running: mq.animating && !mq.hold
            onTriggered: {
                mq.x -= mq.step;
                if (mq.x <= -(mq.textW + mq.gap)) {
                    mq.x = 0;
                    mq.hold = true;
                }
            }
        }
''', '''        // Kali: pixel-smooth glide at the display's refresh rate instead of 1 px every 33 ms (read as jerky
        // on the 144 / 240 Hz screens). Hold at the start, glide one copy left, jump back seamlessly, repeat.
        SequentialAnimation {
            id: mqScroll
            running: mq.animating
            loops: Animation.Infinite
            PropertyAction { target: mq; property: "x"; value: 0 }
            PauseAnimation { duration: mq.holdMs }
            NumberAnimation {
                target: mq; property: "x"; from: 0; to: -(mq.textW + mq.gap)
                duration: Math.max(1000, (mq.textW + mq.gap) / mq.speed * 1000)
            }
        }
        onAnimatingChanged: x = 0
        onTitleChanged: { x = 0; if (animating) mqScroll.restart(); }
        onMaxWChanged: { x = 0; if (animating) mqScroll.restart(); }
''')

# 14. componenta tray (copiata din bara locala)
a = loc.index('    // System tray (StatusNotifierItem): one icon per app that offers one')
b = loc.index('    Component {\n        id: volumeC', a)
ta = src.index('Component {\n    id: trayIconC'); tb = src.index('    Component {\n        id: mediaC')
src = src[:ta] + loc[a:b] + src[tb:]   # Kali: our tray (TrayMenu.qml) replaces upstream's trayIconC / trayArrowC / trayC

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

rep('                player: Marquee.player\n', '                player: mq.player\n')

# 16. spatiere (upstream 19 nov a schimbat sensul lui modPad: din padding in jurul fiecarei iconite in gol intre module).
#     Kali: in modul ne-insule modulele vecine sunt separate de modPad, dar statisticile (CPU/GPU/RAM/temp) raman lipite
#     (le desparte doar statsGap), ca inainte. Modul "islands" ramane exact ca upstream.
rep('''    function groupsOf(ids) {
        if (!islands) return [ids];''', '''    function groupsOf(ids) {
        // Kali: grouped in every style (stats side by side), not only for islands''')
rep('''            id: laneItem; anchors.centerIn: parent; gap: root.islands ? root.effGap + root.islandGapPx : 0''',
    '''            id: laneItem; anchors.centerIn: parent; gap: root.islands ? root.effGap + root.islandGapPx : root.modPadPx   // Kali''')
rep('''                        id: islLane; anchors.centerIn: parent; gap: root.modPadPx''',
    '''                        id: islLane; anchors.centerIn: parent; gap: root.islands ? root.modPadPx : 0   // Kali: stats stay together''')

open(sys.argv[3], 'w', encoding='utf-8').write(src)
print("Bar.qml portat:", src.count('\n'), "linii;", len(FAIL), "ancore ratate")
for c, o in FAIL: print(f"  gasit {c}x: {o!r}")
sys.exit(1 if FAIL else 0)
