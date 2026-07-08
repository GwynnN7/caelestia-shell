import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Font Sizes")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: TokenConfig.appearance.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Standard Fonts")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Small")
            value: TokenConfig.appearance.fontSize.small
            from: 6
            to: 36
            stepSize: 1
            onMoved: v => TokenConfig.appearance.fontSize.small = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Smaller")
            value: TokenConfig.appearance.fontSize.smaller
            from: 6
            to: 36
            stepSize: 1
            onMoved: v => TokenConfig.appearance.fontSize.smaller = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Normal")
            value: TokenConfig.appearance.fontSize.normal
            from: 8
            to: 40
            stepSize: 1
            onMoved: v => TokenConfig.appearance.fontSize.normal = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Larger")
            value: TokenConfig.appearance.fontSize.larger
            from: 8
            to: 40
            stepSize: 1
            onMoved: v => TokenConfig.appearance.fontSize.larger = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Large")
            value: TokenConfig.appearance.fontSize.large
            from: 10
            to: 48
            stepSize: 1
            onMoved: v => TokenConfig.appearance.fontSize.large = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Extra Large")
            value: TokenConfig.appearance.fontSize.extraLarge
            from: 12
            to: 72
            stepSize: 1
            onMoved: v => TokenConfig.appearance.fontSize.extraLarge = v
        }

        SectionHeader {
            text: qsTr("Monospace Fonts")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Mono Small")
            value: TokenConfig.appearance.fontSize.monoSmall
            from: 6
            to: 36
            stepSize: 1
            onMoved: v => TokenConfig.appearance.fontSize.monoSmall = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Mono Medium")
            value: TokenConfig.appearance.fontSize.monoMedium
            from: 8
            to: 40
            stepSize: 1
            onMoved: v => TokenConfig.appearance.fontSize.monoMedium = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Mono Large")
            value: TokenConfig.appearance.fontSize.monoLarge
            from: 10
            to: 48
            stepSize: 1
            onMoved: v => TokenConfig.appearance.fontSize.monoLarge = v
        }
    }
}
