import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    required property var controller
 spacing: 12
    KCard { Layout.fillWidth: true; Layout.preferredHeight: 195; clip: true
        Image { anchors.fill: parent; source: controller.selectedUrl; asynchronous: true; sourceSize.width: 1000; fillMode: Image.PreserveAspectCrop }
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 38; color: Appearance.scrim }
        KText { anchors.left: parent.left; anchors.leftMargin: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; text: controller.selectedImage ? controller.selectedImage.split('/').pop() : "Select an image to preview your desktop"; width: parent.width-28 }
    }
    RowLayout { Layout.fillWidth: true
        KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Preview"; enabled: !!controller.selectedImage && !controller.busy; accent: controller.accent; selected: true; onClicked: controller.act("preview",controller.selectedImage) }
        KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Apply to scene"; enabled: !!controller.state.preview && !controller.busy; onClicked: controller.act("preview-apply","") }
        KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "Revert"; enabled: !!controller.state.preview && !controller.busy; onClicked: controller.act("preview-revert","") }
        KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: "☆ Favorite"; enabled: !!controller.selectedImage && !controller.busy; onClicked: controller.act("favorite",controller.selectedImage) }
    }
    RowLayout {
        KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); text: controller.favoritesOnly ? "★ Favorites" : "All images"; selected: controller.favoritesOnly; accent: controller.accent; onClicked: controller.favoritesOnly=!controller.favoritesOnly }
        Repeater { model: ["All","Static","Animated"]
            KButton { motion: controller.motionMode==="off" ? 0 : (controller.data.motion["effect.fast"] || 140); required property string modelData; text: modelData; selected: controller.imageKind===modelData; accent: controller.accent; onClicked: controller.imageKind=modelData; implicitHeight: 32; implicitWidth: 80 }
        }
        KText { text: "Scene: "+(controller.state.scene || "midnight"); color: Appearance.textSecondary; font.pixelSize: 10 }
    }
    GridView {
        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
        cellWidth: width/3; cellHeight: 130
        model: controller.data.wallpapers.filter(w => (!controller.favoritesOnly || w.favorite) && (controller.imageKind==="All" || w.animated===(controller.imageKind==="Animated")) && (w.name+" "+w.tag).toLowerCase().includes(controller.query.toLowerCase()))
        ScrollBar.vertical: ScrollBar {}
        delegate: Item {
            required property var modelData
            width: GridView.view.cellWidth; height: 130
            Button {
                anchors.fill: parent; anchors.margins: 5; hoverEnabled: true; activeFocusOnTab: true
                Accessible.name: modelData.name
                background: Rectangle { radius: 8; color: Appearance.surfaceAlt; border.width: 2; border.color: parent.activeFocus || controller.selectedImage===modelData.path ? controller.accent : Appearance.outline }
                contentItem: Column {
                    spacing: 5
                    Image { width: parent.width; height: 82; source: modelData.url; asynchronous: true; sourceSize.width: 240; sourceSize.height: 135; fillMode: Image.PreserveAspectCrop }
                    KText { width: parent.width; text: (modelData.favorite ? "★ " : "")+modelData.name+(modelData.animated ? " · Motion" : ""); font.pixelSize: 10 }
                }
                onClicked: { controller.selectedImage=modelData.path;controller.selectedUrl=modelData.url; }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }
    }
}
