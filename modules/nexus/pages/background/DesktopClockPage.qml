import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root
    title: qsTr("Desktop clock")
    isSubPage: true

    readonly property list<string> positionValues: ["top-left", "top-center", "top-right", "bottom-left", "bottom-center", "bottom-right", "center"]
    readonly property list<MenuItem> positionItems: [
        MenuItem { text: qsTr("Top Left") },
        MenuItem { text: qsTr("Top Center") },
        MenuItem { text: qsTr("Top Right") },
        MenuItem { text: qsTr("Bottom Left") },
        MenuItem { text: qsTr("Bottom Center") },
        MenuItem { text: qsTr("Bottom Right") },
        MenuItem { text: qsTr("Center") }
    ]

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
            last: true
            Layout.fillWidth: true
            text: qsTr("Enable desktop clock")
            checked: Config.background.desktopClock.enabled
            onToggled: GlobalConfig.background.desktopClock.enabled = checked
        }

        SectionHeader {
            text: qsTr("Appearance")
        }

        SelectRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Position")
            menuItems: root.positionItems
            active: root.positionItems[root.positionValues.indexOf(Config.background.desktopClock.position)] ?? root.positionItems[5]
            onSelected: item => {
                let idx = root.positionItems.indexOf(item);
                if (idx !== -1)
                    GlobalConfig.background.desktopClock.position = root.positionValues[idx];
            }
        }

        SliderRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Scale")
            value: (Config.background.desktopClock.scale - 0.5) / 2.5
            valueLabel: (0.5 + value * 2.5).toFixed(1) + "x"
            onMoved: v => GlobalConfig.background.desktopClock.scale = 0.5 + v * 2.5
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            text: qsTr("Invert colors")
            subtext: qsTr("Invert the clock color when using light wallpaper")
            checked: Config.background.desktopClock.invertColors
            onToggled: GlobalConfig.background.desktopClock.invertColors = checked
        }

        SectionHeader {
            text: qsTr("Background")
        }

        ToggleRow {
            first: true
            Layout.fillWidth: true
            text: qsTr("Enable background")
            checked: Config.background.desktopClock.background.enabled
            onToggled: GlobalConfig.background.desktopClock.background.enabled = checked
        }

        SliderRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Opacity")
            value: Config.background.desktopClock.background.opacity
            valueLabel: Math.round(value * 100) + "%"
            onMoved: v => GlobalConfig.background.desktopClock.background.opacity = v
            enabled: Config.background.desktopClock.background.enabled
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            text: qsTr("Blur")
            checked: Config.background.desktopClock.background.blur
            onToggled: GlobalConfig.background.desktopClock.background.blur = checked
            enabled: Config.background.desktopClock.background.enabled
        }

        SectionHeader {
            text: qsTr("Shadow")
        }

        ToggleRow {
            first: true
            Layout.fillWidth: true
            text: qsTr("Enable shadow")
            checked: Config.background.desktopClock.shadow.enabled
            onToggled: GlobalConfig.background.desktopClock.shadow.enabled = checked
        }

        SliderRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Opacity")
            value: Config.background.desktopClock.shadow.opacity
            valueLabel: Math.round(value * 100) + "%"
            onMoved: v => GlobalConfig.background.desktopClock.shadow.opacity = v
            enabled: Config.background.desktopClock.shadow.enabled
        }

        SliderRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Blur strength")
            value: Config.background.desktopClock.shadow.blur / 2.0
            valueLabel: (value * 2.0).toFixed(1)
            onMoved: v => GlobalConfig.background.desktopClock.shadow.blur = v * 2.0
            enabled: Config.background.desktopClock.shadow.enabled
        }
    }
}
