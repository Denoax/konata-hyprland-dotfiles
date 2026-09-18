pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.modules.nexus
import qs.services

PanelWindow {
    id: root

    readonly property var focusedScreen: {
        const name = Hyprland.focusedMonitor?.name ?? "";
        return Quickshell.screens.find(candidate => candidate.name === name) ?? Quickshell.screens[0];
    }

    function closeSettings(): void {
        visible = false;
        Qt.callLater(Qt.quit);
    }

    screen: focusedScreen
    visible: true
    color: "transparent"
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.namespace: "kona-caelestia-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Shortcut {
        sequence: "Escape"
        onActivated: root.closeSettings()
    }

    IpcHandler {
        target: "konaSettings"
        function status(): string { return "ready"; }
        function close(): void { root.closeSettings(); }
        function toggle(): void { root.closeSettings(); }
    }

    Rectangle {
        anchors.fill: parent
        color: Colours.palette.m3scrim
        opacity: Colours.light ? 0.30 : 0.56
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeSettings()
    }

    Item {
        id: frame
        anchors.centerIn: parent
        implicitWidth: nexus.implicitWidth
        implicitHeight: nexus.implicitHeight

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.72
            shadowOpacity: Colours.light ? 0.22 : 0.52
            shadowVerticalOffset: 10
            shadowColor: Colours.palette.m3shadow
        }

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainerLow
            border.width: 1
            border.color: Colours.palette.m3outlineVariant
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Nexus {
            id: nexus
            anchors.fill: parent
            // Nexus normally follows Caelestia's wallpaper palette. Kona's
            // system appearance owner is authoritative for this window.
            blobColour: Colours.palette.m3surfaceContainerLow
            nState.screen: root.screen
            nState.isWindow: true
            onClose: root.closeSettings()
        }
    }
}
