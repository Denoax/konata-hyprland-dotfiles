import QtQuick
import QtQuick.Layouts
import "../components"
Item {
    id: root
    property string statusLabel: ""
    property url avatar: ""
    implicitWidth: 278
    implicitHeight: content.implicitHeight + 24
    KSurface { anchors.fill: parent; radius: 16; highlighted: true; outlined: false; surfaceOpacity: 0.82 }
    Column {
        id: content
        x: 12; y: 12; width: parent.width - 24; spacing: 14
        RowLayout {
            width: parent.width; spacing: 14
            Item {
                Layout.preferredWidth: 78; Layout.preferredHeight: 78
                Rectangle {
                    id: avatarAura
                    objectName: "avatarAura"
                    anchors.centerIn: parent
                    width: 76; height: 76; radius: 38
                    color: "transparent"; border.width: 3; border.color: Tokens.accent
                    opacity: Tokens.reducedMotion ? 0.32 : 0.28
                    SequentialAnimation on opacity {
                        running: !Tokens.reducedMotion && root.visible
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.66; duration: 1800; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.28; duration: 1800; easing.type: Easing.InOutSine }
                    }
                }
                KRoundedImage {
                    anchors.centerIn: parent; width: 68; height: 68; radius: 34
                    Accessible.ignored: true; source: root.avatar
                    fallbackSource: Qt.resolvedUrl("../../assets/art/profile-avatar-source.png")
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: 6
                Text { objectName: "headerSystemTitle"; text: "KONA"; color: Tokens.shellText; font.family: Tokens.uiFont; font.pixelSize: 23; font.weight: Font.DemiBold; font.letterSpacing: 4; Layout.fillWidth: true }
                Text { objectName: "headerSystemSubtitle"; text: "Arch Linux · Hyprland"; color: Tokens.shellMuted; font.pixelSize: 11; font.family: Tokens.uiFont; elide: Text.ElideRight; Layout.fillWidth: true }
                RowLayout { visible: root.statusLabel.length > 0; spacing: 7; Layout.fillWidth: true
                    Rectangle { Layout.preferredWidth: 7; Layout.preferredHeight: 7; radius: 3.5; color: Tokens.shellAccent }
                    Text { objectName: "headerProfile"; text: root.statusLabel; textFormat: Text.PlainText; color: Tokens.shellAccent; font.pixelSize: 11; font.family: Tokens.uiFont; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                }
            }
        }
    }
}
