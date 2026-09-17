import QtQuick
import Quickshell
import Quickshell.Io
QtObject {
    id: root
    readonly property string home: Quickshell.env("HOME")
    property string configRoot: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
    property string stateRoot: Quickshell.env("XDG_STATE_HOME") || home + "/.local/state"
    property string runtimeRoot: Quickshell.env("XDG_RUNTIME_DIR")
    property bool ready: false
    property bool reducedMotion: true
    property bool profileQuiet: true
    property string profileName: ""
    property bool gameQuiet: true
    property bool recordQuiet: true
    readonly property bool quiet: profileQuiet || gameQuiet || recordQuiet

    // Read existing owners on filesystem events; never write their state or poll it.
    property FileView preferences: FileView {
        path: root.configRoot + "/kona/preferences.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const value = JSON.parse(text());
                const motion = value.motion === undefined ? "full" : value.motion;
                if (!["full", "reduced", "off"].includes(motion)) throw new Error("invalid motion");
                root.reducedMotion = motion !== "full";
            } catch (error) { root.reducedMotion = true; console.warn("Sidebar preferences:", error); }
            root.ready = true;
        }
        onLoadFailed: error => {
            root.reducedMotion = error !== FileViewError.FileNotFound;
            if (error !== FileViewError.FileNotFound) console.warn("Sidebar preferences unreadable:", error);
            root.ready = true;
        }
    }
    property FileView profile: FileView {
        path: root.stateRoot + "/kona/profile.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const value = JSON.parse(text());
                if (!["daily", "focus", "gaming", "showcase"].includes(value.profile)) throw new Error("invalid profile");
                root.profileQuiet = ["focus", "gaming"].includes(value.profile);
                root.profileName = value.schema === 1 ? value.profile : "";
            } catch (error) { root.profileName = ""; root.profileQuiet = true; console.warn("Sidebar profile:", error); }
        }
        onLoadFailed: error => {
            root.profileName = "";
            root.profileQuiet = error !== FileViewError.FileNotFound;
            if (error !== FileViewError.FileNotFound) console.warn("Sidebar profile unreadable:", error);
        }
    }
    property FileView gaming: FileView {
        path: root.runtimeRoot + "/kona-game-mode"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.gameQuiet = true
        onLoadFailed: error => root.gameQuiet = error !== FileViewError.FileNotFound
    }
    // FileView cannot watch a child whose parent does not exist yet. The runtime
    // directory watch reconnects that leaf when the recorder creates its directory.
    property FileView runtimeDirectory: FileView {
        path: root.runtimeRoot
        watchChanges: true
        printErrors: false
        onFileChanged: { root.recording.reload(); root.gaming.reload(); }
    }
    property FileView recording: FileView {
        path: root.runtimeRoot + "/kona-record/pid"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        // A retained recording marker conservatively stays quiet until its owner clears it.
        onLoaded: root.recordQuiet = true
        onLoadFailed: error => root.recordQuiet = error !== FileViewError.FileNotFound
    }
}
