# pas 17 (Kali 20 nov): click pe vreme = cardul WeatherPreview.qml; click mijloc = reimprospatare
STEP17 = [
('''            tip: root.wxTip; primaryHint: "Refresh"; secondaryHint: "Bar settings"
            onPrimary: root.refreshWeather(); onSecondary: root.openSettings()''',
'''            // Kali: left click = weather card (WeatherPreview.qml), middle = refresh, right = bar settings
            readonly property var barWin: QsWindow.window
            active: barWin ? barWin.weatherOpen === true : false
            tip: root.wxTip; primaryHint: active ? "Close forecast" : "Forecast"; secondaryHint: "Bar settings"
            tertiaryHint: "Refresh"
            onPrimary: {
                if (!barWin) return;
                const c = mapToItem(barWin.contentItem, width / 2, height / 2);
                barWin.weatherAnchor = Qt.point(c.x, c.y);
                barWin.musicOpen = false; barWin.trayItem = null;
                barWin.weatherOpen = !barWin.weatherOpen;
            }
            onSecondary: root.openSettings(); onTertiary: root.refreshWeather()'''),
('''                barWin.trayItem = null;
                barWin.musicOpen = !barWin.musicOpen;''',
'''                barWin.trayItem = null; barWin.weatherOpen = false;
                barWin.musicOpen = !barWin.musicOpen;'''),
('''            // Kali: menu of a tray icon on this screen (opened by the tray module)''',
'''            // Kali: weather card for this screen (opened by the weather module)
            property bool weatherOpen: false
            property point weatherAnchor: Qt.point(0, 0)
            WeatherPreview {
                host: bar
                wx: root
                screen: bar.screen
                position: cfg.position
                barThick: root.panelThick + root.effEdge
            }
            // Kali: menu of a tray icon on this screen (opened by the tray module)'''),
('''                        barWin.musicOpen = false;
                        barWin.trayItem = item;''',
'''                        barWin.musicOpen = false; barWin.weatherOpen = false;
                        barWin.trayItem = item;'''),
]
