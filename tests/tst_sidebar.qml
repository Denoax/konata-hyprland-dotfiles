import QtQuick
import QtTest
import "../.config/quickshell/kona/sidebar/qml" as Sidebar
import "../.config/quickshell/kona/sidebar/qml/components" as Controls
Item {
    width: 500; height: 500
    property real backend: 0.4
    Sidebar.SidebarView { id: view; width: implicitWidth; height: 440; revealed: true }
    SignalSpy { id: expansion; target: view; signalName: "expansionRequested" }
    Controls.KButton { id: button; x: 350; text: "Action"; audible: false }
    SignalSpy { id: click; target: button; signalName: "clicked" }
    Controls.KThinSlider { id: slider; x: 310; y: 200; backendValue: backend }
    TestCase {
        name: "SidebarFoundation"
        when: windowShown
        function init() {
            Controls.Feedback.muted = true;
            Controls.Tokens.reducedMotion = true;
            view.expanded = true; view.revealed = true;
            view.statusLabel = "";
            button.enabled = true;
        }
        function test_collapse_emits_intent_without_breaking_owner_binding() {
            const control = findChild(view, "collapseControl");
            control.forceActiveFocus(); expansion.clear();
            keyClick(Qt.Key_Space);
            compare(expansion.count, 1); compare(expansion.signalArguments[0][0], false);
            compare(view.expanded, true);
            view.expanded = false; compare(view.width, 60);
            view.expanded = true; compare(view.width, 300);
        }
        function test_keyboard_and_disabled_control() {
            button.forceActiveFocus(); click.clear();
            keyClick(Qt.Key_Space); compare(click.count, 1);
            keyClick(Qt.Key_Return); compare(click.count, 2);
            button.enabled = false; keyClick(Qt.Key_Space); compare(click.count, 2);
        }
        function test_collapse_control_centers_icon_and_centers_in_rail() {
            const control = findChild(view, "collapseControl");
            const icon = findChild(view, "collapseChevron");
            for (const expanded of [true, false]) {
                view.expanded = expanded;
                compare(control.width, 32); compare(control.height, 32);
                compare(icon.width, 16); compare(icon.height, 16);
                const center = icon.mapToItem(control, icon.width / 2, icon.height / 2);
                compare(center.x, control.width / 2); compare(center.y, control.height / 2);
                if (!expanded) compare(control.x + control.width / 2, view.width / 2);
            }
        }
        function test_reveal_and_reduced_motion_settle_to_latest_state() {
            view.revealed = false; compare(view.revealProgress, 0); compare(view.enabled, false);
            view.revealed = true; compare(view.revealProgress, 1);
            Controls.Tokens.reducedMotion = false;
            view.expanded = false; view.expanded = true; view.expanded = false;
            tryCompare(view, "width", 60, 500);
            view.revealed = false; view.revealed = true;
            tryCompare(view, "revealProgress", 1, 500);
        }
        function test_slider_follows_backend_after_keyboard_input() {
            backend = 0.4; compare(slider.value, 0.4);
            slider.forceActiveFocus(); keyClick(Qt.Key_Right);
            backend = 0.8; compare(slider.value, 0.8);
        }
        function test_system_identity_and_live_profile_fit_without_personal_greeting() {
            const header = findChild(view, "profileHeader");
            const title = findChild(view, "headerSystemTitle");
            const subtitle = findChild(view, "headerSystemSubtitle");
            const status = findChild(view, "headerProfile");
            compare(title.text, "KONA");
            compare(subtitle.text, "Arch Linux · Hyprland");
            compare(status.visible, false);
            view.statusLabel = "Focus profile"; compare(status.visible, true);
            waitForRendering(view);
            compare(status.text, "Focus profile");
            view.statusLabel = "Gaming profile"; compare(status.text, "Gaming profile");
            compare(findChild(view, "headerQuote"), null);
            verify(header.y + header.height < view.height);
            view.expanded = false;
            compare(header.visible, false);
            compare(findChild(view, "railAvatar").visible, true);
        }
        function test_identity_aura_honors_reduced_motion() {
            const aura = findChild(view, "avatarAura");
            verify(aura !== null);
            Controls.Tokens.reducedMotion = true;
            compare(aura.opacity, 0.32);
            Controls.Tokens.reducedMotion = false;
            verify(aura.opacity >= 0.28 && aura.opacity <= 0.66);
        }
    }
}
