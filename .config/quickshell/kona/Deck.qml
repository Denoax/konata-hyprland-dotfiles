import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    required property var controller

    spacing: 16
    Item {
        Layout.fillWidth: true; Layout.preferredHeight: 160; Layout.minimumHeight: 160; Layout.maximumHeight: 160
        ColumnLayout { spacing: 0; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 350
            KText { text: Qt.formatDateTime(controller.date,"dddd, MMMM d"); color: controller.accent; font.pixelSize: 12; font.letterSpacing: 1 }
            KText { text: Qt.formatDateTime(controller.date,"HH:mm"); font.pixelSize: 82; font.weight: Font.Light; font.letterSpacing: -5 }
            KText { text: controller.state.network || "Offline"; color: Appearance.textSecondary; font.pixelSize: 11 }
        }
        ColumnLayout { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 220; spacing: 10
            KText { text: "Profile"; color: Appearance.textSecondary; font.pixelSize: 11 }
            KText { text: (controller.state.profile || "daily").replace(/^./, value => value.toUpperCase()); font.pixelSize: 27; color: controller.accent }
            KText { text: controller.state.scene || "midnight"; font.pixelSize: 13 }
            KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Change profile"; onClicked: { controller.navigate("studio");controller.section="Profiles"; } }
        }
    }
    RowLayout {
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 205; spacing: 16
        KCard {
            Layout.fillWidth: true; Layout.fillHeight: true
            RowLayout {
                anchors.fill: parent; anchors.margins: 20; spacing: 20
                Image { visible: !!controller.player && !!controller.player.trackArtUrl; source: controller.player ? controller.player.trackArtUrl : ""; asynchronous: true; sourceSize.width: 300; sourceSize.height: 300; fillMode: Image.PreserveAspectCrop; Layout.preferredWidth: 165; Layout.preferredHeight: 165 }
                ColumnLayout { Layout.fillWidth: true; spacing: 14
                    KText { text: controller.player ? "Music · "+controller.player.identity : "Applications"; color: controller.accent; font.pixelSize: 11; Layout.fillWidth: true }
                    KText { text: controller.player ? controller.player.trackTitle || "Untitled track" : "Open an application"; font.pixelSize: 23; wrapMode: Text.WordWrap; maximumLineCount: 2; Layout.fillWidth: true }
                    KText { text: controller.player ? controller.player.trackArtist || "Unknown artist" : "Search installed desktop entries."; color: Appearance.textSecondary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    RowLayout { visible: !!controller.player
                        KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "⏮"; implicitWidth: 60; enabled: !!controller.player && controller.player.canGoPrevious; onClicked: controller.player.previous() }
                        KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: controller.player && controller.player.isPlaying ? "Pause" : "Play"; accent: controller.accent; selected: true; enabled: !!controller.player && controller.player.canTogglePlaying; onClicked: controller.player.togglePlaying() }
                        KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "⏭"; implicitWidth: 60; enabled: !!controller.player && controller.player.canGoNext; onClicked: controller.player.next() }
                    }
                    RowLayout { visible: !controller.player
                        KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Apps  ↗"; accent: controller.accent; selected: true; onClicked: controller.act("open","launcher",true) }
                        KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Overview"; onClicked: controller.act("open","overview",true) }
                    }
                }
            }
        }
        KCard { Layout.preferredWidth: 270; Layout.fillHeight: true
            ColumnLayout { anchors.fill: parent; anchors.margins: 20; spacing: 12
                KText { text: "Status"; color: controller.accent; font.pixelSize: 11 }
                KText { text: controller.state.network || "Offline"; font.pixelSize: 18; Layout.fillWidth: true }
                KText { text: (controller.state.notifications===null ? "Unavailable" : (controller.state.notifications || 0)+" waiting")+" · Notifications"; color: Appearance.textSecondary; Layout.fillWidth: true }
                KText { text: controller.state.recording && controller.state.recording.active ? "● Recording active" : "Recording idle"; color: controller.state.recording && controller.state.recording.active ? Appearance.danger : Appearance.textSecondary }
                KText { text: "Night light · "+(controller.state.night_light ? controller.state.night_light.mode : "scheduled"); color: Appearance.textSecondary; Layout.fillWidth: true }
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); Layout.fillWidth: true; text: "Control Center  →"; onClicked: controller.act("open","notifications",true) }
            }
        }
    }
    RowLayout { Layout.fillWidth: true; spacing: 8
        Repeater { model: [ ["Wallpaper","wallpapers"],["Shortcuts","shortcuts"],["Capture","capture"],["Audio","audio"] ]
            KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); required property var modelData; text: modelData[0]; Layout.fillWidth: true; onClicked: modelData[1]==="wallpapers" || modelData[1]==="shortcuts" ? controller.navigate(modelData[1]) : controller.act("open",modelData[1],true) }
        }
    }
}
