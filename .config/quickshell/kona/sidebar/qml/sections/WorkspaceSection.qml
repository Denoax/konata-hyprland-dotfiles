import QtQuick
import QtQuick.Layouts
import "../components"

KAccordion {
    id: root
    title: "Workspaces"
    iconName: "workspaces"
    expanded: true
    property var workspaces: []
    signal request(string actionId, var payload)
    contentHeight: 49

    RowLayout {
        x: 8; width: root.width - 16; height: 42; spacing: 5
        Repeater {
            model: root.workspaces
            delegate: KButton {
                required property var modelData
                text: String(modelData.id)
                selected: modelData.focused === true
                hint: "Workspace " + modelData.id + (modelData.occupied ? " — occupied" : "")
                Layout.fillWidth: true; Layout.minimumWidth: 34; height: 34
                opacity: modelData.occupied ? 1 : 0.62
                actionId: "workspace.select"; payload: ({id: modelData.id})
                onRequest: (id, args) => root.request(id, args)
            }
        }
        KButton {
            iconName: "expand"; hint: "Workspace overview"; plain: true
            width: 34; height: 34; actionId: "overview.open"
            onRequest: (id, args) => root.request(id, args)
        }
    }
}
