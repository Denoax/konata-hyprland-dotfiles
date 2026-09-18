import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root
    property bool opened: false
    property real progress: 0
    property var weatherData: ({status:"loading",location:{name:"",region:""},current:{},units:{temperature:"",wind:"",precipitation:""},hourly:[]})
    readonly property int enterMs: 200
    readonly property int exitMs: 140
    function request(force) { fetch.command=[Quickshell.env("HOME")+"/.local/bin/kona-weather", force ? "refresh" : "status"]; fetch.running=true; }
    function close() { opened=false; progress=0; closeTimer.restart(); }
    function finish() { Qt.quit(); }
    function toggle() { if(opened) close(); else { opened=true; progress=1; request(false); } }
    Component.onCompleted: { Quickshell.watchFiles=false; opened=true; progress=1; request(false); }
    IpcHandler { target:"weather"
        function toggle(): void { root.toggle(); }
        function close(): void { root.close(); }
        function refresh(): void { root.request(true); }
        function status(): string { return JSON.stringify(root.weatherData); }
    }
    Behavior on progress { NumberAnimation { duration: root.opened ? root.enterMs : root.exitMs; easing.type:Easing.OutCubic } }
    Timer { id:closeTimer; interval:root.exitMs+30; repeat:false; onTriggered:root.finish() }
    Process { id: fetch; running:false
        stdout: StdioCollector { onStreamFinished: { try { root.weatherData=JSON.parse(text); } catch(error) { root.weatherData={status:"error",message:"Weather response was invalid"}; } } }
        stderr: SplitParser { onRead: line => console.warn("Weather:",line) }
    }
    PanelWindow {
        screen: Quickshell.screens.find(s=>s.name==="DP-4") || Quickshell.screens[0]
        anchors { left:true; right:true; top:true; bottom:true }
        color:"transparent"; exclusionMode:ExclusionMode.Ignore
        WlrLayershell.namespace:"kona-weather-popup"; WlrLayershell.layer:WlrLayer.Overlay; WlrLayershell.keyboardFocus:WlrKeyboardFocus.Exclusive
        Item { anchors.fill:parent; focus:true; Keys.onEscapePressed:root.close()
            WeatherPopupView { id:popup; anchors.centerIn:parent
                weatherData:root.weatherData
                reveal:root.progress
                onRequestRefresh:root.request(true)
            }
        }
    }
}
