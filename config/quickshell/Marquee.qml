// Marquee.qml — shared MPRIS + marquee state (one ticker for all screens)
// Kali local changes vs upstream:
//   • the text glides pixel-smooth (NumberAnimation, every frame at the display's refresh
//     rate) instead of 1 px every 33 ms — on the 120/144 Hz screens here the stepped
//     ticker read as jerky
//   • player choice prefers what is playing, then the instance with cover art: browsers
//     expose the same tab twice (brave.instanceN + plasma-browser-integration, only the
//     latter has art, artist and a clean title)
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Scope {
    id: root

    readonly property var player: {
        const ps = Mpris.players.values;
        let best = null, bestScore = -1;
        for (const p of ps) {
            const s = (p.isPlaying ? 2 : 0) + (p.trackArtUrl ? 1 : 0);
            if (s > bestScore) { best = p; bestScore = s; }
        }
        return best;
    }
    readonly property bool playing: player !== null && player.isPlaying
    // a bar's MusicPreview card is open: VolumeOsd skips its track-change popup meanwhile
    property bool previewOpen: false
    readonly property string title: player
        ? ((player.trackArtist ? player.trackArtist + " - " : "") + player.trackTitle)
        : ""
    // nf-md play / pause
    readonly property string text: (playing ? "󰐊 " : "󰏤 ") + title

    readonly property int maxW: 180       // visible width in px
    readonly property int gap: 40         // gap between the two copies
    readonly property int speed: 40       // px per second
    readonly property int holdMs: 2500    // idle pause at the start of each loop

    readonly property real textW: measure.implicitWidth
    readonly property bool animating: playing && textW > maxW

    property real x: 0

    // Invisible text, only used to measure the width
    Item {
        visible: false
        Text {
            id: measure
            text: root.text
            font.family: Theme.iconFont
            font.pixelSize: 11
        }
    }

    // hold at the start, glide one full copy to the left, jump back (seamless: copy 2 is
    // exactly where copy 1 started), repeat. Stopped = zero repaints.
    SequentialAnimation {
        id: scroller
        running: root.animating
        loops: Animation.Infinite
        PropertyAction { target: root; property: "x"; value: 0 }
        PauseAnimation { duration: root.holdMs }
        NumberAnimation {
            target: root; property: "x"
            from: 0; to: -(root.textW + root.gap)
            duration: Math.max(1000, (root.textW + root.gap) / root.speed * 1000)
        }
    }

    onAnimatingChanged: x = 0
    onTextChanged: { x = 0; if (animating) scroller.restart(); }
}
