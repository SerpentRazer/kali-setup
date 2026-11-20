// MusicPreview.qml — mini player card that drops out of the bar's media pill when the
// pill is clicked (Bar.qml, media module). Same look as the media popup in VolumeOsd.qml
// (portrait cover, cava sound waves, glyph controls) at that popup's default settings:
// 80% scale, 260 px wide, 24 bars. The played part of the waves is brighter, so they are
// also the progress bar: click / drag them to seek.
// Follows the bar: below a top bar, above a bottom bar, beside a vertical bar. The
// translucent card is blurred by Hyprland through the "qs-music" layer rule in
// hypr/rules.lua. Clicking anywhere outside closes it, like a Windows flyout.
// The surface stays mapped (transparent, click-through) so Hyprland never plays its own
// layer animation on top of ours.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick

PanelWindow {
    id: root
    property var host: null              // the bar window: owns musicOpen / musicAnchor
    property var player: null
    property string position: "top"      // bar position: top / bottom / left / right
    property real barThick: 28           // bar thickness incl. its edge margin
    readonly property bool open: host !== null && host.musicOpen === true
    readonly property point anchorPt: host ? host.musicAnchor : Qt.point(0, 0)
    readonly property bool vertical: position === "left" || position === "right"

    // VolumeOsd defaults: osdScale 80%, barCount 24, barFps 30
    readonly property real k: 0.8
    readonly property int barCount: 24
    readonly property int barFps: 30
    property var bars: []
    readonly property real progress: seek.pressed ? seek.frac
        : (player && player.length > 0 ? Math.min(1, player.position / player.length) : 0)

    function close() { if (host) host.musicOpen = false }

    anchors {
        top: position !== "bottom"
        bottom: position === "bottom"
        left: position !== "right"
        right: position === "right"
    }
    // centred on the pill along the bar, a small gap away from the bar across it
    margins {
        top: position === "top" ? barThick + 6
             : vertical ? Math.max(8, Math.min((screen ? screen.height : 1080) - implicitHeight - 8,
                                               anchorPt.y - implicitHeight / 2)) : 0
        bottom: position === "bottom" ? barThick + 6 : 0
        left: position === "left" ? barThick + 6
              : !vertical ? Math.max(8, Math.min((screen ? screen.width : 1920) - implicitWidth - 8,
                                                 anchorPt.x - implicitWidth / 2)) : 0
        right: position === "right" ? barThick + 6 : 0
    }
    implicitWidth: Math.ceil(face.width * k)
    implicitHeight: Math.ceil(face.height * k)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-music"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: root.open ? card : null }

    onPlayerChanged: if (!player) close()
    onOpenChanged: if (!open) bars = []

    // the card already shows the new track: no second popup in the middle of the screen
    Binding { target: Marquee; property: "previewOpen"; value: true; when: root.open }

    // click anywhere else -> close
    HyprlandFocusGrab {
        windows: root.host ? [root, root.host] : [root]
        active: root.open
        onCleared: root.close()
    }

    // MPRIS position is not reactive: poll it while the card is visible
    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: root.open && root.player !== null
        onTriggered: root.player.positionChanged()
    }

    // sound waves: same cava setup as VolumeOsd, own config file, only while the card is open
    Process {
        running: root.open && root.player !== null
        command: [
            "sh", "-c",
            "printf '%s\\n' " +
            "'[general]' 'bars = " + root.barCount + "' 'framerate = " + root.barFps + "' " +
            "'[input]' 'method = pulse' " +   // Kali: cava e compilat fara pipewire
            "'[output]' 'method = raw' 'raw_target = /dev/stdout' " +
            "'data_format = ascii' 'ascii_max_range = 100' " +
            "'bar_delimiter = 59' 'frame_delimiter = 10' " +
            "> /tmp/quickshell-cava-preview.conf && exec cava -p /tmp/quickshell-cava-preview.conf"
        ]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.split(";")
                var out = new Array(root.barCount)
                for (var i = 0; i < root.barCount; i++)
                    out[i] = parseInt(parts[i]) || 0
                root.bars = out
            }
        }
    }

    Item {
        id: card
        width: root.implicitWidth
        height: root.implicitHeight
        // grows out of the bar: from the top edge under a top bar, the bottom edge above a bottom bar...
        transformOrigin: root.position === "bottom" ? Item.Bottom
                       : root.position === "left" ? Item.Left
                       : root.position === "right" ? Item.Right : Item.Top
        property real slide: root.open ? 0 : -6
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96
        x: root.position === "left" ? slide : root.position === "right" ? -slide : 0
        y: root.position === "top" ? slide : root.position === "bottom" ? -slide : 0
        Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on slide { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

        // laid out at the popup's 100% sizes, then scaled like the popup is
        Rectangle {
            id: face
            width: 260
            height: col.height + 28
            radius: 24
            color: Theme.bg
            scale: root.k
            transformOrigin: Item.TopLeft

            Column {
                id: col
                x: 20; y: 14
                width: face.width - 40
                spacing: 6

                // ---- cover + track info (click = bring the player window forward)
                Item {
                    id: topBlock
                    width: parent.width
                    readonly property bool artShown: root.player !== null
                        && root.player.trackArtUrl !== "" && cover.status !== Image.Error
                    height: (artShown ? width + 8 : 0) + textCol.height

                    ClippingRectangle {
                        id: art
                        visible: topBlock.artShown
                        width: parent.width; height: width; radius: 16
                        color: "transparent"
                        Image {
                            id: cover
                            anchors.fill: parent
                            source: root.player ? root.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 400; sourceSize.height: 400
                            asynchronous: true
                            cache: false            // browsers reuse one temp file for every track
                            opacity: status === Image.Ready ? 0.8 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }
                    Column {
                        id: textCol
                        y: topBlock.artShown ? art.height + 8 : 0
                        width: parent.width
                        spacing: 2
                        Text {
                            width: parent.width
                            text: root.player ? (root.player.trackTitle || "Unknown") : "Nothing playing"
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: 13; font.bold: true
                            color: Theme.text
                        }
                        Text {
                            width: parent.width
                            text: root.player ? (root.player.trackArtist || "No artist") : ""
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: 11
                            color: Theme.text
                            opacity: 0.65
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player !== null && root.player.canRaise
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.player.raise(); root.close() }
                    }
                }

                // ---- sound waves = progress (click / drag to seek)
                Item {
                    id: waves
                    width: parent.width; height: 20
                    readonly property real gap: 3
                    readonly property real barW: Math.max(1, (width - gap * (root.barCount - 1)) / root.barCount)

                    Repeater {
                        model: root.barCount
                        Rectangle {
                            required property int index
                            x: index * (waves.barW + waves.gap)
                            width: waves.barW
                            radius: width / 2
                            color: Theme.text
                            opacity: (index + 0.5) / root.barCount <= root.progress ? 0.9 : 0.3
                            height: Math.max(3, ((root.bars[index] ?? 0) / 100) * waves.height)
                            y: waves.height - height
                            Behavior on height { NumberAnimation { duration: 60 } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }
                    MouseArea {
                        id: seek
                        property real frac: 0
                        anchors.fill: parent
                        anchors.topMargin: -4; anchors.bottomMargin: -4
                        enabled: root.player !== null && root.player.canSeek && root.player.length > 0
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (m) => frac = Math.max(0, Math.min(1, m.x / width))
                        onPositionChanged: (m) => { if (pressed) frac = Math.max(0, Math.min(1, m.x / width)) }
                        onReleased: root.player.position = frac * root.player.length
                    }
                }

                // ---- controls
                Item {
                    width: parent.width; height: 26
                    Row {
                        anchors.centerIn: parent
                        spacing: 28
                        Glyph {
                            text: String.fromCodePoint(0xF04AE)
                            font.pixelSize: 19
                            enabled: root.player !== null && root.player.canGoPrevious
                            onClicked: root.player.previous()
                        }
                        Glyph {
                            text: String.fromCodePoint(root.player && root.player.isPlaying ? 0xF03E4 : 0xF040A)
                            font.pixelSize: 21
                            enabled: root.player !== null && root.player.canTogglePlaying
                            onClicked: root.player.togglePlaying()
                        }
                        Glyph {
                            text: String.fromCodePoint(0xF04AD)
                            font.pixelSize: 19
                            enabled: root.player !== null && root.player.canGoNext
                            onClicked: root.player.next()
                        }
                    }
                }
            }
        }
    }

    component Glyph: Text {
        signal clicked()
        font.family: "Symbols Nerd Font"
        color: Theme.text
        opacity: enabled ? 1 : 0.3
        MouseArea {
            anchors.fill: parent
            enabled: parent.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
