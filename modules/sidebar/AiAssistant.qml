pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils
import M3Shapes
import Caelestia.Blobs

Item {
    id: root

    property var aiController: sharedAiController

    property string currentTab: "chat"
    property string hoverLinkUrl: ""

    property bool userScrolledUp: false
    property bool isAutoScrolling: false

    onCurrentTabChanged: {
        if (currentTab === "chat") {
            Qt.callLater(() => {
                root.smartScroll();
            });
        }
    }

    function smartScroll() {
        if (!root.userScrolledUp && typeof listView !== "undefined") {
            root.isAutoScrolling = true;
            listView.positionViewAtEnd();
            Qt.callLater(() => {
                root.isAutoScrolling = false;
            });
        }
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
                    if (textEdit)
                        textEdit.updateText();
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
                    if (imagePath !== "")
                        rendering = false;
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
        id: mainWrapper
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium

        RowLayout {
            id: modeSwitcherRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40
            spacing: Tokens.spacing.small

            StyledRect {
                Layout.preferredWidth: 80
                Layout.fillHeight: true
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainer

                StyledRect {
                    width: 36
                    height: parent.height - 4
                    x: root.currentTab === "chat" ? 2 : parent.width - width - 2
                    y: 2
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary
                    Behavior on x {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Row {
                    anchors.fill: parent
                    spacing: 0
                    Item {
                        width: parent.width / 2
                        height: parent.height
                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "chat"
                            color: root.currentTab === "chat" ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.icon.small
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.currentTab = "chat"
                        }
                    }
                    Item {
                        width: parent.width / 2
                        height: parent.height
                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "history"
                            color: root.currentTab === "history" ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.icon.small
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.currentTab = "history"
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Tokens.spacing.medium
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
        }

        Item {
            id: contentStack
            anchors.top: modeSwitcherRow.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Tokens.spacing.medium

            Item {
                anchors.fill: parent
                visible: root.currentTab === "chat"

                StyledListView {
                    id: listView
                    anchors.top: parent.top
                    anchors.bottom: inputBoxRow.top
                    anchors.bottomMargin: Tokens.spacing.medium
                    anchors.left: parent.left
                    anchors.right: parent.right
                    clip: true
                    model: aiController.chatModel
                    spacing: Tokens.spacing.medium

                    Component.onCompleted: Qt.callLater(() => {
                        positionViewAtEnd();
                    })

                    onContentYChanged: {
                        if (!root.isAutoScrolling && contentHeight > height) {
                            var dist = contentHeight - contentY - height;
                            root.userScrolledUp = dist > 30;
                        }
                    }

                    onCountChanged: {
                        root.smartScroll();
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
                                        return Math.min(listView.width * 0.90, Math.max(120, paddedWidth));
                                    }
                                    height: bubbleColumn.implicitHeight + (delegateItem.loading ? Tokens.padding.small * 2 : Tokens.padding.medium * 2)

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
                }

                StyledRect {
                    id: inputBoxRow
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Math.max(48, inputArea.implicitHeight + Tokens.padding.medium * 2)
                    color: Colours.tPalette.m3surfaceContainer
                    radius: 24

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.large
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            TextArea {
                                id: inputArea
                                verticalAlignment: TextInput.AlignVCenter
                                placeholderText: qsTr("Ask Cortana...")
                                color: Colours.palette.m3onSurface
                                placeholderTextColor: Colours.palette.m3outline
                                font: Tokens.font.body.small
                                wrapMode: Text.Wrap
                                background: null

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Return && !(event.modifiers & Qt.ShiftModifier)) {
                                        event.accepted = true;
                                        if (!aiController.isGenerating && inputArea.text.length > 0) {
                                            aiController.sendMessage(inputArea.text);
                                            inputArea.clear();
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36

                            MaterialShape {
                                anchors.fill: parent
                                color: aiController.isGenerating ? Colours.palette.m3error : (inputArea.text.length > 0 ? Colours.palette.m3primary : Colours.layer(Colours.tPalette.m3surfaceContainerHigh, 2))
                                shape: aiController.isGenerating ? MaterialShape.Cookie4Sided : (inputArea.text.length > 0 ? MaterialShape.Arrow : MaterialShape.Circle)
                                scale: (inputArea.text.length === 0 && !aiController.isGenerating) ? 1 : sendMouse.pressed ? 0.6 : sendMouse.containsMouse ? 0.8 : 0.7
                                Behavior on scale {
                                    Anim {
                                        type: Anim.FastSpatial
                                    }
                                }

                                MouseArea {
                                    id: sendMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: (inputArea.text.length > 0 || aiController.isGenerating) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (aiController.isGenerating) {
                                            aiController.stopGeneration();
                                        } else if (inputArea.text.length > 0) {
                                            aiController.sendMessage(inputArea.text);
                                            inputArea.clear();
                                        }
                                    }
                                }
                            }
                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "arrow_upward"
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.icon.small
                                opacity: (inputArea.text.length > 0 || aiController.isGenerating) ? 0 : 1
                                Behavior on opacity {
                                    Anim {
                                        type: Anim.DefaultEffects
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                anchors.fill: parent
                visible: root.currentTab === "history"

                ListView {
                    anchors.fill: parent
                    anchors.bottomMargin: 50 // Room for clear button
                    model: aiController.historyModel
                    clip: true
                    spacing: Tokens.spacing.small

                    delegate: StyledRect {
                        width: ListView.view.width
                        height: 60
                        radius: Tokens.rounding.medium
                        color: Colours.tPalette.m3surfaceContainerHigh

                        required property var model
                        property string chatId: model && model.convId ? String(model.convId) : ""
                        property string chatTitle: model && model.title ? String(model.title) : ""

                        StateLayer {
                            radius: Tokens.rounding.medium
                            onClicked: {
                                aiController.selectConversation(chatId);
                                root.currentTab = "chat";
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.small
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                Layout.margins: Tokens.padding.small
                                text: "chat_bubble_outline"
                                color: Colours.palette.m3primary
                                font: Tokens.font.icon.small
                            }

                            Text {
                                Layout.fillWidth: true
                                text: chatTitle ? chatTitle : "New Chat"
                                color: Colours.palette.m3onSurface
                                font: Tokens.font.label.medium
                                elide: Text.ElideRight
                            }

                            IconButton {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                icon: "close"
                                activeColour: Colours.palette.m3error
                                onClicked: aiController.deleteConversation(chatId)
                            }
                        }
                    }
                }

                Item {
                    id: historyActions
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Tokens.padding.small
                    height: 38

                    RowLayout {
                        anchors.fill: parent
                        spacing: Tokens.spacing.small

                        IconTextButton {
                            Layout.fillWidth: true
                            text: "Clear History"
                            icon: "delete"
                            type: ButtonBase.Tonal
                            onClicked: {
                                aiController.conversationsList = [];
                                aiController.createNewChat();
                            }
                        }

                        IconTextButton {
                            Layout.fillWidth: true
                            text: "New Chat"
                            icon: "add"
                            type: ButtonBase.Tonal
                            onClicked: {
                                aiController.createNewChat();
                                root.currentTab = "chat";
                            }
                        }
                    }
                }
            }
        }
    }
}
