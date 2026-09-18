pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.modules.bar.components.workspaces as WorkspaceComponents
import qs.modules.dashboard as Dashboard
import qs.services
import qs.utils

PanelWindow {
    id: root

    readonly property int initialTab: {
        const value = Number(Quickshell.env("KONA_CAELESTIA_TAB"));
        return Number.isInteger(value) ? Math.max(0, Math.min(3, value)) : 0;
    }
    readonly property string weatherLocation: Quickshell.env("KONA_WEATHER_LOCATION")
    readonly property bool weatherUsesFahrenheit: Quickshell.env("KONA_WEATHER_UNITS") === "imperial"
    readonly property var focusedScreen: {
        const name = Hyprland.focusedMonitor?.name ?? "";
        return Quickshell.screens.find(candidate => candidate.name === name) ?? Quickshell.screens[0];
    }

    function closeDashboard(): void {
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

    WlrLayershell.namespace: "kona-caelestia-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Component.onCompleted: {
        // Kona's weather.json remains the single location/unit source. Setting the
        // upstream service here also prevents its IP-based location fallback.
        GlobalConfig.services.weatherLocation = weatherLocation;
        GlobalConfig.services.useFahrenheit = weatherUsesFahrenheit;
    }

    ScreenState {
        id: screenState

        modelData: root.screen
        dashboard: true
        dashboardTab: root.initialTab
    }

    FileDialog {
        id: facePicker

        title: "Select a profile picture"
        filterLabel: "Image files"
        filters: Images.validImageExtensions
        onAccepted: path => CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`))
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.closeDashboard()
    }

    IpcHandler {
        target: "konaDashboard"

        function status(): string { return "ready"; }

        function close(): void {
            root.closeDashboard();
        }

        function toggle(): void {
            root.closeDashboard();
        }

        function tab(index: int): void {
            screenState.dashboardTab = Math.max(0, Math.min(3, index));
        }
    }

    Item {
        id: dashboardFrame

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Tokens.spacing.large

        implicitWidth: dashboardContent.implicitWidth + Tokens.padding.large * 2
        implicitHeight: dashboardContent.implicitHeight + Tokens.padding.large * 2

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.7
            shadowOpacity: Colours.light ? 0.22 : 0.48
            shadowVerticalOffset: 8
            shadowColor: Colours.palette.m3shadow
        }

        StyledRect {
            anchors.fill: parent
            color: Colours.tPalette.m3surface
            radius: Tokens.rounding.extraLarge
            border.width: Math.max(1, Config.border.thickness)
            border.color: Colours.tPalette.m3outlineVariant
        }

        Dashboard.Content {
            id: dashboardContent

            anchors.centerIn: parent
            screenState: screenState
            facePicker: facePicker
        }
    }

    Item {
        id: workspaceFrame

        anchors.left: parent.left
        anchors.leftMargin: Tokens.spacing.large
        anchors.verticalCenter: parent.verticalCenter

        implicitWidth: workspaces.implicitWidth + Tokens.padding.small * 2
        implicitHeight: workspaces.implicitHeight + Tokens.padding.small * 2

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.55
            shadowOpacity: Colours.light ? 0.18 : 0.42
            shadowHorizontalOffset: 4
            shadowColor: Colours.palette.m3shadow
        }

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.full
            color: Colours.tPalette.m3surface
            border.width: 1
            border.color: Colours.tPalette.m3outlineVariant
        }

        WorkspaceComponents.Workspaces {
            id: workspaces

            anchors.centerIn: parent
            screen: root.screen
            fullscreen: false
        }
    }
}
