import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Shell Element Sizes")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: TokenConfig.appearance.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("App Launcher")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Item Width")
            value: TokenConfig.sizes.launcher.itemWidth
            from: 200
            to: 1000
            stepSize: 10
            onMoved: v => TokenConfig.sizes.launcher.itemWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Item Height")
            value: TokenConfig.sizes.launcher.itemHeight
            from: 20
            to: 150
            stepSize: 2
            onMoved: v => TokenConfig.sizes.launcher.itemHeight = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Wallpaper Grid Width")
            value: TokenConfig.sizes.launcher.wallpaperWidth
            from: 100
            to: 500
            stepSize: 10
            onMoved: v => TokenConfig.sizes.launcher.wallpaperWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Wallpaper Grid Height")
            value: TokenConfig.sizes.launcher.wallpaperHeight
            from: 80
            to: 400
            stepSize: 10
            onMoved: v => TokenConfig.sizes.launcher.wallpaperHeight = v
        }

        SectionHeader {
            text: qsTr("Notifications")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Notification Width")
            value: TokenConfig.sizes.notifs.width
            from: 200
            to: 600
            stepSize: 10
            onMoved: v => TokenConfig.sizes.notifs.width = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("App Image Size")
            value: TokenConfig.sizes.notifs.image
            from: 16
            to: 96
            stepSize: 2
            onMoved: v => TokenConfig.sizes.notifs.image = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Badge Indicator Size")
            value: TokenConfig.sizes.notifs.badge
            from: 8
            to: 48
            stepSize: 2
            onMoved: v => TokenConfig.sizes.notifs.badge = v
        }

        SectionHeader {
            text: qsTr("OSD & Volume Sliders")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Slider Width")
            value: TokenConfig.sizes.osd.sliderWidth
            from: 8
            to: 100
            stepSize: 2
            onMoved: v => TokenConfig.sizes.osd.sliderWidth = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Slider Height")
            value: TokenConfig.sizes.osd.sliderHeight
            from: 50
            to: 400
            stepSize: 10
            onMoved: v => TokenConfig.sizes.osd.sliderHeight = v
        }

        SectionHeader {
            text: qsTr("Desktop Popouts & Panels")
        }

        StepperRow {
            first: true
            Layout.fillWidth: true
            label: qsTr("Session Menu Button Size")
            value: TokenConfig.sizes.session.button
            from: 40
            to: 150
            stepSize: 5
            onMoved: v => TokenConfig.sizes.session.button = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Sidebar Width")
            value: TokenConfig.sizes.sidebar.width
            from: 200
            to: 600
            stepSize: 10
            onMoved: v => TokenConfig.sizes.sidebar.width = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Utilities Drawer Width")
            value: TokenConfig.sizes.utilities.width
            from: 200
            to: 600
            stepSize: 10
            onMoved: v => TokenConfig.sizes.utilities.width = v
        }

        StepperRow {
            Layout.topMargin: TokenConfig.appearance.spacing.extraSmall / 2 - parent.spacing
            last: true
            Layout.fillWidth: true
            label: qsTr("Toast Notification Width")
            value: TokenConfig.sizes.utilities.toastWidth
            from: 200
            to: 600
            stepSize: 10
            onMoved: v => TokenConfig.sizes.utilities.toastWidth = v
        }
    }
}
