// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtMultimedia

Loader {
    id: horn
    active: false
    visible: false
    // Do not open audio devices or decode the MP3 until a warning or preview.
    sourceComponent: Component {
        MediaPlayer {
            source: Qt.resolvedUrl("../sounds/invasion-horn.mp3")
            audioOutput: AudioOutput {}
        }
    }
    onLoaded: item.play()
    function playWarning() {
        if (!active) {
            active = true;
        } else if (item) {
            // Restart instead of overlapping or looping warning sounds.
            item.stop();
            item.play();
        }
    }
}
