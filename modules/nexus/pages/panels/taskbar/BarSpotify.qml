pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Spotify")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Configuration")
        }

        ToggleRow {
            first: true
            text: qsTr("Background")
            subtext: qsTr("Render a solid background behind the Spotify widget")
            checked: Config.bar.spotify.background
            onToggled: GlobalConfig.bar.spotify.background = checked
        }

        ToggleRow {
            text: qsTr("Show visualizer")
            subtext: qsTr("Display animated frequency visualizer bars")
            checked: Config.bar.spotify.showVisualiser
            onToggled: GlobalConfig.bar.spotify.showVisualiser = checked
        }

        StepperRow {
            label: qsTr("Max title length")
            subtext: qsTr("Cut off character count for track title")
            value: Config.bar.spotify.maxTitleLength
            from: 5
            to: 100
            stepSize: 1
            onMoved: v => GlobalConfig.bar.spotify.maxTitleLength = v
        }

        ToggleRow {
            text: qsTr("Inverted text direction")
            subtext: qsTr("Rotate text in the opposite direction when the bar is vertical")
            checked: Config.bar.spotify.inverted
            onToggled: GlobalConfig.bar.spotify.inverted = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Horizontal volume slider")
            subtext: qsTr("Place a horizontal volume slider below the playback controls in the popout")
            checked: Config.bar.spotify.horizontalVolume
            onToggled: GlobalConfig.bar.spotify.horizontalVolume = checked
        }
    }
}
