import QtQuick
import QtQuick.Effects
Item {
    id: root
    property url source: ""
    property real radius: 8
    property url fallbackSource: ""
    readonly property bool loaded: picture.status === Image.Ready
    Rectangle { anchors.fill: parent; radius: root.radius; color: Tokens.surface }
    Image {
        id: picture
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(Math.max(96, root.width * 2), Math.max(96, root.height * 2))
        visible: false
    }
    Image {
        id: fallback
        anchors.fill: parent
        source: root.fallbackSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    Rectangle { id: roundedMask; anchors.fill: parent; radius: root.radius; color: "white"; layer.enabled: true; visible: false }
    MultiEffect {
        anchors.fill: parent
        source: root.loaded ? picture : fallback
        maskEnabled: true
        maskSource: roundedMask
        visible: root.loaded || fallback.status === Image.Ready
        autoPaddingEnabled: false
    }
}
