import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

RowLayout {
    id: studioView
    Component { id: wallpapers; WallpaperPage { controller: studioView.controller } }
    Component { id: help; ShortcutPage { controller: studioView.controller } }
    Component { id: settings; SettingsPage { controller: studioView.controller } }
    required property var controller
 spacing: 24
    ColumnLayout { Layout.preferredWidth: 205; Layout.minimumWidth: 205; Layout.maximumWidth: 205; Layout.fillHeight: true; spacing: 5
        TextField { implicitHeight: 40; Layout.fillWidth: true; placeholderText: "Search settings…"; placeholderTextColor: Appearance.textSecondary; color: Appearance.text; font.family: "Noto Sans"; font.pixelSize: 12; onTextChanged: controller.query=text; background: Rectangle { radius: 8; color: Appearance.surfaceAlt; border.color: parent.activeFocus ? Appearance.focus : Appearance.outline } }
        Repeater { model: controller.sections
            KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); required property string modelData; text: modelData; visible: controller.section==="Shortcuts" || controller.section==="Wallpaper" || !controller.query || modelData.toLowerCase().includes(controller.query.toLowerCase()); Layout.fillWidth: true; implicitHeight: 40; accent: controller.accent; selected: controller.section===modelData; onClicked: { controller.section=modelData;controller.query=""; } }
        }
        Item { Layout.fillHeight: true }
    }
    Rectangle { Layout.fillHeight: true; width: 1; color: Appearance.outline }
    ColumnLayout { Layout.fillWidth: true; Layout.fillHeight: true; spacing: 12
        KText { text: controller.section; font.pixelSize: 30; font.weight: Font.Light }
        Loader { Layout.fillWidth: true; Layout.fillHeight: true; sourceComponent: controller.section==="Wallpaper" ? wallpapers : controller.section==="Shortcuts" ? help : settings }
    }
}
