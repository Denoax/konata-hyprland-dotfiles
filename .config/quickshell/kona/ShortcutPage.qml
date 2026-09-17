import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    required property var controller

    KText { text: "From your installed bindings. Filter by action, key or category."; color: Appearance.textSecondary; font.pixelSize: 11; Layout.fillWidth: true }
    ListView { Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6; ScrollBar.vertical: ScrollBar {}
        model: controller.data.shortcuts.filter(s => (s.keys+" "+s.label+" "+s.category).toLowerCase().includes(controller.query.toLowerCase()))
        delegate: KCard { required property var modelData; width: ListView.view.width; height: 64
            RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 12
                KText { text: modelData.keys; color: controller.accent; Layout.preferredWidth: 200; font.pixelSize: 11; wrapMode: Text.WordWrap }
                ColumnLayout { Layout.fillWidth: true; spacing: 3
                    KText { text: modelData.label; Layout.fillWidth: true; font.pixelSize: 11 }
                    KText { text: modelData.category; color: Appearance.textSecondary; font.pixelSize: 9 }
                }
            }
        }
    }
}
