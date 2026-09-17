import QtQuick
Item { id: root; property color surfaceColor: "#F7FAFF"; property color outlineColor: "#C9DBF3"; property real radius: 14
Rectangle { anchors.fill: parent; radius: root.radius; color: root.surfaceColor; border.width: 1; border.color: root.outlineColor } }
