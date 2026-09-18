pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    readonly property string configRoot: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    property string mode: "light"
    property var palette: ({
        mode: "light", background: "#EEF4FC", surface: "#F7FAFF",
        surface_alt: "#EEF4FC", surface_elevated: "#FFFFFF",
        surface_pressed: "#E3EDF9", text: "#263446",
        text_secondary: "#5B6B80", text_muted: "#8A98AA",
        accent: "#78A9FF", accent_hover: "#8CB7FF", accent_pressed: "#6498F5",
        accent_soft: "#DDEAFF", outline: "#C9DBF3", outline_strong: "#AFC9EB",
        focus: "#6FA6FF", danger: "#D95E6A", warning: "#C88932",
        success: "#28A875", shadow: "rgba(36,59,89,0.16)",
        glow: "rgba(111,166,255,0.24)", scrim: "rgba(12,19,30,0.18)"
    })
    readonly property color background: palette.background
    readonly property color surface: palette.surface
    readonly property color surfaceAlt: palette.surface_alt
    readonly property color surfaceElevated: palette.surface_elevated
    readonly property color surfacePressed: palette.surface_pressed
    readonly property color text: palette.text
    readonly property color textSecondary: palette.text_secondary
    readonly property color textMuted: palette.text_muted
    readonly property color accent: palette.accent
    readonly property color accentHover: palette.accent_hover
    readonly property color accentPressed: palette.accent_pressed
    readonly property color accentSoft: palette.accent_soft
    readonly property color outline: palette.outline
    readonly property color outlineStrong: palette.outline_strong
    readonly property color focus: palette.focus
    readonly property color danger: palette.danger
    readonly property color warning: palette.warning
    readonly property color success: palette.success
    readonly property color shadow: palette.shadow
    readonly property color glow: palette.glow
    readonly property color scrim: palette.scrim

    function accept(value) {
        const required = ["mode", "background", "surface", "surface_alt",
            "surface_elevated", "surface_pressed", "text", "text_secondary",
            "text_muted", "accent", "accent_hover", "accent_pressed", "accent_soft",
            "outline", "outline_strong", "focus", "danger", "warning", "success",
            "shadow", "glow", "scrim"];
        if (!value || !["light", "kona", "dark"].includes(value.mode)
                || required.some(key => typeof value[key] !== "string"))
            throw new Error("invalid semantic appearance palette");
        root.palette = value;
        root.mode = value.mode;
    }

    property FileView source: FileView {
        path: root.configRoot + "/kona/appearance/current.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { root.accept(JSON.parse(text())); }
            catch (error) { console.warn("Kona appearance palette:", error); }
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Kona appearance palette unavailable:", error);
        }
    }
}
