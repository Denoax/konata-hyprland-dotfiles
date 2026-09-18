import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root
    title: qsTr("Kona appearance")

    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader { first: true; text: qsTr("Appearance") }
        NavRow {
            first: true
            icon: "light_mode"
            text: qsTr("Light")
            subtext: qsTr("Use Kona's system-wide light appearance")
            onClicked: Quickshell.execDetached([root.bin + "kona-appearance", "light"])
        }
        NavRow {
            icon: "palette"
            text: qsTr("Kona")
            subtext: qsTr("Use Kona's pastel blue system appearance")
            onClicked: Quickshell.execDetached([root.bin + "kona-appearance", "kona"])
        }
        NavRow {
            icon: "dark_mode"
            text: qsTr("Dark")
            subtext: qsTr("Use Kona's pastel dark appearance")
            onClicked: Quickshell.execDetached([root.bin + "kona-appearance", "dark"])
        }
        NavRow {
            last: true
            icon: "contrast"
            text: qsTr("Toggle appearance")
            subtext: qsTr("Switch between standard Light and Dark")
            onClicked: Quickshell.execDetached([root.bin + "kona-appearance", "toggle"])
        }

        SectionHeader { text: qsTr("Desktop") }
        NavRow {
            first: true
            icon: "person"
            text: qsTr("Profile")
            subtext: qsTr("Daily, Focus, Gaming and Showcase")
            onClicked: Quickshell.execDetached([root.bin + "kona-profile-menu"])
        }
        NavRow {
            icon: "wallpaper"
            text: qsTr("Local wallpaper")
            subtext: qsTr("Browse local images with the native visual picker")
            onClicked: root.nState.openSubPage(1)
        }
        NavRow {
            icon: "subscriptions"
            text: qsTr("Wallpaper Engine")
            subtext: qsTr("Kona scenes and subscribed Steam Workshop wallpapers")
            onClicked: Quickshell.execDetached([root.bin + "kona-wallpaper-menu"])
        }
        NavRow {
            last: true
            icon: "animation"
            text: qsTr("Reduced Motion")
            subtext: qsTr("Configure motion through Kona preferences")
            onClicked: Quickshell.execDetached([root.bin + "kona-preferences"])
        }
    }
}
