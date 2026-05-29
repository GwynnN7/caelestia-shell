import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property Props props
    required property DrawerVisibilities visibilities

    GridLayout {
        id: layout

        anchors.fill: parent
        columns: 1
        rowSpacing: Tokens.spacing.normal

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.row: Config.bar.position === "bottom" ? 1 : 0

            radius: Tokens.rounding.normal
            color: Colours.tPalette.m3surfaceContainerLow

            NotifDock {
                props: root.props
                visibilities: root.visibilities
            }
        }

        StyledRect {
            Layout.row: Config.bar.position === "bottom" ? 0 : 1
            Layout.topMargin: Config.bar.position === "bottom" ? 0 : (Tokens.padding.large - layout.rowSpacing)
            Layout.bottomMargin: Config.bar.position === "bottom" ? (Tokens.padding.large - layout.rowSpacing) : 0
            Layout.fillWidth: true
            implicitHeight: 1

            color: Colours.tPalette.m3outlineVariant
        }
    }
}
