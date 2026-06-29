pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils
import Quickshell
import M3Shapes
import Caelestia.Blobs

Item {
    id: root

    property var aiController: sharedAiController

    property bool isHistoryTab: false
    property string hoverLinkUrl: ""

    property var renderingInlineMath: ({})
    property var compiledInlineMath: ({})

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

            onLinkActivated: (link) => Qt.openUrlExternally(link)
            onLinkHovered: (link) => { root.hoverLinkUrl = link; }

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

                var html = root.markdownToHtml(content, colorStr);
                processedText = root.processInlineMathHtml(html, colorStr, isUserMsg, function() {
                    if (textEdit) textEdit.updateText();
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

                    Rectangle { width: 8; height: 8; radius: 4; color: Colours.palette.m3primary; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: (lang === "code" ? "plaintext" : lang).toUpperCase(); font.pixelSize: Tokens.font.label.small.pixelSize; font.family: "monospace"; font.weight: Font.Medium; color: Colours.palette.m3primary; anchors.verticalCenter: parent.verticalCenter }
                }

                IconButton {
                    id: codeCopyBtn
                    property bool copied: false
                    icon: copied ? "check" : "content_copy"
                    type: IconButton.Text
                    width: 24; height: 24
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
                    Timer { id: codeRevertTimer; interval: 1500; onTriggered: codeCopyBtn.copied = false }
                }
            }

            Item {
                id: codeBody
                width: parent.width
                anchors.top: codeHeader.bottom
                height: codeText.implicitHeight + Tokens.padding.medium * 2

                TextEdit {
                    id: codeText
                    text: blockData ? root.highlightCode(blockData.content, lang) : ""
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
                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                    onLinkHovered: (link) => { root.hoverLinkUrl = link; }
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor }
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
                if (!blockData || !blockData.content || loading) { imagePath = ""; rendering = false; lastCacheKey = ""; return; }
                var colorStr = isUserMsg ? (Colours.palette.m3onPrimaryContainer + "") : (Colours.palette.m3onSurface + "");
                var currentLatex = blockData.content;
                var cacheKey = currentLatex + "|" + colorStr;
                if (cacheKey === lastCacheKey) { if (imagePath !== "") rendering = false; return; }

                imagePath = ""; rendering = true; lastCacheKey = cacheKey;
                var scriptPath = "/etc/xdg/quickshell/caelestia/utils/scripts/render_math.py";

                root.aiController.runCommand([scriptPath, currentLatex, colorStr, "9"], function(stdout) {
                    if (!mathBlock) return;
                    var path = stdout.trim();
                    if (path.indexOf("/tmp") === 0) { mathBlock.imagePath = "file://" + path; mathBlock.rendering = false; }
                    else { console.log("Math rendering error: " + stdout); mathBlock.rendering = false; }
                });
            }

            onBlockDataChanged: updateMath()
            onLoadingChanged: updateMath()
            Component.onCompleted: updateMath()

            Rectangle {
                anchors.fill: parent; anchors.topMargin: mathBlock.vGap; anchors.bottomMargin: mathBlock.vGap; color: "transparent"
                Text { id: rawMathText; anchors.centerIn: parent; text: blockData ? "$$" + blockData.content + "$$" : ""; color: isUserMsg ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface; font: Tokens.font.body.medium; visible: mathBlock.loading; wrapMode: Text.WordWrap; width: parent.width; horizontalAlignment: Text.AlignHCenter }
                Text { id: loadingText; anchors.centerIn: parent; text: "Rendering expression..."; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.body.small; visible: !mathBlock.loading && mathBlock.rendering }
                Image { id: mathImage; anchors.centerIn: parent; source: mathBlock.imagePath; visible: !mathBlock.loading && !mathBlock.rendering && mathBlock.imagePath !== ""; fillMode: Image.PreserveAspectFit; cache: true; asynchronous: true }
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
             anchors.rightMargin: 0
             z: 10
             spacing: Tokens.spacing.small

             StyledRect {
                 id: modeSwitcherBg
                 implicitWidth: modeRow.width
                 implicitHeight: 32
                 radius: Tokens.rounding.full
                 color: Colours.tPalette.m3surfaceContainer

                 StyledClippingRect {
                     z: -1
                     anchors.fill: parent
                     radius: Tokens.rounding.full
                     ShaderEffectSource {
                         id: switcherBlurSource
                         sourceItem: contentStack
                         sourceRect: {
                             var p = parent.mapToItem(contentStack, 0, 0);
                             return Qt.rect(p.x, p.y, parent.width, parent.height);
                         }
                     }
                     MultiEffect {
                         anchors.fill: parent
                         source: switcherBlurSource
                         blurEnabled: true
                         blurMax: 32
                     }
                 }

                 StyledRect {
                     width: isHistoryTab ? historyTab.width : chatTab.width
                     height: parent.height
                     radius: Tokens.rounding.full
                     color: Colours.palette.m3primary
                     x: isHistoryTab ? historyTab.x : chatTab.x
                     Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                     Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                 }

                 Row {
                     id: modeRow
                     height: parent.height

                     Item {
                         id: chatTab
                         height: parent.height
                         width: !isHistoryTab ? 40 : chatContent.implicitWidth + Tokens.padding.medium * 2
                         Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                         StateLayer { radius: Tokens.rounding.full; onClicked: isHistoryTab = false }
                         Row {
                             id: chatContent; anchors.centerIn: parent; spacing: Tokens.spacing.small
                             MaterialIcon { anchors.verticalCenter: parent.verticalCenter; text: "chat"; color: !isHistoryTab ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant; font: Tokens.font.icon.small }
                             Text { anchors.verticalCenter: parent.verticalCenter; text: "Chat"; color: !isHistoryTab ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant; font: Tokens.font.body.small; visible: isHistoryTab }
                         }
                     }

                     Item {
                         id: historyTab
                         height: parent.height
                         width: isHistoryTab ? 40 : historyContent.implicitWidth + Tokens.padding.medium * 2
                         Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                         StateLayer { radius: Tokens.rounding.full; onClicked: isHistoryTab = true }
                         Row {
                             id: historyContent; anchors.centerIn: parent; spacing: Tokens.spacing.small
                             MaterialIcon { anchors.verticalCenter: parent.verticalCenter; text: "history"; color: isHistoryTab ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant; font: Tokens.font.icon.small }
                             Text { anchors.verticalCenter: parent.verticalCenter; text: "History"; color: isHistoryTab ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant; font: Tokens.font.body.small; visible: !isHistoryTab }
                         }
                     }
                 }
             }

             Item { Layout.fillWidth: true }

             SplitButton {
                 id: modelSelector
                 type: SplitButton.Tonal
                 verticalPadding: 4
                 Layout.preferredWidth: implicitWidth

                 active: menuItems.find(m => m.modelData === GlobalConfig.ai.activeModel) ?? menuItems[0] ?? null
                 menu.onItemSelected: item => { aiController.changeModel(item.modelData); }

                 menuItems: modelVariants.instances
                 fallbackIcon: "smart_toy"
                 fallbackText: qsTr("Select Model")
                 stateLayer.disabled: true

                 Variants {
                     id: modelVariants
                     model: aiController.availableModels
                     delegate: MenuItem { required property string modelData; text: modelData }
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
                 opacity: !isHistoryTab ? 1 : 0
                 visible: opacity > 0
                 Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

                 VerticalFadeListView {
                     id: listView
                     anchors.top: parent.top
                     anchors.bottom: inputBoxRow.top
                     anchors.left: parent.left
                     anchors.right: parent.right
                     anchors.bottomMargin: Tokens.spacing.medium
                     spacing: Tokens.spacing.medium
                     model: aiController.chatModel
                     boundsBehavior: Flickable.StopAtBounds
                     
                     ColumnLayout {
                         anchors.centerIn: parent
                         opacity: aiController.chatModel.count === 0 && !aiController.isGenerating ? 1.0 : 0.0
                         visible: opacity > 0
                         Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                         spacing: Tokens.spacing.large

                         Item {
                             Layout.alignment: Qt.AlignHCenter; implicitWidth: 72; implicitHeight: 72
                             Logo { id: emptyStateLogo; anchors.fill: parent; visible: false }
                             MultiEffect { anchors.fill: parent; source: emptyStateLogo; colorization: 1.0; colorizationColor: Colours.palette.m3primary }
                         }

                         StyledText {
                             id: greetingText
                             Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: listView.width - (Tokens.padding.large * 2)
                             horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; font: Tokens.font.title.medium; color: Colours.palette.m3onSurfaceVariant
                             text: "Cortana OS Workspace Ready."
                         }
                     }

                     ScrollBar.vertical: StyledScrollBar { flickable: listView }

                     footer: Item {
                         width: listView.width
                         height: aiController.isGenerating && aiController.chatModel.count > 0 && aiController.chatModel.get(aiController.chatModel.count - 1).text === "Thinking..." ? bubbleBg.height + Tokens.spacing.medium : 0
                         visible: opacity > 0
                         opacity: aiController.isGenerating && aiController.chatModel.count > 0 && aiController.chatModel.get(aiController.chatModel.count - 1).text === "Thinking..." ? 1 : 0
                         Behavior on height { Anim { type: Anim.DefaultSpatial } }
                         Behavior on opacity { Anim { type: Anim.DefaultSpatial } }

                         StyledRect {
                             id: bubbleBg
                             y: Tokens.spacing.medium / 2
                             width: footerCol.implicitWidth + Tokens.padding.medium * 2 + 8; height: footerCol.implicitHeight + Tokens.padding.medium * 2
                             radius: Tokens.rounding.large; color: Colours.tPalette.m3surfaceContainer
                             topLeftRadius: Tokens.rounding.large; topRightRadius: Tokens.rounding.large; bottomLeftRadius: 4; bottomRightRadius: Tokens.rounding.large

                             Column {
                                 id: footerCol; anchors.margins: Tokens.padding.medium; spacing: Tokens.spacing.small
                                 Row {
                                     spacing: Tokens.spacing.small
                                     LoadingIndicator { width: 20; height: 20; color: Colours.palette.m3primary }
                                     StyledText { text: "Cortana is thinking..."; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.body.small }
                                 }
                             }
                         }
                     }

                     delegate: Item {
                         id: delegateItem
                         required property string text
                         required property string sender
                         required property bool loading
                         required property string thinking

                         readonly property bool isUser: sender === "user"
                         readonly property bool isFinished: !loading
                         readonly property string thoughtText: thinking
                         readonly property bool isStatusText: text === "Thinking..." || text.startsWith("🔍") || text.startsWith("🌐") || text.startsWith("💻") || text.startsWith("📖") || text.startsWith("✍️") || text.startsWith("⚙️")

                         width: listView.width - Tokens.padding.large
                         visible: (!delegateItem.isFinished && aiController.isGenerating) ? false : (delegateItem.text !== "" || delegateItem.thoughtText !== "")
                         height: visible ? bubbleRect.height : 0
                         scale: 0.0; opacity: 0.0
                         Component.onCompleted: { popInAnim.start(); }
                         
                         ParallelAnimation {
                             id: popInAnim
                             NumberAnimation { target: delegateItem; property: "scale"; from: 0.8; to: 1.0; duration: 300; easing.type: Easing.OutBack }
                             NumberAnimation { target: delegateItem; property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
                         }
                         
                         SequentialAnimation {
                             id: popDoneAnim
                             NumberAnimation { target: delegateItem; property: "scale"; from: 1.0; to: 1.02; duration: 100; easing.type: Easing.OutQuad }
                             NumberAnimation { target: delegateItem; property: "scale"; from: 1.02; to: 1.0; duration: 150; easing.type: Easing.OutSine }
                         }
                         
                         onIsFinishedChanged: { if (isFinished) popDoneAnim.start(); }

                         StyledRect {
                             id: bubbleRect
                             readonly property real maxBubbleWidth: delegateItem.width * 0.95
                             anchors.right: delegateItem.isUser ? parent.right : undefined; anchors.left: delegateItem.isUser ? undefined : parent.left

                             width: {
                                var maxW = 120;
                                for (var i = 0; i < bubbleLayout.children.length; i++) {
                                    var child = bubbleLayout.children[i];
                                    if (child.visible && child.hasOwnProperty("blockWidth")) { if (child.blockWidth > maxW) maxW = child.blockWidth; }
                                }
                                if (delegateItem.loading && streamingView) {
                                    for (var j = 0; j < streamingView.children.length; j++) {
                                        var schild = streamingView.children[j];
                                        if (schild.visible) {
                                            if (schild.hasOwnProperty("blockWidth") && schild.blockWidth > maxW) maxW = schild.blockWidth;
                                            else if (schild.hasOwnProperty("text") && schild.implicitWidth > maxW) maxW = schild.implicitWidth;
                                        }
                                    }
                                }
                                var paddedWidth = maxW + Tokens.padding.medium * 2 + (delegateItem.loading ? 24 : 0);
                                return Math.min(maxBubbleWidth, Math.max(120, paddedWidth));
                             }

                             height: bubbleLayout.implicitHeight + (delegateItem.loading ? Tokens.padding.small * 2 : Tokens.padding.medium * 2)
                             radius: Tokens.rounding.large; color: delegateItem.isUser ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainer
                             topLeftRadius: Tokens.rounding.large; topRightRadius: Tokens.rounding.large; bottomLeftRadius: delegateItem.isUser ? Tokens.rounding.large : 4; bottomRightRadius: delegateItem.isUser ? 4 : Tokens.rounding.large
                             
                             Behavior on width { enabled: opacity === 1; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                             Behavior on height { enabled: opacity === 1; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                             Column {
                                 id: bubbleLayout
                                 anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                 anchors.topMargin: delegateItem.loading ? Tokens.padding.small : Tokens.padding.medium
                                 anchors.leftMargin: Tokens.padding.medium
                                 anchors.rightMargin: Tokens.padding.medium + (delegateItem.loading && !delegateItem.isUser ? 24 : 0)
                                 anchors.bottomMargin: delegateItem.loading ? Tokens.padding.small : Tokens.padding.medium
                                 spacing: Tokens.spacing.small
                                 
                                 property string delegateThought: delegateItem.thoughtText
                                 property bool isExpanded: false


                                 Item {
                                     visible: bubbleLayout.delegateThought !== ""
                                     implicitWidth: thoughtRow.implicitWidth; implicitHeight: thoughtRow.implicitHeight; height: visible ? implicitHeight : 0
                                     Row {
                                         id: thoughtRow; spacing: Tokens.spacing.small
                                         Text { text: "Thought Process"; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.body.small }
                                         MaterialIcon { id: thoughtArrow; text: "expand_more"; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.icon.small; rotation: bubbleLayout.isExpanded ? 180 : 0; Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } } }
                                     }
                                     MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bubbleLayout.isExpanded = !bubbleLayout.isExpanded }
                                 }

                                 Item {
                                     id: thoughtContentWrapper
                                     width: thoughtContent.width; height: bubbleLayout.isExpanded ? thoughtContent.implicitHeight : 0; clip: true
                                     Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                                     TextEdit {
                                         id: thoughtContent
                                         width: Math.min(implicitWidth, bubbleRect.maxBubbleWidth - Tokens.padding.medium * 2)
                                         textFormat: Text.MarkdownText
                                         property string fullThought: bubbleLayout.delegateThought
                                         property bool cursorVisible: true
                                         Timer { running: !delegateItem.isFinished; repeat: true; interval: 400; onTriggered: thoughtContent.cursorVisible = !thoughtContent.cursorVisible }
                                         text: delegateItem.isFinished ? fullThought : fullThought + (cursorVisible ? "▌" : "")
                                         color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.body.small; wrapMode: Text.Wrap; readOnly: true; selectByMouse: true; selectionColor: Colours.palette.m3primary; selectedTextColor: Colours.palette.m3onPrimary; opacity: bubbleLayout.isExpanded ? 1.0 : 0.0
                                         Behavior on opacity { SequentialAnimation { PauseAnimation { duration: bubbleLayout.isExpanded ? 100 : 0 } NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } } }
                                     }
                                 }

                                 LoadingIndicator {
                                     width: 16; height: 16
                                     visible: delegateItem.loading === true && delegateItem.text.trim() !== "" && !delegateItem.isStatusText
                                     animated: delegateItem.loading === true && delegateItem.text.trim() !== "" && !delegateItem.isStatusText
                                     color: Colours.palette.m3onSurfaceVariant
                                 }

                                 Repeater {
                                     model: delegateItem.loading ? [] : root.parseMessageBlocks(delegateItem.text)
                                     Item {
                                         id: blockHolder
                                         required property var modelData
                                         readonly property bool isUserMsg: delegateItem.isUser
                                         readonly property real blockWidth: blockLoader.item ? blockLoader.item.implicitWidth : 0
                                         width: bubbleLayout.width
                                         height: blockLoader.item ? blockLoader.item.height : 0

                                         Loader {
                                             id: blockLoader
                                             width: parent.width
                                             sourceComponent: blockHolder.modelData.type === "code" ? codeBlockComponent : (blockHolder.modelData.type === "math" ? mathBlockComponent : textBlockComponent)
                                             onLoaded: {
                                                 item.blockData = blockHolder.modelData;
                                                 if (item.hasOwnProperty("isUserMsg")) item.isUserMsg = blockHolder.isUserMsg;
                                                 if (item.hasOwnProperty("loading")) item.loading = Qt.binding(function() { return delegateItem.loading; });
                                             }
                                         }
                                     }
                                 }

                                 Column {
                                     id: streamingView
                                     visible: delegateItem.loading && !delegateItem.isStatusText
                                     width: parent.width
                                     spacing: Tokens.spacing.small
                                     property var streamSplit: delegateItem.loading ? root.parseStreamingBlocks(delegateItem.text) : { committed: "", tail: "" }

                                     Repeater {
                                         model: streamingView.streamSplit.committed !== "" ? root.parseMessageBlocks(streamingView.streamSplit.committed) : []
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
                                                     if (item.hasOwnProperty("isUserMsg")) item.isUserMsg = committedHolder.isUserMsg;
                                                     if (item.hasOwnProperty("loading")) item.loading = false;
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
                                         Timer { id: cursorBlink; property bool cursorVisible: true; interval: 530; repeat: true; running: delegateItem.loading; onTriggered: cursorVisible = !cursorVisible }
                                     }
                                 }
                             }
                         }
                     }
                 }

                 StyledRect {
                     id: inputBoxRow
                     anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; z: 10
                     implicitHeight: Math.max(48, inputArea.implicitHeight + Tokens.padding.medium * 2); color: Colours.tPalette.m3surfaceContainer; radius: 24

                     StyledClippingRect {
                         z: -1; anchors.fill: parent; radius: 24
                         ShaderEffectSource {
                             id: inputBlurSource; sourceItem: contentStack
                             sourceRect: { var p = parent.mapToItem(contentStack, 0, 0); return Qt.rect(p.x, p.y, parent.width, parent.height); }
                         }
                         MultiEffect { anchors.fill: parent; source: inputBlurSource; blurEnabled: true; blurMax: 32 }
                     }

                     StateLayer { id: inputStateLayer; anchors.fill: parent; radius: 24; hoverEnabled: false; cursorShape: Qt.IBeamCursor; onClicked: inputArea.forceActiveFocus() }

                     RowLayout {
                         anchors.fill: parent; anchors.leftMargin: Tokens.padding.large; anchors.rightMargin: Tokens.padding.small; spacing: Tokens.spacing.small
                         ScrollView {
                             id: inputScroll; Layout.fillWidth: true; Layout.fillHeight: true
                             TextArea {
                                 id: inputArea
                                 verticalAlignment: TextInput.AlignVCenter; placeholderText: qsTr("Ask Cortana..."); color: Colours.palette.m3onSurface; placeholderTextColor: Colours.palette.m3outline; font: Tokens.font.body.small; wrapMode: Text.Wrap; selectByMouse: true; background: null
                                 MouseArea {
                                     anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.IBeamCursor; propagateComposedEvents: true
                                     onPressed: mouse => { var mapped = mapToItem(inputStateLayer, mouse.x, mouse.y); inputStateLayer.press(mapped.x, mapped.y); mouse.accepted = false; }
                                 }
                                 Keys.onPressed: event => {
                                     if (event.key === Qt.Key_Return && !(event.modifiers & Qt.ShiftModifier)) {
                                         event.accepted = true;
                                         if (!aiController.isGenerating) { aiController.sendMessage(inputArea.text); inputArea.clear(); }
                                     }
                                 }
                             }
                         }

                         Item {
                             Layout.preferredWidth: 36; Layout.preferredHeight: 36
                             MaterialShape {
                                 anchors.fill: parent
                                 color: aiController.isGenerating ? Colours.palette.m3error : (inputArea.text.length > 0 ? Colours.palette.m3primary : Colours.layer(Colours.tPalette.m3surfaceContainerHigh, 2))
                                 shape: aiController.isGenerating ? MaterialShape.Cookie4Sided : (inputArea.text.length > 0 ? MaterialShape.Arrow : MaterialShape.Circle)
                                 scale: (inputArea.text.length === 0 && !aiController.isGenerating) ? 1 : sendMouse.pressed ? 0.6 : sendMouse.containsMouse ? 0.8 : 0.7
                                 Behavior on scale { Anim { type: Anim.FastSpatial } }
                                 Behavior on color { CAnim {} }
                                 MouseArea {
                                     id: sendMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: (inputArea.text.length > 0 || aiController.isGenerating) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                     onClicked: {
                                         if (aiController.isGenerating) { aiController.stopGeneration(); } 
                                         else if (inputArea.text.length > 0) { aiController.sendMessage(inputArea.text); inputArea.clear(); }
                                     }
                                 }
                             }
                             MaterialIcon {
                                 anchors.centerIn: parent; text: "arrow_upward"; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.icon.small
                                 opacity: (inputArea.text.length > 0 || aiController.isGenerating) ? 0 : 1
                                 Behavior on opacity { Anim { type: Anim.DefaultEffects } }
                             }
                         }
                     }
                 }
             }

             Item {
                 anchors.fill: parent
                 opacity: isHistoryTab ? 1 : 0
                 visible: opacity > 0
                 Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

                 GridView {
                     anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: newChatButton.top; anchors.bottomMargin: Tokens.spacing.medium
                     cellWidth: width / 2; cellHeight: 90
                     model: aiController.historyModel

                     delegate: Item {
                         required property var model
                         property string chatId: model && model.convId ? String(model.convId) : ""
                         property string chatTitle: model && model.title ? String(model.title) : ""

                         width: GridView.view.cellWidth; height: GridView.view.cellHeight

                         StyledRect {
                             anchors.fill: parent; anchors.margins: Tokens.spacing.small; radius: Tokens.rounding.medium; color: Colours.tPalette.m3surfaceContainerHigh
                             StateLayer { radius: Tokens.rounding.medium; onClicked: { aiController.selectConversation(chatId); root.isHistoryTab = false; } }

                             RowLayout {
                                 anchors.fill: parent; anchors.margins: Tokens.padding.small; spacing: Tokens.spacing.medium
                                 StyledRect { Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16; color: Colours.tPalette.m3surfaceContainerHighest; MaterialIcon { anchors.centerIn: parent; text: "chat"; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.icon.small } }
                                 ColumnLayout { Layout.fillWidth: true; spacing: 0; Text { Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; text: chatTitle ? chatTitle : "New Chat"; color: Colours.palette.m3onSurface; font: Tokens.font.label.small; elide: Text.ElideRight; wrapMode: Text.Wrap; maximumLineCount: 3 } }
                                 Item {
                                     Layout.alignment: Qt.AlignTop | Qt.AlignRight; Layout.preferredWidth: 24; Layout.preferredHeight: 24
                                     StyledRect { anchors.fill: parent; radius: 12; color: Colours.palette.m3onSurfaceVariant; opacity: deleteMouseArea.containsMouse ? 0.12 : 0.0; Behavior on opacity { NumberAnimation { duration: 150 } } }
                                     MaterialIcon { anchors.centerIn: parent; text: "close"; font: Tokens.font.icon.small; color: Colours.palette.m3onSurfaceVariant }
                                     MouseArea { id: deleteMouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: aiController.deleteConversation(chatId) }
                                 }
                             }
                         }
                     }
                 }

                 StyledRect {
                     id: clearAllButton
                     anchors.bottom: parent.bottom; anchors.left: parent.left; width: clearAllLayout.implicitWidth + Tokens.padding.large * 2; height: 32; radius: 16; color: Colours.palette.m3errorContainer
                     StateLayer { radius: 16; onClicked: { aiController.conversationsList = []; aiController.createNewChat(); } }
                     RowLayout { id: clearAllLayout; anchors.centerIn: parent; spacing: Tokens.spacing.small; MaterialIcon { text: "delete"; color: Colours.palette.m3onErrorContainer; font: Tokens.font.icon.small } Text { text: "Clear All"; color: Colours.palette.m3onErrorContainer; font: Tokens.font.body.small } }
                 }

                 StyledRect {
                     id: newChatButton
                     anchors.bottom: parent.bottom; anchors.right: parent.right; width: newChatLayout.implicitWidth + Tokens.padding.large * 2; height: 32; radius: 16; color: Colours.palette.m3primaryContainer
                     StateLayer { radius: 16; onClicked: { aiController.createNewChat(); root.isHistoryTab = false; } }
                     RowLayout { id: newChatLayout; anchors.centerIn: parent; spacing: Tokens.spacing.small; MaterialIcon { text: "add"; color: Colours.palette.m3onPrimaryContainer; font: Tokens.font.icon.small } Text { text: "New Chat"; color: Colours.palette.m3onPrimaryContainer; font: Tokens.font.body.small } }
                 }
             }
         }
    }

    function parseStreamingBlocks(raw) {
        if (!raw || raw === "Thinking...") return { committed: "", tail: "" };

        var committed = "";
        var tail = raw;
        var i = 0;

        while (i < tail.length) {

            var fenceOpen = tail.indexOf("```", i);
            var mathOpen = tail.indexOf("$$", i);

            var firstOpen = -1;
            var isMath = false;
            var markerLength = 3;

            if (fenceOpen !== -1 && mathOpen !== -1) {
                if (fenceOpen < mathOpen) {
                    firstOpen = fenceOpen;
                    isMath = false;
                    markerLength = 3;
                } else {
                    firstOpen = mathOpen;
                    isMath = true;
                    markerLength = 2;
                }
            } else if (fenceOpen !== -1) {
                firstOpen = fenceOpen;
                isMath = false;
                markerLength = 3;
            } else if (mathOpen !== -1) {
                firstOpen = mathOpen;
                isMath = true;
                markerLength = 2;
            }

            if (firstOpen !== -1) {

                var closeIndex = -1;
                if (isMath) {
                    closeIndex = tail.indexOf("$$", firstOpen + 2);
                } else {
                    closeIndex = tail.indexOf("```", firstOpen + 3);
                }

                if (closeIndex !== -1) {

                    var blockEnd = closeIndex + (isMath ? 2 : 3);

                    if (blockEnd < tail.length && tail[blockEnd] === "\n") blockEnd++;
                    committed += tail.substring(0, blockEnd);
                    tail = tail.substring(blockEnd);
                    i = 0;
                    continue;
                } else {

                    var beforeBlock = tail.substring(0, firstOpen);

                    var lastPara = beforeBlock.lastIndexOf("\n\n");
                    if (lastPara !== -1) {
                        committed += beforeBlock.substring(0, lastPara + 2);
                        tail = beforeBlock.substring(lastPara + 2) + tail.substring(firstOpen);
                    }
                    break;
                }
            }

            var lastDouble = tail.lastIndexOf("\n\n");
            if (lastDouble !== -1) {
                committed += tail.substring(0, lastDouble + 2);
                tail = tail.substring(lastDouble + 2);
            }
            break;
        }

        var headingRe = /^(#{1,6} .+)\n/m;
        var hm;
        while ((hm = headingRe.exec(tail)) !== null) {
            if (hm.index === 0) {
                committed += hm[0];
                tail = tail.substring(hm[0].length);
            } else {
                break;
            }
        }

        return { committed: committed.trim(), tail: tail };
    }

    function parseMessageBlocks(raw) {
        var blocks = [];
        var pattern = /(```([\w]*)?\n?([\s\S]*?)```)|(\$\$([\s\S]*?)\$\$)/g;
        var last = 0;
        var match;
        while ((match = pattern.exec(raw)) !== null) {
            if (match.index > last) {
                var txt = raw.substring(last, match.index).trim();
                if (txt.length > 0)
                    blocks.push({ type: "text", content: txt, language: "" });
            }
            if (match[1]) {
                blocks.push({ type: "code", content: match[3] || "", language: match[2] || "code" });
            } else if (match[4]) {
                blocks.push({ type: "math", content: match[5] || "", language: "" });
            }
            last = match.index + match[0].length;
        }
        if (last < raw.length) {
            var rest = raw.substring(last).trim();
            if (rest.length > 0)
                blocks.push({ type: "text", content: rest, language: "" });
        }
        return blocks.length > 0 ? blocks : [{ type: "text", content: raw, language: "" }];
    }

    function highlightCode(code, lang) {
        var l = (lang || "").toLowerCase();

        function bright(c, f) { return Qt.lighter(c, f || 2.0) + ""; }
        var C = {
            keyword:  bright(Colours.palette.m3primary,   2.0),
            builtin:  bright(Colours.palette.m3primary,   1.7),
            string:   bright(Colours.palette.m3tertiary,  2.0),
            number:   bright(Colours.palette.m3error,     2.2),
            comment:  Colours.palette.m3onSurfaceVariant + "",
            operator: bright(Colours.palette.m3secondary, 2.0),
            func:     bright(Colours.palette.m3primary,   1.85),
            normal:   Colours.palette.m3onSurface + ""
        };

        var keywords = {
            python:     ["False","None","True","and","as","assert","async","await","break","class","continue","def","del","elif","else","except","finally","for","from","global","if","import","in","is","lambda","nonlocal","not","or","pass","raise","return","try","while","with","yield"],
            javascript: ["async","await","break","case","catch","class","const","continue","debugger","default","delete","do","else","export","extends","finally","for","function","if","import","in","instanceof","let","new","of","return","static","super","switch","this","throw","try","typeof","var","void","while","with","yield","true","false","null","undefined"],
            typescript: ["abstract","any","as","async","await","boolean","break","case","catch","class","const","constructor","continue","declare","default","delete","do","else","enum","export","extends","false","finally","for","from","function","if","implements","import","in","instanceof","interface","let","module","namespace","new","null","number","of","private","protected","public","readonly","return","static","string","super","switch","this","throw","true","try","type","typeof","undefined","var","void","while","yield"],
            rust:       ["as","async","await","break","const","continue","crate","dyn","else","enum","extern","false","fn","for","if","impl","in","let","loop","match","mod","move","mut","pub","ref","return","self","Self","static","struct","super","trait","true","type","union","unsafe","use","where","while"],
            go:         ["break","case","chan","const","continue","default","defer","else","fallthrough","for","func","go","goto","if","import","interface","map","package","range","return","select","struct","switch","type","var","true","false","nil"],
            java:       ["abstract","assert","boolean","break","byte","case","catch","char","class","const","continue","default","do","double","else","enum","extends","final","finally","float","for","goto","if","implements","import","instanceof","int","interface","long","native","new","null","package","private","protected","public","return","short","static","strictfp","super","switch","synchronized","this","throw","throws","transient","true","try","void","volatile","while"],
            kotlin:     ["abstract","actual","annotation","as","break","by","catch","class","companion","const","constructor","continue","crossinline","data","do","dynamic","else","enum","expect","external","false","field","final","finally","for","fun","get","if","import","in","infix","init","inline","inner","interface","internal","is","it","lateinit","noinline","null","object","open","operator","out","override","package","private","protected","public","reified","return","sealed","set","super","suspend","tailrec","this","throw","true","try","typealias","typeof","val","var","vararg","when","where","while"],
            swift:      ["as","break","case","catch","class","continue","default","defer","deinit","do","else","enum","extension","fallthrough","false","fileprivate","final","for","func","guard","if","import","in","init","inout","internal","is","lazy","let","mutating","nil","open","operator","override","private","protocol","public","repeat","required","rethrows","return","self","Self","static","struct","subscript","super","switch","throw","throws","true","try","typealias","var","weak","where","while"],
            bash:       ["if","then","else","elif","fi","for","while","do","done","case","esac","in","function","return","export","local","readonly","unset","shift","break","continue","exit","echo","source","alias","declare","typeset","true","false"],
            cpp:        ["alignas","alignof","and","and_eq","asm","auto","bitand","bitor","bool","break","case","catch","char","char8_t","char16_t","char32_t","class","compl","concept","const","consteval","constexpr","constinit","const_cast","continue","co_await","co_return","co_yield","decltype","default","delete","do","double","dynamic_cast","else","enum","explicit","export","extern","false","float","for","friend","goto","if","inline","int","long","mutable","namespace","new","noexcept","not","not_eq","nullptr","operator","or","or_eq","private","protected","public","reinterpret_cast","requires","return","short","signed","sizeof","static","static_assert","static_cast","struct","switch","template","this","thread_local","throw","true","try","typedef","typeid","typename","union","unsigned","using","virtual","void","volatile","wchar_t","while","xor","xor_eq"],
            sql:        ["SELECT","FROM","WHERE","INSERT","UPDATE","DELETE","CREATE","DROP","ALTER","TABLE","INDEX","VIEW","TRIGGER","PROCEDURE","FUNCTION","DATABASE","SCHEMA","JOIN","INNER","LEFT","RIGHT","FULL","OUTER","ON","AS","GROUP","BY","ORDER","HAVING","LIMIT","OFFSET","UNION","ALL","DISTINCT","AND","OR","NOT","IN","IS","NULL","LIKE","BETWEEN","CASE","WHEN","THEN","ELSE","END","EXISTS","PRIMARY","KEY","FOREIGN","REFERENCES","UNIQUE","CHECK","DEFAULT","AUTO_INCREMENT","SET","VALUES","INTO","BEGIN","COMMIT","ROLLBACK","TRANSACTION","INT","VARCHAR","TEXT","BOOLEAN","FLOAT","DOUBLE","DATETIME","DATE","TIMESTAMP"]
        };

        var kw = keywords[l] || keywords[l === "js" ? "javascript" : l === "ts" ? "typescript" : l === "sh" || l === "shell" ? "bash" : l === "c" || l === "c++" ? "cpp" : l === "kt" ? "kotlin" : ""] || [];
        var kwSet = {};
        for (var ki = 0; ki < kw.length; ki++) kwSet[kw[ki]] = true;

        function esc(s) {
            return s.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
        }
        function span(color, text) {
            return '<font color="' + color + '">' + esc(text) + '</font>';
        }

        var lines = code.split("\n");
        var out = [];

        var lineComment = "//";
        var blockCommentStart = "/*"; var blockCommentEnd = "*/";
        if (l === "python" || l === "py" || l === "bash" || l === "sh" || l === "shell" || l === "ruby" || l === "rb") {
            lineComment = "#"; blockCommentStart = ""; blockCommentEnd = "";
        } else if (l === "sql") {
            lineComment = "--";
        } else if (l === "html" || l === "xml") {
            lineComment = ""; blockCommentStart = "<!--"; blockCommentEnd = "-->";
        }

        var inBlockComment = false;

        for (var li = 0; li < lines.length; li++) {
            var line = lines[li];
            var result = "";
            var i = 0;

            while (i < line.length) {

                if (inBlockComment) {
                    var endIdx = blockCommentEnd ? line.indexOf(blockCommentEnd, i) : -1;
                    if (endIdx !== -1) {
                        result += span(C.comment, line.substring(i, endIdx + blockCommentEnd.length));
                        i = endIdx + blockCommentEnd.length;
                        inBlockComment = false;
                    } else {
                        result += span(C.comment, line.substring(i));
                        i = line.length;
                    }
                    continue;
                }

                if (blockCommentStart && line.startsWith(blockCommentStart, i)) {
                    var bcEnd = blockCommentEnd ? line.indexOf(blockCommentEnd, i + blockCommentStart.length) : -1;
                    if (bcEnd !== -1) {
                        result += span(C.comment, line.substring(i, bcEnd + blockCommentEnd.length));
                        i = bcEnd + blockCommentEnd.length;
                    } else {
                        result += span(C.comment, line.substring(i));
                        i = line.length;
                        inBlockComment = true;
                    }
                    continue;
                }

                if (lineComment && line.startsWith(lineComment, i)) {
                    result += span(C.comment, line.substring(i));
                    i = line.length;
                    continue;
                }

                var ch = line[i];
                if (ch === '"' || ch === "'") {
                    var quote = ch;
                    var j = i + 1;
                    while (j < line.length) {
                        if (line[j] === '\\') { j += 2; continue; }
                        if (line[j] === quote) { j++; break; }
                        j++;
                    }
                    result += span(C.string, line.substring(i, j));
                    i = j;
                    continue;
                }

                if (ch === '`' && (l === "javascript" || l === "js" || l === "typescript" || l === "ts")) {
                    var j2 = i + 1;
                    while (j2 < line.length) {
                        if (line[j2] === '\\') { j2 += 2; continue; }
                        if (line[j2] === '`') { j2++; break; }
                        j2++;
                    }
                    result += span(C.string, line.substring(i, j2));
                    i = j2;
                    continue;
                }

                if (/[0-9]/.test(ch) || (ch === '.' && /[0-9]/.test(line[i+1] || ''))) {
                    var j3 = i;
                    while (j3 < line.length && /[0-9a-fA-FxXoObB_\.]/.test(line[j3])) j3++;
                    result += span(C.number, line.substring(i, j3));
                    i = j3;
                    continue;
                }

                if (/[a-zA-Z_$]/.test(ch)) {
                    var j4 = i;
                    while (j4 < line.length && /[\w$]/.test(line[j4])) j4++;
                    var word = line.substring(i, j4);

                    var rest2 = line.substring(j4).replace(/^\s+/, "");
                    if (kwSet[word]) {
                        result += span(C.keyword, word);
                    } else if (rest2[0] === '(') {
                        result += span(C.func, word);
                    } else {
                        result += span(C.normal, word);
                    }
                    i = j4;
                    continue;
                }

                if (/[+\-*/%=<>!&|^~?:;,\.\[\]{}()]/.test(ch)) {
                    result += span(C.operator, ch);
                    i++;
                    continue;
                }

                result += esc(ch);
                i++;
            }

            out.push(result);
        }

        return out.join("<br/>");
    }

    function markdownToHtml(md, colorStr) {
        if (!md) return "";

        function esc(s) {
            return s.replace(/&/g, "&amp;")
                    .replace(/</g, "&lt;")
                    .replace(/>/g, "&gt;");
        }

        function inlineHtml(line) {

            var codePlaceholders = [];
            line = line.replace(/`([^`]+)`/g, function(m, code) {
                var idx = codePlaceholders.length;
                codePlaceholders.push("<code>" + esc(code) + "</code>");
                return "\x00CODE" + idx + "\x00";
            });

            var mathPlaceholders = [];
            line = line.replace(/\$([^\$\n]+)\$/g, function(m, formula) {
                var idx = mathPlaceholders.length;
                mathPlaceholders.push(m);
                return "\x00MATH" + idx + "\x00";
            });
            line = line.replace(/\\\([\s\S]*?\\\)/g, function(m) {
                var idx = mathPlaceholders.length;
                mathPlaceholders.push(m);
                return "\x00MATH" + idx + "\x00";
            });

            line = esc(line);

            line = line.replace(/\*\*\*(.+?)\*\*\*/g, "<b><i>$1</i></b>");
            line = line.replace(/___(.+?)___/g, "<b><i>$1</i></b>");
            line = line.replace(/\*\*(.+?)\*\*/g, "<b>$1</b>");
            line = line.replace(/__(.+?)__/g, "<b>$1</b>");
            line = line.replace(/\*([^\*]+?)\*/g, "<i>$1</i>");
            line = line.replace(/_([^_]+?)_/g, "<i>$1</i>");
            line = line.replace(/~~(.+?)~~/g, "<s>$1</s>");
            line = line.replace(/\[([^\]]+)\]\(([^\)]+)\)/g, '<a href="$2">$1</a>');

            line = line.replace(/\x00MATH(\d+)\x00/g, function(m, idx) {
                return mathPlaceholders[parseInt(idx)];
            });
            line = line.replace(/\x00CODE(\d+)\x00/g, function(m, idx) {
                return codePlaceholders[parseInt(idx)];
            });
            return line;
        }

        var lines = md.split("\n");
        var html = "";
        var inList = false;   // unordered
        var inOList = false;  // ordered
        var inTable = false;
        var tableHeaderActive = false;
        var listDepth = 0;

        function closeList() {
            if (inList)  { html += "</ul>"; inList = false; }
            if (inOList) { html += "</ol>"; inOList = false; }
        }

        function closeTable() {
            if (inTable) {
                html += "</table>";
                inTable = false;
                tableHeaderActive = false;
            }
        }

        for (var i = 0; i < lines.length; i++) {
            var raw = lines[i];
            var line = raw.replace(/^\s+/, "");

            var isTableRow = (line.startsWith("|") && line.endsWith("|")) || (line.includes("|") && inTable);
            if (isTableRow) {
                closeList();
                var isSeparator = /^\|?([\s\-\:\*\|]+)\|?$/.test(line) && line.indexOf("-") !== -1;
                if (isSeparator) {
                    continue;
                }

                if (!inTable) {
                    html += "<table border='1' style='border-collapse: collapse; margin: 8px 0;'>";
                    inTable = true;
                    tableHeaderActive = true;
                }

                var cells = line.split("|");
                if (cells[0] === "") cells.shift();
                if (cells[cells.length - 1] === "") cells.pop();

                html += "<tr>";
                for (var c = 0; c < cells.length; c++) {
                    var cellText = inlineHtml(cells[c].trim());
                    if (tableHeaderActive) {
                        html += "<th>" + cellText + "</th>";
                    } else {
                        html += "<td>" + cellText + "</td>";
                    }
                }
                html += "</tr>";
                tableHeaderActive = false;
                continue;
            } else {
                closeTable();
            }

            var hm = line.match(/^(#{1,6})\s+(.*)$/);
            if (hm) {
                closeList();
                var level = hm[1].length;
                html += "<h" + level + ">" + inlineHtml(hm[2]) + "</h" + level + ">";
                continue;
            }

            if (/^[-*_]{3,}\s*$/.test(line)) {
                closeList();
                html += "<hr/>";
                continue;
            }

            if (line.startsWith("> ")) {
                closeList();
                html += "<blockquote>" + inlineHtml(line.substring(2)) + "</blockquote>";
                continue;
            }

            var ulm = line.match(/^[-*+]\s+(.*)$/);
            if (ulm) {
                if (!inList) { closeList(); html += "<ul>"; inList = true; }
                html += "<li>" + inlineHtml(ulm[1]) + "</li>";
                continue;
            }

            var olm = line.match(/^\d+\.\s+(.*)$/);
            if (olm) {
                if (!inOList) { closeList(); html += "<ol>"; inOList = true; }
                html += "<li>" + inlineHtml(olm[1]) + "</li>";
                continue;
            }

            if (line === "") {
                closeList();
                html += "<br/>";
                continue;
            }

            closeList();
            html += "<p style='margin:0'>" + inlineHtml(line) + "</p>";
        }
        closeList();
        closeTable();
        return html;
    }

    function processInlineMathHtml(html, colorStr, isUserMsg, callback) {
        if (!html) return "";

        var fg = colorStr;
        if (fg.startsWith("#") && fg.length === 9) {
            fg = "#" + fg.substring(3, 9) + fg.substring(1, 3);
        }

        var size = "18";
        var processed = html;

        processed = processed.replace(/\\\(([^\)]*?)\\\)/g, function(match, formula) {
            formula = formula.trim();
            if (formula.length === 0) return match;

            var cacheKey = formula + "|" + fg + "|" + size;

            if (root.compiledInlineMath[cacheKey]) {
                return '<img src="file://' + root.compiledInlineMath[cacheKey] + '" height="22" align="middle" style="vertical-align:middle;margin:0 1px" />';
            } else {
                if (!root.renderingInlineMath[cacheKey]) {
                    root.renderingInlineMath[cacheKey] = true;
                    var scriptPath = "/etc/xdg/quickshell/caelestia/utils/scripts/render_math.py";
                    aiController.runCommand([scriptPath, formula, colorStr, size], function(stdout) {
                        var path = stdout.trim();
                        if (root) {
                            if (root.renderingInlineMath) delete root.renderingInlineMath[cacheKey];
                            if (root.compiledInlineMath) root.compiledInlineMath[cacheKey] = path;
                        }
                        if (callback) callback();
                    });
                }
                return match;
            }
        });

        processed = processed.replace(/\$([^\$\n]+)\$/g, function(match, formula) {
            formula = formula.trim();
            if (formula.length === 0) return match;
            if (/^[0-9.,\s+\-*\/=()]+$/.test(formula) && !/[\^\\_{]/.test(formula)) {
                return match;
            }

            var cacheKey = formula + "|" + fg + "|" + size;

            if (root.compiledInlineMath[cacheKey]) {
                return '<img src="file://' + root.compiledInlineMath[cacheKey] + '" height="22" align="middle" style="vertical-align:middle;margin:0 1px" />';
            } else {
                if (!root.renderingInlineMath[cacheKey]) {
                    root.renderingInlineMath[cacheKey] = true;
                    var scriptPath = "/etc/xdg/quickshell/caelestia/utils/scripts/render_math.py";
                    aiController.runCommand([scriptPath, formula, colorStr, size], function(stdout) {
                        var path = stdout.trim();
                        if (root) {
                            if (root.renderingInlineMath) delete root.renderingInlineMath[cacheKey];
                            if (root.compiledInlineMath) root.compiledInlineMath[cacheKey] = path;
                        }
                        if (callback) callback();
                    });
                }
                return match;
            }
        });

        return processed;
    }

    function processInlineMath(content, colorStr, isUserMsg, callback) {
        if (!content) return "";

        var fg = colorStr;
        if (fg.startsWith("#") && fg.length === 9) {
            fg = "#" + fg.substring(3, 9) + fg.substring(1, 3);
        }

        var size = "18";
        var processed = content;

        processed = processed.replace(/\\\(([\s\S]*?)\\\)/g, function(match, formula) {
            formula = formula.trim();
            if (formula.length === 0) return match;

            var cacheKey = formula + "|" + fg + "|" + size;

            if (root.compiledInlineMath[cacheKey]) {
                return '<img src="file://' + root.compiledInlineMath[cacheKey] + '" height="22" align="middle" style="vertical-align:middle;margin:0 1px" />';
            } else {
                if (!root.renderingInlineMath[cacheKey]) {
                    root.renderingInlineMath[cacheKey] = true;
                    var scriptPath = "/etc/xdg/quickshell/caelestia/utils/scripts/render_math.py";
                    aiController.runCommand([scriptPath, formula, colorStr, size], function(stdout) {
                        var path = stdout.trim();
                        if (root) {
                            if (root.renderingInlineMath) delete root.renderingInlineMath[cacheKey];
                            if (root.compiledInlineMath) root.compiledInlineMath[cacheKey] = path;
                        }
                        if (callback) callback();
                    });
                }
                return match;
            }
        });

        processed = processed.replace(/\$([^\$\n]+)\$/g, function(match, formula) {
            formula = formula.trim();
            if (formula.length === 0) return match;
            if (/^[0-9.,\s+\-*\/=()]+$/.test(formula) && !/[\^\\_]/.test(formula)) {
                return match;
            }

            var cacheKey = formula + "|" + fg + "|" + size;

            if (root.compiledInlineMath[cacheKey]) {
                return '<img src="file://' + root.compiledInlineMath[cacheKey] + '" height="22" align="middle" style="vertical-align:middle;margin:0 1px" />';
            } else {
                if (!root.renderingInlineMath[cacheKey]) {
                    root.renderingInlineMath[cacheKey] = true;
                    var scriptPath = "/etc/xdg/quickshell/caelestia/utils/scripts/render_math.py";
                    aiController.runCommand([scriptPath, formula, colorStr, size], function(stdout) {
                        var path = stdout.trim();
                        if (root) {
                            if (root.renderingInlineMath) delete root.renderingInlineMath[cacheKey];
                            if (root.compiledInlineMath) root.compiledInlineMath[cacheKey] = path;
                        }
                        if (callback) callback();
                    });
                }
                return match;
            }
        });

        return processed;
    }
}