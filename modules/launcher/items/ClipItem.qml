pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var list
    required property var modelData

    readonly property string entryId: modelData?.entryId ?? ""
    readonly property string entryText: modelData?.entryText ?? ""
    readonly property bool isImageEntry: modelData?.isImage ?? false

    readonly property string displayText: isImageEntry ? "image" : entryText

    function copyAndPasteClip(): void {
        root.list.visibilities.launcher = false;
        Quickshell.execDetached(["sh", "-c", "sleep 0.3 && cliphist decode '" + root.entryId + "' | wl-copy && wl-paste | wtype -"]);
    }

    function onClicked(): void {
        copyAndPasteClip();
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.list.visibilities.launcher = false;
            copyAndPasteClip();
            event.accepted = true;
        }
    }
   
    implicitHeight: isImageEntry ? Tokens.sizes.launcher.itemHeight + 120 : Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.small

        onClicked: {
            root.onClicked();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.larger
        anchors.rightMargin: Tokens.padding.larger
        anchors.topMargin: Tokens.padding.small
        anchors.bottomMargin: Tokens.padding.small
        spacing: Tokens.spacing.small

        StyledClippingRect {
            id: imageContainer
            visible: root.isImageEntry
            Layout.fillWidth: true
            Layout.preferredHeight: root.isImageEntry ? 100 : 0
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainerLow

            property bool imageReady: false
            property string imagePath: "/tmp/cliphist-launcher-" + root.entryId + ".png"

            Component.onCompleted: {
                if (root.isImageEntry && root.entryId) {
                    Quickshell.execDetached([
                        "sh", "-c",
                        "cliphist decode " + root.entryId + " > " + imagePath
                    ]);
                    imageLoadTimer.start();
                }
            }

            Timer {
                id: imageLoadTimer
                interval: 200
                onTriggered: imageContainer.imageReady = true
            }

            Image {
                id: previewImage
                anchors.centerIn: parent
                source: imageContainer.imageReady ? "file://" + imageContainer.imagePath : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                width: parent.width - Tokens.padding.normal * 2
                height: parent.height - Tokens.padding.normal * 2
                smooth: true

                onStatusChanged: {
                    if (status === Image.Error && retryTimer.retryCount < 3) {
                        retryTimer.start();
                    }
                }

                Timer {
                    id: retryTimer
                    property int retryCount: 0
                    interval: 300
                    onTriggered: {
                        retryCount++;
                        const oldSource = previewImage.source;
                        previewImage.source = "";
                        previewImage.source = oldSource;
                    }
                }
            }

            // Loading spinner
            StyledRect {
                visible: root.isImageEntry && (previewImage.status === Image.Loading || !imageContainer.imageReady)
                anchors.centerIn: parent
                width: 32
                height: 32
                radius: Tokens.rounding.full
                color: Colours.palette.m3surfaceContainerHigh

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "progress_activity"
                    font.pointSize: Tokens.font.size.normal
                    color: Colours.palette.m3primary

                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                    }
                }
            }

            // Error state
            MaterialIcon {
                visible: root.isImageEntry && previewImage.status === Image.Error
                anchors.centerIn: parent
                text: "broken_image"
                font.pointSize: Tokens.font.size.extraLarge
                color: Colours.palette.m3outline
            }
        }

        /* TEXT & BUTTONS ROW */
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: !root.isImageEntry
            spacing: Tokens.spacing.large

            // Icon
            MaterialIcon {
                text: root.isImageEntry ? "image" : "content_paste"
                font.pointSize: Tokens.font.size.extraLarge
                color: root.isImageEntry ? Colours.palette.m3tertiary : Colours.palette.m3primary
                Layout.alignment: Qt.AlignVCenter
            }

            // Text content
            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: root.displayText
                font.pointSize: Tokens.font.size.small
                elide: Text.ElideRight
                maximumLineCount: 1
                color: root.isImageEntry ? Colours.palette.m3outline : Colours.palette.m3onSurface
            }

            // Copy button
            StyledRect {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                radius: Tokens.rounding.small
                color: "transparent"

                StateLayer {
                    radius: parent.radius
                    color: Colours.palette.m3primary

                    onClicked: {
                        Quickshell.execDetached([
                            "sh", "-c",
                            "cliphist decode '" + root.entryId + "' | wl-copy && wl-paste"
                        ]);
                        copyFeedback.opacity = 1;
                        copyFeedbackTimer.start();
                    }
                }

                MaterialIcon {
                    id: copyIcon
                    anchors.centerIn: parent
                    text: "content_copy"
                    font.pointSize: Tokens.font.size.normal
                    color: Colours.palette.m3primary
                    opacity: copyFeedback.opacity === 0 ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            duration: Tokens.anim.durations.small
                        }
                    }
                }

                MaterialIcon {
                    id: copyFeedback
                    anchors.centerIn: parent
                    text: "check"
                    font.pointSize: Tokens.font.size.normal
                    color: Colours.palette.m3tertiary
                    opacity: 0

                    Behavior on opacity {
                        Anim {
                            duration: Tokens.anim.durations.small
                        }
                    }
                }

                Timer {
                    id: copyFeedbackTimer
                    interval: 800
                    onTriggered: copyFeedback.opacity = 0
                }
            }

            // Delete button
            StyledRect {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                radius: Tokens.rounding.small
                color: "transparent"

                StateLayer {
                    radius: parent.radius
                    color: Colours.palette.m3error

                    onClicked: {
                        Quickshell.execDetached(["cliphist", "delete", root.entryId]);
                        console.log("Deleted clip entry with ID:", root.entryId);
                        root.list.removeClipEntry(root.entryId);
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "delete"
                    font.pointSize: Tokens.font.size.normal
                    color: Colours.palette.m3error
                }
            }
        }
    }
}