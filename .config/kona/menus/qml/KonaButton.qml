import QtQuick
import QtQuick.Controls
Button { id: root; property color accent: "#78A9FF"; property bool reducedMotion: false; implicitHeight: 36; scale: reducedMotion ? 1.0 : down ? 0.97 : hovered ? 1.01 : 1.0; Behavior on scale { enabled: !root.reducedMotion; NumberAnimation { duration: root.down ? 90 : 120; easing.type: Easing.OutCubic } } }
