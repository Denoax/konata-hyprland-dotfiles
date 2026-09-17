pragma Singleton
import QtQuick
import QtMultimedia
QtObject {
    // One reusable nonverbal sound, no process per click or global input hook.
    property bool muted: true // Preview opt-in; connect to the real preference at integration.
    property real gain: 0.35
    property double lastPlayed: 0
    property int activations: 0
    property SoundEffect effect: SoundEffect {
        source: Qt.resolvedUrl("../../assets/audio/bubble-click.wav")
        volume: 0.35
        loops: 1
    }
    function bubble() {
        const now = Date.now()
        if (muted || now - lastPlayed < 40 || effect.status !== SoundEffect.Ready) return
        lastPlayed = now
        effect.volume = Math.max(0, Math.min(1, gain))
        effect.play()
        activations += 1
    }
    function stop() { effect.stop() }
}
