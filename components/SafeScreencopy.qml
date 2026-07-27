import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    property var captureSource: null
    property bool live: false
    property bool smooth: false
    property size constraintSize: Qt.size(-1, -1)
    property bool _isStable: false

    implicitWidth: view.implicitWidth
    implicitHeight: view.implicitHeight

    Timer {
        id: stableTimer
        interval: 150
        repeat: false
        onTriggered: root._isStable = true
    }

    onCaptureSourceChanged: {
        root._isStable = false;
        if (root.captureSource) {
            stableTimer.restart();
        } else {
            stableTimer.stop();
        }
    }

    ScreencopyView {
        id: view
        anchors.fill: parent
        captureSource: root._isStable ? root.captureSource : null
        live: root.live
        smooth: root.smooth
        constraintSize: root.constraintSize
    }
}
