pragma Singleton
import QtQuick
import "../.." as Sidebar
QtObject {
    property bool reducedMotion: false
    readonly property string appearanceMode: Sidebar.Appearance.mode
    readonly property color text: Sidebar.Appearance.text
    readonly property color muted: Sidebar.Appearance.textSecondary
    readonly property color subtle: Sidebar.Appearance.textMuted
    readonly property color accent: Sidebar.Appearance.accent
    readonly property color accentStrong: Sidebar.Appearance.focus
    readonly property color panel: Sidebar.Appearance.surface
    readonly property color surface: Sidebar.Appearance.surfaceAlt
    readonly property color surfaceRaised: Sidebar.Appearance.surfaceElevated
    readonly property color surfacePressed: Sidebar.Appearance.surfacePressed
    readonly property color line: Sidebar.Appearance.outline
    readonly property color lineStrong: Sidebar.Appearance.outlineStrong
    readonly property color active: Sidebar.Appearance.accentSoft
    readonly property color ice: Sidebar.Appearance.surfaceElevated
    readonly property color shadow: Sidebar.Appearance.shadow
    readonly property color glow: Sidebar.Appearance.glow
    readonly property color shellText: text
    readonly property color shellMuted: muted
    readonly property color shellSubtle: subtle
    readonly property color shellAccent: accent
    readonly property string uiFont: "Noto Sans"
    readonly property string dataFont: "JetBrains Mono"
    readonly property int pressMs: reducedMotion ? 0 : 90
    readonly property int releaseMs: reducedMotion ? 0 : 140
    readonly property int accordionMs: reducedMotion ? 0 : 200
    readonly property int enterMs: reducedMotion ? 0 : 220
    readonly property int exitMs: reducedMotion ? 0 : 180
}
