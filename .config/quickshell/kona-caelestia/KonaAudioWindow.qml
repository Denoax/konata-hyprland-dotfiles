pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.modules.bar.popouts as BarPopouts
import qs.services

PanelWindow {
    id: root

    readonly property var focusedScreen: {
        const name = Hyprland.focusedMonitor?.name ?? "";
        return Quickshell.screens.find(candidate => candidate.name === name) ?? Quickshell.screens[0];
    }

    function closeSurface(): void {
        visible = false;
        Qt.callLater(Qt.quit);
    }

    screen: focusedScreen
    visible: true
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.namespace: "kona-caelestia-audio"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Rectangle {
        anchors.fill: parent
        color: Colours.palette.m3scrim
        opacity: 0.24
        TapHandler { onTapped: root.closeSurface() }
    }

    Item {
        id: frame
        anchors.right: parent.right
        anchors.rightMargin: Tokens.spacing.large
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: audio.implicitWidth + Tokens.padding.large * 2
        implicitHeight: audio.implicitHeight + Tokens.padding.large * 2
        width: implicitWidth
        height: implicitHeight

        Rectangle {
            anchors.fill: parent
            // Caelestia normally receives opacity from its whole-shell blob layer.
            // This isolated surface needs its own readable backing plane.
            color: Colours.palette.m3surface
            radius: Tokens.rounding.extraLarge
            border.width: Math.max(1, Config.border.thickness)
            border.color: Colours.tPalette.m3outlineVariant
        }

        BarPopouts.PopoutState { id: popoutState }

        BarPopouts.AudioPopout {
            id: audio
            anchors.centerIn: parent
            popouts: popoutState
        }

        Connections {
            target: popoutState
            function onDetachRequested(mode): void {
                if (mode === "audio")
                    Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/kona-app-mixer"]);
                root.closeSurface();
            }
        }
    }

    Shortcut { sequence: "Escape"; onActivated: root.closeSurface() }

    IpcHandler {
        target: "konaAudio"
        function status(): string { return "ready"; }
        function close(): void { root.closeSurface(); }
        function toggle(): void { root.closeSurface(); }
    }
}
