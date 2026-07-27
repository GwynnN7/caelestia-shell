import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root
    title: qsTr("Desktop lyrics")
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
            Layout.fillWidth: true
            text: qsTr("Enable desktop lyrics")
            checked: Config.background.desktopLyrics.enabled
            onToggled: GlobalConfig.background.desktopLyrics.enabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            text: qsTr("Auto-hide lyrics")
            subtext: qsTr("Hide lyrics when a window is open")
            checked: Config.background.desktopLyrics.autoHide
            onToggled: GlobalConfig.background.desktopLyrics.autoHide = checked
            enabled: Config.background.desktopLyrics.enabled
        }

        SectionHeader {
            text: qsTr("Appearance")
        }

        SelectRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Position")
            menuItems: root.positionItems
            active: root.positionItems[root.positionValues.indexOf(Config.background.desktopLyrics.position)] ?? root.positionItems[5]
            onSelected: item => {
                let idx = root.positionItems.indexOf(item);
                if (idx !== -1)
                    GlobalConfig.background.desktopLyrics.position = root.positionValues[idx];
            }
        }

        SliderRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Scale")
            value: (Config.background.desktopLyrics.scale - 0.5) / 2.5
            valueLabel: (0.5 + value * 2.5).toFixed(1) + "x"
            onMoved: v => GlobalConfig.background.desktopLyrics.scale = 0.5 + v * 2.5
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            text: qsTr("Invert colors")
            subtext: qsTr("Invert the lyrics color when using light wallpaper")
            checked: Config.background.desktopLyrics.invertColors
            onToggled: GlobalConfig.background.desktopLyrics.invertColors = checked
        }

        SectionHeader {
            text: qsTr("Background")
        }

        ToggleRow {
            first: true
            Layout.fillWidth: true
            text: qsTr("Enable background")
            checked: Config.background.desktopLyrics.background.enabled
            onToggled: GlobalConfig.background.desktopLyrics.background.enabled = checked
        }

        SliderRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Opacity")
            value: Config.background.desktopLyrics.background.opacity
            valueLabel: Math.round(value * 100) + "%"
            onMoved: v => GlobalConfig.background.desktopLyrics.background.opacity = v
            enabled: Config.background.desktopLyrics.background.enabled
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            text: qsTr("Blur")
            checked: Config.background.desktopLyrics.background.blur
            onToggled: GlobalConfig.background.desktopLyrics.background.blur = checked
            enabled: Config.background.desktopLyrics.background.enabled
        }

        SectionHeader {
            text: qsTr("Shadow")
        }

        ToggleRow {
            first: true
            Layout.fillWidth: true
            text: qsTr("Enable shadow")
            checked: Config.background.desktopLyrics.shadow.enabled
            onToggled: GlobalConfig.background.desktopLyrics.shadow.enabled = checked
        }

        SliderRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Opacity")
            value: Config.background.desktopLyrics.shadow.opacity
            valueLabel: Math.round(value * 100) + "%"
            onMoved: v => GlobalConfig.background.desktopLyrics.shadow.opacity = v
            enabled: Config.background.desktopLyrics.shadow.enabled
        }

        SliderRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Blur strength")
            value: Config.background.desktopLyrics.shadow.blur / 2.0
            valueLabel: (value * 2.0).toFixed(1)
            onMoved: v => GlobalConfig.background.desktopLyrics.shadow.blur = v * 2.0
            enabled: Config.background.desktopLyrics.shadow.enabled
        }
    }
}
