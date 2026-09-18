//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules/common"
import "modules/ii/cheatsheet"
import "modules/ii/overview"
import "modules/ii/sidebarLeft"
import "services"
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property bool started
    readonly property string surface: Quickshell.env("KONA_END4_SURFACE") || "overview"

    FontLoader {
        source: "file:///etc/xdg/quickshell/caelestia/assets/google-sans-flex/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf"
    }

    LazyLoader {
        active: root.surface === "overview"
        component: Overview {}
    }

    LazyLoader {
        active: root.surface === "assistant"
        component: SidebarLeft {}
    }

    LazyLoader {
        active: root.surface === "cheatsheet"
        component: Cheatsheet {}
    }

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme();
        if (surface === "overview")
            GlobalStates.overviewOpen = true;
        else if (surface === "assistant")
            GlobalStates.sidebarLeftOpen = true;
        started = true;
    }

    IpcHandler {
        target: "konaEnd4"

        function status(): string { return root.surface; }

        function close(): void {
            if (root.surface === "overview")
                GlobalStates.overviewOpen = false;
            else if (root.surface === "assistant")
                GlobalStates.sidebarLeftOpen = false;
            else
                Qt.callLater(Qt.quit);
        }
    }

    Connections {
        target: GlobalStates

        function onOverviewOpenChanged(): void {
            if (root.started && root.surface === "overview" && !GlobalStates.overviewOpen)
                Qt.callLater(Qt.quit);
        }

        function onSidebarLeftOpenChanged(): void {
            if (root.started && root.surface === "assistant" && !GlobalStates.sidebarLeftOpen)
                Qt.callLater(Qt.quit);
        }
    }
}
