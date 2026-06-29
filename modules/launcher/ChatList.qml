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

    required property StyledTextField search
    required property DrawerVisibilities visibilities
    required property real screenWidth
    required property real maxHeight

    implicitHeight: GlobalConfig.launcher.aiDefaultHeight
    implicitWidth: parent ? parent.width : GlobalConfig.launcher.aiDefaultWidth

    property bool expanded: GlobalConfig.launcher.aiFullScreen
    property bool userScrolledUp: false
    property bool isAutoScrolling: false
    property string hoverLinkUrl: ""

    property bool isResizing: false

    onWidthChanged: {
        isResizing = true;
        resizeTimer.restart();
    }

    Timer {
        id: resizeTimer
        interval: 200
        onTriggered: root.isResizing = false
    }

    property var aiController: sharedAiController
    
    property var chatModel: aiController.chatModel
    property var historyModel: aiController.historyModel

    property bool showHistory: false
    readonly property alias currentList: listView

    property bool showSettings: false
    property bool hasUnsavedPromptChanges: false
    
    property bool isGenerating: aiController.isGenerating

    onIsGeneratingChanged: {
        if (!isGenerating && root.visibilities && !root.visibilities.launcher) {
            Quickshell.execDetached(["notify-send", "Caelestia AI", GlobalConfig.ai.activeModel + " finished generating response."]);
        }
    }

    onShowHistoryChanged: {
        if (!showHistory) {
            showSettings = false;
        }
    }

    onShowSettingsChanged: {
        if (showSettings) {
            promptTextEdit.text = GlobalConfig.ai.systemPrompt;
            hasUnsavedPromptChanges = false;
        }
    }

    function smartScroll() {
        if (!root.userScrolledUp) {
            root.isAutoScrolling = true;
            listView.positionViewAtEnd();
            Qt.callLater(function() { root.isAutoScrolling = false; });
        }
    }

    function sendMessage(text) {
        if (!text || text.trim() === "") return;
        root.userScrolledUp = false;
        let userIndex = aiController.sendMessage(text);
        Qt.callLater(function() {
            listView.positionViewAtIndex(userIndex, ListView.Beginning);
        });
    }

    function stopGeneration() {
        aiController.stopGeneration();
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

            color: Qt.tint(Colours.palette.m3surfaceContainerLowest,
                           Qt.rgba(Colours.palette.m3primary.r,
                                   Colours.palette.m3primary.g,
                                   Colours.palette.m3primary.b, 0.08))
            radius: Tokens.rounding.medium
            clip: true

            Rectangle {
                id: codeHeader
                width: parent.width
                height: 32
                color: Qt.tint(Colours.palette.m3surfaceContainerLow,
                               Qt.rgba(Colours.palette.m3primary.r,
                                       Colours.palette.m3primary.g,
                                       Colours.palette.m3primary.b, 0.13))
                radius: Tokens.rounding.medium

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.spacing.medium
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.extraSmall

                    Rectangle {
                        width: 8; height: 8; radius: 4
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
                    text: blockData ? highlightCode(blockData.content, lang) : ""
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
            height: loading
                ? Math.max(30, rawMathText.implicitHeight) + vGap * 2
                : (rendering ? 40 + vGap * 2 : Math.max(30, mathImage.implicitHeight + 16) + vGap * 2)

            function updateMath() {
                if (!blockData || !blockData.content) {
                    imagePath = "";
                    rendering = false;
                    lastCacheKey = "";
                    return;
                }

                if (loading) {
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

                var scriptPath = "/etc/xdg/quickshell/caelestia/utils/scripts/render_math.py";
                aiController.runCommand([scriptPath, currentLatex, colorStr, "9"], function(stdout) {
                    if (!mathBlock) return;
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

    function parseStreamingBlocks(raw) {
        if (!raw || raw === "Cortana Thinking...") return { committed: "", tail: "" };

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

    function calculateFooterHeight() {
        if (!listView || !listView.contentItem) return 0;
        var lastUserIndex = -1;
        for (var i = chatModel.count - 1; i >= 0; i--) {
            var item = chatModel.get(i);
            if (item && item.sender === "user") {
                lastUserIndex = i;
                break;
            }
        }
        if (lastUserIndex === -1) return 0;

        var heightBelowUser = 0;
        for (var c = 0; c < listView.contentItem.children.length; c++) {
            var child = listView.contentItem.children[c];
            if (child && child.hasOwnProperty("index")) {
                if (child.index >= lastUserIndex) {
                    heightBelowUser += child.height + listView.spacing;
                }
            }
        }
        if (heightBelowUser > 0) {
            heightBelowUser -= listView.spacing;
        }
        return Math.max(0, listView.height - heightBelowUser);
    }

    Item {
        id: headerBar
        anchors.top: parent.top
        anchors.topMargin: Tokens.spacing.extraSmall / 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Tokens.spacing.small
        anchors.rightMargin: Tokens.spacing.small
        height: 50

        StyledRect {
            id: segmentControl
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: {
                var w = modelSplitButton.width > 0 ? modelSplitButton.width : 188;
                return w % 2 === 0 ? w : w + 1;
            }
            height: modelSplitButton.height > 0 ? modelSplitButton.height : 38
            radius: Tokens.rounding.full
            color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
            border.width: 0
            border.color: "transparent"

            StyledRect {
                id: activeIndicator
                x: !root.showHistory ? 3 : (parent.width / 2 + 3)
                y: 3
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
                            color: !root.showHistory ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "Chat"
                            font: Tokens.font.label.medium
                            color: !root.showHistory ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showHistory = false;
                        }
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
                            color: root.showHistory ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "History"
                            font: Tokens.font.label.medium
                            color: root.showHistory ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showHistory = true;
                        }
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
            height: 38
            isRound: true

            activeColour: Colours.palette.m3primary
            inactiveColour: Colours.layer(Colours.palette.m3surfaceContainer, 1)
            activeOnColour: Colours.palette.m3onPrimary
            inactiveOnColour: Colours.palette.m3onSurfaceVariant

            checked: GlobalConfig.launcher.aiFullScreen
            isToggle: false

            onClicked: GlobalConfig.launcher.aiFullScreen = !GlobalConfig.launcher.aiFullScreen
        }

        Row {
            id: modelsRowWrapper
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.medium
            visible: opacity > 0
            opacity: !root.showHistory ? 1 : 0

            Behavior on opacity { Anim { type: Anim.DefaultEffects } }

            StyledText {
                text: "Model"
                anchors.verticalCenter: parent.verticalCenter
                font: Tokens.font.label.medium
                color: Colours.palette.m3onSurfaceVariant
            }

            SplitButton {
                id: modelSplitButton
                anchors.verticalCenter: parent.verticalCenter
                type: SplitButton.Tonal

                minLeftWidth: 150

                active: menuItems.find(m => m.modelData === GlobalConfig.ai.activeModel) ?? menuItems[0] ?? null
                menu.onItemSelected: item => { aiController.changeModel(item.modelData); }

                menuItems: modelVariants.instances
                fallbackIcon: "smart_toy"
                fallbackText: qsTr("Select Model")

                Variants {
                    id: modelVariants
                    model: aiController.availableModels
                    delegate: MenuItem { required property string modelData; text: modelData }
                }
             }
        }

        Row {
            id: historyHeaderControls
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.medium
            visible: opacity > 0
            opacity: root.showHistory && !root.showSettings ? 1 : 0

            Behavior on opacity { Anim { type: Anim.DefaultEffects } }

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
                    x: root.historyGridView ? 3 : 39
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
                            color: root.historyGridView ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.historyGridView = true
                        }
                    }

                    Item {
                        width: 38
                        height: 38

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "view_list"
                            fontStyle: Tokens.font.icon.small
                            color: !root.historyGridView ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.historyGridView = false
                        }
                    }
                }
            }
        }

        IconButton {
            id: settingsBtn
            anchors.right: newChatBtn.left
            anchors.rightMargin: Tokens.spacing.medium
            anchors.verticalCenter: parent.verticalCenter
            icon: "settings"
            width: 38
            height: 38
            isRound: true

            activeColour: Colours.palette.m3primary
            inactiveColour: Colours.layer(Colours.palette.m3surfaceContainer, 1)
            activeOnColour: Colours.palette.m3onPrimary
            inactiveOnColour: Colours.palette.m3onSurfaceVariant

            checked: root.showSettings
            isToggle: false

            visible: opacity > 0
            opacity: root.showHistory ? 1 : 0

            Behavior on opacity { Anim { type: Anim.DefaultEffects } }

            onClicked: {
                root.showSettings = !root.showSettings;
            }
        }

        IconTextButton {
            id: newChatBtn
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon: "add"
            text: "New Chat"
            isRound: true
            type: ButtonBase.Filled
            visible: opacity > 0
            opacity: root.showHistory ? 1 : 0

            Behavior on opacity { Anim { type: Anim.DefaultEffects } }

            onClicked: {
                aiController.createNewChat();
                root.showHistory = false;
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
        opacity: root.showHistory ? 0 : 1

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

            model: chatModel
            spacing: Tokens.spacing.medium
            clip: true
            footer: Item {
                width: listView.width
                height: root.calculateFooterHeight()
            }

            onContentYChanged: {
                if (!root.isAutoScrolling) {
                    var dist = contentHeight - contentY - height;
                    if (dist > 30) {
                        root.userScrolledUp = true;
                    } else {
                        root.userScrolledUp = false;
                    }
                }
            }

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
            }

            delegate: Item {
                id: delegateItem
                width: listView.width
                height: column.implicitHeight

                required property string sender
                required property string text
                required property bool loading
                required property int index

                readonly property bool isUser: sender === "user"
                readonly property bool isStatusText: text === "Cortana Thinking..." || text.startsWith("🔍") || text.startsWith("🌐") || text.startsWith("💻") || text.startsWith("📖") || text.startsWith("✍️") || text.startsWith("⚙️")
                property string messageThinking: model.thinking || ""
                property string messageModelUsed: (index >= 0 && index < chatModel.count && chatModel.get(index)) ? (chatModel.get(index).modelUsed || "") : ""

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
                                        var bw = child.blockWidth;
                                        if (bw > maxW) maxW = bw;
                                    }
                                }
                                if (delegateItem.loading) {
                                    for (var j = 0; j < streamingView.children.length; j++) {
                                        var schild = streamingView.children[j];
                                        if (schild.visible) {
                                            if (schild.hasOwnProperty("blockWidth")) {
                                                var sbw = schild.blockWidth;
                                                if (sbw > maxW) maxW = sbw;
                                            } else if (schild.hasOwnProperty("text")) {
                                                var stw = schild.implicitWidth;
                                                if (stw > maxW) maxW = stw;
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

                                Row {
                                    id: thinkingRow
                                    visible: delegateItem.loading && (delegateItem.text.trim() === "" || delegateItem.isStatusText)
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
                                        text: (delegateItem.text.trim() === "" || delegateItem.text === "Cortana Thinking...") ? "Cortana Thinking..." : delegateItem.text
                                        font: Tokens.font.body.medium
                                        color: Colours.palette.m3onSurfaceVariant
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    SequentialAnimation {
                                        running: thinkingRow.visible
                                        loops: Animation.Infinite
                                        NumberAnimation { target: thinkingRow; property: "opacity"; from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                                        NumberAnimation { target: thinkingRow; property: "opacity"; from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                                        onRunningChanged: {
                                            if (!running) {
                                                thinkingRow.opacity = 1.0;
                                            }
                                        }
                                    }
                                }

                                LoadingIndicator {
                                    width: 16
                                    height: 16
                                    visible: delegateItem.loading === true && delegateItem.text.trim() !== "" && !delegateItem.isStatusText
                                    animated: delegateItem.loading === true && delegateItem.text.trim() !== "" && !delegateItem.isStatusText
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                Repeater {
                                    model: delegateItem.loading ? [] : parseMessageBlocks(delegateItem.text)

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
                                                    item.loading = Qt.binding(function() { return delegateItem.loading; });
                                            }
                                        }
                                    }
                                }

                                Column {
                                    id: streamingView
                                    visible: delegateItem.loading && !delegateItem.isStatusText
                                    width: parent.width
                                    spacing: Tokens.spacing.small

                                    property var streamSplit: delegateItem.loading
                                        ? parseStreamingBlocks(delegateItem.text)
                                        : { committed: "", tail: "" }

                                    Repeater {
                                        model: streamingView.streamSplit.committed !== ""
                                            ? parseMessageBlocks(streamingView.streamSplit.committed)
                                            : []

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
                                        color: delegateItem.isUser
                                            ? Colours.palette.m3onPrimaryContainer
                                            : Colours.palette.m3onSurface
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
                                id: copyBtn
                                property bool copied: false
                                icon: copied ? "check" : "content_copy"
                                type: IconButton.Filled
                                width: 28
                                height: 28
                                isRound: true
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Tokens.spacing.extraSmall
                                visible: opacity > 0
                                opacity: (hoverArea.containsMouse || copyBtn.hovered) && !delegateItem.loading ? 1 : 0

                                activeColour: delegateItem.isUser ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3primary
                                inactiveColour: delegateItem.isUser ? Qt.rgba(Colours.palette.m3onPrimaryContainer.r, Colours.palette.m3onPrimaryContainer.g, Colours.palette.m3onPrimaryContainer.b, 0.15) : Qt.rgba(Colours.palette.m3onSurface.r, Colours.palette.m3onSurface.g, Colours.palette.m3onSurface.b, 0.08)
                                activeOnColour: delegateItem.isUser ? Colours.palette.m3primaryContainer : Colours.palette.m3onPrimary
                                inactiveOnColour: delegateItem.isUser ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                                Behavior on opacity { Anim { type: Anim.DefaultEffects } }

                                onClicked: {
                                    Quickshell.clipboardText = delegateItem.text;
                                    Toaster.toast("Copied", "Message copied to clipboard", "content_copy");
                                    copied = true;
                                    revertTimer.start();
                                }

                                Timer {
                                    id: revertTimer
                                    interval: 1500
                                    onTriggered: copyBtn.copied = false
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
                    NumberAnimation { target: delegateItem; property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutQuad }
                    NumberAnimation { target: column; property: "y"; from: 10; to: 0; duration: 250; easing.type: Easing.OutQuad }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: chatModel.count === 0
                spacing: Tokens.spacing.medium
                width: parent.width - Tokens.padding.large * 2

                MaterialIcon {
                    text: "forum"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.Medium).build()
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: "AI Assistant Chat"
                    font: Tokens.font.title.builders.medium.weight(Font.Bold).build()
                    color: Colours.palette.m3onSurface
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: "Type your query and press Enter."
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
        opacity: root.showHistory ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        GridView {
            id: historyGrid
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            opacity: GlobalConfig.launcher.aiHistoryGridView && !root.showSettings ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim { type: Anim.DefaultEffects } }

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

            model: historyModel

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
                            root.showHistory = false;
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
                            color: hoverArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
                            anchors.verticalCenter: parent.verticalCenter

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "chat_bubble"
                                color: hoverArea.containsMouse ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                                fontStyle: Tokens.font.icon.small
                            }
                        }

                        Column {
                            width: card.width - 40 - Tokens.spacing.medium - Tokens.padding.medium * 2 - 30
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: title
                                color: hoverArea.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            StyledText {
                                text: subtitle
                                color: hoverArea.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                                width: parent.width
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
                        Behavior on opacity { Anim { type: Anim.DefaultEffects } }
                        onClicked: aiController.deleteConversation(convId)
                    }
                }
            }
        }

        ListView {
            id: historyList
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Tokens.spacing.medium

            opacity: !GlobalConfig.launcher.aiHistoryGridView && !root.showSettings ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim { type: Anim.DefaultEffects } }

            spacing: Tokens.spacing.small
            clip: true
            model: historyModel

            delegate: Item {
                id: listDelegateItem
                width: historyList.width
                height: 76

                required property string convId
                required property string title
                required property string subtitle
                required property int index

                StyledRect {
                    id: listCard
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Tokens.rounding.medium
                    color: listHoverArea.containsMouse ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)
                    border.width: 0
                    border.color: "transparent"

                    MouseArea {
                        id: listHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            aiController.selectConversation(convId);
                            root.showHistory = false;
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
                            color: listHoverArea.containsMouse ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                            fontStyle: Tokens.font.icon.small
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
                        Behavior on opacity { Anim { type: Anim.DefaultEffects } }
                        onClicked: aiController.deleteConversation(convId)
                    }

                    Column {
                        anchors.left: bubbleIcon.right
                        anchors.leftMargin: Tokens.spacing.medium
                        anchors.right: parent.right
                        anchors.rightMargin: (listHoverArea.containsMouse || listDeleteBtn.hovered) ? (listDeleteBtn.width + Tokens.spacing.medium + Tokens.padding.medium) : Tokens.padding.medium
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Behavior on anchors.rightMargin {
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }

                        StyledText {
                            text: title
                            color: listHoverArea.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        StyledText {
                            text: subtitle
                            color: listHoverArea.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }
            }
        }

        Item {
            id: settingsView
            anchors.fill: parent
            opacity: root.showSettings ? 1 : 0
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
                    onClicked: {
                        root.showSettings = false;
                    }
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
                        height: 80
                        radius: Tokens.rounding.large
                        color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                        border.width: 0

                        Row {
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: "grid_view"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.medium
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                width: parent.width - 40 - 80
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                StyledText {
                                    text: "History View Style"
                                    font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                    color: Colours.palette.m3onSurface
                                }
                                StyledText {
                                    text: "Choose between grid and list layouts for chat history"
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3onSurfaceVariant
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }

                            StyledRect {
                                id: settingsViewTogglePill
                                width: 76
                                height: 38
                                radius: Tokens.rounding.full
                                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                                border.width: 0
                                border.color: "transparent"
                                anchors.verticalCenter: parent.verticalCenter

                                StyledRect {
                                    id: settingsViewActiveIndicator
                                    x: GlobalConfig.launcher.aiHistoryGridView ? 3 : 39
                                    y: 3
                                    width: 34;
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
                        }
                    }

                    StyledRect {
                        width: parent.width
                        height: 96
                        radius: Tokens.rounding.large
                        color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                        border.width: 0

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

                    StyledRect {
                        width: parent.width
                        height: 96
                        radius: Tokens.rounding.large
                        color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                        border.width: 0
                        opacity: GlobalConfig.launcher.aiFullScreen ? 0.5 : 1

                        MaterialIcon {
                            id: expandedHeightIcon
                            anchors.left: parent.left
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.verticalCenter: parent.verticalCenter
                            text: "swap_vert"
                            color: GlobalConfig.launcher.aiFullScreen ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                        }

                        Column {
                            anchors.left: expandedHeightIcon.right
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
                                    text: "Expanded Height"
                                    font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                    color: Colours.palette.m3onSurface
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    anchors.right: parent.right
                                    text: GlobalConfig.launcher.aiExpandedHeight + "px"
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            StyledSlider {
                                id: expandedHeightSlider
                                width: parent.width
                                from: 400; to: root.maxHeight
                                value: GlobalConfig.launcher.aiExpandedHeight
                                enabled: !GlobalConfig.launcher.aiFullScreen
                                onInteraction: v => {
                                    GlobalConfig.launcher.aiExpandedHeight = Math.round(expandedHeightSlider.from + v * (expandedHeightSlider.to - expandedHeightSlider.from));
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
                        opacity: GlobalConfig.launcher.aiFullScreen ? 0.5 : 1

                        MaterialIcon {
                            id: expandedWidthIcon
                            anchors.left: parent.left
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.verticalCenter: parent.verticalCenter
                            text: "swap_horiz"
                            color: GlobalConfig.launcher.aiFullScreen ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                        }

                        Column {
                            anchors.left: expandedWidthIcon.right
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
                                    text: "Expanded Width"
                                    font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                    color: Colours.palette.m3onSurface
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    anchors.right: parent.right
                                    text: GlobalConfig.launcher.aiExpandedWidth + "px"
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            StyledSlider {
                                id: expandedWidthSlider
                                width: parent.width
                                from: 630; 
                                to: root.screenWidth - 32
                                value: GlobalConfig.launcher.aiExpandedWidth
                                enabled: !GlobalConfig.launcher.aiFullScreen
                                onInteraction: v => {
                                    GlobalConfig.launcher.aiExpandedWidth = Math.round(expandedWidthSlider.from + v * (expandedWidthSlider.to - expandedWidthSlider.from));
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

                        Row {
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: "schedule"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.medium
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                width: parent.width - 40 - 60
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                StyledText {
                                    text: "Date & Time"
                                    font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                    color: Colours.palette.m3onSurface
                                }
                                StyledText {
                                    text: "Allow Cortana to access the current date and time"
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3onSurfaceVariant
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }

                            StyledSwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                checked: GlobalConfig.ai.agentDateTime
                                onToggled: GlobalConfig.ai.agentDateTime = checked
                            }
                        }
                    }

                    StyledRect {
                        width: parent.width
                        height: 80
                        radius: Tokens.rounding.large
                        color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                        border.width: 0

                        Row {
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: "location_on"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.medium
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                width: parent.width - 40 - 60
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                StyledText {
                                    text: "Location"
                                    font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                    color: Colours.palette.m3onSurface
                                }
                                StyledText {
                                    text: Weather.city ? Weather.city : "Allow Cortana to access system location"
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3onSurfaceVariant
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }

                            StyledSwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                checked: GlobalConfig.ai.agentLocation
                                onToggled: {
                                    GlobalConfig.ai.agentLocation = checked;
                                    if (checked) Weather.reload();
                                }
                            }
                        }
                    }

                    StyledRect {
                        width: parent.width
                        height: 80
                        radius: Tokens.rounding.large
                        color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                        border.width: 0

                        Row {
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: "public"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.medium
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                width: parent.width - 40 - 60
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                StyledText {
                                    text: "Web Search"
                                    font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                    color: Colours.palette.m3onSurface
                                }
                                StyledText {
                                    text: "Allow Cortana to perform web searches"
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3onSurfaceVariant
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }

                            StyledSwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                checked: GlobalConfig.ai.agentWebSearch
                                onToggled: GlobalConfig.ai.agentWebSearch = checked
                            }
                        }
                    }

                    StyledRect {
                        width: parent.width
                        height: 80
                        radius: Tokens.rounding.large
                        color: Colours.layer(Colours.palette.m3surfaceContainerLow, 1)
                        border.width: 0

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
    }

    StyledRect {
        id: linkStatusHover
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.spacing.medium
        height: 28

        property string displayUrl: ""

        onOpacityChanged: {
            if (opacity === 0) displayUrl = "";
        }

        Connections {
            target: root
            function onHoverLinkUrlChanged() {
                if (root.hoverLinkUrl !== "") linkStatusHover.displayUrl = root.hoverLinkUrl;
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

        Behavior on opacity { Anim { type: Anim.DefaultEffects } }

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
    
    property var renderingInlineMath: ({})
    property var compiledInlineMath: ({})

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