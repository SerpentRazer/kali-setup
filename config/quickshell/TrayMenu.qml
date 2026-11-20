// TrayMenu.qml — menu of a system tray icon (Bar.qml, tray module), drawn in the bar's own style
// (translucent card, Geist, 43PR colours) instead of the app's Qt/GTK menu. Same frame as
// MusicPreview.qml: follows the bar's side, centred on the icon, blurred by Hyprland through the
// "qs-traymenu" layer rule in hypr/rules.lua, closes on a click anywhere else.
// Submenus open in place (a "back" row on top), like a phone menu: no cascading popups to place.
// The surface stays mapped (transparent, click-through) so Hyprland never plays its own
// layer animation on top of ours.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root
    property var host: null              // the bar window: owns trayItem / trayAnchor
    property string position: "top"      // bar position: top / bottom / left / right
    property real barThick: 28           // bar thickness incl. its edge margin
    readonly property var item: host ? host.trayItem : null
    readonly property bool open: !!item
    readonly property point anchorPt: host ? host.trayAnchor : Qt.point(0, 0)
    readonly property bool vertical: position === "left" || position === "right"

    // submenus drilled into; empty = the item's own menu
    property var stack: []
    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : (item ? item.menu : null)
    // reserve the icon / check column only when some entry uses it
    readonly property bool lead: opener.children.values.some(e =>
        !e.isSeparator && (e.icon !== "" || e.buttonType !== QsMenuButtonType.None))

    function close() { if (host) host.trayItem = null }
    // DBusMenu labels carry mnemonics: "_Quit" -> "Quit", "__" -> "_"
    function label(t) { return (t ?? "").replace(/__/g, "\u0001").replace(/_/g, "").replace(/\u0001/g, "_") }

    onItemChanged: stack = []

    anchors {
        top: position !== "bottom"
        bottom: position === "bottom"
        left: position !== "right"
        right: position === "right"
    }
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
    implicitWidth: Math.ceil(face.width)
    implicitHeight: Math.ceil(face.height)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-traymenu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: root.open ? card : null }

    // click anywhere else -> close (the bar itself stays clickable: another icon switches menus)
    HyprlandFocusGrab {
        windows: root.host ? [root, root.host] : [root]
        active: root.open
        onCleared: root.close()
    }

    QsMenuOpener {
        id: opener
        menu: root.current
    }
    // every menu on the way down stays open: closing a parent menu frees its entries, and the
    // submenu shown (one of those entries) would come up empty
    QsMenuOpener { menu: root.item ? root.item.menu : null }
    Variants {
        model: root.stack
        QsMenuOpener {
            required property var modelData
            menu: modelData
        }
    }

    Item {
        id: card
        width: face.width
        height: face.height
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

        Rectangle {
            id: face
            width: Math.max(170, Math.min(340, list.implicitWidth)) + 12
            height: list.implicitHeight + 12
            radius: 14
            color: Theme.bg
            border.width: 1
            border.color: Qt.alpha(Theme.text, 0.12)

            ColumnLayout {
                id: list
                x: 6; y: 6
                width: face.width - 12
                spacing: 0

                // back to the parent menu (only inside a submenu)
                Item {
                    visible: root.stack.length > 0
                    Layout.fillWidth: true
                    implicitWidth: backTxt.implicitWidth + 20
                    implicitHeight: 28
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: backMa.containsMouse ? Qt.alpha(Theme.text, 0.1) : Qt.alpha(Theme.text, 0)
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    Text {
                        id: backTxt
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 16
                        elide: Text.ElideRight
                        text: "󰅁  " + (root.stack.length > 0 ? root.label(root.stack[root.stack.length - 1].text) : "")
                        color: Theme.textDim
                        font.family: Theme.iconFont
                        font.pixelSize: 12
                        font.bold: true
                    }
                    MouseArea {
                        id: backMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.stack = root.stack.slice(0, -1)
                    }
                }
                Rectangle {
                    visible: root.stack.length > 0
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    implicitHeight: 1
                    color: Qt.alpha(Theme.text, 0.12)
                }

                Repeater {
                    model: opener.children
                    delegate: Item {
                        id: row
                        required property QsMenuEntry modelData
                        readonly property bool sep: modelData.isSeparator
                        readonly property bool check: modelData.buttonType !== QsMenuButtonType.None
                        readonly property bool checked: modelData.checkState === Qt.Checked
                        readonly property bool radio: modelData.buttonType === QsMenuButtonType.RadioButton

                        Layout.fillWidth: true
                        implicitWidth: sep ? 0 : 12 + (root.lead ? 24 : 0) + txt.implicitWidth + (modelData.hasChildren ? 28 : 12)
                        implicitHeight: sep ? 9 : 28
                        opacity: sep || modelData.enabled ? 1 : 0.4

                        Rectangle {
                            visible: row.sep
                            anchors.centerIn: parent
                            width: parent.width - 16
                            height: 1
                            color: Qt.alpha(Theme.text, 0.12)
                        }

                        Rectangle {
                            visible: !row.sep
                            anchors.fill: parent
                            radius: 8
                            color: rowMa.containsMouse ? Qt.alpha(Theme.text, 0.1) : Qt.alpha(Theme.text, 0)
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        // check box / radio button / icon
                        Item {
                            visible: !row.sep && root.lead
                            x: 10
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                visible: row.check
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                radius: row.radio ? 6 : 3
                                color: row.checked ? Qt.alpha(Theme.accent, 0.6) : "transparent"
                                border.width: 1
                                border.color: row.checked ? Theme.accent : Theme.textDim
                                Rectangle {
                                    visible: row.checked && row.radio
                                    anchors.centerIn: parent
                                    width: 4; height: 4; radius: 2
                                    color: Theme.text
                                }
                                Text {
                                    visible: row.checked && !row.radio
                                    anchors.centerIn: parent
                                    text: ""
                                    color: Theme.text
                                    font.family: Theme.iconFont
                                    font.pixelSize: 8
                                }
                            }
                            IconImage {
                                visible: !row.check && row.modelData.icon !== ""
                                anchors.fill: parent
                                source: row.modelData.icon
                                asynchronous: true
                            }
                        }

                        Text {
                            id: txt
                            visible: !row.sep
                            x: 12 + (root.lead ? 24 : 0)
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - x - (row.modelData.hasChildren ? 28 : 12)
                            elide: Text.ElideRight
                            text: root.label(row.modelData.text)
                            color: Theme.text
                            font.family: Theme.iconFont
                            font.pixelSize: 12
                        }

                        Text {
                            visible: !row.sep && row.modelData.hasChildren
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰅂"
                            color: Theme.textDim
                            font.family: Theme.iconFont
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            enabled: !row.sep && row.modelData.enabled
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (row.modelData.hasChildren) {
                                    root.stack = root.stack.concat([row.modelData]);
                                } else {
                                    row.modelData.triggered();
                                    root.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
