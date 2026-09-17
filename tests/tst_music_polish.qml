import QtQuick
import QtTest
import "../.config/quickshell/kona/music" as Music
Item {
    width: 200; height: 200
    Music.KonaIconButton {
        id: button
        anchors.centerIn: parent
        primary: true
    }
    SignalSpy { id: clicked; target: button; signalName: "clicked" }
    TestCase {
        name: "MusicPolish"
        when: windowShown
        function init() {
            button.primary = true;
            button.outputDeviceIcon = false;
            button.playingDecoration = false;
            button.reducedMotion = false;
            button.enabled = true;
        }
        function test_playing_ring_respects_pause_and_reduced_motion() {
            button.playingDecoration = true;
            tryCompare(button, "decorationRotating", true);
            tryVerify(() => button.decorationRotation > 0);
            compare(button.rotation, 0); // The control and glyph never rotate.
            button.playingDecoration = false;
            compare(button.decorationRotating, false);
            const pausedAngle = button.decorationRotation;
            wait(80);
            compare(button.decorationRotation, pausedAngle);
            button.reducedMotion = true;
            button.playingDecoration = true;
            compare(button.decorationRotating, false);
            compare(findChild(button, "playbackRing").visible, true);
            const reducedAngle = button.decorationRotation;
            wait(80);
            compare(button.decorationRotation, reducedAngle);
            button.reducedMotion = false;
            tryCompare(button, "decorationRotating", true);
            button.playingDecoration = false;
        }
        function test_output_device_keeps_keyboard_action_and_focus_color() {
            button.primary = false;
            button.outputDeviceIcon = true;
            button.forceActiveFocus();
            compare(button.deviceColor, button.accent);
            clicked.clear();
            keyClick(Qt.Key_Space);
            compare(clicked.count, 1);
            button.enabled = false;
            keyClick(Qt.Key_Space);
            compare(clicked.count, 1);
            button.enabled = true;
        }
    }
}
