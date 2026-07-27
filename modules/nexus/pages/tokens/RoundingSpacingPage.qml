import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Rounding & Spacing")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: TokenConfig.appearance.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Corner Rounding")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Extra Small")
            value: TokenConfig.appearance.rounding.extraSmall
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.rounding.extraSmall = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Small")
            value: TokenConfig.appearance.rounding.small
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.rounding.small = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Medium")
            value: TokenConfig.appearance.rounding.medium
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.rounding.medium = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Large")
            value: TokenConfig.appearance.rounding.large
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.rounding.large = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Large Increased")
            value: TokenConfig.appearance.rounding.largeIncreased
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.rounding.largeIncreased = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Extra Large")
            value: TokenConfig.appearance.rounding.extraLarge
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.rounding.extraLarge = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Extra Large Increased")
            value: TokenConfig.appearance.rounding.extraLargeIncreased
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.rounding.extraLargeIncreased = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Extra Extra Large")
            value: TokenConfig.appearance.rounding.extraExtraLarge
            from: 0
            to: 150
            stepSize: 2
            onMoved: v => TokenConfig.appearance.rounding.extraExtraLarge = v
        }

        SectionHeader {
            text: qsTr("Layout Spacing")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Extra Small")
            value: TokenConfig.appearance.spacing.extraSmall
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.spacing.extraSmall = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Small")
            value: TokenConfig.appearance.spacing.small
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.spacing.small = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Medium")
            value: TokenConfig.appearance.spacing.medium
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.spacing.medium = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Large")
            value: TokenConfig.appearance.spacing.large
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.spacing.large = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Large Increased")
            value: TokenConfig.appearance.spacing.largeIncreased
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.spacing.largeIncreased = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Extra Large")
            value: TokenConfig.appearance.spacing.extraLarge
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.spacing.extraLarge = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Extra Large Increased")
            value: TokenConfig.appearance.spacing.extraLargeIncreased
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.spacing.extraLargeIncreased = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Extra Extra Large")
            value: TokenConfig.appearance.spacing.extraExtraLarge
            from: 0
            to: 150
            stepSize: 2
            onMoved: v => TokenConfig.appearance.spacing.extraExtraLarge = v
        }

        SectionHeader {
            text: qsTr("Inner Padding")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Extra Small")
            value: TokenConfig.appearance.padding.extraSmall
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.padding.extraSmall = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Small")
            value: TokenConfig.appearance.padding.small
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.padding.small = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Medium")
            value: TokenConfig.appearance.padding.medium
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.padding.medium = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Large")
            value: TokenConfig.appearance.padding.large
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.padding.large = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Large Increased")
            value: TokenConfig.appearance.padding.largeIncreased
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.padding.largeIncreased = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Extra Large")
            value: TokenConfig.appearance.padding.extraLarge
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.padding.extraLarge = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Extra Large Increased")
            value: TokenConfig.appearance.padding.extraLargeIncreased
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => TokenConfig.appearance.padding.extraLargeIncreased = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Extra Extra Large")
            value: TokenConfig.appearance.padding.extraExtraLarge
            from: 0
            to: 150
            stepSize: 2
            onMoved: v => TokenConfig.appearance.padding.extraExtraLarge = v
        }
    }
}
