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

    Component.onCompleted: {
        root.isFirstInstance = (BadApplePlayer.firstInstance === null);
        BadApplePlayer.firstInstance = root;
    }

    Component.onDestruction: {
        if (BadApplePlayer.firstInstance === root) {
            BadApplePlayer.firstInstance = null;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    Loader {
        active: root.visible
        anchors.fill: parent
        sourceComponent: Component {
            Item {
                MediaPlayer {
                    id: mediaPlayer
                    source: `${Quickshell.shellDir}/assets/badapple.mp4`
                    videoOutput: videoOutput
                    audioOutput: audioOut
                    Component.onCompleted: mediaPlayer.play()
                }

                VideoOutput {
                    id: videoOutput
                    anchors.fill: parent
                }

                AudioOutput {
                    id: audioOut
                    muted: !root.isFirstInstance
                }
            }
        }
    }
}
