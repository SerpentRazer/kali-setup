// WeatherPreview.qml — Kali (20 nov 2026): weather card that drops out of the bar's weather module when it is
// clicked (Bar.qml, weather module). Upstream's module only refreshed on click; this adds what Windows' weather
// flyout shows: now (temperature, feels like, humidity, wind, sunrise / sunset), the next hours and the next days.
// Same build as MusicPreview.qml: follows the bar (below a top bar, beside a vertical one), the translucent card is
// blurred by Hyprland through the "qs-weather" layer rule in hypr/rules.lua, a click anywhere else closes it.
// Data: open-meteo for the bar's location (weatherCity, Oradea here), fetched when the card opens if older than 10 min.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: root
    property var host: null              // the bar window: owns weatherOpen / weatherAnchor
    property var wx: null                // the bar (Bar.qml root): wxLat / wxLon / wxHave / wxNames / config
    property string position: "top"
    property real barThick: 28
    readonly property bool open: host !== null && host.weatherOpen === true
    readonly property point anchorPt: host ? host.weatherAnchor : Qt.point(0, 0)
    readonly property bool vertical: position === "left" || position === "right"
    readonly property bool fahrenheit: wx !== null && wx.config.weatherF === true
    readonly property string city: wx !== null && wx.config.weatherCity !== "" ? wx.config.weatherCity : "Your location"

    property var wxData: null              // parsed open-meteo answer
    property double fetchedAt: 0
    property bool loading: false
    property bool failed: false

    function close() { if (host) host.weatherOpen = false }
    function refresh() {
        if (!wx || !wx.wxHave || fetch.running) return
        loading = true; failed = false
        fetch.running = true
    }
    onOpenChanged: if (open && (wxData === null || Date.now() - fetchedAt > 10 * 60 * 1000)) refresh()

    // ---- helpers
    readonly property var names: wx ? wx.wxNames : ({})
    function glyph(c, day) {
        if (c === 0 || c === 1) return day ? "󰖙" : "󰖔";
        if (c === 2) return day ? "󰖕" : "󰼱";
        if (c === 3) return "󰖐";
        if (c === 45 || c === 48) return "󰖑";
        if (c >= 95) return "󰙾";
        if (c === 56 || c === 57 || c === 66 || c === 67) return "󰙿";
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "󰖘";
        if (c === 65 || c === 82) return "󰖖";
        return "󰖗";
    }
    function deg(t) { return Math.round(t) + "°" }
    function hm(iso) { return iso ? iso.slice(11, 16) : "–" }
    readonly property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    function dayName(iso, i) {
        if (i === 0) return "Today"
        const d = new Date(iso + "T12:00:00")
        return dayNames[d.getDay()]
    }
    readonly property var cur: wxData ? wxData.current : null
    // next 12 hours, every 2 h (the first entry is the current hour)
    readonly property var hours: {
        if (!wxData) return []
        const h = wxData.hourly, out = []
        for (let i = 2; i < h.time.length && out.length < 6; i += 2)
            out.push({ t: h.time[i], temp: h.temperature_2m[i], code: h.weather_code[i],
                       rain: h.precipitation_probability[i], day: h.is_day[i] === 1 })
        return out
    }
    readonly property var days: {
        if (!wxData) return []
        const d = wxData.daily, out = []
        for (let i = 0; i < d.time.length; i++)
            out.push({ t: d.time[i], max: d.temperature_2m_max[i], min: d.temperature_2m_min[i],
                       code: d.weather_code[i], rain: d.precipitation_probability_max[i] })
        return out
    }
    readonly property real lo: days.length ? Math.min(...days.map(x => x.min)) : 0
    readonly property real hi: days.length ? Math.max(...days.map(x => x.max)) : 1

    Process {
        id: fetch
        command: ["curl", "-sf", "-m", "15",
            "https://api.open-meteo.com/v1/forecast?latitude=" + (root.wx ? root.wx.wxLat : 0)
            + "&longitude=" + (root.wx ? root.wx.wxLon : 0)
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"
            + "&hourly=temperature_2m,weather_code,precipitation_probability,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset"
            + "&forecast_days=6&forecast_hours=14&timezone=auto"
            + (root.fahrenheit ? "&temperature_unit=fahrenheit" : "")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    if (!j.current || !j.daily || !j.hourly) throw "incomplete"
                    root.wxData = j; root.fetchedAt = Date.now(); root.failed = false
                } catch (e) { root.failed = true }
                root.loading = false
            }
        }
        onExited: code => { if (code !== 0) { root.failed = true; root.loading = false } }
    }
    onFahrenheitChanged: { wxData = null; if (open) refresh() }

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
    implicitWidth: face.width
    implicitHeight: face.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-weather"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: root.open ? card : null }

    HyprlandFocusGrab {
        windows: root.host ? [root, root.host] : [root]
        active: root.open
        onCleared: root.close()
    }

    Item {
        id: card
        width: face.width; height: face.height
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
            width: 300
            height: col.height + 32
            radius: 20
            color: root.wx ? root.wx.bgColor : Theme.bg   // same translucency as the bar (Bar settings → opacity), blurred behind

            Column {
                id: col
                x: 18; y: 16
                width: face.width - 36
                spacing: 14

                // ---- now (click = refresh)
                Item {
                    width: parent.width; height: nowRow.height
                    Row {
                        id: nowRow
                        spacing: 14
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.cur ? root.glyph(root.cur.weather_code, root.cur.is_day === 1) : "󰖐"
                            font.family: Theme.iconFont; font.pixelSize: 44
                            color: Theme.text
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: root.cur ? root.deg(root.cur.temperature_2m) : (root.failed ? "–" : "…")
                                font.family: Theme.fontFamily; font.pixelSize: 30; font.bold: true
                                color: Theme.text
                            }
                            Text {
                                text: root.cur ? (root.names[root.cur.weather_code] ?? "") : (root.failed ? "Weather unavailable" : "Loading…")
                                font.family: Theme.fontFamily; font.pixelSize: 12
                                color: Theme.text
                            }
                            Text {
                                text: root.city + (root.cur ? "  ·  feels " + root.deg(root.cur.apparent_temperature) : "")
                                font.family: Theme.fontFamily; font.pixelSize: 11
                                color: Theme.text; opacity: 0.6
                            }
                        }
                    }
                    Text {   // refresh hint
                        anchors.right: parent.right; anchors.top: parent.top
                        text: "󰑐"
                        font.family: Theme.iconFont; font.pixelSize: 14
                        color: Theme.text
                        opacity: nowMa.containsMouse ? 0.9 : 0.35
                        RotationAnimation on rotation {
                            running: root.loading; loops: Animation.Infinite; from: 0; to: 360; duration: 900
                        }
                    }
                    MouseArea {
                        id: nowMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.refresh()
                    }
                }

                // ---- humidity / wind / sun
                Row {
                    visible: root.cur !== null
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: root.cur && root.wxData ? [
                            { g: "󰖎", v: root.cur.relative_humidity_2m + "%" },
                            { g: "󰖝", v: Math.round(root.cur.wind_speed_10m) + " km/h" },
                            { g: "󰖜", v: root.hm(root.wxData.daily.sunrise[0]) },
                            { g: "󰖛", v: root.hm(root.wxData.daily.sunset[0]) }
                        ] : []
                        delegate: Rectangle {
                            required property var modelData
                            width: (col.width - 18) / 4; height: 26; radius: 13
                            color: Qt.alpha(Theme.text, 0.07)
                            Row {
                                anchors.centerIn: parent; spacing: 4
                                Text { text: modelData.g; font.family: Theme.iconFont; font.pixelSize: 12; color: Theme.text; opacity: 0.7 }
                                Text { text: modelData.v; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.text }
                            }
                        }
                    }
                }

                // ---- next hours
                Row {
                    visible: root.hours.length > 0
                    width: parent.width
                    Repeater {
                        model: root.hours
                        delegate: Column {
                            required property var modelData
                            width: col.width / Math.max(1, root.hours.length)
                            spacing: 3
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.hm(modelData.t)
                                font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.text; opacity: 0.6
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.glyph(modelData.code, modelData.day)
                                font.family: Theme.iconFont; font.pixelSize: 18; color: Theme.text
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.deg(modelData.temp)
                                font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true; color: Theme.text
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.rain >= 20 ? modelData.rain + "%" : " "
                                font.family: Theme.fontFamily; font.pixelSize: 9; color: Theme.accent2
                            }
                        }
                    }
                }

                Rectangle { visible: root.days.length > 0; width: parent.width; height: 1; color: Qt.alpha(Theme.text, 0.1) }

                // ---- next days: name, icon, rain chance, min, range bar, max
                Column {
                    visible: root.days.length > 0
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: root.days
                        delegate: Item {
                            id: dayRow
                            required property var modelData
                            required property int index
                            width: col.width; height: 20
                            Text {
                                x: 0; anchors.verticalCenter: parent.verticalCenter
                                text: root.dayName(dayRow.modelData.t, dayRow.index)
                                font.family: Theme.fontFamily; font.pixelSize: 11
                                font.bold: dayRow.index === 0; color: Theme.text
                            }
                            Text {
                                x: 50; anchors.verticalCenter: parent.verticalCenter
                                text: root.glyph(dayRow.modelData.code, true)
                                font.family: Theme.iconFont; font.pixelSize: 15; color: Theme.text
                            }
                            Text {
                                x: 74; anchors.verticalCenter: parent.verticalCenter
                                text: dayRow.modelData.rain >= 20 ? dayRow.modelData.rain + "%" : ""
                                font.family: Theme.fontFamily; font.pixelSize: 9; color: Theme.accent2
                            }
                            Text {
                                id: minT
                                x: 108; width: 30; anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                text: root.deg(dayRow.modelData.min)
                                font.family: Theme.fontFamily; font.pixelSize: 11; color: Theme.text; opacity: 0.6
                            }
                            Rectangle {   // the day's range on the week's scale
                                id: track
                                x: 146; width: col.width - 146 - 38; height: 4; radius: 2
                                anchors.verticalCenter: parent.verticalCenter
                                color: Qt.alpha(Theme.text, 0.1)
                                readonly property real span: Math.max(1, root.hi - root.lo)
                                Rectangle {
                                    height: parent.height; radius: 2
                                    x: (dayRow.modelData.min - root.lo) / track.span * track.width
                                    width: Math.max(4, (dayRow.modelData.max - dayRow.modelData.min) / track.span * track.width)
                                    color: Theme.accent2; opacity: 0.8
                                }
                            }
                            Text {
                                anchors.right: parent.right; width: 30; anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                text: root.deg(dayRow.modelData.max)
                                font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true; color: Theme.text
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: root.wxData ? "updated " + root.hm(root.wxData.current.time) + " · open-meteo" : ""
                    font.family: Theme.fontFamily; font.pixelSize: 9; color: Theme.text; opacity: 0.35
                }
            }
        }
    }
}
