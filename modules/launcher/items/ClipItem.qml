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

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.small

        onClicked: {
            root.onClicked();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        spacing: Tokens.spacing.large

       MaterialIcon {
            text: root.isImageEntry ? "image" : "content_paste"
            font.pointSize: Tokens.font.size.large
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
