pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.utils

Item {
    id: root

    required property DrawerVisibilities visibilities
    readonly property DashboardState dashState: DashboardState {
        reloadableId: "dashboardState"
    }
    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }

    readonly property real nonAnimHeight: (content.item as Content)?.nonAnimHeight ?? 0
    readonly property bool shouldBeActive: visibilities.dashboard && Config.dashboard.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    clip: false
    visible: offsetScale < 1
    anchors.topMargin: Config.bar.position === "top" ? 0 : (-implicitHeight - 5) * offsetScale
    height: implicitHeight
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 854 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Item {
        anchors.fill: parent
        clip: Config.bar.position === "top"

        Loader {
            id: content

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: Config.bar.position === "top" ? undefined : parent.bottom
            anchors.top: Config.bar.position === "top" ? parent.top : undefined
            anchors.topMargin: Config.bar.position === "top" ? (-implicitHeight - 5) * root.offsetScale : 0

            active: root.shouldBeActive || root.visible

            sourceComponent: Content {
                visibilities: root.visibilities
                dashState: root.dashState
                facePicker: root.facePicker
            }
        }
    }
}
