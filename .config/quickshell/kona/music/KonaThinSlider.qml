import QtQuick

Item {
    id: root

    property real value: 0.0
    property real dragValue: 0
    property string accessibleLabel: ""
    objectName: accessibleLabel
    property int motionDuration: 120
    readonly property real displayedValue: drag.pressed ? dragValue : value
    activeFocusOnTab: enabled && interactive
    Accessible.role: Accessible.Slider
    Accessible.name: accessibleLabel
    Accessible.description: Math.round(displayedValue * 100) + " percent"
    Accessible.onIncreaseAction: adjust(0.05)
    Accessible.onDecreaseAction: adjust(-0.05)
    function adjust(delta) {
        if (!enabled || !interactive) return;
        const next = Math.max(0, Math.min(1, value + delta));
        moved(next); committed(next);
    }
    Keys.onLeftPressed: adjust(-0.05)
    Keys.onRightPressed: adjust(0.05)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home) { adjust(-1); event.accepted = true; }
        if (event.key === Qt.Key_End) { adjust(1); event.accepted = true; }
    }
    property bool interactive: true
    property color accent: Appearance.accent
    property color trackColor: Appearance.surfacePressed
    property real trackHeight: 10
    property real knobSize: 22

    signal moved(real value)
    signal committed(real value)

    implicitHeight: Math.max(knobSize, 26)

    function updateFromX(x) {
        var pct = Math.max(0, Math.min(1, x / Math.max(1, width)))
        root.dragValue = pct
        root.moved(pct)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: root.trackHeight
        radius: height / 2
        color: root.trackColor
        opacity: root.enabled ? 1.0 : 0.5
    }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(root.trackHeight, parent.width * Math.max(0, Math.min(1, root.displayedValue)))
        height: root.trackHeight
        radius: height / 2
        color: root.accent
        opacity: root.enabled ? 1.0 : 0.45

        Behavior on width {
            enabled: !drag.pressed
            NumberAnimation { duration: root.motionDuration; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        width: root.knobSize
        height: root.knobSize
        radius: width / 2
        x: Math.max(0, Math.min(parent.width - width, parent.width * Math.max(0, Math.min(1, root.displayedValue)) - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        color: root.accent
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? Appearance.focus : Appearance.outline
        visible: root.interactive
        opacity: root.enabled ? 1.0 : 0.45

        Behavior on x {
            enabled: !drag.pressed
            NumberAnimation { duration: root.motionDuration; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        enabled: root.enabled && root.interactive
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: mouse => { root.forceActiveFocus(); root.updateFromX(mouse.x); }
        onPositionChanged: mouse => { if (pressed) root.updateFromX(mouse.x) }
        onReleased: root.committed(root.dragValue)
    }
}
