import QtQuick
import "../components"

KAccordion {
    id: root
    title: "Weather"
    iconName: "sun"
    expanded: false
    property var weather: ({status:"loading"})
    readonly property bool ready: weather && ["ok","stale"].includes(weather.status) && weather.current
    readonly property var current: ready ? weather.current : ({temperature: 0, condition: ""})
    readonly property var location: weather && weather.location ? weather.location : ({name: ""})
    signal request(string actionId, var payload)
    contentHeight: 70
    Item {
        width: root.width; height: 70
        Column { x:12; anchors.verticalCenter:parent.verticalCenter; width:170; spacing:3
            Text { text: root.ready ? root.current.condition : root.weather.status === "setup" ? "Set your location" : "Weather unavailable"; color:Tokens.text; font.family:Tokens.uiFont; font.pixelSize:12; font.weight:Font.DemiBold; elide:Text.ElideRight; width:parent.width }
            Text { text: root.ready ? root.location.name : "Open weather"; color:Tokens.muted; font.family:Tokens.uiFont; font.pixelSize:10; elide:Text.ElideRight; width:parent.width }
        }
        Text { visible:root.ready; anchors.right:open.left; anchors.rightMargin:8; anchors.verticalCenter:parent.verticalCenter; text:Math.round(root.current.temperature)+"°"; color:Tokens.accent; font.family:Tokens.uiFont; font.pixelSize:22; font.weight:Font.DemiBold }
        KButton { id:open; anchors.right:parent.right; anchors.rightMargin:8; anchors.verticalCenter:parent.verticalCenter; width:36; height:36; round:true; iconName:"cloud"; hint:"Open weather"; actionId:"weather.open"; onRequest:(id,args)=>root.request(id,args) }
    }
}
