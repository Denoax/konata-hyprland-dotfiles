//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules/common"
import "modules/ii/notificationPopup"
import "services"
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    NotificationPopup {}

    Loader {
        active: GlobalStates.sidebarRightOpen
        source: active ? Quickshell.shellPath("KonaSidebarRight.qml") : ""
    }

    Component.onCompleted: MaterialThemeLoader.reapplyTheme()

    IpcHandler {
        target: "konaNotifications"

        function status(): string {
            return JSON.stringify({open: GlobalStates.sidebarRightOpen,
                count: Notifications.list.length, silent: Notifications.silent});
        }
        function toggle(): void { GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen; }
        function open(): void { GlobalStates.sidebarRightOpen = true; }
        function close(): void { GlobalStates.sidebarRightOpen = false; }
        function dnd(value: bool): void { Notifications.silent = value; }
        function toggleDnd(): void { Notifications.silent = !Notifications.silent; }
        function shutdown(): void { Qt.callLater(Qt.quit); }
    }
}
