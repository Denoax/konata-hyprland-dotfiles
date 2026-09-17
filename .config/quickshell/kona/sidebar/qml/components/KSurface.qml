import QtQuick
Item {
    id: root
    property real radius: 12
    property bool focused: false
    property bool glow: false
    property bool frostedEdge: false
    property bool highlighted: false
    property real surfaceOpacity: 0.95
    BorderImage {
        anchors.fill: parent
        anchors.margins: -30
        source: Qt.resolvedUrl("../../assets/glows/" + (root.focused ? "panel-focus.png" : "panel-soft.png"))
        border { left: 48; right: 48; top: 48; bottom: 48 }
        visible: root.glow && !root.frostedEdge
        opacity: root.focused ? 0.8 : 0.6
    }
    Item {
        x: parent.width
        width: 20
        height: parent.height
        clip: true
        visible: root.glow && root.frostedEdge
        BorderImage {
            x: -root.width - 30; y: -30
            width: root.width + 60; height: root.height + 60
            source: Qt.resolvedUrl("../../assets/glows/panel-soft.png")
            border { left: 48; right: 48; top: 48; bottom: 48 }
            opacity: 0.18
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        topLeftRadius: root.frostedEdge ? 0 : root.radius
        bottomLeftRadius: root.frostedEdge ? 0 : root.radius
        opacity: root.surfaceOpacity
        gradient: Gradient {
            GradientStop { position: 0; color: root.highlighted ? Tokens.surfaceRaised : Tokens.panel }
            GradientStop { position: 1; color: root.highlighted ? Tokens.active : Tokens.surface }
        }
        border.width: 1
        border.color: root.focused ? Tokens.accent : Tokens.line
    }
}
