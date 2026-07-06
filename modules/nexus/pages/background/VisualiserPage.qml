import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root
    title: qsTr("Background visualiser")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            Layout.fillWidth: true
            text: qsTr("Enable background visualiser")
            checked: Config.background.visualiser.enabled
            onToggled: GlobalConfig.background.visualiser.enabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: qsTr("Auto-hide visualiser")
            subtext: qsTr("Hide visualiser when a window is open")
            checked: Config.background.visualiser.autoHide
            onToggled: GlobalConfig.background.visualiser.autoHide = checked
            enabled: Config.background.visualiser.enabled
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            text: qsTr("Blur background")
            subtext: qsTr("Blur the wallpaper behind the visualiser")
            checked: Config.background.visualiser.blur
            onToggled: GlobalConfig.background.visualiser.blur = checked
            enabled: Config.background.visualiser.enabled
        }

        SectionHeader {
            text: qsTr("Appearance")
        }

        SliderRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Rounding")
            value: Config.background.visualiser.rounding / 10.0
            valueLabel: (value * 10.0).toFixed(1)
            onMoved: v => GlobalConfig.background.visualiser.rounding = v * 10.0
        }

        SliderRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Spacing")
            value: Config.background.visualiser.spacing / 10.0
            valueLabel: (value * 10.0).toFixed(1)
            onMoved: v => GlobalConfig.background.visualiser.spacing = v * 10.0
        }

        StepperRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Visualiser bars")
            subtext: qsTr("Number of bars in the audio visualisers")
            value: GlobalConfig.services.visualiserBars
            from: 10
            to: 120
            stepSize: 2
            onMoved: v => GlobalConfig.services.visualiserBars = v
        }
    }
}
