import QtQuick
import QtQuick.Effects
Item {
    id: root
    property string name: "info"
    property bool accented: false
    width: 20
    height: 20
    Accessible.ignored: true
    Image {
        id: sourceImage
        anchors.fill: parent
        sourceSize: Qt.size(Math.max(20, width * 2), Math.max(20, height * 2))
        source: root.name.length ? Qt.resolvedUrl("../../assets/icons/line/" + root.name + ".svg") : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: sourceImage
        colorization: 1
        colorizationColor: root.accented ? Tokens.accentStrong : Tokens.text
    }
}
