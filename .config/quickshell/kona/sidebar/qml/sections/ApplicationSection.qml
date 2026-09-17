import QtQuick
import QtQuick.Layouts
import "../components"

KAccordion {
    id: root
    title: "Applications"
    iconName: "grid"
    expanded: true
    signal request(string actionId, var payload)
    property var applications: []
    property var runningApplications: []
    contentHeight: body.implicitHeight + 10

    Column {
        id: body
        x: 6; width: root.width - 12; spacing: 6
        Text { text: "PINNED"; color: Tokens.subtle; font.family: Tokens.uiFont; font.pixelSize: 9; font.letterSpacing: 1.4 }
        GridLayout {
            width: parent.width; columns: 3; rowSpacing: 6; columnSpacing: 6
            Repeater {
                model: root.applications
                delegate: KButton {
                    required property var modelData
                    objectName: "pinnedApplication"
                    Layout.fillWidth: true; Layout.preferredWidth: 82; Layout.preferredHeight: 55
                    selected: modelData.active === true
                    hint: modelData.name + (modelData.running ? " — running; right-click for a new window" : "")
                    contentItem: Column {
                        spacing: 3
                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter; width: 26; height: 24
                            Image { anchors.centerIn: parent; width: 24; height: 24; source: modelData.icon; fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true }
                            Rectangle {
                                visible: modelData.running === true
                                anchors.right: parent.right; anchors.bottom: parent.bottom
                                width: 7; height: 7; radius: 3.5
                                color: modelData.active ? Tokens.accentStrong : Tokens.accent
                                border.width: 1; border.color: Tokens.ice
                            }
                        }
                        Text {
                            width: parent.width; text: modelData.name
                            font.family: Tokens.uiFont; font.pixelSize: 10; color: Tokens.text
                            horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                        }
                    }
                    actionId: modelData.running ? "application.activate" : "application.launch"
                    payload: ({desktopId: modelData.desktopId, address: modelData.address})
                    onRequest: (id, args) => root.request(id, args)
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: root.request("application.launch", {desktopId: modelData.desktopId})
                    }
                }
            }
        }
        Rectangle { width: parent.width; height: 1; color: Tokens.line; visible: root.runningApplications.length > 0 }
        Text { text: "RUNNING"; color: Tokens.subtle; font.family: Tokens.uiFont; font.pixelSize: 9; font.letterSpacing: 1.4; visible: root.runningApplications.length > 0 }
        Column {
            width: parent.width; spacing: 3; visible: root.runningApplications.length > 0
            Repeater {
                model: root.runningApplications
                delegate: KButton {
                    required property var modelData
                    objectName: "runningApplication"
                    width: parent.width; height: 34; selected: modelData.active === true
                    hint: "Focus " + modelData.name
                    actionId: "application.activate"; payload: ({address: modelData.address})
                    contentItem: RowLayout {
                        spacing: 9
                        Image { source: modelData.icon; Layout.preferredWidth: 20; Layout.preferredHeight: 20; fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true }
                        Text { text: modelData.name; color: Tokens.text; font.family: Tokens.uiFont; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { visible: modelData.windowCount > 1; text: String(modelData.windowCount); color: Tokens.muted; font.family: Tokens.dataFont; font.pixelSize: 10 }
                        Rectangle { Layout.preferredWidth: 7; Layout.preferredHeight: 7; radius: 3.5; color: modelData.active ? Tokens.accentStrong : Tokens.accent }
                    }
                    onRequest: (id, args) => root.request(id, args)
                }
            }
        }
        RowLayout {
            width: parent.width; spacing: 6
            KButton { Layout.fillWidth: true; height: 34; text: "All apps"; iconName: "apps"; actionId: "applications.open"; hint: "All applications"; onRequest: (id, args) => root.request(id, args) }
            KButton { Layout.fillWidth: true; height: 34; text: "Windows"; iconName: "monitor"; actionId: "windows.open"; hint: "Open windows"; onRequest: (id, args) => root.request(id, args) }
        }
    }
}
