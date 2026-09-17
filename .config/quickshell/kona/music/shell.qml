import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

ShellRoot {
    id: root
    // Same native MPRIS selection policy as Deck; the player remains authoritative.
    readonly property var players: Mpris.players.values.filter(p => !Quickshell.env("KONA_MUSIC_PLAYER") || p.dbusName === Quickshell.env("KONA_MUSIC_PLAYER"))
    readonly property var player: players.find(p => p.isPlaying) || players.find(p => p.trackTitle) || null
    readonly property var sink: Pipewire.defaultAudioSink
    property bool opened: false
    property real progress: 0
    property string motionMode: "full"
    property var spectrum: []
    property bool deviceAfterClose: false
    readonly property int enterMs: motionMode === "off" ? 0 : motionMode === "reduced" ? 120 : 220
    readonly property int exitMs: motionMode === "off" ? 0 : 150

    function focusControl(item) {
        if (item.activeFocus && item.objectName) return item.objectName;
        for (const child of item.children) {
            const name = focusControl(child);
            if (name) return name;
        }
        return "";
    }

    function close() {
        opened = false;
        progress = 0;
        if (exitMs === 0) finish();
    }
    function finish() {
        if (deviceAfterClose) Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/kona-audio-menu"]);
        Qt.quit();
    }
    function toggle() {
        if (opened) close();
        else { opened = true; progress = 1; }
    }
    Component.onCompleted: { Quickshell.watchFiles = false; opened = true; progress = 1; }
    IpcHandler {
        target: "music"
        function toggle(): void { root.toggle(); }
        function close(): void { root.close(); }
        function status(): string {
            return JSON.stringify({playing: popup.playing, hasMedia: popup.hasMedia,
                title: popup.trackTitle, position: popup.positionSeconds, duration: popup.durationSeconds,
                volume: popup.volume, canSeek: popup.canSeek, canPlay: popup.canPlayPause,
                canShuffle: popup.canShuffle, canRepeat: popup.canRepeat, spectrum: root.spectrum,
                focusControl: root.focusControl(popup), artworkReady: popup.artworkReady,
                artwork: popup.displayedArtwork.toString(),
                ringRotating: popup.playbackRingRotating, ringRotation: popup.playbackRingRotation, motionMode: root.motionMode});
        }
    }
    Behavior on progress {
        NumberAnimation {
            duration: root.opened ? root.enterMs : root.exitMs
            easing.type: Easing.OutCubic
            onRunningChanged: if (!running && !root.opened && root.progress === 0) root.finish()
        }
    }
    Process {
        command: [Quickshell.env("HOME") + "/.local/bin/kona-preferences"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { root.motionMode = JSON.parse(text).motion; } catch(e) { console.warn("Music preferences:", e); } } }
    }
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    // Native MPRIS computes current position; one visible-only signal refresh is
    // sufficient for timestamps. This performs no periodic DBus metadata query.
    Timer {
        interval: 1000; repeat: true
        running: root.opened && !!root.player && root.player.isPlaying && root.player.positionSupported
        onTriggered: root.player.positionChanged()
    }
    Process {
        id: visualizer
        command: ["cava", "-p", Qt.resolvedUrl("cava.conf").toString().replace("file://", "")]
        running: root.opened && !!root.player && root.player.isPlaying
        onRunningChanged: if (!running) root.spectrum = []
        stdout: SplitParser {
            onRead: line => {
                const bars = line.split(";").filter(v => v.length).map(v => Number(v) / 1000);
                if (bars.length === 21 && bars.every(v => Number.isFinite(v)))
                    root.spectrum = bars.map(v => Math.max(0, Math.min(1, v)));
            }
        }
        stderr: SplitParser { onRead: line => console.warn("Music spectrum:", line) }
    }
    PanelWindow {
        id: panel
        screen: Quickshell.screens.find(s => s.name === "DP-4") || Quickshell.screens[0]
        anchors { left: true; right: true; top: true; bottom: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "kona-music-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.close()
            MouseArea { anchors.fill: parent; onClicked: root.close() }
            // Separate blue perimeter glow preserves the existing neutral drop shadow.
            RectangularShadow {
                x: popup.x; y: popup.y
                width: popup.width; height: popup.height
                radius: popup.radius
                color: Qt.rgba(popup.accent.r, popup.accent.g, popup.accent.b, 0.20)
                blur: 36
                spread: 4
                scale: popup.scale
                transformOrigin: Item.Top
                opacity: popup.opacity
            }
            MusicPopupView {
                id: popup
                x: (parent.width - width) / 2
                y: Math.min(74, Math.max(12, parent.height - height * scale - 12))
                transformOrigin: Item.Top
                scale: Math.min(1, (parent.width - 32) / width, (parent.height - 36) / height) * (0.97 + root.progress * 0.03)
                opacity: root.progress
                layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.65; shadowOpacity: 0.22; shadowVerticalOffset: 10 }
                // The supplied composition owns all content. Catch only unused panel
                // space, letting the supplied controls handle their own pointer input.
                MouseArea { anchors.fill: parent; z: -1; onClicked: popup.forceActiveFocus() }
                sourceName: root.player ? root.player.identity : "Music"
                artworkSource: root.player ? root.player.trackArtUrl : ""
                fallbackSource: "file://" + Quickshell.env("HOME") + "/.local/share/wallpapers/konata-command-center/v2/selected.png"
                trackTitle: root.player ? root.player.trackTitle || "Untitled track" : ""
                artistName: root.player ? root.player.trackArtist || "Unknown artist" : ""
                positionSeconds: root.player && root.player.positionSupported ? root.player.position : 0
                durationSeconds: root.player && root.player.lengthSupported ? root.player.length : 0
                hasMedia: !!root.player
                playing: !!root.player && root.player.isPlaying
                canPlayPause: !!root.player && root.player.canTogglePlaying
                canPrevious: !!root.player && root.player.canGoPrevious
                canNext: !!root.player && root.player.canGoNext
                canSeek: !!root.player && root.player.canSeek && root.player.positionSupported && root.player.lengthSupported
                canShuffle: !!root.player && root.player.canControl && root.player.shuffleSupported
                canRepeat: !!root.player && root.player.canControl && root.player.loopSupported
                shuffleEnabled: !!root.player && root.player.shuffle
                repeatEnabled: !!root.player && root.player.loopState !== MprisLoopState.None
                canSetVolume: !!root.sink && root.sink.ready && !!root.sink.audio
                volume: canSetVolume ? Math.max(0, Math.min(1, root.sink.audio.volume)) : 0
                spectrumValues: playing ? root.spectrum : []
                reducedMotion: root.motionMode !== "full"
                motionDuration: root.motionMode === "off" ? 0 : 120
                onRequestPrevious: if (canPrevious) root.player.previous()
                onRequestPlayPause: if (canPlayPause) root.player.togglePlaying()
                onRequestNext: if (canNext) root.player.next()
                onRequestSeek: seconds => { if (canSeek) root.player.position = seconds; }
                onRequestShuffle: enabled => { if (canShuffle) root.player.shuffle = enabled; }
                onRequestRepeat: enabled => { if (canRepeat) root.player.loopState = enabled ? MprisLoopState.Playlist : MprisLoopState.None; }
                onRequestVolume: normalized => { if (canSetVolume) root.sink.audio.volume = Math.max(0, Math.min(1, normalized)); }
                onRequestDeviceMenu: { root.deviceAfterClose = true; root.close(); }
                onRequestClose: root.close()
            }
        }
    }
}
