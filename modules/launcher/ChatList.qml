pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property SearchBar search
    required property DrawerVisibilities visibilities
    required property real screenWidth
    required property real maxHeight

    implicitHeight: GlobalConfig.launcher.aiDefaultHeight
    implicitWidth: parent ? parent.width : GlobalConfig.launcher.aiDefaultWidth
    property real calculatedFooterHeight: 0

    property bool expanded: GlobalConfig.launcher.aiFullScreen
    property bool userScrolledUp: false
    property bool isAutoScrolling: false
    property string hoverLinkUrl: ""
    property bool isResizing: false
    property bool hasUnsavedPromptChanges: false

    property var aiController: sharedAiController

    property string currentView: "chat"

    readonly property alias currentList: listView
    property bool isGenerating: aiController.isGenerating

    onWidthChanged: {
        isResizing = true;
        resizeTimer.restart();
    }

    Timer {
        id: resizeTimer
        interval: 200
        onTriggered: root.isResizing = false
    }

    onIsGeneratingChanged: {
        if (!isGenerating && root.visibilities && !root.visibilities.launcher) {
            Quickshell.execDetached(["sh", "-c", "echo '" + GlobalConfig.ai.activeModel + " finished generating response' | cortana notify"]);
        }
    }

    onCurrentViewChanged: {
        if (currentView === "settings") {
            promptTextEdit.text = GlobalConfig.ai.systemPrompt;
            hasUnsavedPromptChanges = false;
        } else if (currentView === "chat") {
            Qt.callLater(() => {
                root.smartScroll();
            });
        }
    }

    function smartScroll() {
        if (!root.userScrolledUp) {
            root.isAutoScrolling = true;
            listView.positionViewAtEnd();
            Qt.callLater(function () {
                root.isAutoScrolling = false;
            });
        }
    }

    function sendMessage(text) {
        if (!text || text.trim() === "")
            return;
        root.userScrolledUp = false;
        let userIndex = aiController.sendMessage(text);
        Qt.callLater(function () {
            listView.positionViewAtIndex(userIndex, ListView.Beginning);
        });
    }

    function stopGeneration() {
        aiController.stopGeneration();
    }

    function calculateFooterHeight() {
        if (!listView || !listView.contentItem)
            return 0;
        var lastUserIndex = -1;
        for (var i = aiController.chatModel.count - 1; i >= 0; i--) {
            var item = aiController.chatModel.get(i);
            if (item && item.sender === "user") {
                lastUserIndex = i;
                break;
            }
        }
        if (lastUserIndex === -1)
            return 0;

        var heightBelowUser = 0;
        for (var c = 0; c < listView.contentItem.children.length; c++) {
            var child = listView.contentItem.children[c];
            if (child && child.hasOwnProperty("index")) {
                if (child.index >= lastUserIndex) {
                    heightBelowUser += child.height + listView.spacing;
                }
            }
        }
        if (heightBelowUser > 0)
            heightBelowUser -= listView.spacing;
        return Math.max(0, listView.height - heightBelowUser);
    }

    Component {
        id: menuItemComponent
        MenuItem {}
    }

    Component {
        id: textBlockComponent
        TextEdit {
            id: textEdit
            property var blockData: null
            property bool isUserMsg: false
            property string processedText: ""
            property bool loading: false

            text: processedText
            color: isUserMsg ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            selectedTextColor: isUserMsg ? Colours.palette.m3primaryContainer : Colours.palette.m3onPrimary
            selectionColor: isUserMsg ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3primary
            wrapMode: TextEdit.WordWrap
            width: parent ? parent.width : 0

            textFormat: loading ? TextEdit.MarkdownText : TextEdit.RichText
            font: Tokens.font.body.medium
            readOnly: true
            selectByMouse: true
            cursorVisible: false

            onLinkActivated: link => Qt.openUrlExternally(link)
            onLinkHovered: link => {
                root.hoverLinkUrl = link;
            }

            function updateText() {
                if (!blockData || !blockData.content) {
                    processedText = "";
                    return;
                }
                var content = blockData.content;
                if (loading) {
                    processedText = content;
                    return;
                }
                var colorStr = isUserMsg ? (Colours.palette.m3onPrimaryContainer + "") : (Colours.palette.m3onSurface + "");
                var html = aiController.markdownToHtml(content, colorStr);
                processedText = aiController.processInlineMathHtml(html, colorStr, isUserMsg, function () {
                    if (textEdit) {
                        textEdit.updateText();
                    }
                });
            }

            onBlockDataChanged: updateText()
            onLoadingChanged: updateText()
            Component.onCompleted: updateText()

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
            }
        }
    }

    Component {
        id: codeBlockComponent
        StyledRect {
            property var blockData: null
            readonly property string lang: blockData ? (blockData.language || "code").toLowerCase() : "code"

            implicitWidth: 10000
            width: parent ? parent.width : 0
            height: codeHeader.height + codeBody.height

            color: Qt.tint(Colours.palette.m3surfaceContainerLowest, Qt.rgba(Colours.palette.m3primary.r, Colours.palette.m3primary.g, Colours.palette.m3primary.b, 0.08))
            radius: Tokens.rounding.medium
            clip: true

            Rectangle {
                id: codeHeader
                width: parent.width
                height: 32
                color: Qt.tint(Colours.palette.m3surfaceContainerLow, Qt.rgba(Colours.palette.m3primary.r, Colours.palette.m3primary.g, Colours.palette.m3primary.b, 0.13))
                radius: Tokens.rounding.medium

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.spacing.medium
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.extraSmall

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: Colours.palette.m3primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: (lang === "code" ? "plaintext" : lang).toUpperCase()
                        font.pixelSize: Tokens.font.label.small.pixelSize
                        font.family: "monospace"
                        font.weight: Font.Medium
                        color: Colours.palette.m3primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                IconButton {
                    id: codeCopyBtn
                    property bool copied: false
                    icon: copied ? "check" : "content_copy"
                    type: IconButton.Text
                    width: 24
                    height: 24
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.spacing.small
                    anchors.verticalCenter: parent.verticalCenter
                    activeOnColour: Colours.palette.m3primary
                    inactiveOnColour: Colours.palette.m3onSurfaceVariant

                    onClicked: {
                        if (blockData) {
                            Quickshell.clipboardText = blockData.content;
                            Toaster.toast("Code copied", "Snippet copied to clipboard", "content_copy");
                            copied = true;
                            codeRevertTimer.start();
                        }
                    }

                    Timer {
                        id: codeRevertTimer
                        interval: 1500
                        onTriggered: codeCopyBtn.copied = false
                    }
                }
            }

            Item {
                id: codeBody
                width: parent.width
                anchors.top: codeHeader.bottom
                height: codeText.implicitHeight + Tokens.padding.medium * 2

                TextEdit {
                    id: codeText
                    text: blockData ? aiController.highlightCode(blockData.content, lang) : ""
                    textFormat: TextEdit.RichText
                    font.family: "monospace"
                    font.pixelSize: Tokens.font.body.small.pixelSize
                    color: Colours.palette.m3onSurface
                    selectedTextColor: Colours.palette.m3onPrimary
                    selectionColor: Colours.palette.m3primary
                    wrapMode: TextEdit.WrapAnywhere
                    readOnly: true
                    selectByMouse: true
                    cursorVisible: false
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium

                    onLinkActivated: link => Qt.openUrlExternally(link)
                    onLinkHovered: link => {
                        root.hoverLinkUrl = link;
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
                    }
                }
            }
        }
    }

    Component {
        id: mathBlockComponent
        Item {
            id: mathBlock
            property var blockData: null
            property bool isUserMsg: false
            property string imagePath: ""
            property bool rendering: true
            property string lastCacheKey: ""
            property bool loading: false

            implicitWidth: mathImage.visible ? mathImage.implicitWidth + 16 : 120
            width: parent ? parent.width : 0
            readonly property int vGap: 6
            height: loading ? Math.max(30, rawMathText.implicitHeight) + vGap * 2 : (rendering ? 40 + vGap * 2 : Math.max(30, mathImage.implicitHeight + 16) + vGap * 2)

            function updateMath() {
                if (!blockData || !blockData.content || loading) {
                    imagePath = "";
                    rendering = false;
                    lastCacheKey = "";
                    return;
                }

                var colorStr = isUserMsg ? (Colours.palette.m3onPrimaryContainer + "") : (Colours.palette.m3onSurface + "");
                var currentLatex = blockData.content;
                var cacheKey = currentLatex + "|" + colorStr;
                if (cacheKey === lastCacheKey) {
                    if (imagePath !== "") {
                        rendering = false;
                    }
                    return;
                }

                imagePath = "";
                rendering = true;
                lastCacheKey = cacheKey;

                var scriptPath = `${Quickshell.shellDir}/scripts/render_math.py`;
                aiController.runCommand([scriptPath, currentLatex, colorStr, "9"], function (stdout) {
                    if (!mathBlock)
                        return;
                    var path = stdout.trim();
                    if (path.indexOf("/tmp") === 0) {
                        mathBlock.imagePath = "file://" + path;
                        mathBlock.rendering = false;
                    } else {
                        console.log("Math rendering error: " + stdout);
                        mathBlock.rendering = false;
                    }
                });
            }

            onBlockDataChanged: updateMath()
            onLoadingChanged: updateMath()
            Component.onCompleted: updateMath()

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: mathBlock.vGap
                anchors.bottomMargin: mathBlock.vGap
                color: "transparent"

                Text {
                    id: rawMathText
                    anchors.centerIn: parent
                    text: blockData ? "$$" + blockData.content + "$$" : ""
                    color: isUserMsg ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    font: Tokens.font.body.medium
                    visible: mathBlock.loading
                    wrapMode: Text.WordWrap
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    id: loadingText
                    anchors.centerIn: parent
                    text: "Rendering expression..."
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    visible: !mathBlock.loading && mathBlock.rendering
                }

                Image {
                    id: mathImage
                    anchors.centerIn: parent
                    source: mathBlock.imagePath
                    visible: !mathBlock.loading && !mathBlock.rendering && mathBlock.imagePath !== ""
                    fillMode: Image.PreserveAspectFit
                    cache: true
                    asynchronous: true
                }
            }
        }
    }

    Item {
        id: headerBar
        anchors.top: parent.top
        anchors.topMargin: Tokens.spacing.extraSmall / 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Tokens.spacing.small
        anchors.rightMargin: Tokens.spacing.small
        height: 40

        StyledRect {
            id: segmentControl
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 200
            height: parent.height
            radius: Tokens.rounding.full
            color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
            border.width: 0
            border.color: "transparent"

            StyledRect {
                id: activeIndicator
                x: root.currentView === "chat" ? 4 : (parent.width / 2 + 4)
                y: 2
                width: parent.width / 2 - 6
                height: parent.height - 6
                radius: Tokens.rounding.full
                color: Colours.palette.m3secondaryContainer

                Behavior on x {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Row {
                anchors.fill: parent
                spacing: 0

                Item {
                    width: parent.width / 2
                    height: parent.height
                    Row {
                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall
                        MaterialIcon {
                            text: "chat"
                            fontStyle: Tokens.font.icon.small
                            color: root.currentView === "chat" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: "Chat"
                            font: Tokens.font.label.medium
                            color: root.currentView === "chat" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentView = "chat"
                    }
                }

                Item {
                    width: parent.width / 2
                    height: parent.height
                    Row {
                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall
                        MaterialIcon {
                            text: "history"
                            fontStyle: Tokens.font.icon.small
                            color: root.currentView !== "chat" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: "History"
                            font: Tokens.font.label.medium
                            color: root.currentView !== "chat" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentView = "history"
                    }
                }
            }
        }

        IconButton {
            id: expandBtn
            anchors.left: segmentControl.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: parent.verticalCenter
            icon: GlobalConfig.launcher.aiFullScreen ? "close_fullscreen" : "open_in_full"
            width: 38
            height: parent.height
            isRound: true
            activeColour: Colours.palette.m3primary
            inactiveColour: Colours.layer(Colours.palette.m3surfaceContainer, 1)
            activeOnColour: Colours.palette.m3onPrimary
            inactiveOnColour: Colours.palette.m3onSurfaceVariant
            checked: GlobalConfig.launcher.aiFullScreen
            onClicked: GlobalConfig.launcher.aiFullScreen = !GlobalConfig.launcher.aiFullScreen
        }

        Row {
            id: modelsRowWrapper
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            spacing: Tokens.spacing.medium
            visible: opacity > 0
            opacity: root.currentView === "chat" ? 1 : 0
            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            SplitButton {
                id: modelFamilySelector

                type: SplitButton.Tonal
                active: menuItems.find(m => m.modelData === aiController.selectedModelFamily) ?? menuItems[0] ?? null
                menu.onItemSelected: item => {
                    aiController.setModelFamily(item.modelData);
                }
                menuItems: modelFamilyVariants.instances
                fallbackIcon: "smart_toy"
                fallbackText: qsTr("Family")

                Variants {
                    id: modelFamilyVariants
                    model: aiController.modelFamilies
                    delegate: MenuItem {
                        required property string modelData
                        text: modelData
                    }
                }
            }

            SplitButton {
                id: modelVariantSelector

                type: SplitButton.Tonal
                active: menuItems.find(m => m.modelData.fullModel === aiController.selectedModelVariant) ?? menuItems[0] ?? null
                enabled: aiController.selectedModelVariants.length > 0
                menu.onItemSelected: item => {
                    aiController.setModelVariant(item.modelData.fullModel);
                }
                menuItems: modelSizeVariants.instances
                fallbackIcon: "tune"
                fallbackText: qsTr("Variant")

                Variants {
                    id: modelSizeVariants
                    model: aiController.selectedModelVariants
                    delegate: MenuItem {
                        required property var modelData
                        text: modelData.label
                    }
                }
            }
        }

        Row {
            id: historyHeaderControls
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.medium
            visible: opacity > 0
            opacity: root.currentView === "history" ? 1 : 0
            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            StyledRect {
                id: viewTogglePill
                width: 76
                height: 38
                radius: Tokens.rounding.full
                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                border.width: 0
                border.color: "transparent"
                anchors.verticalCenter: parent.verticalCenter

                StyledRect {
                    id: viewActiveIndicator
                    x: GlobalConfig.launcher.aiHistoryGridView ? 3 : 39
                    y: 3
                    width: 34
                    height: 32
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3secondaryContainer
                    Behavior on x {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Row {
                    anchors.fill: parent
                    spacing: 0
                    Item {
                        width: 38
                        height: 38
                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "grid_view"
                            fontStyle: Tokens.font.icon.small
                            color: GlobalConfig.launcher.aiHistoryGridView ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: GlobalConfig.launcher.aiHistoryGridView = true
                        }
                    }
                    Item {
                        width: 38
                        height: 38
                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "view_list"
                            fontStyle: Tokens.font.icon.small
                            color: !GlobalConfig.launcher.aiHistoryGridView ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: GlobalConfig.launcher.aiHistoryGridView = false
                        }
                    }
                }
            }

            IconButton {
                icon: "settings"
                width: 38
                height: 38
                isRound: true
                activeColour: Colours.palette.m3primary
                inactiveColour: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                activeOnColour: Colours.palette.m3onPrimary
                inactiveOnColour: Colours.palette.m3onSurfaceVariant
                onClicked: root.currentView = "settings"
            }

            IconTextButton {
                icon: "add"
                text: "New Chat"
                isRound: true
                type: ButtonBase.Filled
                onClicked: {
                    aiController.createNewChat();
                    root.currentView = "chat";
                }
            }
        }
    }

    Item {
        id: chatView
        anchors.top: headerBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: opacity > 0
        opacity: root.currentView === "chat" ? 1 : 0
        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        StyledListView {
            id: listView
            cacheBuffer: 2000
            anchors.fill: parent
            anchors.leftMargin: Tokens.spacing.medium
            anchors.topMargin: Tokens.spacing.medium
            anchors.bottomMargin: Tokens.spacing.medium
            anchors.rightMargin: 4
            model: aiController.chatModel
            spacing: Tokens.spacing.medium
            clip: true

            onContentHeightChanged: Qt.callLater(function () {
                root.calculatedFooterHeight = root.calculateFooterHeight();
            })
            onHeightChanged: Qt.callLater(function () {
                root.calculatedFooterHeight = root.calculateFooterHeight();
            })

            Component.onCompleted: {
                Qt.callLater(function () {
                    listView.positionViewAtEnd();
                });
            }

            footer: Item {
                width: listView.width
                height: root.calculatedFooterHeight
            }

            onContentYChanged: {
                if (!root.isAutoScrolling) {
                    var dist = contentHeight - contentY - height;
                    root.userScrolledUp = dist > 30;
                }
            }

            onCountChanged: {
                root.smartScroll();
            }

            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.95
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            delegate: Item {
                id: delegateItem
                width: listView.width
                height: column.implicitHeight

                required property bool loading
                required property int index
                required property string sender
                required property string text
                required property string thinking

                readonly property bool isUser: sender === "user"
                readonly property bool isStatusText: text.trim() === "" || text.startsWith("🔍") || text.startsWith("🌐") || text.startsWith("💻") || text.startsWith("📖") || text.startsWith("✍️") || text.startsWith("⚙️")

                property string messageModelUsed: (index >= 0 && index < aiController.chatModel.count && aiController.chatModel.get(index)) ? (aiController.chatModel.get(index).modelUsed || "") : ""

                Column {
                    id: column
                    width: parent.width
                    spacing: Tokens.spacing.extraSmall

                    Row {
                        width: parent.width
                        layoutDirection: delegateItem.isUser ? Qt.RightToLeft : Qt.LeftToRight

                        StyledRect {
                            id: bubbleWrapper
                            color: delegateItem.isUser ? Colours.palette.m3primaryContainer : Colours.layer(Colours.palette.m3surfaceContainer, 1)
                            radius: Tokens.rounding.large
                            border.width: 0
                            border.color: "transparent"

                            width: {
                                var maxW = 120;
                                for (var i = 0; i < bubbleColumn.children.length; i++) {
                                    var child = bubbleColumn.children[i];
                                    if (child.visible && child.hasOwnProperty("blockWidth")) {
                                        if (child.blockWidth > maxW)
                                            maxW = child.blockWidth;
                                    }
                                }
                                if (delegateItem.loading && typeof streamingView !== "undefined") {
                                    for (var j = 0; j < streamingView.children.length; j++) {
                                        var schild = streamingView.children[j];
                                        if (schild.visible) {
                                            if (schild.hasOwnProperty("blockWidth")) {
                                                if (schild.blockWidth > maxW)
                                                    maxW = schild.blockWidth;
                                            } else if (schild.hasOwnProperty("text")) {
                                                if (schild.implicitWidth > maxW)
                                                    maxW = schild.implicitWidth;
                                            }
                                        }
                                    }
                                }
                                var paddedWidth = maxW + Tokens.padding.medium * 2 + (delegateItem.loading ? 24 : 0);
                                return Math.min(listView.width * 0.85, Math.max(120, paddedWidth));
                            }
                            height: bubbleColumn.implicitHeight + (delegateItem.loading ? Tokens.padding.small * 2 : Tokens.padding.medium * 2)

                            Behavior on width {
                                enabled: !root.isResizing && chatView.opacity === 1
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on height {
                                enabled: chatView.opacity === 1
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }

                            MouseArea {
                                id: hoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }

                            Column {
                                id: bubbleColumn
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.topMargin: delegateItem.loading ? Tokens.padding.small : Tokens.padding.medium
                                anchors.leftMargin: Tokens.padding.medium
                                anchors.rightMargin: Tokens.padding.medium + 20 + (delegateItem.loading ? 24 : 0)
                                anchors.bottomMargin: delegateItem.loading ? Tokens.padding.small : Tokens.padding.medium
                                topPadding: 0
                                spacing: Tokens.spacing.small

                                property bool isExpanded: false

                                Item {
                                    visible: delegateItem.thinking !== ""
                                    readonly property real blockWidth: thoughtRow.implicitWidth
                                    implicitWidth: thoughtRow.implicitWidth
                                    implicitHeight: thoughtRow.implicitHeight
                                    height: visible ? implicitHeight : 0

                                    Row {
                                        id: thoughtRow
                                        spacing: Tokens.spacing.small
                                        StyledText {
                                            text: "Thought Process"
                                            color: Colours.palette.m3onSurfaceVariant
                                            font: Tokens.font.body.small
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        MaterialIcon {
                                            id: thoughtArrow
                                            text: "expand_more"
                                            color: Colours.palette.m3onSurfaceVariant
                                            fontStyle: Tokens.font.icon.small
                                            rotation: bubbleColumn.isExpanded ? 180 : 0
                                            anchors.verticalCenter: parent.verticalCenter
                                            Behavior on rotation {
                                                NumberAnimation {
                                                    duration: 150
                                                    easing.type: Easing.OutQuad
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: bubbleColumn.isExpanded = !bubbleColumn.isExpanded
                                    }
                                }

                                Item {
                                    id: thoughtContentWrapper
                                    readonly property real blockWidth: bubbleColumn.isExpanded ? thoughtContent.implicitWidth : 0
                                    width: thoughtContent.width
                                    height: bubbleColumn.isExpanded ? thoughtContent.implicitHeight : 0
                                    clip: true
                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.InOutQuad
                                        }
                                    }

                                    TextEdit {
                                        id: thoughtContent
                                        width: Math.min(implicitWidth, listView.width * 0.85 - Tokens.padding.medium * 2)
                                        textFormat: Text.MarkdownText
                                        text: delegateItem.thinking
                                        color: Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.body.small
                                        wrapMode: Text.Wrap
                                        readOnly: true
                                        selectByMouse: true
                                        selectionColor: Colours.palette.m3primary
                                        selectedTextColor: Colours.palette.m3onPrimary
                                        opacity: bubbleColumn.isExpanded ? 1.0 : 0.0

                                        Behavior on opacity {
                                            SequentialAnimation {
                                                PauseAnimation {
                                                    duration: bubbleColumn.isExpanded ? 100 : 0
                                                }
                                                NumberAnimation {
                                                    duration: 150
                                                    easing.type: Easing.InOutQuad
                                                }
                                            }
                                        }
                                    }
                                }

                                Row {
                                    id: thinkingRow
                                    visible: delegateItem.isStatusText
                                    spacing: Tokens.spacing.medium
                                    height: 20
                                    readonly property real blockWidth: implicitWidth

                                    LoadingIndicator {
                                        width: 16
                                        height: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: thinkingRow.visible
                                        animated: thinkingRow.visible
                                        color: Colours.palette.m3onSurfaceVariant
                                    }
                                    StyledText {
                                        text: "Cortana is thinking..."
                                        font: Tokens.font.body.medium
                                        color: Colours.palette.m3onSurfaceVariant
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    SequentialAnimation {
                                        running: thinkingRow.visible
                                        loops: Animation.Infinite
                                        NumberAnimation {
                                            target: thinkingRow
                                            property: "opacity"
                                            from: 1.0
                                            to: 0.4
                                            duration: 800
                                            easing.type: Easing.InOutSine
                                        }
                                        NumberAnimation {
                                            target: thinkingRow
                                            property: "opacity"
                                            from: 0.4
                                            to: 1.0
                                            duration: 800
                                            easing.type: Easing.InOutSine
                                        }
                                        onRunningChanged: {
                                            if (!running) {
                                                thinkingRow.opacity = 1.0;
                                            }
                                        }
                                    }
                                }

                                Repeater {
                                    model: delegateItem.loading ? [] : aiController.parseMessageBlocks(delegateItem.text)
                                    Item {
                                        id: blockHolder
                                        required property var modelData
                                        readonly property bool isUserMsg: delegateItem.isUser
                                        readonly property real blockWidth: blockLoader.item ? blockLoader.item.implicitWidth : 0
                                        width: bubbleColumn.width
                                        height: blockLoader.item ? blockLoader.item.height : 0

                                        Loader {
                                            id: blockLoader
                                            width: parent.width
                                            sourceComponent: blockHolder.modelData.type === "code" ? codeBlockComponent : (blockHolder.modelData.type === "math" ? mathBlockComponent : textBlockComponent)
                                            onLoaded: {
                                                item.blockData = blockHolder.modelData;
                                                if (item.hasOwnProperty("isUserMsg"))
                                                    item.isUserMsg = blockHolder.isUserMsg;
                                                if (item.hasOwnProperty("loading"))
                                                    item.loading = Qt.binding(function () {
                                                        return delegateItem.loading;
                                                    });
                                            }
                                        }
                                    }
                                }

                                Column {
                                    id: streamingView
                                    visible: delegateItem.loading && !delegateItem.isStatusText
                                    width: parent.width
                                    spacing: Tokens.spacing.small

                                    property var streamSplit: delegateItem.loading ? aiController.parseStreamingBlocks(delegateItem.text) : {
                                        committed: "",
                                        tail: ""
                                    }

                                    Repeater {
                                        model: streamingView.streamSplit.committed !== "" ? aiController.parseMessageBlocks(streamingView.streamSplit.committed) : []
                                        Item {
                                            id: committedHolder
                                            required property var modelData
                                            readonly property bool isUserMsg: delegateItem.isUser
                                            readonly property real blockWidth: committedLoader.item ? committedLoader.item.implicitWidth : 0
                                            width: streamingView.width
                                            height: committedLoader.item ? committedLoader.item.height : 0

                                            Loader {
                                                id: committedLoader
                                                width: parent.width
                                                sourceComponent: committedHolder.modelData.type === "code" ? codeBlockComponent : (committedHolder.modelData.type === "math" ? mathBlockComponent : textBlockComponent)
                                                onLoaded: {
                                                    item.blockData = committedHolder.modelData;
                                                    if (item.hasOwnProperty("isUserMsg"))
                                                        item.isUserMsg = committedHolder.isUserMsg;
                                                    if (item.hasOwnProperty("loading"))
                                                        item.loading = false;
                                                }
                                            }
                                        }
                                    }

                                    StyledText {
                                        id: streamTail
                                        visible: streamingView.streamSplit.tail !== ""
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        font: Tokens.font.body.medium
                                        color: delegateItem.isUser ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                        text: streamingView.streamSplit.tail + (cursorBlink.cursorVisible ? "▌" : " ")

                                        property bool cursorVisible: true
                                        Timer {
                                            id: cursorBlink
                                            property bool cursorVisible: true
                                            interval: 530
                                            repeat: true
                                            running: delegateItem.loading
                                            onTriggered: cursorVisible = !cursorVisible
                                        }
                                    }
                                }
                            }

                            IconButton {
                                id: deleteBtn
                                icon: "delete"
                                type: IconButton.Filled
                                width: 28
                                height: 28
                                isRound: true
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Tokens.spacing.extraSmall
                                visible: opacity > 0
                                opacity: (hoverArea.containsMouse || deleteBtn.hovered) && !delegateItem.loading ? 1 : 0
                                activeColour: Colours.palette.m3error
                                inactiveColour: delegateItem.isUser ? Qt.rgba(Colours.palette.m3onPrimaryContainer.r, Colours.palette.m3onPrimaryContainer.g, Colours.palette.m3onPrimaryContainer.b, 0.15) : Qt.rgba(Colours.palette.m3onSurface.r, Colours.palette.m3onSurface.g, Colours.palette.m3onSurface.b, 0.08)
                                activeOnColour: Colours.palette.m3onError
                                inactiveOnColour: delegateItem.isUser ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                Behavior on opacity {
                                    Anim {
                                        type: Anim.DefaultEffects
                                    }
                                }

                                onClicked: {
                                    aiController.deleteMessage(delegateItem.index);
                                    Toaster.toast("Deleted", "Message removed", "delete");
                                }
                            }
                        }
                    }

                    StyledText {
                        id: timeText
                        text: delegateItem.isUser ? "You" : (delegateItem.messageModelUsed !== "" ? ("AI (" + delegateItem.messageModelUsed + ")") : "AI")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        horizontalAlignment: delegateItem.isUser ? Text.AlignRight : Text.AlignLeft
                        width: parent.width
                    }
                }

                Component.onCompleted: {
                    fadeInAnim.start();
                }
                ParallelAnimation {
                    id: fadeInAnim
                    NumberAnimation {
                        target: delegateItem
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 250
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: column
                        property: "y"
                        from: 10
                        to: 0
                        duration: 250
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: aiController.chatModel.count === 0
                spacing: Tokens.spacing.medium
                width: parent.width - Tokens.padding.large * 2

                MaterialIcon {
                    text: "forum"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.Medium).build()
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                StyledText {
                    text: "Hi, I'm Cortana"
                    font: Tokens.font.title.builders.medium.weight(Font.Bold).build()
                    color: Colours.palette.m3onSurface
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                StyledText {
                    text: "Ask me anything!"
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Item {
        id: historyView
        anchors.top: headerBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: opacity > 0
        opacity: root.currentView === "history" ? 1 : 0
        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        GridView {
            id: historyGrid
            anchors.fill: parent
            opacity: GlobalConfig.launcher.aiHistoryGridView ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            readonly property real baseMargin: Tokens.spacing.medium
            readonly property real availableWidth: parent.width - baseMargin * 2
            readonly property int cols: Math.floor(availableWidth / cellWidth)
            readonly property real extraSpace: availableWidth - (cols * cellWidth)

            anchors.leftMargin: baseMargin + extraSpace / 2
            anchors.rightMargin: baseMargin + extraSpace / 2
            anchors.topMargin: baseMargin
            anchors.bottomMargin: baseMargin
            cellWidth: 270
            cellHeight: 120
            clip: true
            model: aiController.historyModel

            delegate: Item {
                width: 270
                height: 120
                required property string convId
                required property string title
                required property string subtitle
                required property int index

                StyledRect {
                    id: card
                    width: 250
                    height: 100
                    anchors.centerIn: parent
                    radius: Tokens.rounding.large
                    color: hoverArea.containsMouse ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                    border.width: 0
                    border.color: "transparent"

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            aiController.selectConversation(convId);
                            root.currentView = "chat";
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium
                        StyledRect {
                            width: 40
                            height: 40
                            radius: Tokens.rounding.full
                            anchors.verticalCenter: parent.verticalCenter
                            color: hoverArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "chat_bubble"
                                fontStyle: Tokens.font.icon.small
                                color: hoverArea.containsMouse ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                            }
                        }
                        Column {
                            width: card.width - 40 - Tokens.spacing.medium - Tokens.padding.medium * 2 - 30
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            StyledText {
                                text: title
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                elide: Text.ElideRight
                                width: parent.width
                                color: hoverArea.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: subtitle
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                                width: parent.width
                                color: hoverArea.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }

                    IconButton {
                        id: deleteBtn
                        icon: "close"
                        type: IconButton.Text
                        width: 24
                        height: 24
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: Tokens.spacing.extraSmall
                        visible: opacity > 0
                        opacity: hoverArea.containsMouse || deleteBtn.hovered ? 1 : 0
                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                        onClicked: aiController.deleteConversation(convId)
                    }
                }
            }
        }

        ListView {
            id: historyList
            anchors.fill: parent
            anchors.margins: Tokens.spacing.medium
            opacity: !GlobalConfig.launcher.aiHistoryGridView ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
            spacing: Tokens.spacing.small
            clip: true
            model: aiController.historyModel

            delegate: Item {
                width: historyList.width
                height: 76
                required property string convId
                required property string title
                required property string subtitle
                required property int index

                StyledRect {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Tokens.rounding.medium
                    color: listHoverArea.containsMouse ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)

                    MouseArea {
                        id: listHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            aiController.selectConversation(convId);
                            root.currentView = "chat";
                        }
                    }

                    StyledRect {
                        id: bubbleIcon
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 36
                        radius: Tokens.rounding.full
                        color: listHoverArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "chat_bubble"
                            fontStyle: Tokens.font.icon.small
                            color: listHoverArea.containsMouse ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                        }
                    }

                    IconButton {
                        id: listDeleteBtn
                        icon: "close"
                        type: IconButton.Text
                        width: 24
                        height: 24
                        anchors.right: parent.right
                        anchors.rightMargin: Tokens.padding.medium
                        anchors.verticalCenter: parent.verticalCenter
                        visible: opacity > 0
                        opacity: listHoverArea.containsMouse || listDeleteBtn.hovered ? 1 : 0
                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                        onClicked: aiController.deleteConversation(convId)
                    }

                    Column {
                        anchors.left: bubbleIcon.right
                        anchors.leftMargin: Tokens.spacing.medium
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        anchors.rightMargin: (listHoverArea.containsMouse || listDeleteBtn.hovered) ? (listDeleteBtn.width + Tokens.spacing.medium + Tokens.padding.medium) : Tokens.padding.medium
                        Behavior on anchors.rightMargin {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutQuad
                            }
                        }
                        StyledText {
                            text: title
                            font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                            elide: Text.ElideRight
                            width: parent.width
                            color: listHoverArea.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        }
                        StyledText {
                            text: subtitle
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                            width: parent.width
                            color: listHoverArea.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        }
                    }
                }
            }
        }
    }

    Item {
        id: settingsView
        anchors.top: headerBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        opacity: root.currentView === "settings" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Row {
            id: settingsTitleBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.large
            anchors.topMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium
            IconButton {
                icon: "arrow_back"
                type: IconButton.Text
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.currentView = "history"
            }
            StyledText {
                text: "Model Settings"
                font: Tokens.font.title.builders.medium.weight(Font.Bold).build()
                color: Colours.palette.m3onSurface
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Flickable {
            id: settingsList
            anchors.top: settingsTitleBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Tokens.padding.medium
            clip: true
            contentHeight: settingsColumn.implicitHeight
            contentWidth: width

            Column {
                id: settingsColumn
                width: Math.min(600, parent.width - Tokens.padding.large * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Tokens.spacing.medium
                bottomPadding: Tokens.padding.large

                Item {
                    width: parent.width
                    height: 36
                    StyledText {
                        text: "INTERFACE & FEATURES"
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3primary
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Tokens.spacing.extraSmall
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.padding.medium
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 80
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium
                        MaterialIcon {
                            text: "fullscreen"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            width: parent.width - 40 - 60
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            StyledText {
                                text: "Default Full Screen"
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: "Open chat in full screen mode by default"
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }
                        StyledSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: GlobalConfig.launcher.aiFullScreen
                            onToggled: GlobalConfig.launcher.aiFullScreen = checked
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 96
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"

                    MaterialIcon {
                        id: defaultHeightIcon
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.verticalCenter: parent.verticalCenter
                        text: "swap_vert"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.medium
                    }
                    Column {
                        anchors.left: defaultHeightIcon.right
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
                                text: "Default Height"
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText {
                                anchors.right: parent.right
                                text: GlobalConfig.launcher.aiDefaultHeight + "px"
                                font: Tokens.font.label.medium
                                color: Colours.palette.m3onSurfaceVariant
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        StyledSlider {
                            id: defaultHeightSlider
                            width: parent.width
                            from: 400
                            to: root.maxHeight
                            value: GlobalConfig.launcher.aiDefaultHeight
                            onInteraction: v => {
                                GlobalConfig.launcher.aiDefaultHeight = Math.round(defaultHeightSlider.from + v * (defaultHeightSlider.to - defaultHeightSlider.from));
                            }
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 96
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"
                    MaterialIcon {
                        id: defaultWidthIcon
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.verticalCenter: parent.verticalCenter
                        text: "swap_horiz"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.medium
                    }
                    Column {
                        anchors.left: defaultWidthIcon.right
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
                                text: "Default Width"
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText {
                                anchors.right: parent.right
                                text: GlobalConfig.launcher.aiDefaultWidth + "px"
                                font: Tokens.font.label.medium
                                color: Colours.palette.m3onSurfaceVariant
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        StyledSlider {
                            id: defaultWidthSlider
                            width: parent.width
                            from: 630
                            to: root.screenWidth - 32
                            value: GlobalConfig.launcher.aiDefaultWidth
                            onInteraction: v => {
                                GlobalConfig.launcher.aiDefaultWidth = Math.round(defaultWidthSlider.from + v * (defaultWidthSlider.to - defaultWidthSlider.from));
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 56
                    StyledText {
                        text: "AI ENGINE & MODEL"
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3primary
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Tokens.spacing.extraSmall
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.padding.medium
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 80
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"
                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "find_in_page"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 40 - 60
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: "Read Webpages"
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: "Allow Cortana to fetch and read specific URLs"
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        StyledSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: GlobalConfig.ai.agentReadWebpage
                            onToggled: GlobalConfig.ai.agentReadWebpage = checked
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 80
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"
                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "partly_cloudy_day"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 40 - 60
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: "Weather Forecast"
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: "Allow Cortana to check the weather forecast"
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        StyledSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: GlobalConfig.ai.agentGetWeather
                            onToggled: GlobalConfig.ai.agentGetWeather = checked
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 80
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"
                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "screenshot_monitor"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 40 - 60
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: "Screen Analysis"
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: "Allow Cortana to capture and view your screen"
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        StyledSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: GlobalConfig.ai.agentTakeScreenshot
                            onToggled: GlobalConfig.ai.agentTakeScreenshot = checked
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 80
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"
                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "apps"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 40 - 60
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: "Open Applications"
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: "Allow Cortana to launch installed desktop apps"
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        StyledSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: GlobalConfig.ai.agentOpenApp
                            onToggled: GlobalConfig.ai.agentOpenApp = checked
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 80
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "timer"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 40 - 60
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: "Set Timers"
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: "Allow Cortana to create system background timers"
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        StyledSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: GlobalConfig.ai.agentSetTimer
                            onToggled: GlobalConfig.ai.agentSetTimer = checked
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 80
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "terminal"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 40 - 60
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: "Caelestia Command"
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: "Allow Cortana to execute Caelestia commands"
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        StyledSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: GlobalConfig.ai.agentCaelestiaCommand
                            onToggled: GlobalConfig.ai.agentCaelestiaCommand = checked
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 80
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "router"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 40 - 60
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: "Cortana API"
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: "Allow Cortana to access the Cortana API"
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        StyledSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: GlobalConfig.ai.agentCortanaApi
                            onToggled: GlobalConfig.ai.agentCortanaApi = checked
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 80
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"
                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "code"
                            color: Colours.palette.m3error
                            fontStyle: Tokens.font.icon.medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 40 - 60
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: "Shell Execution"
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: "Allow Cortana to run arbitrary bash commands"
                                font: Tokens.font.body.small
                                color: Colours.palette.m3error
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        StyledSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: GlobalConfig.ai.agentRunCommand
                            onToggled: GlobalConfig.ai.agentRunCommand = checked
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 80
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "folder_open"
                            color: Colours.palette.m3error
                            fontStyle: Tokens.font.icon.medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 40 - 60
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: "File Operations"
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: "Allow Cortana to read and write local files"
                                font: Tokens.font.body.small
                                color: Colours.palette.m3error
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        StyledSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: GlobalConfig.ai.agentFileOps
                            onToggled: GlobalConfig.ai.agentFileOps = checked
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 56
                    StyledText {
                        text: "MODEL CONFIGURATION"
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3primary
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Tokens.spacing.extraSmall
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.padding.medium
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 96
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                    border.width: 0
                    border.color: "transparent"

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
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText {
                                anchors.right: parent.right
                                text: (GlobalConfig.ai.contextWindow >= 1024 ? Math.round(GlobalConfig.ai.contextWindow / 1024) + "k" : GlobalConfig.ai.contextWindow) + " tokens"
                                font: Tokens.font.label.medium
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
                    border.color: "transparent"

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
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                color: Colours.palette.m3onSurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        StyledText {
                            text: "Customize the rules and persona for the AI assistant."
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
            }
        }
    }

    StyledRect {
        id: linkStatusHover
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.spacing.medium
        height: 28
        property string displayUrl: ""
        onOpacityChanged: {
            if (opacity === 0)
                displayUrl = "";
        }
        Connections {
            target: root
            function onHoverLinkUrlChanged() {
                if (root.hoverLinkUrl !== "")
                    linkStatusHover.displayUrl = root.hoverLinkUrl;
            }
        }
        width: Math.min(parent.width - Tokens.spacing.medium * 2, statusText.implicitWidth + Tokens.padding.medium * 2 + (statusIcon.visible ? 24 : 0))
        radius: Tokens.rounding.small
        color: Colours.palette.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.palette.m3outlineVariant
        z: 99999
        opacity: root.hoverLinkUrl !== "" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
        clip: true

        Row {
            x: Tokens.padding.medium
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.small
            width: parent.width - Tokens.padding.medium * 2
            MaterialIcon {
                id: statusIcon
                text: "link"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.small
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                id: statusText
                text: linkStatusHover.displayUrl
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
                width: parent.width - Tokens.padding.medium * 2 - (statusIcon.visible ? 24 : 0)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
