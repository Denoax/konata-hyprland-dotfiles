import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Button {
    id: root
    property string iconName: ""
    property string actionId: ""
    property var payload: ({})
    property bool selected: false
    property bool plain: false
    property bool round: false
    property bool audible: true
    property string hint: text
    signal request(string actionId, var payload)
    implicitHeight: 34
    implicitWidth: text.length ? Math.max(72, contentItem.implicitWidth + 24) : 34
    padding: 8
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: root.hint.length ? root.hint : root.iconName
    Accessible.role: Accessible.Button
    opacity: enabled ? 1 : 0.4
    scale: down && !Tokens.reducedMotion ? 0.96 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: root.down ? Tokens.pressMs : Tokens.releaseMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.expressiveFastCurve
        }
    }
    background: Rectangle {
        radius: root.round ? height / 2 : 9
        color: root.down ? Tokens.surfacePressed : root.selected ? Tokens.active : root.hovered ? Tokens.surface : root.plain ? "transparent" : Tokens.panel
        border.width: root.activeFocus ? 2 : root.selected ? 1 : 0
        border.color: root.activeFocus ? Tokens.accentStrong : Tokens.accent
        Behavior on color { ColorAnimation { duration: Tokens.releaseMs; easing.type: Easing.OutCubic } }
    }
    contentItem: RowLayout {
        spacing: root.iconName.length && root.text.length ? 9 : 0
        KIcon { name: root.iconName; visible: root.iconName.length > 0; accented: root.selected; Layout.alignment: Qt.AlignVCenter }
        Text { text: root.text; visible: text.length > 0; color: Tokens.text; font.family: Tokens.uiFont; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
    }
    ToolTip.visible: hovered && hint.length > 0
    ToolTip.text: hint
    ToolTip.delay: 600
    Keys.onReturnPressed: event => { if (enabled && !event.isAutoRepeat) click(); event.accepted = true; }
    Keys.onEnterPressed: event => { if (enabled && !event.isAutoRepeat) click(); event.accepted = true; }
    onClicked: {
        if (audible) Feedback.bubble()
        if (actionId.length) request(actionId, payload)
    }
}
