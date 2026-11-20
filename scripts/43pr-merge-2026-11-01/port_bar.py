import sys
S = sys.argv[1]
src = open(f'{S}/upstream/.config/quickshell/Bar.qml').read()
def rep(old, new, count=1):
    global src
    c = src.count(old)
    assert c == count, (c, old[:120])
    src = src.replace(old, new)

# 1. header
src = '''// Bar.qml — upstream 43PR bar (c998d6d, 31 oct 2026) + Kali/laptop additions (merge 1 nov 2026):
//   • GPU module fed by one long-lived `nvidia-smi -lms` on NVIDIA (upstream spawns sh + nvidia-smi every 2 s)
//   • click on CPU / GPU / RAM opens the Task Manager (KDE System Monitor)
//   • GPU-smooth hover zoom on every module (scale transform, no reflow), capped inside its panel
//   • each bar shows only the workspaces of its own monitor (Bar settings → "Workspaces per monitor")
//   • media pill opens the MusicPreview card (looks like the VolumeOsd media popup, sound waves);
//     marquee scrolls pixel-smooth (Marquee.qml)
//   • system tray (Discord, Steam, nm-applet...): app icons, menu in the bar's style (TrayMenu.qml)
//   • power button = wlogout; defaults = this machine's layout (top, floating, CPU/GPU/RAM visible)
''' + src

# 2. imports
rep('import Quickshell.Services.UPower\n', 'import Quickshell.Services.UPower\nimport Quickshell.Widgets\nimport Quickshell.Services.SystemTray\n')

# 3. defaults
rep('''        // layout
        position: "left", style: "joined", thickness: 20, margin: 4,''',
'''        // Kali defaults (upstream: left / joined / thickness 20 / radius 16 / stats hidden)
        // layout
        position: "top", style: "floating", thickness: 24, margin: 4,''')
rep('scale: 1.0, barScale: 1.0, bgOpacity: 0.5, border: false, radius: 16, calRadius: 15, calScale: 1.0,',
    'scale: 1.0, barScale: 1.0, bgOpacity: 0.5, border: false, radius: 10, calRadius: 15, calScale: 1.0,\n        // Kali\n        hoverZoom: true, wsPerMonitor: true,')
rep('''        hidden: "cpu,ram,gpu,temp,wall,settings,tasks",
        startMods: "cpu,ram,gpu,temp,ws",''',
'''        hidden: "temp,wall,settings,tasks",
        startMods: "cpu,gpu,ram,temp,ws",''')
rep('endMods: "media,volume,battery,net,notif,wall,settings,power"', 'endMods: "media,tray,volume,battery,net,notif,wall,settings,power"')

# 4. cfg adapter
rep('            property bool border: root.defaults.border\n',
    '            property bool border: root.defaults.border\n'
    '            property bool hoverZoom: root.defaults.hoverZoom     // Kali: modules grow a bit under the pointer\n'
    '            property bool wsPerMonitor: root.defaults.wsPerMonitor // Kali: each bar shows only its monitor\'s workspaces\n')

# 5. Kali constants
rep('    readonly property var config: cfg\n',
    '''    readonly property var config: cfg

    // Kali
    readonly property real hoverScale: 1.15
    // extra transparent room on the inner side of the bar so a zoomed module isn't clipped
    readonly property int zoomPad: cfg.hoverZoom ? 4 : 0
    readonly property string taskManager: Quickshell.env("HOME") + "/.config/hypr/scripts/open-taskmanager.sh"
    readonly property var trayHidden: ["nm-applet"]   // tray icons the bar already has a module for
''')

# 6. edgeMargin
rep('        return alongBar ? effGap : 0;\n', '        return alongBar ? effGap : zoomPad;   // Kali: inner side = room for the hover zoom\n')

# 7. moduleDefs
rep('        { id: "media",    l: "Media" },\n', '        { id: "media",    l: "Media" },\n        { id: "tray",     l: "System tray" },\n')
rep('{ id: "power",    l: "Power",         cmd: "qs ipc call powermenu toggle", g: "\\u23FB",',
    '{ id: "power",    l: "Power",         cmd: "$HOME/.config/hypr/scripts/wlogout.sh", g: "\\u23FB", // Kali: wlogout; qs: "qs ipc call powermenu toggle"\n                                             ')
# 8. comps
rep('ws: wsC, tasks: tasksC, media: mediaC, volume: volumeC,', 'ws: wsC, tasks: tasksC, media: mediaC, tray: trayC, volume: volumeC,')
# 9. csv migration
rep('''    // The old combined "stats" module is migrated to "cpu" + "ram" in saved configs.''',
    '''    // The old combined "stats" module is migrated to "cpu" + "gpu" + "ram" in saved configs
    // (Kali: our old stats module showed the GPU too; upstream migrates to cpu + ram only).''')
rep('x === "stats" ? out.push("cpu", "ram") : out.push(x);', 'x === "stats" ? out.push("cpu", "gpu", "ram") : out.push(x);')
# 10. modVisible
rep('        case "battery": return battery !== null;\n', '        case "battery": return battery !== null;\n        case "tray":    return trayModel.count > 0;\n')

# 11. GPU: persistent nvidia-smi
rep('''    // GPU usage / temps (only while the GPU or temperature module is enabled)
    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: root.barVisible && (root.isOn("gpu") || root.isOn("temp"))
        onTriggered: { if (!gpuProc.running) gpuProc.running = true; }
    }''',
'''    // GPU usage / temps (only while the GPU or temperature module is enabled)
    // Kali: on NVIDIA one long-lived `nvidia-smi -lms 2000` feeds the same updateGpuFromProbe()
    // (measured 16 oct on the RTX 3060: ~0.1% CPU vs ~1% for spawning sh + nvidia-smi every 2 s).
    // If nvidia-smi is missing / keeps dying without output (3x), the upstream probe takes over.
    readonly property bool gpuWanted: root.barVisible && (root.isOn("gpu") || root.isOn("temp"))
    property bool nvLive: false
    property int nvFails: 0
    readonly property bool nvOk: nvFails < 3
    Process {
        id: nvProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu",
                  "--format=csv,noheader,nounits", "-lms", "2000"]
        stdout: SplitParser {
            onRead: data => {
                const f = data.split(",").map(s => parseInt(s));
                if (isNaN(f[0])) return;
                root.nvLive = true;
                root.updateGpuFromProbe(f[0] + " " + (isNaN(f[1]) ? "-" : f[1]));
            }
        }
        onExited: { if (!root.nvLive) root.nvFails++; root.nvLive = false; }
    }
    onGpuWantedChanged: if (!gpuWanted) nvProc.running = false
    Timer {   // starts it, and restarts it if it ever dies (driver reload)
        interval: 10000; repeat: true; triggeredOnStart: true
        running: root.gpuWanted && root.nvOk
        onTriggered: if (!nvProc.running) nvProc.running = true
    }
    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: root.gpuWanted && !root.nvOk
        onTriggered: { if (!gpuProc.running) gpuProc.running = true; }
    }''')

# 12 + 13. run detached + tray model
rep('''    Process { id: runner }
    function run(cmd) { runner.command = ["sh", "-c", cmd]; runner.running = true; }''',
'''    // ───────────────────────── System tray (Kali) ─────────────────────────
    // The tray module repeats over trayModel, not over SystemTray.items: a Repeater on the live list
    // deletes an icon the moment its app quits, so it could never animate out. Here an app that goes
    // away is only marked `leaving`, its icon shrinks / fades, and trayGc drops it afterwards.
    // Keys are numbers handed out per SystemTrayItem (the same object always gets the same key).
    ListModel { id: trayModel }          // roles: key (int), leaving (bool)
    property int _trayNext: 0
    property var _trayKeys: new Map()
    function trayKeyOf(item) {
        if (!_trayKeys.has(item)) _trayKeys.set(item, ++_trayNext);
        return _trayKeys.get(item);
    }
    function trayItemOf(key) { return trayLive.find(i => trayKeyOf(i) === key) ?? null; }
    readonly property var trayLive: SystemTray.items.values.filter(i => trayHidden.indexOf(i.id) < 0)
    onTrayLiveChanged: {
        const live = trayLive.map(trayKeyOf);
        const have = [];
        for (let i = 0; i < trayModel.count; i++) {
            const e = trayModel.get(i);
            have.push(e.key);
            if (!e.leaving && live.indexOf(e.key) < 0) trayModel.setProperty(i, "leaving", true);
        }
        for (const k of live)
            if (have.indexOf(k) < 0) trayModel.append({ key: k, leaving: false });
        trayGc.restart();
    }
    Timer {
        id: trayGc
        interval: Theme.animMed + 80
        onTriggered: {
            for (let i = trayModel.count - 1; i >= 0; i--)
                if (trayModel.get(i).leaving) trayModel.remove(i);
        }
    }

    // Kali: detached — two quick clicks never drop a command (a single shared Process would)
    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }''')

# 14. Tip popup colour
rep('''                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(cfg.radius, height / 2)
                    color: root.bgColor
                    border.width: 1
                    border.color: root.borderColor

                    Column {
                        id: tcol''',
'''                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(cfg.radius, height / 2)
                    // Kali: popups get no blur, so at the bar's 50% the text behind bled through
                    color: Qt.alpha(Theme.bg, Math.max(cfg.bgOpacity, 0.88))
                    border.width: 1
                    border.color: root.borderColor

                    Column {
                        id: tcol''')

# 15. Interactive zoom
rep('''        opacity: disabled ? 0.4 : 1
        Behavior on opacity { NumberAnimation { duration: 120 } }

        // state layer: pressed > active > warning, with a hover overlay''',
'''        opacity: disabled ? 0.4 : 1
        Behavior on opacity { NumberAnimation { duration: 120 } }

        // Kali — hover zoom: a scale transform, so it animates at the display's refresh rate and the
        // neighbours never reflow (animating font-size would jump in whole pixels).
        // Capped so the zoomed module stays inside its black panel: a wide module at the panel's
        // end (media pill, CPU, clock) only grows into the panel's padding instead of spilling out.
        property real zoomTo: root.hoverScale
        function fitZoom() {
            let p = parent;
            while (p && p.lane === undefined) p = p.parent;     // the Panel holding this module
            if (!p) return root.hoverScale;
            if (root.joined) p = p.parent;                      // joined / strip: one background for the whole bar
            const o = mapToItem(p, 0, 0);
            const v = root.vertical;
            const len = v ? height : width, across = v ? width : height;
            const pos = v ? o.y : o.x;
            const plen = v ? p.height : p.width, pacross = v ? p.width : p.height;
            const room = Math.min(pos, plen - pos - len) + 1;   // +1: the state layer sits 1 px inside
            const along = 1 + 2 * Math.max(0, room) / Math.max(1, len);
            const acr = pacross / Math.max(1, across - 2);
            return Math.max(1, Math.min(root.hoverScale, along, acr));
        }
        onHoveredChanged: if (hovered) zoomTo = fitZoom()
        scale: cfg.hoverZoom && hovered && interactive ? zoomTo : 1.0
        z: hovered ? 1 : 0
        Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

        // state layer: pressed > active > warning, with a hover overlay''')

# 16. Slot z
rep('        z: dragging ? 100 : 0\n', '        z: dragging ? 100 : (item && item.hovered === true ? 1 : 0)   // Kali: a zoomed module draws over its neighbours\n')
# 17. marquee render
rep('                    renderType: root.vertical ? Text.QtRendering : Text.NativeRendering\n',
    '                    renderType: Text.QtRendering   // Kali: subpixel positioning, the smooth marquee glides instead of snapping\n')

# 18. stats click -> Task Manager
for lab, extra in (("CPU", ""), ("RAM", ""), ("GPU", "")):
    pass
rep('''            label: "CPU"
            unit: "%"''', '''            label: "CPU"
            unit: "%"
            interactive: true                       // Kali: click = Task Manager
            primaryHint: "Open Task Manager"
            onPrimary: Quickshell.execDetached(["bash", root.taskManager])''')
rep('''            label: "RAM"
            unit: "%"''', '''            label: "RAM"
            unit: "%"
            interactive: true
            primaryHint: "Open Task Manager"
            onPrimary: Quickshell.execDetached(["bash", root.taskManager])''')
rep('''            label: "GPU"
            unit: root.gpuHasUsage ? "%" : ""''', '''            label: "GPU"
            unit: root.gpuHasUsage ? "%" : ""
            interactive: true
            primaryHint: "Open Task Manager"
            onPrimary: Quickshell.execDetached(["bash", root.taskManager])''')
rep('            tip: root.gpuHasUsage ? "GPU usage: " + root.gpuUsage + "%" : "GPU usage: unavailable"',
    '            tip: root.gpuHasUsage ? "GPU usage: " + root.gpuUsage + "%" + (root.gpuTemp >= 0 ? " · " + root.gpuTemp + "°C" : "")\n                                  : "GPU usage: unavailable"')

# 19. workspaces per monitor
rep('''        id: wsC
        Item {
            implicitWidth: root.vertical ? root.panelThick : wsLane.implicitWidth + 12''',
'''        id: wsC
        Item {
            id: wsRoot
            // Kali: which monitor this bar instance lives on. With "Workspaces per monitor" each bar
            // shows only its own monitor's workspaces, and the wide dot is the workspace that
            // monitor is showing (not the globally focused one) — combined was confusing on 2 screens.
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

            implicitWidth: root.vertical ? root.panelThick : wsLane.implicitWidth + 12''')
rep('''                Repeater {
                    model: Hyprland.workspaces
                    delegate: Rectangle {
                        id: dot
                        required property var modelData
                        visible: modelData.id > 0
                        Layout.alignment: Qt.AlignCenter
                        implicitWidth: root.vertical ? root.wsDotPx
                                     : (modelData.focused ? Math.round(root.wsDotPx * 3.2) : root.wsDotPx)
                        implicitHeight: root.vertical ? (modelData.focused ? Math.round(root.wsDotPx * 2.4) : root.wsDotPx)
                                                      : root.wsDotPx
                        radius: root.wsDotPx / 2
                        color: modelData.urgent ? Theme.danger
                             : modelData.focused ? Qt.alpha(Theme.accent, 0.2)
                             : dotMa.containsMouse ? Theme.accent2
                             : Qt.alpha(Theme.textFaint, 0.5)
''', '''                Repeater {
                    model: wsRoot.wsList
                    delegate: Rectangle {
                        id: dot
                        required property var modelData
                        readonly property bool current: wsRoot.isCurrent(modelData)
                        Layout.alignment: Qt.AlignCenter
                        implicitWidth: root.vertical ? root.wsDotPx
                                     : (current ? Math.round(root.wsDotPx * 3.2) : root.wsDotPx)
                        implicitHeight: root.vertical ? (current ? Math.round(root.wsDotPx * 2.4) : root.wsDotPx)
                                                      : root.wsDotPx
                        radius: root.wsDotPx / 2
                        // Kali: upstream draws the current one at accent 0.2 — next to the 0.5 faint dots it was
                        // hard to tell which workspace a screen shows, so it is solid here (like the old bar)
                        color: modelData.urgent ? Theme.danger
                             : current ? Qt.alpha(Theme.accent, 0.85)
                             : dotMa.containsMouse ? Theme.accent2
                             : Qt.alpha(Theme.textFaint, 0.5)
                        Behavior on color { ColorAnimation { duration: Theme.animMed } }
''')
rep('''                            title: "Workspace " + dot.modelData.id
                                   + (dot.modelData.urgent ? " · urgent" : dot.modelData.focused ? " · focused" : "")''',
'''                            // per monitor: the laptop's 11-20 read as 1-10, matching SUPER+1..0 on that screen
                            title: "Workspace " + (cfg.wsPerMonitor ? (dot.modelData.id - 1) % 10 + 1 : dot.modelData.id)
                                   + (dot.modelData.urgent ? " · urgent" : dot.modelData.focused ? " · focused"
                                      : dot.current ? " · shown" : "")''')
rep('''                onWheel: e => root.run("hyprctl dispatch 'hl.dsp.focus({workspace=\\"e"
                                       + (e.angleDelta.y > 0 ? "+1" : "-1") + "\\"})'")''',
'''                // Kali: previous / next workspace of THIS bar's monitor (wraps around). Upstream used e+1 / e-1,
                // the next open workspace on ANY monitor: scrolling the Samsung bar past 3 jumped to the laptop.
                onWheel: e => {
                    const l = wsRoot.wsList;
                    if (l.length === 0) return;
                    const cur = l.findIndex(w => wsRoot.isCurrent(w));
                    const i = cur < 0 ? 0 : (cur + (e.angleDelta.y > 0 ? 1 : -1) + l.length) % l.length;
                    root.run("hyprctl dispatch 'hl.dsp.focus({workspace=" + l[i].id + "})'");
                }''')

# 20. media -> MusicPreview
rep('''    Component {
        id: mediaC
        Interactive {
            readonly property bool playing: Marquee.player !== null && Marquee.player.isPlaying === true
            readonly property real len: Math.min(Marquee.textW, Marquee.maxW)   // visible text length
''', '''    // Kali — media: left click drops the MusicPreview card (cover, sound waves = seek bar, controls) under
    // the pill; right click = next track, middle click = play / pause.
    Component {
        id: mediaC
        Interactive {
            id: mediaItem
            readonly property bool playing: Marquee.player !== null && Marquee.player.isPlaying === true
            readonly property real len: Math.min(Marquee.textW, Marquee.maxW)   // visible text length
            readonly property var barWin: QsWindow.window
''')
rep('''            tip: Marquee.text
            primaryHint: playing ? "Pause" : "Play"
            secondaryHint: "Next track"
            tertiaryHint: "Previous track"
            onPrimary: root.mediaAct("toggle")
            onSecondary: root.mediaAct("next")
            onTertiary: root.mediaAct("prev")''',
'''            tip: Marquee.text
            active: barWin ? barWin.musicOpen === true : false
            primaryHint: active ? "Close player" : "Open player"
            secondaryHint: "Next track"
            tertiaryHint: playing ? "Pause" : "Play"
            onPrimary: {
                if (!barWin) return;
                // the card is centred on the pill: remember where the pill is in bar coordinates
                const c = mapToItem(barWin.contentItem, width / 2, height / 2);
                barWin.musicAnchor = Qt.point(c.x, c.y);
                barWin.trayItem = null;
                barWin.musicOpen = !barWin.musicOpen;
            }
            onSecondary: root.mediaAct("next")
            onTertiary: root.mediaAct("toggle")''')

# 21. tray component (copied from the current local Bar.qml)
loc = open(sys.argv[2]).read()
a = loc.index('    // System tray (StatusNotifierItem): one icon per app that offers one')
b = loc.index('    Component {\n        id: volumeC', a)
tray = loc[a:b]
rep('    Component {\n        id: volumeC', tray + '    Component {\n        id: volumeC')

# 22. bar window
rep('''            implicitWidth: root.vertical ? root.panelThick + root.effEdge : 0
            implicitHeight: root.vertical ? 0 : root.panelThick + root.effEdge
            exclusionMode: cfg.reserveSpace ? ExclusionMode.Auto : ExclusionMode.Ignore
            color: "transparent"
            visible: root.barVisible
''', '''            // Kali — zoomPad: transparent room on the inner side for the hover zoom. It is not part of the
            // exclusive zone (windows don't move) and the input mask keeps it click-through.
            implicitWidth: root.vertical ? root.panelThick + root.effEdge + root.zoomPad : 0
            implicitHeight: root.vertical ? 0 : root.panelThick + root.effEdge + root.zoomPad
            exclusionMode: cfg.reserveSpace ? ExclusionMode.Normal : ExclusionMode.Ignore
            exclusiveZone: root.panelThick + root.effEdge
            mask: Region { item: frame }
            color: "transparent"
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
open(f'{S}/merged/quickshell/Bar.qml', 'w').write(src)
print("Bar.qml portat:", src.count('\n'), "linii")
