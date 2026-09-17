import QtQuick
import QtQuick.Controls
Button {
    id: control
    property color accent: Appearance.accent
    property bool selected: false
    property int motion: 140
    hoverEnabled: true
    implicitHeight: 42
    implicitWidth: Math.max(90, label.implicitWidth + 30)
    activeFocusOnTab: true
    Accessible.name: text
    contentItem: KText {
        id: label
        text: control.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: control.selected ? (Appearance.mode === "dark" ? Appearance.background : Appearance.text) : control.enabled ? Appearance.text : Appearance.textMuted
    }
    background: Rectangle {
        radius: 7
        color: control.selected ? control.accent : control.down ? Appearance.surfacePressed : control.hovered ? Appearance.accentSoft : Appearance.surfaceAlt
        border.width: 1
        border.color: control.activeFocus ? Appearance.focus : control.selected ? control.accent : Appearance.outline
        Behavior on color { ColorAnimation { duration: control.motion } }
        Rectangle {
            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
            width: control.down ? parent.width-16 : 0; height: 2; color: control.accent
            Behavior on width { NumberAnimation { duration: control.motion } }
        }
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
