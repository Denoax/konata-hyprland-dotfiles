import QtQuick
import QtQuick.Layouts
import "../components"

KAccordion {
    id: root
    title: "Music"
    iconName: "music"
    expanded: true
    property var player: null
    signal request(string actionId, var payload)
    contentHeight: 116

    Item {
        width: root.width
        height: 116
        KRoundedImage {
            x: 10; y: 8; width: 58; height: 58; radius: 9
            source: root.player ? root.player.trackArtUrl : ""
            fallbackSource: Qt.resolvedUrl("../../assets/art/konata-avatar.jpg")
        }
        Column {
            x: 78; y: 11; width: parent.width - 90; spacing: 3
            Text {
                width: parent.width
                text: root.player ? (root.player.trackTitle || "Untitled track") : "Nothing playing"
                color: Tokens.text; font.family: Tokens.uiFont; font.pixelSize: 13
                font.weight: Font.DemiBold; elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.player ? (root.player.trackArtist || root.player.identity || "Music") : "Open the player to begin"
                color: Tokens.muted; font.family: Tokens.uiFont; font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
        RowLayout {
            x: 76; y: 58; width: parent.width - 86; height: 42; spacing: 8
            KButton {
                iconName: "previous"; plain: true; round: true; width: 34; height: 34
                hint: "Previous track"; enabled: !!root.player && root.player.canGoPrevious
                onClicked: if (enabled) root.player.previous()
            }
            KButton {
                iconName: root.player && root.player.isPlaying ? "pause" : "play"
                round: true; width: 38; height: 38
                hint: root.player && root.player.isPlaying ? "Pause" : "Play"
                enabled: !!root.player && root.player.canTogglePlaying
                onClicked: if (enabled) root.player.togglePlaying()
            }
            KButton {
                iconName: "next"; plain: true; round: true; width: 34; height: 34
                hint: "Next track"; enabled: !!root.player && root.player.canGoNext
                onClicked: if (enabled) root.player.next()
            }
            Item { Layout.fillWidth: true }
            KButton {
                iconName: "expand"; plain: true; round: true; width: 34; height: 34
                hint: "Open music"
                actionId: "music.open"
                onRequest: (id, args) => root.request(id, args)
            }
        }
    }
}
