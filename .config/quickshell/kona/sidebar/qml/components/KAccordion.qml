import QtQuick
Item {
    id: root
    default property alias body: content.data
    property string title: ""
    property string iconName: ""
    property bool expanded: false
    property real contentHeight: content.childrenRect.height
    signal expansionChanged(bool isExpanded)
    implicitWidth: 278
    implicitHeight: 38 + reveal.height
    data: [
        KSurface {
            anchors.fill: parent
            visible: root.expanded
            radius: 14
            highlighted: true
            outlined: false
            surfaceOpacity: 0.82
        },
        KSectionRow {
            id: row
            width: root.width
            text: root.title
            iconName: root.iconName
            expanded: root.expanded
            onClicked: { root.expanded = !root.expanded; root.expansionChanged(root.expanded) }
        },
        Item {
            id: reveal
            y: 38
            width: root.width
            height: root.expanded ? root.contentHeight : 0
            clip: true
            enabled: root.expanded
            Behavior on height {
                NumberAnimation {
                    duration: Tokens.accordionMs
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.expressiveFastCurve
                }
            }
            Item {
                id: content
                width: parent.width
                opacity: root.expanded ? 1 : 0
                visible: reveal.height > 0
                Behavior on opacity { NumberAnimation { duration: Tokens.reducedMotion ? 0 : 180; easing.type: Easing.OutCubic } }
            }
        }
    ]
}
