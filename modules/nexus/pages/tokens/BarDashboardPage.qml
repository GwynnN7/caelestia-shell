import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Bar & Dashboard Sizes")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: TokenConfig.appearance.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Status Bar Widgets")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Inner Width")
            value: TokenConfig.sizes.bar.innerWidth
            from: 10
            to: 100
            stepSize: 2
            onMoved: v => TokenConfig.sizes.bar.innerWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Window Preview Size")
            value: TokenConfig.sizes.bar.windowPreviewSize
            from: 100
            to: 600
            stepSize: 10
            onMoved: v => TokenConfig.sizes.bar.windowPreviewSize = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Tray Menu Width")
            value: TokenConfig.sizes.bar.trayMenuWidth
            from: 150
            to: 500
            stepSize: 10
            onMoved: v => TokenConfig.sizes.bar.trayMenuWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Battery Width")
            value: TokenConfig.sizes.bar.batteryWidth
            from: 100
            to: 400
            stepSize: 5
            onMoved: v => TokenConfig.sizes.bar.batteryWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Network Width")
            value: TokenConfig.sizes.bar.networkWidth
            from: 150
            to: 500
            stepSize: 10
            onMoved: v => TokenConfig.sizes.bar.networkWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Keyboard Layout Width")
            value: TokenConfig.sizes.bar.kbLayoutWidth
            from: 150
            to: 500
            stepSize: 10
            onMoved: v => TokenConfig.sizes.bar.kbLayoutWidth = v
        }

        SectionHeader {
            text: qsTr("Dashboard Widgets")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("User Card Width")
            value: TokenConfig.sizes.dashboard.userWidth
            from: 200
            to: 500
            stepSize: 10
            onMoved: v => TokenConfig.sizes.dashboard.userWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Logo Size")
            value: TokenConfig.sizes.dashboard.logoSize
            from: 16
            to: 64
            stepSize: 2
            onMoved: v => TokenConfig.sizes.dashboard.logoSize = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Uptime Text Size")
            value: TokenConfig.sizes.dashboard.uptimeSize
            from: 16
            to: 64
            stepSize: 2
            onMoved: v => TokenConfig.sizes.dashboard.uptimeSize = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Date/Time Widget Width")
            value: TokenConfig.sizes.dashboard.dateTimeWidth
            from: 80
            to: 300
            stepSize: 5
            onMoved: v => TokenConfig.sizes.dashboard.dateTimeWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Weather Width")
            value: TokenConfig.sizes.dashboard.weatherWidth
            from: 150
            to: 400
            stepSize: 5
            onMoved: v => TokenConfig.sizes.dashboard.weatherWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Media Widget Width")
            value: TokenConfig.sizes.dashboard.mediaWidth
            from: 100
            to: 400
            stepSize: 10
            onMoved: v => TokenConfig.sizes.dashboard.mediaWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Media Section Width")
            value: TokenConfig.sizes.dashboard.mediaSectionWidth
            from: 150
            to: 500
            stepSize: 10
            onMoved: v => TokenConfig.sizes.dashboard.mediaSectionWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Media Cover Art Size")
            value: TokenConfig.sizes.dashboard.mediaCoverArtSize
            from: 100
            to: 300
            stepSize: 10
            onMoved: v => TokenConfig.sizes.dashboard.mediaCoverArtSize = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Media Tab Width")
            value: TokenConfig.sizes.dashboard.mediaTabWidth
            from: 400
            to: 1500
            stepSize: 20
            onMoved: v => TokenConfig.sizes.dashboard.mediaTabWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Media Tab Height")
            value: TokenConfig.sizes.dashboard.mediaTabHeight
            from: 200
            to: 600
            stepSize: 10
            onMoved: v => TokenConfig.sizes.dashboard.mediaTabHeight = v
        }
    }
}
