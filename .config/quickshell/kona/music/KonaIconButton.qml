import QtQuick
import QtQuick.Effects

Item {
    id: root

    property string glyph: ""
    property string accessibleLabel: glyph
    objectName: accessibleLabel
    property int motionDuration: 120
    activeFocusOnTab: enabled
    Accessible.role: Accessible.Button
    Accessible.name: accessibleLabel
    Accessible.onPressAction: if (enabled) clicked()
    property bool outputDeviceIcon: false
    property bool playingDecoration: false
    property bool reducedMotion: false
    readonly property bool decorationRotating: ringAnimation.running
    readonly property real decorationRotation: ring.rotation
    readonly property color deviceColor: mouse.containsMouse || activeFocus ? accent : iconColor
    onDeviceColorChanged: deviceGlyph.requestPaint()
    property bool primary: false
    property bool selected: false
    property real diameter: primary ? 72 : 48
    property color accent: Appearance.accent
    property color iconColor: primary ? (Appearance.mode === "dark" ? Appearance.background : Appearance.text) : Appearance.textSecondary

    signal clicked()

    implicitWidth: diameter
    implicitHeight: diameter

    scale: mouse.pressed && enabled ? 0.965 : (mouse.containsMouse && enabled ? 1.035 : 1.0)
    opacity: enabled ? 1.0 : 0.35

    Behavior on scale {
        NumberAnimation { duration: root.motionDuration; easing.type: Easing.OutCubic }
    }
    Behavior on opacity { NumberAnimation { duration: root.motionDuration } }

    // Analytic shadow avoids a blurred source texture; only the arc rotates.
    RectangularShadow {
        anchors.fill: parent
        radius: width / 2
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
        blur: 20
        spread: 4
        visible: root.primary && root.playingDecoration
    }
    Canvas {
        id: ring
        objectName: "playbackRing"
        anchors.centerIn: parent
        width: root.width + 18
        height: root.height + 18
        visible: root.primary && root.playingDecoration
        opacity: 0.5
        antialiasing: true
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = root.accent;
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, width / 2 - 2, -Math.PI / 2, Math.PI * 0.9);
            ctx.stroke();
        }
        NumberAnimation on rotation {
            id: ringAnimation
            from: 0; to: 360; duration: 8000
            loops: Animation.Infinite
            running: root.primary && root.playingDecoration && !root.reducedMotion && root.visible
        }
        Connections {
            target: root
            function onAccentChanged() { ring.requestPaint(); }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.primary
               ? root.accent
               : (mouse.containsMouse && root.enabled ? Appearance.surfacePressed : "transparent")
        border.width: root.activeFocus ? 2 : root.primary ? 1 : 0
        border.color: root.activeFocus ? Appearance.focus : root.primary ? Appearance.outlineStrong : "transparent"

        Behavior on color { ColorAnimation { duration: root.motionDuration } }

        Text {
            anchors.centerIn: parent
            visible: !root.outputDeviceIcon
            text: root.glyph
            color: root.iconColor
            font.pixelSize: root.primary ? 30 : 25
            font.weight: Font.DemiBold
            opacity: root.enabled ? 1.0 : 0.45
        }
    }

    Canvas {
        id: deviceGlyph
        anchors.centerIn: parent
        width: 34; height: 34
        visible: root.outputDeviceIcon
        antialiasing: true
        // Monitor with a distinct foreground speaker, not a transport symbol.
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = root.deviceColor;
            ctx.lineWidth = 2.2;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(16, 24); ctx.lineTo(3, 24); ctx.lineTo(3, 5);
            ctx.lineTo(29, 5); ctx.lineTo(29, 11);
            ctx.moveTo(12, 24); ctx.lineTo(12, 29);
            ctx.moveTo(8, 29); ctx.lineTo(16, 29);
            ctx.moveTo(20, 17); ctx.lineTo(31, 14); ctx.lineTo(31, 31);
            ctx.lineTo(20, 28); ctx.closePath();
            ctx.stroke();
            ctx.beginPath(); ctx.arc(25.5, 23, 2.4, 0, Math.PI * 2); ctx.stroke();
        }
    }

    Keys.onReturnPressed: if (root.enabled) root.clicked()
    Keys.onEnterPressed: if (root.enabled) root.clicked()
    Keys.onSpacePressed: if (root.enabled) root.clicked()

    focus: false

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: { root.forceActiveFocus(); root.clicked(); }
    }
}
