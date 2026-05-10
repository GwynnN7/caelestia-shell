pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import Caelestia.Config
import Quickshell
import Quickshell.Io as Io
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property var modelData
    required property var list
    readonly property bool isImage: modelData?.isImage ?? false
    readonly property string entryId: modelData?.entryId ?? ""
    readonly property string entryText: modelData?.entryText ?? ""

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.small

    implicitWidth: 300
    implicitHeight: 400

    property string _decodingId: ""
    property bool imageReady: false
    property string decodedText: "" 

    readonly property string imagePath: "/tmp/cliphist-preview.png"

    onEntryIdChanged: {
        imageReady = false;
        decoder.running = false;
        decodedText = ""; 
        _decodingId = "";
        
        if (entryId !== "") {
            decodeDebounce.restart();
        }
    }

    Timer {
        id: decodeDebounce
        interval: 100 
        onTriggered: {
            if (root.entryId !== "") {
                root._decodingId = root.entryId;
                const escapedId = root.entryId.replace(/'/g, "'\\''");
                
                if (root.isImage) {
                    decoder.command = ["sh", "-c", "printf '%s' '" + escapedId + "' | cliphist decode > " + root.imagePath];
                } else {
                    decoder.command = ["sh", "-c", "printf '%s' '" + escapedId + "' | cliphist decode"];
                }
                decoder.running = true;
            }
        }
    }

    Io.Process {
        id: decoder
        
        stdout: Io.StdioCollector {
            onStreamFinished: {
                if (!root.isImage && root.entryId === root._decodingId && root.entryId !== "") {
                    root.decodedText = (this.text || "").trim();
                }
            }
        }

        onExited: (exitCode) => {
            if (exitCode === 0 && root.entryId === root._decodingId && root.entryId !== "") {
                if (root.isImage) {
                    syncTimer.restart();
                } 
            }
        }
    }

    Timer {
        id: syncTimer
        interval: 50
        onTriggered: root.imageReady = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.normal

            MaterialIcon {
                text: root.isImage ? "image" : "description"
                color: Colours.palette.m3primary
                font.pointSize: Tokens.font.size.normal
            }

            StyledText {
                text: root.isImage ? qsTr("Image Preview") : qsTr("Text Preview")
                font.pointSize: Tokens.font.size.normal
                font.weight: 600
                color: Colours.palette.m3onSurface
                Layout.fillWidth: true
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colours.tPalette.m3surfaceContainerLow
            radius: Tokens.rounding.small
            clip: true

            // Image Preview
            Image {
                visible: root.isImage
                anchors.fill: parent
                anchors.margins: Tokens.padding.normal
                source: (root.imageReady && root.entryId === root._decodingId) ? "file://" + root.imagePath + "?t=" + Date.now() : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                smooth: true
            }

            // Text Preview
            StyledFlickable {
                visible: !root.isImage
                anchors.fill: parent
                contentWidth: width
                contentHeight: previewText.implicitHeight
                clip: true

                StyledText {
                    id: previewText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.normal
                    
                    bottomPadding: Tokens.padding.large * 2 
                    
                    text: root.decodedText !== "" ? root.decodedText : root.entryText
                    
                    wrapMode: Text.Wrap 
                    elide: Text.ElideNone           
                    maximumLineCount: 99999         
                    
                    font.pointSize: Tokens.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            // Loading state for image
            StyledRect {
                visible: root.isImage && !root.imageReady
                anchors.fill: parent
                color: Colours.tPalette.m3surfaceContainerLow
                radius: Tokens.rounding.small

                StyledBusyIndicator {
                    anchors.centerIn: parent
                }
            }
        }
    }
}