import QtQuick

Item {
    id: root

    property url source: ""
    property int iconSize: 24
    readonly property bool hasIcon: appImage.status === Image.Ready && root.source.toString().length > 0

    width: iconSize
    height: iconSize
    implicitWidth: iconSize
    implicitHeight: iconSize

    Image {
        id: appImage
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        visible: root.hasIcon
    }

    KIcon {
        anchors.centerIn: parent
        width: Math.round(root.iconSize * 0.78)
        height: width
        name: "apps"
        opacity: 0.72
        visible: !root.hasIcon
    }
}
