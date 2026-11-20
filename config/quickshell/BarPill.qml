// BarPill.qml — a bar module that zooms up SMOOTHLY on hover using a GPU
// transform (scale), not font-size. Scale is a transform, so it never reflows
// neighbours -> buttery at the compositor's frame rate.
import QtQuick

Item {
    id: root
    default property alias content: holder.data
    property real hoverScale: 1.18
    property color hoverBg: Qt.alpha(Theme.text, 0.12)   // follows the 43pr palette (light presets too)
    property bool active: false            // keeps the highlight while something it opened is shown
    signal clicked()
    signal rightClicked()
    signal scrolled(int dy)

    implicitWidth: pill.implicitWidth      // layout size is the UNSCALED size (no reflow on zoom)
    implicitHeight: 20

    Rectangle {
        id: pill
        anchors.centerIn: parent
        implicitWidth: holder.implicitWidth + 18
        implicitHeight: 20
        radius: 8
        color: hover.hovered || root.active ? root.hoverBg : Qt.alpha(Theme.text, 0)
        scale: hover.hovered ? root.hoverScale : 1.0
        transformOrigin: Item.Center

        Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Row {
            id: holder
            anchors.centerIn: parent
            spacing: 6
        }

        HoverHandler { id: hover }
        TapHandler {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onTapped: (ev) => ev.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (ev) => root.scrolled(ev.angleDelta.y)
        }
    }
}
