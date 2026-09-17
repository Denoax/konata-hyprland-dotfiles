import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: root

    // Data inputs
    property string sourceName: "Music"
    property url artworkSource: ""
    property string trackTitle: ""
    property string artistName: ""
    property real positionSeconds: 0
    property real durationSeconds: 0
    property real volume: 0.72
    property bool playing: false
    property bool shuffleEnabled: false
    property bool repeatEnabled: false
    property bool hasMedia: false
    property bool canPlayPause: false
    property url fallbackSource: ""
    property int motionDuration: 120
    property bool reducedMotion: false
    readonly property bool playbackRingRotating: playButton.decorationRotating
    readonly property real playbackRingRotation: playButton.decorationRotation
    property bool canPrevious: true
    property bool canNext: true
    property bool canSeek: true
    property bool canShuffle: true
    property bool canRepeat: true
    property bool canSetVolume: true
    property var spectrumValues: []

    property bool artworkFailed: false
    readonly property bool artworkReady: cover.status === Image.Ready
    readonly property url displayedArtwork: cover.source
    onArtworkSourceChanged: artworkFailed = false

    // Visual tokens
    property color surface: Appearance.surface
    property color surfaceHighlight: Appearance.surfaceElevated
    property color textColor: Appearance.text
    property color secondaryText: Appearance.textSecondary
    property color iconColor: Appearance.textSecondary
    property color accent: Appearance.accent
    property color accentSoft: Appearance.accentSoft
    property color trackInactive: Appearance.surfacePressed
    property color dividerColor: Appearance.outline

    signal requestPrevious()
    signal requestPlayPause()
    signal requestNext()
    signal requestShuffle(bool enabled)
    signal requestRepeat(bool enabled)
    signal requestSeek(real seconds)
    signal requestVolume(real normalized)
    signal requestDeviceMenu()
    signal requestClose()

    width: 1180
    height: 420
    radius: 32
    color: surface
    border.width: 1
    border.color: Appearance.outline

    layer.enabled: true

    function formatTime(seconds) {
        var s = Math.max(0, Math.floor(Number(seconds) || 0))
        var m = Math.floor(s / 60)
        var r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    // Soft upper highlight — intentionally subtle.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.surfaceHighlight
        opacity: 0.28
        z: -1
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 34

        Rectangle {
            id: artFrame
            Layout.preferredWidth: 360
            Layout.preferredHeight: 360
            Layout.alignment: Qt.AlignVCenter
            radius: 22
            color: Appearance.surfaceAlt
            clip: true

            Image {
                id: cover
                anchors.fill: parent
                source: root.artworkSource.toString().length > 0 && !root.artworkFailed ? root.artworkSource : root.fallbackSource
                sourceSize.width: 720
                sourceSize.height: 720
                onStatusChanged: if (status === Image.Error && root.artworkSource.toString().length > 0 && !root.artworkFailed) root.artworkFailed = true
                fillMode: Image.PreserveAspectCrop
                horizontalAlignment: source.toString() === root.fallbackSource.toString() ? Image.AlignLeft : Image.AlignHCenter
                asynchronous: true
                cache: true
                visible: status === Image.Ready
                layer.enabled: true
                layer.effect: MultiEffect { maskEnabled: true; maskSource: artMask }
            }

            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: 22
                layer.enabled: true
                visible: false
            }

            Rectangle {
                anchors.fill: parent
                radius: 22
                visible: cover.status !== Image.Ready
                color: Appearance.surfacePressed

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        font.family: "Noto Sans"

                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "KONA"
                        color: root.accent
                        font.pixelSize: 34
                        font.weight: Font.Medium
                        font.letterSpacing: 5
                    }
                    Text {
                        font.family: "Noto Sans"

                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.hasMedia ? "Artwork unavailable" : "Nothing playing"
                        color: root.secondaryText
                        font.pixelSize: 15
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                spacing: 12

                Text {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    visible: root.hasMedia
                    text: root.sourceName.toLowerCase().includes("spotify") ? "\uf1bc" : "\uf001"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 32
                    color: root.accent
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    font.family: "Noto Sans"
                    text: root.hasMedia ? root.sourceName : "Music"
                    color: root.secondaryText
                    font.pixelSize: 19
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }


            }

            Item { Layout.preferredHeight: 18 }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 112
                spacing: 24

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    Text {
                        font.family: "Noto Sans"

                        Layout.fillWidth: true
                        text: root.hasMedia ? root.trackTitle : "Nothing playing"
                        color: root.textColor
                        font.pixelSize: 40
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        font.family: "Noto Sans"

                        Layout.fillWidth: true
                        text: root.hasMedia ? root.artistName : "Start media to see controls"
                        color: root.secondaryText
                        font.pixelSize: 23
                        font.weight: Font.Normal
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                KonaSpectrum {
                    Layout.preferredWidth: 230
                    Layout.preferredHeight: 52
                    Layout.alignment: Qt.AlignVCenter
                    values: root.spectrumValues
                    active: root.playing && root.hasMedia
                    accent: root.accent
                    visible: root.hasMedia
                }
            }

            Item { Layout.preferredHeight: 10 }

            KonaThinSlider {
                id: seekSlider
                accessibleLabel: "Track position"
                motionDuration: root.motionDuration
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                value: root.durationSeconds > 0 ? Math.max(0, Math.min(1, root.positionSeconds / root.durationSeconds)) : 0
                enabled: root.hasMedia && root.canSeek && root.durationSeconds > 0
                interactive: enabled
                accent: root.accent
                trackColor: root.trackInactive
                trackHeight: 10
                knobSize: 22
                onCommitted: pct => root.requestSeek(pct * Math.max(0, root.durationSeconds))
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                Text {
                    font.family: "Noto Sans"
                    text: root.formatTime(root.positionSeconds)
                    color: root.secondaryText
                    font.pixelSize: 16
                }
                Item { Layout.fillWidth: true }
                Text {
                    font.family: "Noto Sans"
                    text: root.formatTime(root.durationSeconds)
                    color: root.secondaryText
                    font.pixelSize: 16
                }
            }

            Item { Layout.preferredHeight: 16 }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                KonaIconButton {
                    motionDuration: root.motionDuration
                    glyph: "⇄"
                    accessibleLabel: "Shuffle"
                    enabled: root.hasMedia && root.canShuffle
                    selected: root.shuffleEnabled
                    iconColor: root.shuffleEnabled ? root.accent : root.iconColor
                    onClicked: root.requestShuffle(!root.shuffleEnabled)
                }

                KonaIconButton {
                    motionDuration: root.motionDuration
                    glyph: "◀|"
                    accessibleLabel: "Previous track"
                    enabled: root.hasMedia && root.canPrevious
                    onClicked: root.requestPrevious()
                }

                KonaIconButton {
                    motionDuration: root.motionDuration
                    id: playButton
                    primary: true
                    playingDecoration: root.hasMedia && root.playing
                    reducedMotion: root.reducedMotion
                    diameter: 72
                    glyph: root.playing ? "Ⅱ" : "▶"
                    accessibleLabel: root.playing ? "Pause" : "Play"
                    enabled: root.hasMedia && root.canPlayPause
                    accent: root.accent
                    onClicked: root.requestPlayPause()
                }

                KonaIconButton {
                    motionDuration: root.motionDuration
                    glyph: "|▶"
                    accessibleLabel: "Next track"
                    enabled: root.hasMedia && root.canNext
                    onClicked: root.requestNext()
                }

                KonaIconButton {
                    motionDuration: root.motionDuration
                    glyph: "↻"
                    accessibleLabel: "Repeat"
                    enabled: root.hasMedia && root.canRepeat
                    iconColor: root.repeatEnabled ? root.accent : root.iconColor
                    onClicked: root.requestRepeat(!root.repeatEnabled)
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 58
                    Layout.leftMargin: 10
                    Layout.rightMargin: 14
                    color: root.dividerColor
                }

                Text {
                    font.family: "JetBrainsMono Nerd Font"
                    text: "\uf028"
                    color: root.iconColor
                    font.pixelSize: 23
                    opacity: root.canSetVolume ? 1.0 : 0.4
                }

                KonaThinSlider {
                    Layout.preferredWidth: 150
                    accessibleLabel: "Output volume"
                    motionDuration: root.motionDuration
                    Layout.preferredHeight: 26
                    value: root.volume
                    enabled: root.canSetVolume
                    interactive: enabled
                    accent: root.accent
                    trackColor: root.trackInactive
                    trackHeight: 7
                    knobSize: 18
                    onMoved: pct => root.requestVolume(pct)
                }

                KonaIconButton {
                    motionDuration: root.motionDuration
                    outputDeviceIcon: true
                    accent: root.accent
                    iconColor: root.iconColor
                    accessibleLabel: "Audio output devices"
                    enabled: true
                    onClicked: root.requestDeviceMenu()
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
