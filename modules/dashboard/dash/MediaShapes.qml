pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import M3Shapes
import Caelestia.Config
import Caelestia.Services
import qs.services

Item {
    id: root

    readonly property list<int> shapeTiers: [
        MaterialShape.Circle,
        MaterialShape.Cookie4Sided,
        MaterialShape.Cookie6Sided, 
        MaterialShape.Cookie7Sided,
        MaterialShape.Cookie9Sided,
        MaterialShape.Cookie12Sided
    ]

    readonly property list<string> colorPool: [
        Colours.palette.m3primary,
        Colours.palette.m3secondary,
        Colours.palette.m3tertiary,
        Colours.palette.m3primaryContainer,
        Colours.palette.m3secondaryContainer,
        Colours.palette.m3tertiaryContainer,
        Colours.palette.m3error
    ]

    ServiceRef {
        service: Audio.cava
    }

    MaterialShape {
        id: materialShape
        
        anchors.centerIn: parent
        implicitSize: Math.min(parent.width, parent.height) * 0.8
        
        shape: root.shapeTiers[0]
        color: Colours.palette.m3primary
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        function morph() {
            if (Config.dashboard.useMediaShapes && root.visible) {
                let bassValue = 0;
                if (Audio.cava && Audio.cava.values && Audio.cava.values.length > 2) {
                    // Average the first few bands (bass layer) to get a stable magnitude
                    bassValue = (Audio.cava.values[0] + Audio.cava.values[1] + Audio.cava.values[2]) / 3.0;
                }
                
                // Amplify the signal slightly so it confidently reaches the top tiers on strong beats
                bassValue = Math.min(1.0, bassValue * 1.3); 
                
                let tier = Math.floor(bassValue * root.shapeTiers.length);
                if (tier >= root.shapeTiers.length) tier = root.shapeTiers.length - 1;
                if (tier < 0) tier = 0;
                
                materialShape.shape = root.shapeTiers[tier];
                if (Config.dashboard.randomizeMediaShapeColors) {
                    materialShape.color = root.colorPool[Math.floor(Math.random() * root.colorPool.length)];
                } else {
                    materialShape.color = Colours.palette.m3primary;
                }
                materialShape.rotation = Math.random() * 360;
                beatAnim.restart();
            }
        }

        Timer {
            running: root.visible && Config.dashboard.useMediaShapes && (Players.active?.isPlaying ?? false)
            repeat: true
            interval: 60000 / Math.max(1, Audio.beatTracker.bpm > 0 ? Audio.beatTracker.bpm : 120)
            onTriggered: materialShape.morph()
        }
        
        Connections {
            target: Audio.beatTracker
            function onBeat(bpm) {
                materialShape.morph();
            }
        }
        
        Behavior on rotation {
            NumberAnimation { duration: 250; easing.type: Easing.OutElastic }
        }

        SequentialAnimation on scale {
            id: beatAnim
            running: false
            NumberAnimation { to: 1.15; duration: 80; easing.type: Easing.OutQuad }
            NumberAnimation { to: 1.0; duration: 170; easing.type: Easing.InOutQuad }
        }
    }
}
