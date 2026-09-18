import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

ShellRoot {
    id: root
    property string page: Quickshell.env("KONA_SURFACE") || "deck"
    property bool mosaicSession: !!state.mosaic
    property string section: page === "wallpapers" ? "Wallpaper" : page === "shortcuts" ? "Shortcuts" : "Appearance"
    property var data: ({state:{}, prefs:{}, tokens:{}, motion:{}, wallpapers:[], shortcuts:[], monitors:[], versions:{}})
    property var state: data.state
    property color accent: Appearance.accent
    property bool ready: false
    property bool opened: false
    property bool closing: false
    property real progress: 0
    property string message: "Connecting to your desktop…"
    property string query: ""
    property string selectedImage: ""
    property string selectedUrl: ""
    property bool favoritesOnly: false
    property string imageKind: "All"
    property var imported: null
    property string presetPath: Quickshell.env("HOME")+"/Documents/Kona-preset.json"
    property var appearance: ({rounding:8,opacity:.96,inactive:.9,blur:true})
    property bool appearancePending: false
    property string motionMode: data.prefs.motion==="off" || state.profile==="gaming" ? "off" : state.profile==="focus" ? "reduced" : (data.prefs.motion || "full")
    property int duration: motionMode === "off" ? 0 : motionMode === "reduced" ? 100 : (data.motion["spatial.default"] || 380) * (data.prefs.intensity || 1)
    property var player: Mpris.players.values.find(p => p.isPlaying) || Mpris.players.values.find(p => p.trackTitle) || null
    property bool isDeck: page === "deck" || page === "mosaic"
    property var sections: ["Appearance","Motion","Profiles","Wallpaper","Bars & Dock","Displays","Shortcuts","System & Recovery","About"]
    property string helper: Quickshell.env("KONA_SURFACE_HELPER")
    property bool busy: commandJob.running
    property date date: clock.date
    property string actionName: ""
    property string actionValue: ""
    property bool closeAfter: false
    onStateChanged: if (ready && state.mosaic && state.profile!=="showcase") close()
    function updateStatus() { statusDebounce.restart() }
    function refresh() { if (!snapshot.running) snapshot.running = true }
    function act(name, value, dismiss) {
        if (commandJob.running) return;
        actionName=name; actionValue=value || ""; closeAfter=!!dismiss;
        message="Working…"; commandJob.command=[helper,"action",name,actionValue]; commandJob.running=true;
    }
    function close() {
        if (!ready) { Qt.quit(); return; }
        if (commandJob.running) { message="Finishing the current change before closing."; closeAfter=true; return; }
        if (appearancePending) { act("appearance-revert","",true); return; }
        if (state.preview) { act("preview-revert","",true); return; }
        closing=true; opened=false; progress=0;
        if (duration===0) Qt.quit();
    }
    function navigate(target) {
        page=target; query="";
        if (target === "wallpapers") section="Wallpaper";
        if (target === "shortcuts") section="Shortcuts";
    }
    function show(target) {
        if (target === "close" || (target==="mosaic" && mosaicSession) || (target===page && opened)) { close(); return; }
        if (target==="mosaic" && !mosaicSession) act("mosaic-start","");
        closing=false; navigate(target); opened=true; progress=1;
    }
    Behavior on progress {
        NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic
            onRunningChanged: if (!running && root.closing && root.progress===0) Qt.quit()
        }
    }
    Component.onCompleted: { Quickshell.watchFiles=false; refresh(); }
    IpcHandler { target: "surface"; function activate(page: string): void { root.show(page) } function section(name: string): void { root.navigate("studio"); root.section=name } }
    Process {
        id: snapshot
        command: [root.helper,"snapshot"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                const reply=JSON.parse(text);
                if (!reply.ok) { root.message=reply.error; return; }
                root.data=reply.data; root.state=reply.data.state; if(!root.appearancePending) root.appearance=Object.assign({},root.data.prefs.appearance); if(root.message==="Connecting to your desktop…" || root.message==="Working…") root.message="";
                if (!root.ready) { root.selectedImage=root.data.currentImage; root.selectedUrl=root.data.currentImageUrl; root.ready=true; root.opened=true; root.progress=1; }
            } catch(e) { root.message="Could not read desktop state: "+e; }
        } }
    }
    Process {
        id: commandJob
        stdout: StdioCollector { onStreamFinished: {
            try {
                const reply=JSON.parse(text);
                root.message=reply.ok ? (typeof reply.data==="string" ? reply.data : "Applied") : reply.error;
                if (reply.ok && root.actionName==="appearance-preview") root.appearancePending=true;
                if (reply.ok && ["appearance-revert","appearance-commit","appearance-reset"].includes(root.actionName)) root.appearancePending=false;
                if (reply.ok && root.actionName==="import") { root.imported=reply.data; root.message="Preset loaded. Review the profile and scene before applying."; }
                if (reply.ok && root.actionName.startsWith("preview-")) root.state=Object.assign({},root.state,{preview:false});
                if (reply.ok && root.actionName==="preview") root.state=Object.assign({},root.state,{preview:true});
                if (reply.ok && root.closeAfter) Qt.callLater(root.close);
                else if(reply.ok) Qt.callLater(root.refresh);
            } catch(e) { root.message="Action response error: "+e; }
        } }
    }
    Process {
        id: update
        command: [root.helper,"status"]
        stdout: StdioCollector { onStreamFinished: { try { const r=JSON.parse(text); if(r.ok) root.state=r.data; } catch(e) { root.message="Status refresh failed"; } } }
    }
    Timer { id: statusDebounce; interval: 120; onTriggered: { if (!update.running && !commandJob.running) update.running=true; else restart(); } }
    Process { command: [root.helper,"events"]; running: root.opened
        stdout: SplitParser { onRead: data => { if (data.includes("preferences.json") || data.includes("current")) root.refresh(); else root.updateStatus(); } }
    }
    Process { command: ["nmcli","monitor"]; running: root.opened
        stdout: SplitParser { onRead: data => root.updateStatus() }
    }
    Process { id: metricJob; command: [root.helper,"metrics"]
        stdout: StdioCollector { onStreamFinished: { try { const r=JSON.parse(text); if(r.ok) root.state=Object.assign({},root.state,{metrics:r.data}); } catch(e) { root.message="Resource read failed"; } } }
    }
    // Only analog gauges have a visible-surface cadence. Discrete state is event driven.
    Timer { interval: 10000; repeat: true; running: root.opened; onTriggered: if(!metricJob.running) metricJob.running=true }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    PanelWindow {
        id: panel
        visible: true
        screen: Quickshell.screens.find(s => s.name === Quickshell.env("KONA_OUTPUT")) || Quickshell.screens.find(s => s.name === "DP-4") || Quickshell.screens[0]
        anchors { left: true; right: true; top: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "kona-v4"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        Item {
            anchors.fill: parent
            Accessible.role: Accessible.Pane
            Accessible.name: root.isDeck ? "Kona desktop" : "Kona settings"
            focus: true
            Keys.onEscapePressed: root.close()
            Shortcut { sequence: "Escape"; onActivated: root.close() }
            Rectangle { anchors.fill: parent; color: Appearance.scrim; opacity: root.progress }
            MouseArea { anchors.fill: parent; onClicked: root.close() }
            Rectangle {
                id: surface
                Behavior on height { NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
                width: Math.min(parent.width-64,1120)
                height: Math.min(parent.height-100,root.isDeck ? 720 : 790)
                x: (parent.width-width)/2
                y: (parent.height-height)/2+(1-root.progress)*(root.motionMode==="reduced" ? 4 : 28)
                opacity: root.progress
                radius: 14; color: Appearance.surface; border.width: 1; border.color: Appearance.outline
                // Prevent clicks in empty panel space from reaching the dismiss region.
                MouseArea { anchors.fill: parent; onClicked: surface.forceActiveFocus() }
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 24; spacing: 16
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        KText { text: "✦"; color: root.accent; font.pixelSize: 28 }
                        ColumnLayout { spacing: 2
                            KText { text: root.isDeck ? "Kona desktop" : "Kona settings"; font.pixelSize: 15; font.bold: true; font.letterSpacing: 1 }
                            KText { text: root.isDeck ? "Apps, music and current state" : "Appearance and desktop preferences"; color: Appearance.textSecondary; font.pixelSize: 11 }
                        }
                        Item { Layout.fillWidth: true }
                        KButton {
                            motion: root.motionMode==="off" ? 0 : (root.data.motion["effect.fast"] || 140)
                            text: root.isDeck ? "Settings" : "Desktop"
                            accent: root.accent
                            onClicked: {
                                if (root.isDeck) {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/kona-caelestia-settings"]);
                                    root.close();
                                } else root.navigate("deck");
                            }
                        }
                        KButton { motion: root.motionMode==="off" ? 0 : (root.data.motion["effect.fast"] || 140); text: "Esc  ×"; onClicked: root.close(); implicitWidth: 86 }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Appearance.outline }
                    Loader {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        active: root.ready
                        enabled: !commandJob.running
                        sourceComponent: root.isDeck ? deck : studio
                    }
                    RowLayout { Layout.fillWidth: true
                        KText { Layout.fillWidth: true; text: root.message || (root.state.preview ? "Preview · Apply to keep this wallpaper, or revert to return." : "Kona  ·  "+(root.state.profile || "daily")+" profile  ·  "+(root.state.scene || "midnight")); color: root.state.preview ? Appearance.warning : Appearance.textSecondary; font.pixelSize: 11 }
                        KText { text: commandJob.running ? "Working…" : "Ready"; color: commandJob.running ? Appearance.warning : root.accent; font.pixelSize: 10 }
                    }
                }
            }
        }
    }
    Variants {
        model: root.mosaicSession && root.state.profile==="showcase" ? Quickshell.screens.filter(s=>s.name!==panel.screen.name) : []
        PanelWindow {
            required property var modelData
            screen: modelData
            implicitWidth: 600; implicitHeight: 640
            color: "transparent"; exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "kona-mosaic"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            Rectangle {
                anchors.fill: parent; anchors.margins: 10; radius: 14
                color: Appearance.surface; border.color: Appearance.outline; opacity: root.progress
                ColumnLayout { anchors.fill: parent; anchors.margins: 32; spacing: 20
                    KText { text: modelData.name==="HDMI-A-1" ? "Kona" : "Now playing"; color: root.accent; font.letterSpacing: 2; font.pixelSize: 12 }
                    KText { text: modelData.name==="HDMI-A-1" ? Qt.formatDateTime(clock.date,"HH:mm") : Qt.formatDateTime(clock.date,"dddd"); font.pixelSize: modelData.name==="HDMI-A-1" ? 96 : 40; Layout.fillWidth: true }
                    KText { text: Qt.formatDateTime(clock.date,"dddd · MMMM d, yyyy"); color: Appearance.textSecondary; font.pixelSize: 12 }
                    Image {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : root.data.currentImageUrl
                        asynchronous: true; fillMode: Image.PreserveAspectCrop
                    }
                    KText { text: root.player ? root.player.trackTitle : "Nothing playing"; Layout.fillWidth: true; font.pixelSize: 18 }
                    KText { text: "Showcase · Super + Ctrl + M to close"; color: Appearance.textSecondary; font.pixelSize: 10 }
                }
            }
        }
    }
    Component { id: deck; Deck { controller: root } }
    Component { id: studio; Studio { controller: root } }
}
