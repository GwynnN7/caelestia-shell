pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property var panels
    required property real maxHeight
    required property real screenWidth

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: search.height + listWrapper.height + padding + search.anchors.bottomMargin

    Item {
        id: listWrapper

        implicitWidth: list.implicitWidth
        implicitHeight: list.implicitHeight + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            content: root
            visibilities: root.visibilities
            panels: root.panels
            maxHeight: root.maxHeight - search.implicitHeight - root.padding * 3
            screenWidth: root.screenWidth
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    SearchBar {
        id: search

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)

        placeholderText: qsTr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix)

        property string prevText: ""
        property var chatHistory: []
        property int chatHistoryIndex: -1
        property string tempInput: ""

        function updateChatHistoryFromModel() {
            var newHistory = [];
            var chatItem = (list && list.chatList && list.chatList.item);
            if (chatItem && chatItem.chatModel) {
                var model = chatItem.chatModel;
                for (var i = 0; i < model.count; i++) {
                    var msg = model.get(i);
                    if (msg && msg.sender === "user" && msg.text) {
                        var fullText = GlobalConfig.launcher.actionPrefix + "cortana " + msg.text.trim();
                        if (newHistory.length === 0 || newHistory[newHistory.length - 1] !== fullText) {
                            newHistory.push(fullText);
                        }
                    }
                }
            }
            chatHistory = newHistory;
        }

        onTextChanged: {
            const commands = ["cortana", "wallpaper", "windows", "keybinds", "animations", "emoji", "clipboard", "calc"];
            const prefix = GlobalConfig.launcher.actionPrefix;

            for (let cmd of commands) {
                const cmdText = prefix + cmd;
                const cmdTextSpace = cmdText + " ";

                if (text === cmdText) {
                    if (prevText === cmdTextSpace) {
                        text = "";
                    } else if (prevText.length < text.length) {
                        text = cmdTextSpace;
                    }
                    break;
                }
            }
            prevText = text;
        }

        onAccepted: {
            if (list.showChat) {
                const chatItem = (list && list.chatList && list.chatList.item);
                if (chatItem && chatItem.isGenerating) {
                    return;
                }
                const prefix = GlobalConfig.launcher.actionPrefix + "cortana ";
                const message = text.substring(prefix.length).trim();
                if (message.length > 0 && chatItem) {
                    chatHistoryIndex = -1;
                    tempInput = "";
                    chatItem.sendMessage(message);
                    text = prefix;
                }
                return;
            }

            const currentItem = list.currentList?.currentItem;
            if (currentItem) {
                if (list.showWallpapers) {
                    if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                        Wallpapers.previewColourLock = true;
                    Wallpapers.setWallpaper(currentItem.modelData.path);
                    root.visibilities.launcher = false;
                } else if (text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                    if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}calc `))
                        currentItem.onClicked();
                    else if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}emoji `) || text.startsWith(`${GlobalConfig.launcher.actionPrefix}clipboard `) || text.startsWith(`${GlobalConfig.launcher.actionPrefix}windows `) || text.startsWith(`${GlobalConfig.launcher.actionPrefix}keybinds `) || text.startsWith(`${GlobalConfig.launcher.actionPrefix}animations `))
                        currentItem.clicked();
                    else
                        currentItem.modelData.onClicked(list.currentList);
                } else {
                    Apps.launch(currentItem.modelData);
                    root.visibilities.launcher = false;
                }
            }
        }

        Keys.onUpPressed: {
            if (list.showChat) {
                if (chatHistoryIndex === -1) {
                    updateChatHistoryFromModel();
                    tempInput = text;
                    chatHistoryIndex = chatHistory.length - 1;
                } else if (chatHistoryIndex > 0) {
                    chatHistoryIndex--;
                }
                if (chatHistoryIndex >= 0 && chatHistoryIndex < chatHistory.length) {
                    text = chatHistory[chatHistoryIndex];
                    cursorPosition = text.length;
                }
            } else {
                list.currentList?.decrementCurrentIndex();
            }
        }

        Keys.onDownPressed: {
            if (list.showChat) {
                if (chatHistoryIndex !== -1) {
                    if (chatHistoryIndex === chatHistory.length - 1) {
                        chatHistoryIndex = -1;
                        text = tempInput;
                        cursorPosition = text.length;
                    } else if (chatHistoryIndex < chatHistory.length - 1) {
                        chatHistoryIndex++;
                        text = chatHistory[chatHistoryIndex];
                        cursorPosition = text.length;
                    }
                }
            } else {
                list.currentList?.incrementCurrentIndex();
            }
        }

        Keys.onEscapePressed: root.visibilities.launcher = false

        Keys.onPressed: event => {
            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                list.currentList?.incrementCurrentIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                list.currentList?.decrementCurrentIndex();
                event.accepted = true;
            }
        }

        Component.onCompleted: {
            if (Visibilities.launcherInitialSearch) {
                text = Visibilities.launcherInitialSearch;
                Visibilities.launcherInitialSearch = "";
            }
            forceActiveFocus();
        }

        Connections {
            function onLauncherChanged(): void {
                if (root.visibilities.launcher) {
                    search.forceActiveFocus();
                    if (Visibilities.launcherInitialSearch) {
                        search.text = Visibilities.launcherInitialSearch;
                        Visibilities.launcherInitialSearch = "";
                    }
                } else {
                    search.text = "";
                    search.chatHistoryIndex = -1;
                    search.tempInput = "";
                }
            }

            function onSessionChanged(): void {
                if (!root.visibilities.session)
                    search.forceActiveFocus();
            }

            target: root.visibilities
        }

        clearIcon.anchors.rightMargin: list.showChat ? (Tokens.padding.medium + sendBtn.width + Tokens.spacing.medium) : Tokens.padding.medium

        IconButton {
            id: sendBtn

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: list.showChat ? Tokens.padding.medium : 0

            width: list.showChat ? 36 : 0
            height: list.showChat ? 36 : 0
            scale: list.showChat ? (disabled ? 0.85 : (hovered ? 1.08 : 1.0)) : 0
            opacity: list.showChat ? (disabled ? 0.35 : 1.0) : 0
            visible: opacity > 0

            isRound: true
            type: IconButton.Filled
            icon: {
                const chatItem = (list && list.chatList && list.chatList.item);
                return (chatItem && chatItem.isGenerating) ? "stop" : "rocket_launch";
            }
            label.rotation: {
                const chatItem = (list && list.chatList && list.chatList.item);
                return (chatItem && chatItem.isGenerating) ? 0 : 45;
            }
            disabled: {
                const chatItem = (list && list.chatList && list.chatList.item);
                if (chatItem && chatItem.isGenerating) {
                    return false;
                }
                const prefix = GlobalConfig.launcher.actionPrefix + "cortana ";
                return search.text.substring(prefix.length).trim().length === 0;
            }

            onClicked: {
                const chatItem = (list && list.chatList && list.chatList.item);
                if (chatItem && chatItem.isGenerating) {
                    chatItem.stopGeneration();
                } else {
                    const prefix = GlobalConfig.launcher.actionPrefix + "cortana ";
                    const message = search.text.substring(prefix.length).trim();
                    if (message.length > 0 && chatItem) {
                        search.chatHistoryIndex = -1;
                        search.tempInput = "";
                        chatItem.sendMessage(message);
                        search.text = prefix;
                        search.forceActiveFocus();
                    }
                }
            }

            Behavior on scale {
                Anim {
                    type: Anim.StandardSmall
                }
            }
            Behavior on width {
                Anim {
                    type: Anim.StandardSmall
                }
            }
            Behavior on height {
                Anim {
                    type: Anim.StandardSmall
                }
            }
            Behavior on opacity {
                Anim {
                    type: Anim.StandardSmall
                }
            }
        }
    }
}
