import QtQuick
import QtMultimedia
import Quickshell

Item {
    id: root

    property var screenModel: null
    property bool isFirstInstance: false

    readonly property bool playing: BadApplePlayer.shouldPlay

    function play() {
        BadApplePlayer.play();
    }

    function stop() {
        BadApplePlayer.stop();
    }

    visible: BadApplePlayer.shouldPlay

    onVisibleChanged: {
        if (visible) {
            mediaPlayer.play();
            audioOutput.muted = !isFirstInstance;
        } else {
            mediaPlayer.stop();
        }
    }

    Component.onCompleted: {
        mediaPlayer.audioOutput = audioOutput;
        root.isFirstInstance = (BadApplePlayer.firstInstance === null);
        BadApplePlayer.firstInstance = root;
    }

    Component.onDestruction: {
        if (BadApplePlayer.firstInstance === root) {
            BadApplePlayer.firstInstance = null;
        }
    }

    Connections {
        function onToggleRequested() {
            root.visible = BadApplePlayer.shouldPlay;
            if (BadApplePlayer.shouldPlay) {
                mediaPlayer.play();
                audioOutput.muted = !isFirstInstance;
            } else {
                mediaPlayer.stop();
            }
        }

        target: BadApplePlayer
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    MediaPlayer {
        id: mediaPlayer

        source: `${Quickshell.shellDir}/assets/badapple.mp4`
        videoOutput: videoOutput
    }

    VideoOutput {
        id: videoOutput

        anchors.fill: parent
    }

    AudioOutput {
        id: audioOutput
    }
}
