import QtQuick

QtObject {
    id: root
    property bool enabled: true
    property bool pointerInside: false
    property bool keyboardActive: false
    property bool revealed: false
    property bool latched: false
    property int leaveDelay: 450
    property int summonDelay: 2500

    function scheduleHide(delay) {
        timeout.stop();
        if (revealed && !latched && !pointerInside && !keyboardActive) {
            timeout.interval = delay;
            timeout.start();
        }
    }
    function show() {
        if (!enabled) return;
        revealed = true;
        scheduleHide(summonDelay);
    }
    function toggleLatched() {
        if (!enabled) return;
        if (revealed) {
            hide();
        } else {
            timeout.stop();
            latched = true;
            revealed = true;
        }
    }
    function hide() {
        timeout.stop();
        latched = false;
        revealed = false;
    }
    onPointerInsideChanged: {
        if (pointerInside && enabled) show();
        else scheduleHide(leaveDelay);
    }
    onKeyboardActiveChanged: scheduleHide(leaveDelay)
    onEnabledChanged: if (!enabled) hide()
    property Timer timeout: Timer {
        repeat: false
        onTriggered: if (!root.pointerInside && !root.keyboardActive) root.hide()
    }
}
