import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Flickable {
    required property var controller
 contentHeight: settingsColumn.implicitHeight; clip: true; boundsBehavior: Flickable.StopAtBounds; ScrollBar.vertical: ScrollBar {}
    ColumnLayout { id: settingsColumn; width: parent.width; spacing: 16
        KText { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: Appearance.textSecondary; text: ({"Appearance":"One system Light/Dark preference with Kona's restrained accent. Keep your favorite scenes close at hand.","Motion":"Direction gives movement meaning. Full is restrained; Reduced shortens travel; Off removes it. Focus and Gaming retain their quiet policy.","Profiles":"Choose the resource policy for what you are doing. Animated Showcase is an explicit resource spend.","Bars & Dock":"Three roles, one desktop. Existing entrypoints and the canonical dock remain available.","Displays":"Current physical layout. Display changes are outside this pass.","System & Recovery":"Inspect your desktop and carry a small preset between setups. Recovery actions are explicit.","About":"A personal command center. Recognizably Kona."})[controller.section] || "" }
        ColumnLayout { visible: controller.section==="Appearance"; Layout.fillWidth: true; spacing: 14
            KText { text: "ACCENT"; color: controller.accent; font.pixelSize: 11 }
            RowLayout {
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "From wallpaper"; selected: controller.data.prefs.accent==="wallpaper"; accent: controller.accent; onClicked: controller.act("accent","wallpaper") }
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Kona cyan"; selected: controller.data.prefs.accent==="cyan"; accent: controller.accent; onClicked: controller.act("accent","cyan") }
            }
            KText { text: "WINDOW FINISH"; color: controller.accent; font.pixelSize: 11 }
            RowLayout {
                KText { text: "Corners "+controller.appearance.rounding+" px"; Layout.preferredWidth: 160 }
                KSlider { accent: controller.accent; from: 6; to: 16; stepSize: 1; value: controller.appearance.rounding; onMoved: controller.appearance=Object.assign({},controller.appearance,{rounding:Math.round(value)}); Layout.fillWidth: true }
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: controller.appearance.blur ? "Blur on" : "Blur off"; onClicked: controller.appearance=Object.assign({},controller.appearance,{blur:!controller.appearance.blur}) }
            }
            RowLayout {
                KText { text: "Opacity "+Math.round(controller.appearance.opacity*100)+"%"; Layout.preferredWidth: 160 }
                KSlider { accent: controller.accent; from: .8; to: 1; stepSize: .01; value: controller.appearance.opacity; onMoved: controller.appearance=Object.assign({},controller.appearance,{opacity:value,inactive:Math.max(.8,value-.06)}); Layout.fillWidth: true }
            }
            RowLayout {
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Preview finish"; onClicked: controller.act("appearance-preview",JSON.stringify(controller.appearance)) }
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Apply"; enabled: controller.appearancePending; onClicked: controller.act("appearance-commit","") }
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Revert"; enabled: controller.appearancePending; onClicked: controller.act("appearance-revert","") }
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Reset finish"; onClicked: controller.act("appearance-reset","") }
            }
            KText { text: "SCENES"; color: controller.accent; font.pixelSize: 11 }
            Repeater { model: [ ["midnight","Midnight","A single quiet image across your space."],["constellation","Constellation","Three coordinated static panels."],["constellation-motion","Constellation · Motion","Animated in Daily / Showcase; static in Focus / Gaming."] ]
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); required property var modelData; Layout.fillWidth: true; text: modelData[1]+"  ·  "+modelData[2]; accent: controller.accent; selected: controller.state.scene===modelData[0]; onClicked: controller.act("scene",modelData[0]); implicitHeight: 56 }
            }
            KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Open wallpapers"; onClicked: controller.section="Wallpaper" }
        }
        ColumnLayout { visible: controller.section==="Motion"; Layout.fillWidth: true; spacing: 16
            RowLayout { Repeater { model: ["full","reduced","off"]
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); required property string modelData; text: modelData.toUpperCase(); selected: controller.motionMode===modelData; accent: controller.accent; onClicked: controller.act("motion",modelData) }
            } }
            KText { text: "PACE"; color: controller.accent; font.pixelSize: 11 }
            RowLayout { Repeater { model: [["Brisk","0.75"],["Balanced","1"],["Deliberate","1.25"]]
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); required property var modelData; text: modelData[0]; selected: controller.data.prefs.intensity===Number(modelData[1]); accent: controller.accent; onClicked: controller.act("intensity",modelData[1]) }
            } }
            KCard { Layout.fillWidth: true; implicitHeight: 140
                Rectangle { id: demo; x: 24; y: 36; width: 140; height: 68; radius: 10; color: Appearance.surfacePressed; border.color: controller.accent
                    KText { anchors.centerIn: parent; text: "KONA"; color: controller.accent; font.letterSpacing: 3 }
                    SequentialAnimation { id: demoAnim; NumberAnimation { target: demo; property: "x"; to: 360; duration: controller.duration; easing.type: Easing.OutCubic } NumberAnimation { target: demo; property: "x"; to: 24; duration: controller.duration; easing.type: Easing.OutCubic } }
                }
            }
            RowLayout {
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Preview motion"; onClicked: demoAnim.restart() }
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Reset motion section"; onClicked: controller.act("reset-motion","") }
            }
        }
        ColumnLayout { visible: controller.section==="Profiles"; Layout.fillWidth: true; spacing: 12
            Repeater { model: [["daily","DAILY","Normal desktop · static scene recommended"],["focus","FOCUS","Static wallpaper · quiet effects · hidden bar"],["gaming","GAMING","Static wallpaper · tearing/VRR policy · previous profile on exit"],["showcase","SHOWCASE","Full effects · explicit opt-in animation cost"]]
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); required property var modelData; Layout.fillWidth: true; implicitHeight: 64; text: modelData[1]+"  /  "+modelData[2]; selected: controller.state.profile===modelData[0]; accent: controller.accent; onClicked: controller.act("profile",modelData[0]) }
            }
            KText { text: "Gaming returns to "+(controller.state.return_to || "daily")+". Showcase uses all three displays and restores the previous profile when closed."; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: Appearance.textSecondary }
        }
        ColumnLayout { visible: controller.section==="Bars & Dock"; Layout.fillWidth: true; spacing: 16
            Repeater { model: [["LEFT / NAVIGATION","Pinned and running apps, workspaces, media and session state."],["CENTER / COMMAND","240 Hz workspace navigation, clock and quick controls."],["RIGHT / INFORMATION","Resources, connectivity and notifications."],["APPLICATIONS","The Kona sidebar is the primary launcher; Rofi owns the complete app and window indexes."]]
                KCard { required property var modelData; Layout.fillWidth: true; implicitHeight: 82
                    ColumnLayout { anchors.fill: parent; anchors.margins: 16; KText { text: modelData[0]; color: controller.accent; font.pixelSize: 12 } KText { text: modelData[1]; color: Appearance.textSecondary; font.pixelSize: 11; Layout.fillWidth: true } }
                }
            }
            KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "All shortcuts  →"; onClicked: controller.section="Shortcuts" }
        }
        ColumnLayout { visible: controller.section==="Displays"; Layout.fillWidth: true; spacing: 16
            RowLayout { Layout.fillWidth: true; spacing: 8
                Repeater { model: controller.data.monitors.slice().sort((a,b)=>a.x-b.x)
                    KCard { required property var modelData; Layout.fillWidth: true; implicitHeight: 135; border.color: modelData.focused ? controller.accent : Appearance.outline
                        ColumnLayout { anchors.fill: parent; anchors.margins: 12; spacing: 8
                            KText { text: modelData.name; font.pixelSize: 15; color: controller.accent }
                            KText { text: Math.round(modelData.refreshRate)+" Hz"; font.pixelSize: 23 }
                            KText { text: modelData.width+" × "+modelData.height; font.pixelSize: 11 }
                            KText { text: modelData.x+", "+modelData.y; color: Appearance.textSecondary; font.pixelSize: 10 }
                        }
                    }
                }
            }
            Repeater { model: controller.data.monitors
                KText { required property var modelData; text: modelData.name+" / "+modelData.make+" "+modelData.model; Layout.fillWidth: true; color: Appearance.textSecondary; font.pixelSize: 12 }
            }
            KText { text: "Read-only · No monitor modes or GPU environment are changed here."; color: Appearance.textSecondary; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        }
        ColumnLayout { visible: controller.section==="System & Recovery"; Layout.fillWidth: true; spacing: 12
            Repeater { model: Object.keys(controller.data.versions)
                KText { required property string modelData; text: modelData+"  /  "+controller.data.versions[modelData]; Layout.fillWidth: true; font.pixelSize: 12 }
            }
            KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Refresh desktop health"; onClicked: controller.refresh() }
            RowLayout {
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Export preset"; onClicked: controller.act("export","") }
                KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Load preset"; onClicked: controller.act("import",controller.presetPath) }
            }
            TextField { Layout.fillWidth: true; implicitHeight: 40; text: controller.presetPath; color: Appearance.text; onEditingFinished: controller.presetPath=text; background: Rectangle { radius: 7; color: Appearance.surfaceAlt; border.color: parent.activeFocus ? Appearance.focus : Appearance.outline } }
            RowLayout {
                KButton { motion: controller.motionMode==="off" ? 0 : 140; text: "Updates & rollback"; onClicked: controller.act("open","updates",true) }
                KButton { motion: controller.motionMode==="off" ? 0 : 140; text: "Copy backup command"; onClicked: { Quickshell.clipboardText="kona-backup"; controller.message="Copied kona-backup · This command commits and pushes when you run it."; } }
            }
            KText { text: controller.imported ? "Loaded: "+controller.imported.profile+" / "+controller.imported.scene+" / "+controller.imported.preferences.motion : "Presets contain profile, scene and appearance preferences. No display identities or credentials."; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: Appearance.textSecondary }
            KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); visible: !!controller.imported; text: "Apply loaded preset"; onClicked: controller.act("apply-preset",JSON.stringify(controller.imported)) }
            KText { text: "RECOVERY"; color: controller.accent; font.pixelSize: 11 }
            KText { text: "kona-profile preview-revert\nkona-profile reconcile\nkona-theme --default\n\nRofi fallbacks remain available through the existing shortcuts.\n\nkona-backup commits and pushes only when run deliberately from a terminal. Settings never invokes it."; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: Appearance.textSecondary; font.pixelSize: 12 }
        }
        ColumnLayout { visible: controller.section==="About"; Layout.fillWidth: true; spacing: 22
            Image {
                Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 220; Layout.preferredHeight: 180
                source: Qt.resolvedUrl("sidebar/assets/art/konata-avatar.jpg")
                fillMode: Image.PreserveAspectCrop; asynchronous: true
            }
            KText { text: "Kona"; font.pixelSize: 44; font.letterSpacing: 3; color: controller.accent; Layout.alignment: Qt.AlignHCenter }
            KText { text: "A Konata-themed desktop built on Hyprland, Waybar, SwayNC, Rofi and Quickshell. Existing services remain responsible for notifications, audio, profiles, wallpaper and session state.\n\nQuickshell 0.3.1 · Qt 6.11"; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: Appearance.textSecondary }
        }
    }
}
