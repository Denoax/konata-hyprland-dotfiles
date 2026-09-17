import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "qml"
import "qml/components"
ShellRoot {
    FloatingWindow {
        id: window
        title: "Kona foundation — isolated native controls"
        color: Appearance.background
        implicitWidth: 1080
        implicitHeight: 760
        SidebarView {
            x: 30; y: 30; width: implicitWidth; height: 700
            revealed: true
            onExpansionRequested: value => expanded = value
        }
        Column {
            x: 370; y: 28; spacing: 22
            Text { text: "C01–C07 · native component validation"; color: Tokens.text; font.pixelSize: 18 }
            Grid {
                columns: 14; spacing: 14
                Repeater {
                    model: ["expand", "profile", "moon", "link", "copy", "terminal", "settings", "plus", "memory", "monitor", "check", "bluetooth", "calendar", "external", "trash", "volume", "cpu", "play", "image", "camera", "globe", "rain", "heart", "video", "wifi", "folder", "chevron-down", "cloud", "bell-off", "next", "pause", "previous", "close", "storage", "power", "document", "chevron-up", "bell", "grid", "wrench", "music", "warning", "info", "arrow-left", "logout", "download", "sun", "more", "headphones", "microphone", "apps", "edit", "record", "repeat", "minus", "workspaces", "list", "audio-devices", "chevron-right", "search", "gamepad", "battery", "check-square", "muted", "clock", "lock", "home", "refresh", "stop", "chevron-left", "arrow-right", "restore", "shuffle"]
                    KIcon { required property string modelData; name: modelData }
                }
            }
            Row {
                spacing: 10
                KButton { text: "Normal" }
                KButton { text: "Selected"; selected: true }
                KButton { text: "Disabled"; enabled: false }
                KButton { text: "Focus"; focus: true }
            }
            Row {
                spacing: 18
                KButton { iconName: "play"; round: true }
                KButton { iconName: "pause"; round: true; selected: true }
                KButton { iconName: "monitor"; plain: true }
                KButton { text: "Toggle"; checkable: true; selected: checked }
                KThinSlider { backendValue: 0.45 }
            }
            KSectionRow { text: "Shared row fixture"; iconName: "info"; count: 2 }
            KAccordion {
                title: "Accordion fixture"; iconName: "info"; expanded: true
                KButton { text: "Contained control"; width: 180 }
            }
            Row {
                spacing: 12
                Repeater {
                    model: ["default", "hover", "pressed", "selected", "disabled", "focus"]
                    Image { required property string modelData; width: 76; height: 34; source: "assets/skins/svg/action-button--" + modelData + ".svg" }
                }
            }
        }
        Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
    }
}
