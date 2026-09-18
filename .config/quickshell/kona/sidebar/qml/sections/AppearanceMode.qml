import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: root
    property string mode: "light"
    signal request(string actionId, var payload)
    implicitHeight: 36

    RowLayout {
        anchors.fill: parent
        spacing: 5
        Text {
            text: "Appearance"
            color: Tokens.text
            font.family: Tokens.uiFont
            font.pixelSize: 12
            Layout.fillWidth: true
            Accessible.ignored: true
        }
        KButton {
            text: "Light"; selected: root.mode === "light"
            width: 50; height: 32; hint: "Use Light appearance"
            actionId: "appearance.light"
            onRequest: (id, args) => root.request(id, args)
        }
        KButton {
            text: "Kona"; selected: root.mode === "kona"
            width: 52; height: 32; hint: "Use pastel Kona blue appearance"
            actionId: "appearance.kona"
            onRequest: (id, args) => root.request(id, args)
        }
        KButton {
            text: "Dark"; selected: root.mode === "dark"
            width: 50; height: 32; hint: "Use Dark appearance"
            actionId: "appearance.dark"
            onRequest: (id, args) => root.request(id, args)
        }
    }
}
