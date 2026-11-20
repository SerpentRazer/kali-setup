/*
    CyberGlass SDDM theme — minimalist, replica a hyprlock (Super+L).
    Fundal blurat, Roboto Mono alb, ceas+data, pastila de parola transparenta,
    plus controale: selectie sesiune (environment) + power.
    Fara componente Breeze (robust, fara dependente de plugin-uri).
    Animatii fine: intrare in cascada, halou la focus, shake la esec, hover lin.
*/
import QtQuick
import QtQml
import QtQuick.Controls as QQC
import Qt5Compat.GraphicalEffects

Item {
    id: root
    width: 1920
    height: 1080

    // paleta: alb (ca hyprlock); magenta doar pt esec
    readonly property color accent:  "#ffffff"
    readonly property color magenta: "#ff2bd1"
    readonly property color fg:      "#ffffff"

    // 11 nov 2026: login-ul (ceas, parola, controale) DOAR pe ecranul principal; celelalte ecrane raman negre.
    // SDDM injecteaza `primaryScreen` per ecran si da focusul tastaturii ferestrei de pe ecranul primar;
    // primarul = monitorul pe HDMI (Samsung), marcat cu `xrandr --primary` in /usr/share/sddm/scripts/Xsetup.
    readonly property bool showUi: (typeof primaryScreen === "undefined") ? true : primaryScreen

    // baza neagra (altfel ecranele fara UI ar ramane cu fundalul implicit al ferestrei)
    Rectangle { anchors.fill: parent; color: "#000000" }

    // Roboto Mono impachetat in tema (userul sddm nu vede fonturile din home)
    FontLoader { id: mono; source: Qt.resolvedUrl("RobotoMono.ttf") }
    readonly property string ff: mono.status === FontLoader.Ready ? mono.name : "monospace"

    // user tinta (single-user). Prefera lastUser; fallback = userul de la lastIndex/0.
    property string fallbackUser: ""
    Instantiator {
        model: (typeof userModel !== "undefined") ? userModel : 0
        delegate: QtObject {
            required property int index
            required property string name
            Component.onCompleted: {
                var want = (userModel.lastIndex >= 0) ? userModel.lastIndex : 0;
                if (index === want) root.fallbackUser = name;
            }
        }
    }
    readonly property string loginUser: (typeof userModel !== "undefined" && userModel.lastUser) ? userModel.lastUser : fallbackUser

    // ceas live
    QtObject { id: timeSource; property var now: new Date() }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: timeSource.now = new Date() }

    // ---------- FUNDAL: wallpaper blurat (ca hyprlock path=screenshot blur) ----------
    Image {
        id: bg
        anchors.fill: parent
        source: Qt.resolvedUrl(config.background ? config.background : "login-bg.png")
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
        visible: false
    }
    FastBlur {
        id: blur
        visible: root.showUi
        anchors.fill: parent
        source: bg
        radius: 42
        opacity: 0            // intra la load
        scale: 1.06           // se aseaza lin la 1.0
        transformOrigin: Item.Center
    }
    // scrim subtil pt lizibilitate
    Rectangle { id: scrim; visible: root.showUi; anchors.fill: parent; color: "#000000"; opacity: 0 }

    // ---------- CEAS + DATA (sus-centru) ----------
    Column {
        id: clockCol
        visible: root.showUi
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(parent.height * 0.13)
        spacing: 8
        opacity: 0
        transform: Translate { id: clockTr; y: -12 }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.fg
            font.family: root.ff
            font.weight: Font.Light
            font.pixelSize: 76
            text: Qt.formatTime(timeSource.now, "HH:mm:ss")
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.5)
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: root.ff
            font.pixelSize: 19
            text: Qt.formatDate(timeSource.now, "dddd, dd MMMM yyyy")
        }
    }

    // ---------- HALOU PASTILA (sub pastila; apare la focus / esec) ----------
    RectangularGlow {
        id: glow
        visible: root.showUi
        anchors.fill: pill
        glowRadius: 16
        spread: 0.08
        cornerRadius: pill.radius + glowRadius
        color: pill.pwFail ? root.magenta : root.accent
        opacity: pill.pwFail ? 0.5 : (passwordInput.activeFocus ? 0.30 : 0.0)
        z: pill.z - 1
        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ---------- PASTILA DE PAROLA (centru) ----------
    Rectangle {
        id: pill
        visible: root.showUi
        anchors.centerIn: parent
        width: Math.round(parent.width * 0.20)
        height: 58
        radius: 25
        color: "transparent"
        antialiasing: true
        opacity: 0            // intra la load
        scale: 0.96           // intra la load
        border.width: 3
        border.color: pwFail ? root.magenta
                             : (passwordInput.activeFocus ? root.accent : Qt.rgba(1, 1, 1, 0.67))
        Behavior on border.color { ColorAnimation { duration: 150 } }

        property bool pwFail: false

        // shake bland la parola gresita
        SequentialAnimation {
            id: shake
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -10; duration: 55; easing.type: Easing.OutCubic }
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to:  10; duration: 70; easing.type: Easing.InOutCubic }
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to:  -7; duration: 70; easing.type: Easing.InOutCubic }
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to:   7; duration: 70; easing.type: Easing.InOutCubic }
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to:   0; duration: 60; easing.type: Easing.OutCubic }
        }

        TextInput {
            id: passwordInput
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            echoMode: TextInput.Password
            passwordCharacter: "●"
            passwordMaskDelay: 0
            color: root.fg
            selectionColor: root.accent
            selectedTextColor: "#000000"
            font.family: root.ff
            font.pixelSize: 22
            clip: true
            focus: true
            enabled: !busy
            cursorVisible: activeFocus
            onAccepted: root.doLogin()
            Keys.onEscapePressed: text = ""
        }
    }

    property bool busy: false

    // mesaj caps / esec
    Text {
        id: msg
        visible: root.showUi
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: pill.bottom
        anchors.topMargin: 16
        color: pill.pwFail ? root.magenta : Qt.rgba(1, 1, 1, 0.9)
        font.family: root.ff
        font.pixelSize: 14
        text: (typeof keyboard !== "undefined" && keyboard.capsLock) ? "Caps Lock activ" : ""

        // puls subtil cat timp se autentifica
        SequentialAnimation {
            running: root.busy
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { target: msg; property: "opacity"; from: 1.0; to: 0.4; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { target: msg; property: "opacity"; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
            onRunningChanged: if (!running) msg.opacity = 1
        }
    }

    function doLogin() {
        if (passwordInput.text.length === 0 || root.loginUser.length === 0)
            return;
        root.busy = true;
        msg.text = "Autentificare…";
        sddm.login(root.loginUser, passwordInput.text, sessionCombo.currentIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            msg.opacity = 1;
            pill.pwFail = true;
            msg.text = "Autentificare esuata";
            shake.restart();
            passwordInput.selectAll();
            passwordInput.forceActiveFocus();
            failReset.restart();
        }
        function onLoginSucceeded() {
            msg.opacity = 1;
            msg.text = "";
        }
    }
    Timer {
        id: failReset
        interval: 2500
        onTriggered: { pill.pwFail = false; msg.text = Qt.binding(function() {
            return (typeof keyboard !== "undefined" && keyboard.capsLock) ? "Caps Lock activ" : "";
        }); }
    }

    // ---------- CONTROALE JOS ----------
    // Selectie sesiune (environment) — stanga jos
    Row {
        id: sessionRow
        visible: root.showUi
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        anchors.bottomMargin: 20
        spacing: 8
        opacity: 0
        transform: Translate { id: sessTr; y: 14 }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Sesiune:"
            color: Qt.rgba(1, 1, 1, 0.7)
            font.family: root.ff
            font.pixelSize: 14
        }

        QQC.ComboBox {
            id: sessionCombo
            anchors.verticalCenter: parent.verticalCenter
            model: sessionModel
            textRole: "name"
            currentIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
            font.family: root.ff
            font.pixelSize: 14
            implicitWidth: 230
            implicitHeight: 32

            background: Rectangle {
                color: sessionCombo.hovered ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.06)
                border.color: sessionCombo.hovered ? root.accent : Qt.rgba(1, 1, 1, 0.5)
                border.width: 1
                radius: 6
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }
            contentItem: Text {
                leftPadding: 10
                rightPadding: sessionCombo.indicator.width + 6
                text: sessionCombo.displayText
                color: root.fg
                font: sessionCombo.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            indicator: Text {
                x: sessionCombo.width - width - 8
                y: (sessionCombo.height - height) / 2
                text: "▾"
                color: root.accent
                font.pixelSize: 12
                rotation: sessionCombo.popup.visible ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
            popup: QQC.Popup {
                y: sessionCombo.height
                width: sessionCombo.width
                implicitHeight: Math.min(contentHeight, 240)
                padding: 1
                enter: Transition { NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic } }
                exit:  Transition { NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.InCubic } }
                background: Rectangle {
                    color: "#0b0f16"
                    border.color: root.accent
                    border.width: 1
                    radius: 6
                }
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: sessionCombo.popup.visible ? sessionCombo.delegateModel : null
                    currentIndex: sessionCombo.highlightedIndex
                }
            }
            delegate: QQC.ItemDelegate {
                width: sessionCombo.width
                height: 30
                contentItem: Text {
                    text: model.name
                    color: highlighted ? root.accent : root.fg
                    font.family: root.ff
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 10
                }
                highlighted: sessionCombo.highlightedIndex === index
                background: Rectangle {
                    color: highlighted ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
            }
        }
    }

    // Butoane power — centru jos
    Row {
        id: powerRow
        visible: root.showUi
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        spacing: 26
        opacity: 0
        transform: Translate { id: powerTr; y: 14 }

        Repeater {
            model: [
                { label: "Hibernate", act: "hibernate", can: (typeof sddm !== "undefined") ? sddm.canHibernate : false },
                { label: "Sleep",     act: "suspend",   can: (typeof sddm !== "undefined") ? sddm.canSuspend  : false },
                { label: "Restart",   act: "reboot",    can: (typeof sddm !== "undefined") ? sddm.canReboot   : false },
                { label: "Shut Down", act: "poweroff",  can: (typeof sddm !== "undefined") ? sddm.canPowerOff : false }
            ]

            delegate: Text {
                required property var modelData
                text: modelData.label
                color: ma.containsMouse ? root.accent : Qt.rgba(1, 1, 1, modelData.can ? 0.8 : 0.3)
                font.family: root.ff
                font.pixelSize: 14
                scale: (ma.containsMouse && modelData.can) ? 1.1 : 1.0
                transformOrigin: Item.Center
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    enabled: modelData.can
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (modelData.act === "hibernate") sddm.hibernate();
                        else if (modelData.act === "suspend") sddm.suspend();
                        else if (modelData.act === "reboot") sddm.reboot();
                        else if (modelData.act === "poweroff") sddm.powerOff();
                    }
                }
            }
        }
    }

    // ---------- INTRARE: fade + asezare lina, in cascada ----------
    ParallelAnimation {
        id: intro
        running: true
        // fundal
        NumberAnimation { target: blur;  property: "opacity"; from: 0; to: 1;    duration: 700;  easing.type: Easing.OutCubic }
        NumberAnimation { target: blur;  property: "scale";   from: 1.06; to: 1; duration: 1100; easing.type: Easing.OutCubic }
        NumberAnimation { target: scrim; property: "opacity"; from: 0; to: 0.30; duration: 700;  easing.type: Easing.OutCubic }
        // ceas
        SequentialAnimation {
            PauseAnimation { duration: 120 }
            ParallelAnimation {
                NumberAnimation { target: clockCol; property: "opacity"; from: 0; to: 1;   duration: 600; easing.type: Easing.OutCubic }
                NumberAnimation { target: clockTr;  property: "y";       from: -12; to: 0;  duration: 600; easing.type: Easing.OutCubic }
            }
        }
        // pastila
        SequentialAnimation {
            PauseAnimation { duration: 230 }
            ParallelAnimation {
                NumberAnimation { target: pill; property: "opacity"; from: 0; to: 1;    duration: 600; easing.type: Easing.OutCubic }
                NumberAnimation { target: pill; property: "scale";   from: 0.96; to: 1; duration: 600; easing.type: Easing.OutCubic }
            }
        }
        // controale jos
        SequentialAnimation {
            PauseAnimation { duration: 340 }
            ParallelAnimation {
                NumberAnimation { target: sessionRow; property: "opacity"; from: 0; to: 1;  duration: 600; easing.type: Easing.OutCubic }
                NumberAnimation { target: sessTr;     property: "y";       from: 14; to: 0; duration: 600; easing.type: Easing.OutCubic }
                NumberAnimation { target: powerRow;   property: "opacity"; from: 0; to: 1;  duration: 600; easing.type: Easing.OutCubic }
                NumberAnimation { target: powerTr;    property: "y";       from: 14; to: 0; duration: 600; easing.type: Easing.OutCubic }
            }
        }
    }

    // focus pe parola la pornire
    Component.onCompleted: if (root.showUi) passwordInput.forceActiveFocus()
}
