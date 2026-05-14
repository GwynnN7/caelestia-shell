pragma ComponentBehavior: Bound

import "items"
import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var content
    required property DrawerVisibilities visibilities
    required property var panels
    required property real maxHeight
    required property StyledTextField search
    required property int padding
    required property int rounding

    readonly property bool showWallpapers: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `)
    readonly property var currentList: showWallpapers ? wallpaperList.item : appList.item // Can be either ListView or PathView, so can't type properly
    readonly property string activeMode: showWallpapers ? "wallpapers" : (appList.item?.state ?? "apps")
    
    readonly property bool showClipPreview: activeMode === "clip" && Boolean(currentList?.currentItem?.modelData)

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    clip: true
    state: showWallpapers ? "wallpapers" : "apps"

    states: [
        State {
            name: "apps"

            PropertyChanges {
                // Reduced from 450 to 350 to make the preview narrower
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth + (showClipPreview ? 350 + root.Tokens.spacing.large : 0)
                // Reduced from 500 to 450 to make the launcher slightly shorter vertically
                root.implicitHeight: Math.max(appList.implicitHeight > 0 ? appList.implicitHeight : empty.implicitHeight, showClipPreview ? 450 : 0)

                appList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "wallpapers"

            PropertyChanges {
                root.implicitWidth: Math.max(root.Tokens.sizes.launcher.itemWidth * 1.2, wallpaperList.implicitWidth)
                root.implicitHeight: root.Tokens.sizes.launcher.wallpaperHeight
                wallpaperList.active: true
            }
        }
    ]

    Behavior on state {
        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                from: 1
                to: 0
                type: Anim.DefaultEffects
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                from: 0
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }

    RowLayout {
        id: mainRow
        anchors.fill: parent
        spacing: Tokens.spacing.large

        Loader {
            id: appList

            active: false
            asynchronous: true

            Layout.fillHeight: true
            // Increased from 0.6 to 0.75 to make the list larger/wider
            Layout.preferredWidth: root.showClipPreview ? root.Tokens.sizes.launcher.itemWidth * 0.75 : root.Tokens.sizes.launcher.itemWidth
            sourceComponent: AppList {
                search: root.search
                visibilities: root.visibilities
            }
        }

        ClipPreview {
            id: clipPreview
            visible: root.showClipPreview
            modelData: root.currentList?.currentItem?.modelData
            list: appList.item
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }

    Loader {
        id: wallpaperList

        asynchronous: true
        active: false

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: WallpaperList {
            search: root.search
            visibilities: root.visibilities
            panels: root.panels
            content: root.content
        }
    }

    Row {
        id: empty

        opacity: root.currentList?.count === 0 ? 1 : 0
        scale: root.currentList?.count === 0 ? 1 : 0.5

        spacing: Tokens.spacing.medium
        padding: Tokens.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialIcon {
            text: root.state === "wallpapers" ? "wallpaper_slideshow" : "manage_search"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: root.state === "wallpapers" ? qsTr("No wallpapers found") : qsTr("No results")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                text: root.state === "wallpapers" && Wallpapers.list.length === 0 ? qsTr("Try putting some wallpapers in %1").arg(Paths.shortenHome(Paths.wallsdir)) : qsTr("Try searching for something else")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitWidth {
        enabled: root.visibilities.launcher

        Anim {}
    }

    Behavior on implicitHeight {
        enabled: root.visibilities.launcher

        Anim {}
    }
}
