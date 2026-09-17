import QtQuick
import "../components"

KAccordion {
    id: root
    property var entries: []
    property bool showAppearance: false
    property string appearanceMode: "light"
    signal request(string actionId, var payload)
    contentHeight: (entries.length + (showAppearance ? 1 : 0)) * 36 + (entries.length || showAppearance ? 5 : 0)
    Column {
        x: 7; width: root.width - 14; spacing: 2
        AppearanceMode {
            width: parent.width
            visible: root.showAppearance
            mode: root.appearanceMode
            onRequest: (id, args) => root.request(id, args)
        }
        Repeater {
            model: root.entries
            delegate: KButton {
                required property var modelData
                width: parent.width; height: 34
                text: modelData.label; iconName: modelData.icon || ""
                enabled: modelData.available !== false
                hint: modelData.hint || modelData.label
                actionId: modelData.actionId || ""
                payload: modelData.payload || ({})
                onRequest: (id, args) => root.request(id, args)
            }
        }
    }
}
