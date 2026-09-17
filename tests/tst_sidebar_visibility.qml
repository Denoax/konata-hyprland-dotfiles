import QtQuick
import QtTest
import "../.config/quickshell/kona/sidebar/qml" as Sidebar

TestCase {
    name: "SidebarAutoHide"
    Sidebar.SidebarVisibility { id: visibility; leaveDelay: 40; summonDelay: 80 }
    function init() {
        visibility.enabled = false;
        visibility.pointerInside = false;
        visibility.keyboardActive = false;
        visibility.enabled = true;
    }
    function test_edge_enter_reveals_and_leave_hides() {
        compare(visibility.revealed, false);
        visibility.pointerInside = true;
        compare(visibility.revealed, true);
        wait(100); compare(visibility.revealed, true);
        visibility.pointerInside = false;
        compare(visibility.revealed, true);
        tryCompare(visibility, "revealed", false, 300);
    }
    function test_reentry_cancels_pending_hide() {
        visibility.pointerInside = true;
        visibility.pointerInside = false;
        wait(10);
        visibility.pointerInside = true;
        wait(100); compare(visibility.revealed, true);
    }
    function test_keyboard_focus_holds_until_focus_leaves() {
        visibility.show(); visibility.keyboardActive = true;
        wait(100); compare(visibility.revealed, true);
        visibility.keyboardActive = false;
        tryCompare(visibility, "revealed", false, 300);
    }
    function test_explicit_summon_expires_and_hide_requires_new_entry() {
        visibility.show(); compare(visibility.revealed, true);
        tryCompare(visibility, "revealed", false, 300);
        visibility.pointerInside = true; visibility.hide();
        wait(100); compare(visibility.revealed, false);
        visibility.pointerInside = false; visibility.pointerInside = true;
        compare(visibility.revealed, true);
        visibility.enabled = false;
        visibility.show(); compare(visibility.revealed, false);
    }
    function test_latched_toggle_stays_open_until_toggled_again() {
        visibility.toggleLatched();
        compare(visibility.revealed, true); compare(visibility.latched, true);
        wait(120); compare(visibility.revealed, true);
        visibility.pointerInside = true; visibility.pointerInside = false;
        wait(120); compare(visibility.revealed, true);
        visibility.toggleLatched();
        compare(visibility.revealed, false); compare(visibility.latched, false);
    }
}
