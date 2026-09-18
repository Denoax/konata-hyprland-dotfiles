import QtQuick
import QtQuick.Window
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "qml"
import "qml/components"

ShellRoot {
    id: root
    property bool closing: false
    property bool focusAllowed: true
    property string initialAction: ""
    property string lastActiveAddress: ""
    property int toplevelRevision: 0
    property var weatherData: ({status: "loading"})
    readonly property var historyActiveToplevel: Hyprland.toplevels.values.find(value =>
        value.lastIpcObject && Number(value.lastIpcObject.focusHistoryID) === 0) || null
    readonly property string activeAddress: Hyprland.activeToplevel ? Hyprland.activeToplevel.address
        : lastActiveAddress || (historyActiveToplevel ? historyActiveToplevel.address : "")
    readonly property var orderedScreens: [...Quickshell.screens].sort((a, b) => a.x - b.x)
    readonly property var centerScreen: orderedScreens.length ? orderedScreens[Math.floor(orderedScreens.length / 2)] : null
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(value => value.isPlaying) || players.find(value => value.trackTitle) || null
    readonly property var workspaceIds: [2, 5, 8, 10]
    readonly property var workspaceModel: workspaceIds.map(id => {
        const workspace = Hyprland.workspaces.values.find(value => value.id === id);
        return {id: id, focused: workspace ? workspace.focused : false,
            occupied: workspace ? workspace.toplevels.values.length > 0 : false};
    })
    readonly property var preferredAppNames: ["brave", "kitty", "dolphin", "steam", "code"]
    function normalizedAppName(value) {
        return String(value || "").toLowerCase().replace(/\.desktop$/, "").replace(/[^a-z0-9]/g, "");
    }
    function classFor(toplevel) {
        const state = toplevel && toplevel.lastIpcObject ? toplevel.lastIpcObject : {};
        return String(state.class || state.initialClass || "");
    }
    function appIcon(name) {
        const resolved = String(Quickshell.iconPath(String(name || ""), true));
        return resolved && !resolved.includes("image-missing") ? resolved : "";
    }
    function entryMatches(entry, toplevel) {
        const windowClass = normalizedAppName(classFor(toplevel));
        if (!windowClass) return false;
        const candidates = [entry.id, entry.startupClass, entry.name].map(normalizedAppName).filter(value => value.length > 0);
        return candidates.some(value => value === windowClass || value.includes(windowClass) || windowClass.includes(value));
    }
    readonly property var applicationModel: {
        const revision = root.toplevelRevision;
        const available = DesktopEntries.applications.values.filter(app => !app.noDisplay);
        const toplevels = Hyprland.toplevels.values;
        const selected = [];
        for (const wanted of preferredAppNames) {
            const match = available.find(app => {
                const id = String(app.id || "").toLowerCase().replace(/\.desktop$/, "");
                const name = String(app.name || "").toLowerCase();
                if (wanted === "dolphin") return id === "org.kde.dolphin" || name === "dolphin";
                return id.includes(wanted) || name === wanted;
            });
            if (match && !selected.includes(match)) selected.push(match);
        }
        for (const app of available) {
            if (selected.length >= 5) break;
            if (!selected.includes(app)) selected.push(app);
        }
        return selected.slice(0, 5).map(app => {
            const windows = toplevels.filter(toplevel => root.entryMatches(app, toplevel));
            const target = windows.find(toplevel => toplevel.address === root.activeAddress) || windows[0] || null;
            return {desktopId: app.id, name: app.name, icon: root.appIcon(app.icon),
                running: windows.length > 0, active: windows.some(toplevel => toplevel.address === root.activeAddress),
                address: target ? target.address : "", windowCount: windows.length};
        });
    }
    readonly property var runningApplicationModel: {
        const revision = root.toplevelRevision;
        const available = DesktopEntries.applications.values;
        const grouped = {};
        const ordered = [];
        for (const toplevel of Hyprland.toplevels.values) {
            const windowClass = root.classFor(toplevel);
            const key = root.normalizedAppName(windowClass);
            if (!key || ["quickshell", "rofi", "waybar"].includes(key)) continue;
            let item = grouped[key];
            if (!item) {
                const entry = DesktopEntries.heuristicLookup(windowClass) || available.find(app => root.entryMatches(app, toplevel));
                item = {name: entry ? entry.name : windowClass, icon: root.appIcon(entry ? entry.icon : windowClass),
                    address: toplevel.address, active: toplevel.address === root.activeAddress, windowCount: 1};
                grouped[key] = item;
                ordered.push(item);
            } else {
                item.windowCount += 1;
                if (toplevel.address === root.activeAddress) { item.active = true; item.address = toplevel.address; }
            }
        }
        return ordered.slice(0, 4);
    }
    Settings {
        id: saved
        location: "file://" + Quickshell.env("KONA_SIDEBAR_STATE")
        category: "Sidebar"
        property bool expanded: true
        property bool muted: false
        property real gain: 0.35
    }
    SidebarPolicy { id: policy }
    Process {
        id: weatherSummary
        command: [Quickshell.env("HOME") + "/.local/bin/kona-weather", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.weatherData = JSON.parse(text); }
                catch (error) { root.weatherData = ({status:"error", message:"Weather response was invalid"}); }
            }
        }
    }
    Timer {
        id: toplevelRefresh
        interval: 80
        repeat: false
        onTriggered: {
            Hyprland.refreshToplevels();
            root.toplevelRevision += 1;
        }
    }
    SidebarVisibility {
        id: visibility
        enabled: policy.ready && !root.closing
        pointerInside: pointer.hovered
        keyboardActive: sidebar.controlFocused && sidebar.Window.active
    }
    Binding { target: Tokens; property: "reducedMotion"; value: policy.reducedMotion }
    Binding { target: Feedback; property: "muted"; value: saved.muted || policy.quiet }
    Binding { target: Feedback; property: "gain"; value: Math.max(0, Math.min(0.5, saved.gain)) }
    Connections {
        target: policy
        function onReadyChanged() {
            if (policy.ready && !root.closing) {
                Qt.callLater(() => root.initialAction === "toggle" ? visibility.toggleLatched() : visibility.show());
            }
        }
    }
    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            if (Hyprland.activeToplevel) root.lastActiveAddress = Hyprland.activeToplevel.address;
        }
        function onRawEvent(event) {
            if (event.name === "activewindowv2") {
                const fields = event.parse(1);
                if (fields.length && fields[0]) root.lastActiveAddress = fields[0];
            }
            if (["openwindow", "closewindow", "movewindow", "movewindowv2"].includes(event.name)) {
                toplevelRefresh.restart();
            }
        }
    }
    function releaseFocus() {
        root.focusAllowed = false;
        Qt.callLater(() => { root.focusAllowed = true; });
    }
    function expand(value) {
        saved.expanded = value;
        visibility.show();
        releaseFocus();
    }
    function run(command) {
        visibility.hide();
        releaseFocus();
        Quickshell.execDetached(command);
    }
    function finishApplicationNavigation() {
        if (!visibility.latched) visibility.hide();
        releaseFocus();
    }
    function handleAction(actionId, payload) {
        const home = Quickshell.env("HOME");
        const bin = home + "/.local/bin/";
        const actions = {
            "music.open": [bin + "kona-caelestia-dashboard", "media"],
            "weather.open": [bin + "kona-caelestia-dashboard", "weather"],
            "applications.open": [bin + "kona-end4-overview"],
            "windows.open": ["rofi", "-show", "window", "-theme", home + "/.config/rofi/window.rasi"],
            "overview.open": [bin + "kona-end4-overview"],
            "assistant.open": [bin + "kona-end4-surface", "assistant"],
            "files.open": [bin + "kona-file-manager"],
            "cheatsheet.open": [bin + "kona-end4-surface", "cheatsheet"],
            "controls.open": [bin + "kona-quick-settings"],
            "audio.open": [bin + "kona-caelestia-audio"],
            "network.open": ["nm-connection-editor"],
            "bluetooth.open": ["blueman-manager"],
            "night.toggle": [bin + "kona-night-light", "toggle"],
            "notifications.open": [bin + "kona-end4-notifications", "toggle"],
            "clipboard.open": [bin + "kona-clipboard"],
            "screenshot.open": [bin + "kona-screenshot", "region-edit"],
            "wallpaper.open": [bin + "kona-wallpaper-menu"],
            "profiles.open": [bin + "kona-profile-menu"],
            "settings.open": [bin + "kona-caelestia-settings"],
            "shortcuts.open": [bin + "kona-end4-surface", "cheatsheet"],
            "record.open": [bin + "kona-quick-settings"],
            "session.open": [bin + "kona-caelestia-session"]
        };
        if (actionId === "workspace.select" && payload && Number.isInteger(payload.id)) {
            const workspace = Hyprland.workspaces.values.find(value => value.id === payload.id);
            if (workspace) workspace.activate();
            visibility.hide(); releaseFocus(); return;
        }
        if (actionId === "application.launch" && payload && payload.desktopId) {
            const entry = DesktopEntries.byId(payload.desktopId);
            if (entry) { entry.execute(); finishApplicationNavigation(); }
            return;
        }
        if (actionId === "application.activate" && payload && payload.address) {
            const address = String(payload.address).replace(/^0x/, "");
            if (/^[0-9a-f]+$/i.test(address)) {
                Hyprland.dispatch(Hyprland.usingLua
                    ? 'hl.dsp.focus({window = hl.get_window("address:0x' + address + '")})'
                    : "focuswindow address:0x" + address);
            }
            finishApplicationNavigation(); return;
        }
        if (actionId === "sidebar.hide") { visibility.hide(); releaseFocus(); return; }
        if (["appearance.light", "appearance.kona", "appearance.dark", "appearance.toggle"].includes(actionId)) {
            Quickshell.execDetached([bin + "kona-appearance", actionId.split(".")[1]]);
            releaseFocus();
            return;
        }
        if (actions[actionId]) run(actions[actionId]);
        else console.warn("Unknown sidebar action:", actionId);
    }
    function close() {
        closing = true;
        focusAllowed = false;
        visibility.hide();
        Feedback.stop();
        if (sidebar.revealProgress === 0) Qt.quit();
    }
    Component.onCompleted: {
        Quickshell.watchFiles = false;
        const initial = Quickshell.env("KONA_SIDEBAR_INITIAL");
        root.initialAction = initial;
        if (Hyprland.activeToplevel) root.lastActiveAddress = Hyprland.activeToplevel.address;
        if (initial === "expand" || initial === "collapse") saved.expanded = initial === "expand";
    }
    IpcHandler {
        target: "sidebar"
        function toggle(): void {
            root.closing = false;
            root.focusAllowed = true;
            visibility.toggleLatched();
        }
        function show(): void { root.closing = false; root.focusAllowed = true; visibility.show(); }
        function close(): void { root.close(); }
        function expand(): void { root.expand(true); }
        function collapse(): void { root.expand(false); }
        function launch(desktopId: string): void { root.handleAction("application.launch", {desktopId: desktopId}); }
        function activate(address: string): void { root.handleAction("application.activate", {address: address}); }
        function mute(): void { saved.muted = true; Feedback.stop(); }
        function unmute(): void { saved.muted = false; }
        function gain(value: string): void {
            const n = Number(value);
            if (!Number.isFinite(n) || n < 0 || n > 0.5) { console.warn("Sidebar gain must be 0–0.5"); return; }
            saved.gain = n;
        }
        function status(): string {
            return JSON.stringify({expanded: saved.expanded, width: sidebar.width,
                profile: policy.profileName,
                statusLabel: sidebar.statusLabel,
                revealed: sidebar.revealed, revealProgress: sidebar.revealProgress,
                pointerInside: visibility.pointerInside, keyboardActive: visibility.keyboardActive,
                latched: visibility.latched,
                autoHide: true,
                reducedMotion: Tokens.reducedMotion, muted: Feedback.muted, userMuted: saved.muted,
                quiet: policy.quiet, soundStatus: Feedback.effect.status,
                soundPlaying: Feedback.effect.playing, soundGain: Feedback.gain,
                pinnedApps: root.applicationModel.map(app => ({desktopId: app.desktopId, name: app.name,
                    running: app.running, active: app.active, address: app.address})),
                runningApps: root.runningApplicationModel,
                activeAddress: root.activeAddress, lastActiveAddress: root.lastActiveAddress,
                screen: root.centerScreen ? root.centerScreen.name : null,
                focusAllowed: root.focusAllowed, controlFocused: sidebar.controlFocused, soundActivations: Feedback.activations});
        }
    }
    PanelWindow {
        id: panel
        screen: root.centerScreen
        visible: root.centerScreen !== null
        anchors { left: true; top: true; bottom: true }
        // Review foundation: no owner cutover or work-area reservation.
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 360
        color: "transparent"
        WlrLayershell.namespace: "kona-sidebar-foundation"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: root.focusAllowed && sidebar.revealed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        // The same layer owns the panel and its 2px edge hotspot. No extra daemon.
        mask: Region {
            x: Math.max(0, sidebar.x - (1 - sidebar.revealProgress) * (sidebar.width + 32))
            y: sidebar.y
            width: root.closing ? 0 : Math.max(2, sidebar.width - (1 - sidebar.revealProgress) * (sidebar.width + 32))
            height: sidebar.height
            radius: sidebar.revealProgress > 0 ? 14 : 0
            topLeftRadius: 0
            bottomLeftRadius: 0
        }
        Item {
            // Observe hover over the view and its controls without accepting clicks.
            z: 1
            width: sidebar.revealed ? sidebar.width : 2
            height: panel.height
            HoverHandler { id: pointer }
        }
        SidebarView {
            id: sidebar
            focus: true
            x: 0; y: 0
            width: implicitWidth
            height: panel.height
            expanded: saved.expanded
            revealed: visibility.revealed
            statusLabel: policy.profileName ? policy.profileName[0].toUpperCase() + policy.profileName.slice(1) : ""
            player: root.player
            weather: root.weatherData
            workspaces: root.workspaceModel
            applications: root.applicationModel
            runningApplications: root.runningApplicationModel
            onExpansionRequested: value => root.expand(value)
            onRequest: (actionId, payload) => root.handleAction(actionId, payload)
            onDismissed: if (root.closing) Qt.quit()
            Keys.onEscapePressed: { visibility.hide(); root.releaseFocus(); }
        }
    }
}
