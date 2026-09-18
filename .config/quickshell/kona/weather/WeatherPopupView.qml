import QtQuick
import QtQuick.Effects

Item {
    id: root

    property var weatherData: ({status: "loading"})
    property real reveal: 1
    signal requestRefresh()

    readonly property bool ready: weatherData && ["ok", "stale"].includes(weatherData.status) && weatherData.current
    readonly property var current: ready ? weatherData.current : ({})
    readonly property var location: weatherData && weatherData.location ? weatherData.location : ({name: "", region: ""})
    readonly property var units: weatherData && weatherData.units ? weatherData.units : ({temperature: "", wind: "", precipitation: ""})
    readonly property color primaryText: Appearance.text
    readonly property color secondaryText: Appearance.textSecondary
    readonly property color accentText: Appearance.accent

    width: 430
    height: 560
    opacity: reveal
    scale: .985 + reveal * .015
    Accessible.role: Accessible.Pane
    Accessible.name: "Weather"

    function hour(value) {
        const date = new Date(value);
        return Number.isNaN(date.getTime()) ? "—" : date.toLocaleTimeString(Qt.locale(), "h AP");
    }

    function isNight(value) {
        const date = new Date(value);
        if (Number.isNaN(date.getTime())) return false;
        return date.getHours() < 6 || date.getHours() >= 19;
    }

    function weatherIcon(code, night) {
        if ([0, 1].includes(Number(code))) return night ? "clear_night" : "clear_day";
        if (Number(code) === 2) return night ? "partly_cloudy_night" : "partly_cloudy_day";
        return "cloudy";
    }

    function weatherAsset(path) { return Qt.resolvedUrl("assets/reconstruction-v3/" + path); }

    RectangularShadow {
        x: 8; y: 8; width: 414; height: 544
        radius: 28
        color: Appearance.shadow
        blur: 18
        spread: 1
        offset: Qt.vector2d(0, 6)
    }

    Rectangle {
        x: 8; y: 8; width: 414; height: 544
        radius: 28
        color: Appearance.surfaceElevated
        border.width: 2
        border.color: Appearance.outlineStrong
    }

    Item {
        visible: root.ready
        anchors.fill: parent

        Image {
            x: 34; y: 28; width: 38; height: 38
            source: root.weatherAsset("icons/location.png")
            sourceSize: Qt.size(76, 76)
            fillMode: Image.PreserveAspectFit
        }

        Column {
            x: 80; y: 23; width: 245; spacing: -1
            Text {
                width: parent.width
                text: root.location.name
                color: root.primaryText
                font.family: "Noto Sans"
                font.pixelSize: 22
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.location.region || "Configured location"
                color: root.secondaryText
                font.family: "Noto Sans"
                font.pixelSize: 11
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }

        Item {
            x: 365; y: 28; width: 38; height: 38
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: "Refresh weather"
            Image {
                anchors.fill: parent
                source: root.weatherAsset("icons/more.png")
                sourceSize: Qt.size(76, 76)
                fillMode: Image.PreserveAspectFit
                opacity: refreshArea.pressed ? .72 : 1
            }
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: parent.activeFocus ? 2 : 0
                border.color: Appearance.focus
            }
            MouseArea {
                id: refreshArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.requestRefresh()
            }
            Keys.onReturnPressed: root.requestRefresh()
            Keys.onEnterPressed: root.requestRefresh()
            Keys.onSpacePressed: root.requestRefresh()
        }

        Text {
            x: 29; y: 83; width: 135; height: 78
            text: Math.round(root.current.temperature) + "°"
            color: root.accentText
            font.family: "Noto Sans"
            font.pixelSize: 62
            font.weight: Font.Bold
            verticalAlignment: Text.AlignVCenter
        }

        Image {
            x: [0, 1].includes(Number(root.current.code)) ? 139 : 127
            y: Number(root.current.code) === 2 ? 91 : 99
            width: Number(root.current.code) === 2 ? 84 : 66
            height: Number(root.current.code) === 2 ? 78 : 66
            source: Number(root.current.code) === 2 && !root.isNight(root.current.time)
                    ? root.weatherAsset("art/partly_cloudy_hero.png")
                    : root.weatherAsset("icons/" + root.weatherIcon(root.current.code, root.isNight(root.current.time)) + ".png")
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }

        Image {
            x: 194; y: 73; width: 204; height: 132
            source: root.weatherAsset("art/kona_ledge_mascot.png")
            sourceSize: Qt.size(650, 420)
            fillMode: Image.Stretch
            smooth: true
            mipmap: true
        }

        Text {
            x: 31; y: 165; width: 160; height: 29
            text: root.current.condition || ""
            color: root.primaryText
            font.family: "Noto Sans"
            font.pixelSize: 19
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        Text {
            x: 32; y: 194; width: 155; height: 18
            text: "Feels like " + root.current.feels_like + "°"
            color: root.secondaryText
            font.family: "Noto Sans"
            font.pixelSize: 11
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Repeater {
            model: [
                {x: 27, y: 243, label: "High / Low", value: root.current.high + "° / " + root.current.low + "°", icon: "thermometer"},
                {x: 221, y: 243, label: "Feels Like", value: root.current.feels_like + "°", icon: "feels_like"},
                {x: 27, y: 308, label: "Humidity", value: root.current.humidity + "%", icon: "humidity"},
                {x: 221, y: 308, label: "Wind", value: root.current.wind_speed + " " + root.units.wind + "  " + root.current.wind_direction, icon: "wind"}
            ]
            delegate: Rectangle {
                required property var modelData
                x: modelData.x; y: modelData.y
                width: 182; height: 58
                radius: 18
                color: Appearance.surfaceAlt
                border.width: 1
                border.color: Appearance.outline
                Image {
                    x: 10; anchors.verticalCenter: parent.verticalCenter
                    width: 34; height: 34
                    source: root.weatherAsset("icons/" + modelData.icon + ".png")
                    sourceSize: Qt.size(68, 68)
                    fillMode: Image.PreserveAspectFit
                }
                Column {
                    x: 53; anchors.verticalCenter: parent.verticalCenter; spacing: 0
                    Text {
                        width: 119
                        text: modelData.label
                        color: root.secondaryText
                        font.family: "Noto Sans"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        width: 119
                        text: modelData.value
                        color: root.primaryText
                        font.family: "Noto Sans"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Rectangle {
            x: 27; y: 376; width: 376; height: 56
            radius: 18
            color: Appearance.surfaceAlt
            border.width: 1
            border.color: Appearance.outline
            Image {
                x: 10; anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 34
                source: root.weatherAsset("icons/umbrella.png")
                sourceSize: Qt.size(68, 68)
                fillMode: Image.PreserveAspectFit
            }
            Column {
                x: 59; anchors.verticalCenter: parent.verticalCenter; spacing: -1
                Text {
                    text: "Precipitation Chance"
                    color: root.secondaryText
                    font.family: "Noto Sans"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
                Text {
                    text: root.current.precipitation_chance + "%"
                    color: root.primaryText
                    font.family: "Noto Sans"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }
            }
            Text {
                anchors.right: chevron.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.current.precipitation_chance < 25 ? "Mostly dry today" : "Umbrella advised"
                color: root.secondaryText
                font.family: "Noto Sans"
                font.pixelSize: 10
                font.weight: Font.Medium
            }
            Image {
                id: chevron
                anchors.right: parent.right
                anchors.rightMargin: 11
                anchors.verticalCenter: parent.verticalCenter
                width: 12; height: 18
                source: root.weatherAsset("icons/chevron.png")
                sourceSize: Qt.size(38, 38)
                fillMode: Image.PreserveAspectFit
            }
        }

        Rectangle {
            x: 27; y: 447; width: 376; height: 89
            radius: 18
            color: Appearance.surfaceAlt
            border.width: 1
            border.color: Appearance.outline
            Row {
                anchors.fill: parent
                Repeater {
                    model: (root.weatherData.hourly || []).slice(0, 6)
                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: 62.66; height: 89
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: 14
                            visible: index === 0
                            color: Appearance.accentSoft
                        }
                        Rectangle {
                            x: 0; y: 13; width: 1; height: 63
                            visible: index > 0
                            color: Appearance.outline
                            opacity: .65
                        }
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 7; spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: index === 0 ? "Now" : root.hour(modelData.time)
                                color: index === 0 ? root.accentText : root.secondaryText
                                font.family: "Noto Sans"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }
                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 27; height: 27
                                source: root.weatherAsset("icons/" + root.weatherIcon(modelData.code, root.isNight(modelData.time)) + ".png")
                                sourceSize: Qt.size(58, 58)
                                fillMode: Image.PreserveAspectFit
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.temperature + "°"
                                color: root.primaryText
                                font.family: "Noto Sans"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }
        }
    }

    Column {
        visible: !root.ready
        anchors.centerIn: parent
        width: 300
        spacing: 10
        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 62; height: 62
            source: root.weatherAsset("icons/cloudy.png")
            fillMode: Image.PreserveAspectFit
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.weatherData.status === "loading" ? "Loading weather…" :
                  root.weatherData.status === "setup" ? "Weather needs a location" : "Weather unavailable"
            color: root.primaryText
            font.family: "Noto Sans"
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: root.weatherData.message || "Try refreshing."
            color: root.secondaryText
            font.family: "Noto Sans"
            font.pixelSize: 12
        }
    }
}
