import QtQuick
import QtQuick.Controls
import "components"
import "sections"

Item {
    id: root
    property bool expanded: true
    property string statusLabel: ""
    property bool revealed: false
    readonly property bool controlFocused: collapseControl.activeFocus
    property var player: null
    property var weather: ({status: "loading"})
    property var workspaces: []
    property var applications: []
    property var runningApplications: []
    property real revealProgress: revealed ? 1 : 0
    property real expansionProgress: expanded ? 1 : 0
    signal dismissed()
    signal expansionRequested(bool expanded)
    signal request(string actionId, var payload)

    onRevealProgressChanged: if (!revealed && revealProgress === 0) dismissed()
    Behavior on revealProgress { NumberAnimation { duration: root.revealed ? Tokens.enterMs : Tokens.exitMs; easing.type: Easing.OutCubic } }
    Behavior on expansionProgress { NumberAnimation { duration: root.expanded ? Tokens.enterMs : Tokens.exitMs; easing.type: Easing.OutCubic } }
    visible: root.revealed || revealProgress > 0.001
    enabled: root.revealed
    opacity: revealProgress
    transform: Translate { x: -(1 - root.revealProgress) * (root.width + 32) }
    implicitWidth: 60 + 240 * expansionProgress
    implicitHeight: 918
    clip: false

    KSurface { anchors.fill: parent; radius: 15; glow: true; frostedEdge: true }
    Rectangle {
        anchors.right: parent.right; width: 1; height: parent.height
        color: Tokens.glow
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: expandedContent
            width: 300; height: parent.height
            opacity: root.expansionProgress
            visible: opacity > 0.001
            enabled: root.expanded

            ProfileHeader {
                id: profile
                objectName: "profileHeader"
                x: 10; y: 38; width: 280
                statusLabel: root.statusLabel
                avatar: Qt.resolvedUrl("../assets/art/konata-avatar-hd.png")
            }

            Rectangle {
                x: 14; y: profile.y + profile.height + 2; width: 272; height: 1
                color: Tokens.line
            }

            Flickable {
                id: content
                x: 10; y: profile.y + profile.height + 12
                width: 280; height: Math.max(120, footer.y - y - 10)
                contentHeight: sections.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                Column {
                    id: sections; width: content.width; spacing: 5
                    ApplicationSection {
                        width: parent.width
                        applications: root.applications
                        runningApplications: root.runningApplications
                        onRequest: (id, args) => root.request(id, args)
                    }
                    WorkspaceSection { width: parent.width; workspaces: root.workspaces; onRequest: (id, args) => root.request(id, args) }
                    CompactMusic {
                        width: parent.width; player: root.player
                        onRequest: (id, args) => root.request(id, args)
                    }
                    WeatherCompact {
                        width: parent.width; weather: root.weather
                        onRequest: (id, args) => root.request(id, args)
                    }
                    ActionSection {
                        width: parent.width; title: "Quick controls"; iconName: "wrench"; expanded: true
                        showAppearance: true
                        appearanceMode: Tokens.appearanceMode
                        entries: [
                            {label: "Audio", icon: "volume", actionId: "audio.open"},
                            {label: "Network", icon: "wifi", actionId: "network.open"},
                            {label: "Bluetooth", icon: "bluetooth", actionId: "bluetooth.open"},
                            {label: "Night light", icon: "moon", actionId: "night.toggle"}
                        ]
                        onRequest: (id, args) => root.request(id, args)
                    }
                    ActionSection {
                        width: parent.width; title: "Desktop"; iconName: "monitor"; expanded: false
                        entries: [
                            {label: "Notifications", icon: "bell", actionId: "notifications.open"},
                            {label: "Clipboard", icon: "copy", actionId: "clipboard.open"},
                            {label: "Screenshot", icon: "camera", actionId: "screenshot.open"},
                            {label: "Wallpaper", icon: "image", actionId: "wallpaper.open"}
                        ]
                        onRequest: (id, args) => root.request(id, args)
                    }
                    ActionSection {
                        width: parent.width; title: "System"; iconName: "settings"; expanded: false
                        entries: [
                            {label: "Profiles", icon: "profile", actionId: "profiles.open"},
                            {label: "Settings", icon: "settings", actionId: "settings.open"},
                            {label: "Shortcuts", icon: "info", actionId: "shortcuts.open"},
                            {label: "Recording", icon: "record", actionId: "record.open"}
                        ]
                        onRequest: (id, args) => root.request(id, args)
                    }
                }
            }

            Row {
                id: footer
                x: 10; y: parent.height - 50; width: 280; height: 40; spacing: 7
                KButton {
                    width: 233; height: 40; text: "Power and session"; iconName: "power"
                    actionId: "session.open"; hint: "Power and session"
                    onRequest: (id, args) => root.request(id, args)
                }
                KButton {
                    width: 40; height: 40; iconName: "close"; plain: true
                    actionId: "sidebar.hide"; hint: "Hide sidebar"
                    onRequest: (id, args) => root.request(id, args)
                }
            }
        }

        Column {
            id: rail
            x: 10; y: 88; width: 40; spacing: 10
            visible: root.expansionProgress < 0.999
            opacity: 1 - root.expansionProgress
            enabled: !root.expanded
            KRoundedImage {
                objectName: "railAvatar"
                width: 40; height: 40; radius: 20
                source: Qt.resolvedUrl("../assets/art/konata-avatar-hd.png")
                fallbackSource: Qt.resolvedUrl("../assets/art/profile-avatar-source.png")
                Accessible.ignored: true
            }
            Repeater {
                model: [
                    {icon: "music", action: "music.open", label: "Music"},
                    {icon: "sun", action: "weather.open", label: "Weather"},
                    {icon: "apps", action: "applications.open", label: "Applications"},
                    {icon: "workspaces", action: "overview.open", label: "Workspaces"},
                    {icon: "wrench", action: "controls.open", label: "Quick controls"},
                    {icon: "bell", action: "notifications.open", label: "Notifications"},
                    {icon: "settings", action: "settings.open", label: "Settings"}
                ]
                delegate: KButton {
                    required property var modelData
                    width: 40; height: 40; iconName: modelData.icon; hint: modelData.label
                    plain: true; actionId: modelData.action
                    onRequest: (id, args) => root.request(id, args)
                }
            }
        }
        KButton {
            visible: !root.expanded; opacity: 1 - root.expansionProgress
            x: 10; y: parent.height - 50; width: 40; height: 40
            iconName: "power"; hint: "Power and session"; plain: true
            actionId: "session.open"
            onRequest: (id, args) => root.request(id, args)
        }

        KButton {
            id: collapseControl
            x: root.expanded ? parent.width - 46 : 14; y: 45
            width: 32; height: 32; round: true
            iconName: root.expanded ? "chevron-left" : "chevron-right"
            hint: root.expanded ? "Collapse sidebar" : "Expand sidebar"
            objectName: "collapseControl"
            contentItem: Item {
                KIcon {
                    objectName: "collapseChevron"
                    anchors.centerIn: parent; width: 16; height: 16
                    name: collapseControl.iconName
                }
            }
            onClicked: root.expansionRequested(!root.expanded)
        }
    }
}
