import QtQuick

Item {
    id: root

    property int code: 0
    property color accent: Appearance.accent
    property color well: Appearance.accentSoft
    property bool showWell: false
    property bool night: false

    readonly property string iconName: {
        if ([0, 1].includes(code)) return night ? "clear_night" : "clear_day";
        if (code === 2) return night ? "partly_cloudy_night" : "partly_cloudy_day";
        return "cloudy";
    }

    implicitWidth: 48
    implicitHeight: 48

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        visible: root.showWell
        color: root.well
    }

    Image {
        anchors.centerIn: parent
        width: root.showWell ? parent.width * .78 : parent.width
        height: width
        source: Qt.resolvedUrl("assets/reconstruction-v3/icons/" + root.iconName + ".png")
        sourceSize: Qt.size(Math.round(width * 2), Math.round(height * 2))
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
        smooth: true
    }
}
