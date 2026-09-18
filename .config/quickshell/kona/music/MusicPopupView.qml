import QtQuick
import QtQuick.Effects

Item {
    id: root

    property string sourceName: "Music"
    property url artworkSource: ""
    property string trackTitle: ""
    property string artistName: ""
    property real positionSeconds: 0
    property real durationSeconds: 0
    property real volume: .72
    property bool playing: false
    property bool shuffleEnabled: false
    property bool repeatEnabled: false
    property bool hasMedia: false
    property bool canPlayPause: false
    property url fallbackSource: ""
    property int motionDuration: 120
    property bool reducedMotion: false
    property bool canPrevious: true
    property bool canNext: true
    property bool canSeek: true
    property bool canShuffle: true
    property bool canRepeat: true
    property bool canSetVolume: true
    property var spectrumValues: []

    property bool artworkFailed: false
    readonly property url displayedArtwork: artworkSource.toString().length > 0 && !artworkFailed ? artworkSource : fallbackSource
    readonly property bool artworkReady: albumArt.status === Image.Ready
    readonly property bool playbackRingRotating: playButton.decorationRotating
    readonly property real playbackRingRotation: playButton.decorationRotation
    readonly property color primaryText: Appearance.text
    readonly property color secondaryText: Appearance.textSecondary
    readonly property color accentText: Appearance.accent

    onArtworkSourceChanged: artworkFailed = false

    signal requestPrevious()
    signal requestPlayPause()
    signal requestNext()
    signal requestShuffle(bool enabled)
    signal requestRepeat(bool enabled)
    signal requestSeek(real seconds)
    signal requestVolume(real normalized)
    signal requestDeviceMenu()
    signal requestClose()

    width: 1260
    height: 252
    Accessible.role: Accessible.Pane
    Accessible.name: "Music player"

    function formatTime(seconds) {
        const value = Math.max(0, Math.floor(Number(seconds) || 0));
        const minutes = Math.floor(value / 60);
        const remainder = value % 60;
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder;
    }

    function asset(path) { return Qt.resolvedUrl("assets/reconstruction-v3/" + path); }
    function icon(name) {
        const assetMode = Appearance.mode === "dark" ? "dark" : "light";
        return Qt.resolvedUrl("assets/" + assetMode + "/" + name + ".svg");
    }

    RectangularShadow {
        x: 20; y: 20; width: 1220; height: 212
        radius: 30
        color: Appearance.shadow
        blur: 20
        spread: 1
        offset: Qt.vector2d(0, 7)
    }

    Rectangle {
        x: 20; y: 20; width: 1220; height: 212
        radius: 30
        color: Appearance.surfaceElevated
        border.width: 2
        border.color: Appearance.outlineStrong
        z: 1
    }

    Rectangle {
        x: 42; y: 42; width: 168; height: 168
        radius: 24
        color: Appearance.accentSoft
        border.width: 2
        border.color: Appearance.outlineStrong
        z: 2
    }

    Rectangle {
        x: 222; y: 48; width: 2; height: 156
        radius: 1
        color: Appearance.accent
        opacity: .38
        z: 2
    }

    Image {
        id: albumArt
        x: 42; y: 42; width: 168; height: 168
        source: root.displayedArtwork
        sourceSize: Qt.size(360, 360)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
        onStatusChanged: {
            if (status === Image.Error
                    && root.artworkSource.toString().length > 0
                    && source.toString() === root.artworkSource.toString())
                root.artworkFailed = true;
        }
    }

    Rectangle {
        id: albumMask
        x: albumArt.x; y: albumArt.y
        width: albumArt.width; height: albumArt.height
        radius: 24
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        x: albumArt.x; y: albumArt.y
        width: albumArt.width; height: albumArt.height
        source: albumArt
        maskEnabled: true
        maskSource: albumMask
        visible: root.hasMedia && root.displayedArtwork.toString().length > 0
        z: 3
    }

    Column {
        x: 235; y: 55; width: 310; spacing: 1
        z: 3
        Text {
            width: parent.width
            text: root.hasMedia ? (root.trackTitle || "Untitled track") : "Nothing playing"
            color: root.primaryText
            font.family: "Noto Sans"
            font.pixelSize: 25
            font.weight: Font.Bold
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: root.hasMedia ? (root.artistName || "Unknown artist") : "Open a media player to begin"
            color: root.secondaryText
            font.family: "Noto Sans"
            font.pixelSize: 15
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: root.sourceName
            color: Appearance.textMuted
            font.family: "Noto Sans"
            font.pixelSize: 11
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
    }

    KonaThinSlider {
        x: 235; y: 143; width: 326; height: 26
        accessibleLabel: "Track position"
        motionDuration: root.motionDuration
        value: root.durationSeconds > 0 ? Math.max(0, Math.min(1, root.positionSeconds / root.durationSeconds)) : 0
        enabled: root.hasMedia && root.canSeek && root.durationSeconds > 0
        interactive: enabled
        accent: root.accentText
        trackColor: Appearance.surfacePressed
        trackHeight: 6; knobSize: 14
        onCommitted: pct => root.requestSeek(pct * Math.max(0, root.durationSeconds))
        z: 3
    }

    Text {
        x: 235; y: 174
        text: root.formatTime(root.positionSeconds)
        color: root.secondaryText
        font.family: "Noto Sans"
        font.pixelSize: 11
        z: 3
    }

    Text {
        x: 519; y: 174; width: 42
        horizontalAlignment: Text.AlignRight
        text: root.formatTime(root.durationSeconds)
        color: root.secondaryText
        font.family: "Noto Sans"
        font.pixelSize: 11
        z: 3
    }

    KonaIconButton {
        x: 590; y: 100
        diameter: 38; iconSize: 34
        iconSource: root.icon("shuffle")
        accessibleLabel: "Shuffle"
        enabled: root.hasMedia && root.canShuffle
        selected: root.shuffleEnabled
        motionDuration: root.motionDuration
        onClicked: root.requestShuffle(!root.shuffleEnabled)
        z: 3
    }

    KonaIconButton {
        x: 635; y: 94
        diameter: 48; iconSize: 44
        iconSource: root.icon("previous")
        accessibleLabel: "Previous track"
        enabled: root.hasMedia && root.canPrevious
        motionDuration: root.motionDuration
        onClicked: root.requestPrevious()
        z: 3
    }

    KonaIconButton {
        id: playButton
        x: 693; y: 83
        diameter: 68; iconSize: 64
        primary: true
        playingDecoration: root.hasMedia && root.playing
        reducedMotion: root.reducedMotion
        iconSource: root.icon(root.playing ? "pause" : "play")
        accessibleLabel: root.playing ? "Pause" : "Play"
        enabled: root.hasMedia && root.canPlayPause
        accent: root.accentText
        motionDuration: root.motionDuration
        onClicked: root.requestPlayPause()
        z: 3
    }

    KonaIconButton {
        x: 771; y: 94
        diameter: 48; iconSize: 44
        iconSource: root.icon("next")
        accessibleLabel: "Next track"
        enabled: root.hasMedia && root.canNext
        motionDuration: root.motionDuration
        onClicked: root.requestNext()
        z: 3
    }

    KonaIconButton {
        x: 826; y: 100
        diameter: 38; iconSize: 34
        iconSource: root.icon("repeat")
        accessibleLabel: "Repeat"
        enabled: root.hasMedia && root.canRepeat
        selected: root.repeatEnabled
        motionDuration: root.motionDuration
        onClicked: root.requestRepeat(!root.repeatEnabled)
        z: 3
    }

    Rectangle {
        x: 878; y: 73; width: 1; height: 107
        color: Appearance.outline
        opacity: .7
        z: 3
    }

    KonaSpectrum {
        x: 897; y: 74; width: 154; height: 89
        values: root.spectrumValues
        active: root.playing && root.hasMedia
        accent: root.accentText
        minBarHeight: 6
        maxBarHeight: 82
        barWidth: 4
        barSpacing: 3
        visible: root.hasMedia
        z: 3
    }

    KonaIconButton {
        x: 1068; y: 96
        diameter: 46; iconSize: 36
        iconSource: root.icon("device")
        accessibleLabel: "Audio output devices"
        enabled: true
        motionDuration: root.motionDuration
        onClicked: root.requestDeviceMenu()
        z: 3
    }

    KonaThinSlider {
        x: 1121; y: 105; width: 103; height: 26
        accessibleLabel: "Output volume"
        motionDuration: root.motionDuration
        value: root.volume
        enabled: root.canSetVolume
        interactive: enabled
        accent: root.accentText
        trackColor: Appearance.surfacePressed
        trackHeight: 6; knobSize: 14
        onMoved: pct => root.requestVolume(pct)
        z: 3
    }

    Text {
        x: 1121; y: 140; width: 103
        text: Math.round(root.volume * 100) + "%"
        color: root.secondaryText
        font.family: "Noto Sans"
        font.pixelSize: 10
        horizontalAlignment: Text.AlignHCenter
        z: 3
    }
}
