import QtQuick
import QtQuick.Layouts
KButton {
    id: root
    property bool expanded: false
    property bool expandable: true
    property int count: -1
    implicitWidth: 278
    implicitHeight: 38
    plain: true
    contentItem: RowLayout {
        spacing: 10
        KIcon { name: root.iconName; Layout.preferredWidth: 20; Layout.preferredHeight: 20 }
        Text { text: root.text; color: Tokens.text; font.family: Tokens.uiFont; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
        Rectangle {
            visible: root.count >= 0
            width: 21; height: 21; radius: 10.5; color: Tokens.active
            Text { anchors.centerIn: parent; text: Math.min(root.count, 99) + (root.count > 99 ? "+" : ""); color: Tokens.text; font.pixelSize: 11 }
        }
        KIcon { name: root.expanded ? "chevron-up" : "chevron-down"; visible: root.expandable; Layout.preferredWidth: 15; Layout.preferredHeight: 15 }
    }
}
