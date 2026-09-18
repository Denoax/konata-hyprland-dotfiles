pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.modules.session as Session
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

    WlrLayershell.namespace: "kona-caelestia-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Rectangle {
        anchors.fill: parent
        color: Colours.palette.m3scrim
        opacity: 0.38
        TapHandler { onTapped: root.closeSurface() }
    }

    ScreenState {
        id: screenState
        modelData: root.screen
        session: true
        onSessionChanged: if (!session) root.closeSurface()
    }

    Item {
        id: frame
        anchors.right: parent.right
        anchors.rightMargin: Tokens.spacing.large
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: sessionContent.implicitWidth + Tokens.padding.large * 2
        implicitHeight: sessionContent.implicitHeight + Tokens.padding.large * 2
        width: implicitWidth
        height: implicitHeight

        Rectangle {
            anchors.fill: parent
            color: Colours.palette.m3surface
            radius: Tokens.rounding.extraLarge
            border.width: Math.max(1, Config.border.thickness)
            border.color: Colours.palette.m3outlineVariant
        }

        Session.Content {
            id: sessionContent
            anchors.centerIn: parent
            screenState: screenState
        }
    }

    Shortcut { sequence: "Escape"; onActivated: root.closeSurface() }

    IpcHandler {
        target: "konaSession"
        function status(): string { return "ready"; }
        function close(): void { root.closeSurface(); }
        function toggle(): void { root.closeSurface(); }
    }
}
