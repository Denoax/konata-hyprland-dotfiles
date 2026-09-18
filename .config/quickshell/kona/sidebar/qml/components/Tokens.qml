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
    readonly property int releaseMs: reducedMotion ? 0 : 180
    // Match Caelestia's spatial motion grammar while keeping Kona's state owner.
    readonly property int expressiveFastMs: reducedMotion ? 0 : 350
    readonly property int expressiveDefaultMs: reducedMotion ? 0 : 500
    readonly property var expressiveFastCurve: [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var expressiveDefaultCurve: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property int accordionMs: expressiveFastMs
    readonly property int enterMs: expressiveDefaultMs
    readonly property int exitMs: expressiveFastMs
}
