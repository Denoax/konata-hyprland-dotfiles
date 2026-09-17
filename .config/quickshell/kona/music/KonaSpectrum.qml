import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var values: []
    property bool active: false
    property color accent: Appearance.accent
    property real minBarHeight: 5
    property real maxBarHeight: 46

    implicitWidth: 230
    implicitHeight: 52

    Row {
        anchors.fill: parent
        spacing: 7
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.values ? root.values.length : 0

            Rectangle {
                required property int index
                width: 4
                radius: 2
                height: root.active
                        ? root.minBarHeight + (root.maxBarHeight - root.minBarHeight) * Math.max(0, Math.min(1, Number(root.values[index])))
                        : root.minBarHeight
                color: root.accent
                opacity: root.active ? 0.86 : 0.28
                anchors.verticalCenter: parent.verticalCenter

                Behavior on height {
                    NumberAnimation { duration: 95; easing.type: Easing.OutCubic }
                }
                Behavior on opacity { NumberAnimation { duration: 140 } }
            }
        }
    }
}
