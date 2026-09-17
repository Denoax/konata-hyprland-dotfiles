import QtQuick
import QtQuick.Controls
Slider {
    id: root
    property real backendValue: 0
    property string accessibleLabel: "Value"
    property bool beganDrag: false
    signal requested(real normalized)
    signal committed(real normalized)
    from: 0
    to: 1
    stepSize: 0.01
    implicitHeight: 28
    implicitWidth: 180
    padding: 7
    focusPolicy: Qt.StrongFocus
    Accessible.name: accessibleLabel
    // Dragging must not destroy a media/volume binding.
    Binding { target: root; property: "value"; value: Math.max(0, Math.min(1, root.backendValue)); when: !root.pressed; restoreMode: Binding.RestoreBindingOrValue }
    onMoved: { requested(value); if (!pressed) committed(value) }
    onPressedChanged: {
        if (pressed) beganDrag = true
        else if (beganDrag) { beganDrag = false; committed(value); Feedback.bubble() }
    }
    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 4
        radius: 2
        color: Tokens.line
        Rectangle { width: root.visualPosition * parent.width; height: parent.height; radius: 2; color: Tokens.accent }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.pressed || root.activeFocus ? 12 : 8
        height: width
        radius: width / 2
        color: root.enabled ? Tokens.accent : Tokens.subtle
        border.width: root.activeFocus ? 2 : 0
        border.color: Tokens.ice
    }
}
