import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var values: []
    property bool active: false
    property color accent: Appearance.accent
    property real minBarHeight: 5
    property real maxBarHeight: 46
    property real barWidth: 6
    property real barSpacing: 6

    implicitWidth: 230
    implicitHeight: 52

    Row {
        anchors.centerIn: parent
        spacing: root.barSpacing

        Repeater {
            model: root.values ? root.values.length : 0

            Rectangle {
                required property int index
                width: root.barWidth
                radius: width / 2
                height: root.active
                        ? root.minBarHeight + (root.maxBarHeight - root.minBarHeight) * Math.min(1, Math.max(0, Number(root.values[index])) * 2.35)
                        : root.minBarHeight
                color: root.accent
                opacity: root.active ? 0.92 : 0.34
                anchors.verticalCenter: parent.verticalCenter

                Behavior on height {
                    NumberAnimation { duration: 135; easing.type: Easing.OutCubic }
                }
                Behavior on opacity { NumberAnimation { duration: 140 } }
            }
        }
    }
}
