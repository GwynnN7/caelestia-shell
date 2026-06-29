pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.images
import qs.utils
import qs.services
import qs.modules.nexus.common
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Caelestia

PageBase {
    id: root

    title: qsTr("Cortana AI")
    isSubPage: true

    ColumnLayout {
        id: layout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Model Settings")
        }

        StyledRect {
            width: parent.width
            height: 96
            radius: Tokens.rounding.large
            color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
            border.width: 0

            MaterialIcon {
                id: contextWindowIcon
                anchors.left: parent.left
                anchors.leftMargin: Tokens.padding.medium
                anchors.verticalCenter: parent.verticalCenter
                text: "settings_overscan"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            Column {
                anchors.left: contextWindowIcon.right
                anchors.right: parent.right
                anchors.leftMargin: Tokens.spacing.medium
                anchors.rightMargin: Tokens.padding.medium
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.spacing.large

                Item {
                    width: parent.width
                    height: 20

                    StyledText {
                        anchors.left: parent.left
                        text: "Context Window"
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        anchors.right: parent.right
                        text: (GlobalConfig.ai.contextWindow >= 1024 ? Math.round(GlobalConfig.ai.contextWindow / 1024) + "k" : GlobalConfig.ai.contextWindow) + " tokens"
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                StyledSlider {
                    id: contextWindowSlider
                    width: parent.width
                    from: 2048
                    to: 131072
                    value: GlobalConfig.ai.contextWindow
                    onInteraction: v => {
                        var val = contextWindowSlider.from + v * (contextWindowSlider.to - contextWindowSlider.from);
                        GlobalConfig.ai.contextWindow = Math.round(val / 2048) * 2048;
                    }
                }
            }
        }

        StyledRect {
            width: parent.width
            implicitHeight: promptColumn.implicitHeight + Tokens.padding.medium * 2
            radius: Tokens.rounding.large
            color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
            border.width: 0

            Column {
                id: promptColumn
                width: parent.width - Tokens.padding.medium * 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.spacing.small

                Row {
                    width: parent.width
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "description"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.medium
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "System Prompt"
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                StyledText {
                    text: "Customize the rules and persona for Cortana."
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                    width: parent.width
                    wrapMode: Text.WordWrap
                }

                StyledRect {
                    width: parent.width
                    height: 180
                    radius: Tokens.rounding.medium
                    color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    Flickable {
                        id: promptFlickable
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        clip: true
                        contentHeight: promptTextEdit.implicitHeight
                        contentWidth: width

                        TextEdit {
                            id: promptTextEdit
                            width: promptFlickable.width
                            wrapMode: TextEdit.Wrap
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurface
                            selectionColor: Colours.palette.m3primary
                            selectedTextColor: Colours.palette.m3onPrimary
                            selectByMouse: true
                            text: GlobalConfig.ai.systemPrompt

                            onTextChanged: {
                                if (activeFocus) {
                                    root.hasUnsavedPromptChanges = true;
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 40

                    StyledText {
                        id: promptSaveStatusText
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.hasUnsavedPromptChanges ? "Unsaved changes" : "Saved in memory"
                        font: Tokens.font.body.small
                        color: root.hasUnsavedPromptChanges ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    }

                    IconTextButton {
                        id: saveButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Save"
                        icon: "save"
                        type: ButtonBase.Filled
                        onClicked: {
                            GlobalConfig.ai.systemPrompt = promptTextEdit.text;
                            root.hasUnsavedPromptChanges = false;
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Agent Tools & Capabilities")
        }

        ToggleRow {
            first: true
            text: qsTr("Date and time")
            subtext: qsTr("Allow Cortana to access the current date and time")
            checked: GlobalConfig.ai.agentDateTime
            onToggled: GlobalConfig.ai.agentDateTime = checked
        }

        ToggleRow {
            text: qsTr("Location")
            subtext: qsTr("Allow Cortana to access system location")
            checked: GlobalConfig.ai.agentLocation
            onToggled: GlobalConfig.ai.agentLocation = checked
        }

        ToggleRow {
            text: qsTr("Web search")
            subtext: qsTr("Allow Cortana to perform web searches")
            checked: GlobalConfig.ai.agentWebSearch
            onToggled: GlobalConfig.ai.agentWebSearch = checked
        }

        ToggleRow {
            text: qsTr("Read webpage")
            subtext: qsTr("Allow Cortana to fetch and read specific URLs")
            checked: GlobalConfig.ai.agentReadWebpage
            onToggled: GlobalConfig.ai.agentReadWebpage = checked
        }

        ToggleRow {
            text: qsTr("Get weather")
            subtext: qsTr("Allow Cortana to check the weather forecast")
            checked: GlobalConfig.ai.agentGetWeather
            onToggled: GlobalConfig.ai.agentGetWeather = checked
        }

        ToggleRow {
            text: qsTr("Take screenshot")
            subtext: qsTr("Allow Cortana to capture and view your screen")
            checked: GlobalConfig.ai.agentTakeScreenshot
            onToggled: GlobalConfig.ai.agentTakeScreenshot = checked
        }

        ToggleRow {
            text: qsTr("Open app")
            subtext: qsTr("Allow Cortana to launch installed desktop apps")
            checked: GlobalConfig.ai.agentOpenApp
            onToggled: GlobalConfig.ai.agentOpenApp = checked
        }

        ToggleRow {
            text: qsTr("Set timer")
            subtext: qsTr("Allow Cortana to create system background timers")
            checked: GlobalConfig.ai.agentSetTimer
            onToggled: GlobalConfig.ai.agentSetTimer = checked
        }

        

        ToggleRow {
            text: qsTr("Caelestia command")
            subtext: qsTr("Allow Cortana to execute Caelestia commands")
            checked: GlobalConfig.ai.agentCaelestiaCommand
            onToggled: GlobalConfig.ai.agentCaelestiaCommand = checked
        }

        ToggleRow {
            text: qsTr("Cortana API")
            subtext: qsTr("Allow Cortana to access the Cortana API")
            checked: GlobalConfig.ai.agentCortanaApi
            onToggled: GlobalConfig.ai.agentCortanaApi = checked
        }

        ToggleRow {
            text: qsTr("Run command")
            subtext: qsTr("Allow Cortana to run arbitrary bash commands (Dangerous)")
            checked: GlobalConfig.ai.agentRunCommand
            onToggled: GlobalConfig.ai.agentRunCommand = checked
        }

        ToggleRow {
            last: true
            text: qsTr("File operations")
            subtext: qsTr("Allow Cortana to read and write local files (Dangerous)")
            checked: GlobalConfig.ai.agentFileOps
            onToggled: GlobalConfig.ai.agentFileOps = checked
        }
    }
}