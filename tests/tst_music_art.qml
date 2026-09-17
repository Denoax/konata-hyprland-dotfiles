import QtQuick
import QtTest
import "../.config/quickshell/kona/music" as Music
Item {
    width: 1220; height: 460
    Music.MusicPopupView {
        id: popup
        hasMedia: true
        fallbackSource: Qt.resolvedUrl("../.local/share/wallpapers/konata-command-center/v2/selected.png")
    }
    TestCase {
        name: "MusicArtwork"
        when: windowShown
        function test_missing_art_and_recovery_keep_source_binding() {
            // A late fallback input must remain reactive even before media arrives.
            const fallback = popup.fallbackSource;
            popup.fallbackSource = "";
            compare(popup.displayedArtwork.toString(), "");
            popup.fallbackSource = fallback;
            tryCompare(popup, "artworkReady", true);
            compare(popup.displayedArtwork.toString(), fallback.toString());
            popup.artworkSource = "file:///nonexistent-kona-art.jpg";
            tryCompare(popup, "artworkFailed", true);
            tryCompare(popup, "artworkReady", true);
            compare(popup.displayedArtwork.toString(), fallback.toString());
            popup.artworkSource = Qt.resolvedUrl("../.local/share/wallpapers/konata-command-center/center.png");
            compare(popup.artworkFailed, false);
            tryCompare(popup, "artworkReady", true);
            compare(popup.displayedArtwork.toString(), popup.artworkSource.toString());
        }
    }
}
