import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: root

    property url source: ""
    property url fallbackSource: ""
    property bool playing: false
    property bool reducedMotion: false
    property color accent: Appearance.accent
    property var spectrumValues: []
    property bool sourceFailed: false
    property real phase: 0
    property real smoothedEnergy: 0

    readonly property bool artworkReady: cover.status === Image.Ready
    readonly property url displayedArtwork: cover.source
    readonly property real rawEnergy: {
        if (!spectrumValues || spectrumValues.length === 0)
            return 0;
        const count = Math.min(7, spectrumValues.length);
        let total = 0;
        for (let index = 0; index < count; ++index)
            total += Math.max(0, Math.min(1, Number(spectrumValues[index]) || 0));
        return total / count;
    }
    readonly property real deformation: reducedMotion || !playing ? 0 : 1.2 + smoothedEnergy * 4.2

    onSourceChanged: sourceFailed = false
    onRawEnergyChanged: smoothedEnergy = playing && !reducedMotion ? rawEnergy : 0
    onPlayingChanged: if (!playing) smoothedEnergy = 0
    onReducedMotionChanged: if (reducedMotion) { phase = 0; smoothedEnergy = 0; }

    implicitWidth: 310
    implicitHeight: 310

    Behavior on smoothedEnergy {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    NumberAnimation on phase {
        from: 0; to: Math.PI * 2
        duration: 9800
        loops: Animation.Infinite
        running: root.playing && !root.reducedMotion && root.visible
    }

    function liquidPath(radiusOffset, phaseOffset) {
        // The control geometry follows the supplied liquid-bubble guide. Only
        // small control-point offsets move; the artwork itself remains stable.
        const extent = Math.min(width, height) - 12 + radiusOffset * 2;
        const scale = extent / 59;
        const inset = Math.min(width, height) / 2 - 32 * scale;
        const movement = deformation;
        function x(value, wave) { return (inset + (value + movement * wave) * scale).toFixed(2); }
        function y(value, wave) { return (inset + (value + movement * wave) * scale).toFixed(2); }
        return "M " + x(32, Math.sin(phaseOffset) * .18) + " " + y(4, Math.cos(phaseOffset) * .10)
             + " C " + x(43, Math.sin(phaseOffset + .5) * .12) + " " + y(5, 0)
             + " " + x(46, 0) + " " + y(13, Math.cos(phaseOffset + .7) * .16)
             + " " + x(52, Math.sin(phaseOffset + 1.1) * .15) + " " + y(20, 0)
             + " C " + x(58, 0) + " " + y(27, Math.sin(phaseOffset + 1.5) * .14)
             + " " + x(61, Math.cos(phaseOffset + 2.0) * .12) + " " + y(34, 0)
             + " " + x(58, 0) + " " + y(43, Math.sin(phaseOffset + 2.5) * .16)
             + " C " + x(55, Math.cos(phaseOffset + 2.8) * .13) + " " + y(53, 0)
             + " " + x(48, 0) + " " + y(59, Math.sin(phaseOffset + 3.1) * .14)
             + " " + x(38, Math.cos(phaseOffset + 3.5) * .12) + " " + y(60, 0)
             + " C " + x(28, 0) + " " + y(62, Math.sin(phaseOffset + 4.0) * .12)
             + " " + x(20, Math.cos(phaseOffset + 4.4) * .14) + " " + y(60, 0)
             + " " + x(13, 0) + " " + y(52, Math.sin(phaseOffset + 4.8) * .15)
             + " C " + x(6, Math.cos(phaseOffset + 5.1) * .13) + " " + y(44, 0)
             + " " + x(4, 0) + " " + y(34, Math.sin(phaseOffset + 5.5) * .14)
             + " " + x(7, Math.cos(phaseOffset + 5.8) * .12) + " " + y(25, 0)
             + " C " + x(10, 0) + " " + y(15, Math.sin(phaseOffset + 6.1) * .13)
             + " " + x(20, Math.cos(phaseOffset + 6.4) * .14) + " " + y(3, 0)
             + " " + x(32, 0) + " " + y(4, Math.sin(phaseOffset + 6.7) * .10) + " Z";
    }

    Shape {
        anchors.fill: parent
        opacity: Appearance.mode === "dark" ? .30 : .24
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.accent
            strokeWidth: 13
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.liquidPath(2, -root.phase * .72 + .8) }
        }
    }
    Shape {
        anchors.fill: parent
        ShapePath {
            fillColor: Appearance.mode === "dark"
                       ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, .15)
                       : Qt.rgba(.90, .95, 1, .70)
            strokeColor: Appearance.mode === "dark"
                         ? Qt.rgba(.67, .82, 1, .82)
                         : Qt.rgba(.48, .69, 1, .74)
            strokeWidth: 2.4
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.liquidPath(0, root.phase) }
        }
    }
    RectangularShadow {
        anchors.centerIn: parent
        width: parent.width * .75; height: width; radius: width / 2
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, Appearance.mode === "dark" ? .28 : .18)
        blur: 28; spread: 2
    }
    Image {
        id: cover
        anchors.centerIn: parent
        width: parent.width * .735; height: width
        source: root.source.toString().length > 0 && !root.sourceFailed ? root.source : root.fallbackSource
        sourceSize: Qt.size(512, 512)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        onStatusChanged: if (status === Image.Error && root.source.toString().length > 0 && !root.sourceFailed)
            root.sourceFailed = true
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: MultiEffect { maskEnabled: true; maskSource: artMask }
    }
    Rectangle {
        id: artMask
        anchors.centerIn: parent
        width: parent.width * .735; height: width; radius: width / 2
        visible: false
        layer.enabled: true
    }
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * .735; height: width; radius: width / 2
        visible: cover.status !== Image.Ready
        color: Appearance.surfacePressed
        Text {
            anchors.centerIn: parent
            text: "KONA"
            color: root.accent
            font.family: "Noto Sans"
            font.pixelSize: 25
            font.weight: Font.DemiBold
            font.letterSpacing: 3
        }
    }
    Repeater {
        model: [
            {x: -4, y: 30, box: 55, asset: "medium", drift: .2},
            {x: 38, y: -2, box: 35, asset: "small", drift: 1.4},
            {x: 267, y: 37, box: 38, asset: "medium", drift: 2.5},
            {x: 256, y: 236, box: 55, asset: "medium", drift: 3.2},
            {x: 28, y: 259, box: 35, asset: "small", drift: 4.6}
        ]
        delegate: Image {
            required property var modelData
            required property int index
            x: modelData.x + (root.playing && !root.reducedMotion ? Math.sin(root.phase + modelData.drift) * 4 : 0)
            y: modelData.y + (root.playing && !root.reducedMotion ? Math.cos(root.phase * .8 + modelData.drift) * 3 : 0)
            width: modelData.box; height: modelData.box
            scale: 1 + (root.playing && !root.reducedMotion ? root.smoothedEnergy * .10 + Math.sin(root.phase + index) * .025 : 0)
            source: Qt.resolvedUrl("assets/decor/satellite-bubble-" + modelData.asset + ".svg")
            sourceSize: Qt.size(Math.round(width), Math.round(height))
            fillMode: Image.PreserveAspectFit
            opacity: Appearance.mode === "dark" ? .82 : 1
        }
    }
}
