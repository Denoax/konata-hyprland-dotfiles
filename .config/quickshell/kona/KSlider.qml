import QtQuick
import QtQuick.Controls
Slider {
    id: control
    property color accent: Appearance.accent
    implicitHeight: 36
    activeFocusOnTab: true
    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth; height: 4; radius: 2; color: Appearance.outline
        Rectangle { width: control.visualPosition * parent.width; height: 4; radius: 2; color: control.accent }
    }
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: 14; height: 20; radius: 4; color: control.pressed ? control.accent : Appearance.text
        border.width: control.activeFocus ? 2 : 1; border.color: control.accent
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
