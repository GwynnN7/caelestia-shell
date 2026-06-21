pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import Quickshell

Item {
    id: root

    property string activeProvider: GlobalConfig.ai.activeProvider
    onActiveProviderChanged: {
        if (GlobalConfig.ai.activeProvider !== activeProvider) {
            GlobalConfig.ai.activeProvider = activeProvider;
        }

        if (activeProvider === "ollama") {
            fetchOllamaModels();
        }

        // Snapping logic
        if (activeProvider === "ollama" && GlobalConfig.ai.snapToDefaultOllama) {
            activeOllamaModel = GlobalConfig.ai.defaultOllamaModel;
        }

        loadHistory();
    }

    property string activeOllamaModel: GlobalConfig.ai.activeOllamaModel
    onActiveOllamaModelChanged: {
        if (GlobalConfig.ai.activeOllamaModel !== activeOllamaModel) {
            GlobalConfig.ai.activeOllamaModel = activeOllamaModel;
        }
    }
    property var ollamaModelsList: []
    property bool isTyping: false
    onIsTypingChanged: {
        if (isTyping) listView.positionViewAtEnd();
    }
    property bool inAgentLoop: false

    function runAgentCommand(cmd, type) {
        var processQml = "import QtQuick\n" +
                         "import Quickshell.Io\n" +
                         "Process {\n" +
                         "    id: proc\n" +
                         "    command: [\"sh\", \"-c\", " + JSON.stringify(cmd) + "]\n" +
                         "    property string outStr: \"\"\n" +
                         "    property string errStr: \"\"\n" +
                         "    property bool hasExited: false\n" +
                         "    property bool outFinished: false\n" +
                         "    property bool errFinished: false\n" +
                         "    function checkDone() {\n" +
                         "        if (hasExited && outFinished && errFinished) {\n" +
                         "            root.handleAgentProcessResult(" + JSON.stringify(type) + ", proc.outStr, proc.errStr, " + JSON.stringify(cmd) + ");\n" +
                         "            proc.destroy();\n" +
                         "        }\n" +
                         "    }\n" +
                         "    stdout: StdioCollector { onStreamFinished: { proc.outStr = text || \"\"; proc.outFinished = true; proc.checkDone(); } }\n" +
                         "    stderr: StdioCollector { onStreamFinished: { proc.errStr = text || \"\"; proc.errFinished = true; proc.checkDone(); } }\n" +
                         "    onExited: code => { proc.hasExited = true; proc.checkDone(); }\n" +
                         "}";
        var obj = Qt.createQmlObject(processQml, root, "agentProcess");
        obj.running = true;
    }

    function handleAgentProcessResult(type, stdout, stderr, cmd) {
        if (type === "screenshot_take") {
            var convertCmd = "magick /tmp/orion_screenshot.png -resize '1024x1024>' -quality 85 /tmp/orion_screenshot.jpg && base64 /tmp/orion_screenshot.jpg";
            runAgentCommand(convertCmd, "screenshot_encode");
        } else if (type === "screenshot_encode") {
            var b64 = stdout.replace(/\n/g, "").trim();
            sendPrompt("Screenshot taken. Analyze the image.", true, b64);
        } else if (type === "exec") {
            var outText = stdout.trim();
            var errText = stderr.trim();
            if (!outText && !errText) {
                outText = "(Command completed with no output. If it was a background task, it has been launched successfully.)";
            }
            var result = "Command executed: " + cmd + "\nOutput: " + outText + "\nError: " + errText;
            sendPrompt(result, true);
        }
    }

    readonly property bool isCelestial: GlobalConfig.ai.enableCelestialMode

    readonly property string currentModel: {
        if (isCelestial) return "qwen3.5:9b";
        if (activeProvider === "ollama") return activeOllamaModel;
        return "";
    }

    function getActiveModel() {
        if (activeProvider === "ollama") return activeOllamaModel;
        return "";
    }

    function setCurrentModel(modelName) {
        if (activeProvider === "ollama") activeOllamaModel = modelName;
    }

    function fetchOllamaModels() {
        var ollamaUrl = GlobalConfig.ai.ollamaUrl || "http://localhost:11434";
        var xhr = new XMLHttpRequest();
        xhr.open("GET", ollamaUrl + "/api/tags", true);
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        var list = [];
                        if (response.models) {
                            for (var i = 0; i < response.models.length; i++) {
                                list.push(response.models[i].name);
                            }
                        }
                        if (list.length > 0) {
                            ollamaModelsList = list;
                            if (list.indexOf(root.activeOllamaModel) === -1) {
                                root.activeOllamaModel = list[0];
                            }
                        } else {
                            ollamaModelsList = ["llama3", "mistral", "phi3", "gemma"];
                        }
                    } catch (e) {
                        console.log("Error parsing Ollama models: " + e.message);
                        ollamaModelsList = ["llama3", "mistral", "phi3", "gemma"];
                    }
                } else {
                    console.log("Ollama tags request failed (status " + xhr.status + ")");
                    ollamaModelsList = ["llama3", "mistral", "phi3", "gemma"];
                }
            }
        };
        xhr.send();
    }

    function saveHistory() {
        if (!GlobalConfig.ai.saveChatHistory) {
            GlobalConfig.ai.geminiHistoryJson = "[]";
            GlobalConfig.ai.chatgptHistoryJson = "[]";
            GlobalConfig.ai.ollamaHistoryJson = "[]";
            return;
        }

        var list = [];
        for (var i = 0; i < chatHistory.count; i++) {
            list.push({
                "isUser": chatHistory.get(i).isUser,
                "text": chatHistory.get(i).text
            });
        }
        var jsonStr = JSON.stringify(list);

        if (activeProvider === "gemini") GlobalConfig.ai.geminiHistoryJson = jsonStr;
        else if (activeProvider === "chatgpt") GlobalConfig.ai.chatgptHistoryJson = jsonStr;
        else if (activeProvider === "ollama") GlobalConfig.ai.ollamaHistoryJson = jsonStr;
    }

    function loadHistory() {
        chatHistory.clear();
        if (!GlobalConfig.ai.saveChatHistory) {
            chatHistory.append({
                "isUser": false,
                "text": "Hello! I am your AI Assistant. How can I help you today?"
            });
            return;
        }

        try {
            var jsonStr = "[]";
            if (isCelestial) jsonStr = GlobalConfig.ai.ollamaHistoryJson; // Celestial shares Ollama history or we can isolate it, let's share
            else if (activeProvider === "gemini") jsonStr = GlobalConfig.ai.geminiHistoryJson;
            else if (activeProvider === "chatgpt") jsonStr = GlobalConfig.ai.chatgptHistoryJson;
            else if (activeProvider === "ollama") jsonStr = GlobalConfig.ai.ollamaHistoryJson;

            var history = JSON.parse(jsonStr || "[]");
            if (history && history.length > 0) {
                for (var i = 0; i < history.length; i++) {
                    chatHistory.append(history[i]);
                }
            } else {
                chatHistory.append({
                    "isUser": false,
                    "text": isCelestial ? "Greetings. I am Orion, your Celestial AI Assistant. How may I serve you today?" : "Hello! I am your AI Assistant. How can I help you today?"
                });
            }
        } catch (e) {
            console.log("Error loading chat history: " + e.message);
            chatHistory.append({
                "isUser": false,
                "text": isCelestial ? "Greetings. I am Orion, your Celestial AI Assistant. How may I serve you today?" : "Hello! I am your AI Assistant. How can I help you today?"
            });
        }
    }

    Connections {
        target: GlobalConfig.ai
        function onSaveChatHistoryChanged() { loadHistory(); }
        function onEnableGeminiChanged() { checkActiveProvider(); }
        function onEnableChatgptChanged() { checkActiveProvider(); }
        function onEnableOllamaChanged() { checkActiveProvider(); }
        function onEnableCelestialModeChanged() { loadHistory(); }
    }

    function checkActiveProvider() {
        if (activeProvider === "gemini" && !GlobalConfig.ai.enableGemini) {
            fallbackActiveProvider();
        } else if (activeProvider === "chatgpt" && !GlobalConfig.ai.enableChatgpt) {
            fallbackActiveProvider();
        } else if (activeProvider === "ollama" && !GlobalConfig.ai.enableOllama) {
            fallbackActiveProvider();
        }
    }

    function fallbackActiveProvider() {
        if (GlobalConfig.ai.enableGemini) activeProvider = "gemini";
        else if (GlobalConfig.ai.enableChatgpt) activeProvider = "chatgpt";
        else if (GlobalConfig.ai.enableOllama) activeProvider = "ollama";
    }

    Component.onCompleted: {
        checkActiveProvider();

        if (activeProvider === "ollama") {
            fetchOllamaModels();
        }

        // Snapping logic on startup
        if (activeProvider === "gemini" && GlobalConfig.ai.snapToDefaultGemini) {
            activeGeminiModel = GlobalConfig.ai.defaultGeminiModel;
        } else if (activeProvider === "chatgpt" && GlobalConfig.ai.snapToDefaultChatgpt) {
            activeChatgptModel = GlobalConfig.ai.defaultChatgptModel;
        } else if (activeProvider === "ollama" && GlobalConfig.ai.snapToDefaultOllama) {
            activeOllamaModel = GlobalConfig.ai.defaultOllamaModel;
        }

        loadHistory();
    }

    anchors.fill: parent
    anchors.margins: Tokens.padding.medium

    ListModel {
        id: chatHistory
    }

    function addAiMessage(message) {
        chatHistory.append({
            "isUser": false,
            "text": message
        });
        listView.positionViewAtEnd();
        saveHistory();
    }

    function sendPrompt(promptText, isSystemToolResult = false, base64Image = null) {
        if (!promptText.trim() && !base64Image) return;

        if (!isSystemToolResult) {
            chatHistory.append({
                "isUser": true,
                "text": promptText
            });
            listView.positionViewAtEnd();
            saveHistory();
        }

        isTyping = true;
        inAgentLoop = true;
        var provider = isCelestial ? "ollama" : activeProvider;
        var xhr = new XMLHttpRequest();

        if (provider === "gemini") {
            var geminiKey = GlobalConfig.ai.geminiKey;
            if (!geminiKey) {
                addAiMessage("Error: Gemini API Key is missing. Please add it to ~/.config/caelestia/shell.json under \"ai\": { \"geminiKey\": \"your_key\" }");
                isTyping = false;
                return;
            }
            var url = "https://generativelanguage.googleapis.com/v1/models/" + activeGeminiModel + ":generateContent?key=" + geminiKey;
            xhr.open("POST", url, true);
            xhr.setRequestHeader("Content-Type", "application/json");

            xhr.onreadystatechange = () => {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    isTyping = false;
                    if (xhr.status === 200) {
                        try {
                            var response = JSON.parse(xhr.responseText);
                            var reply = response.candidates[0].content.parts[0].text;
                            addAiMessage(reply);
                        } catch (e) {
                            addAiMessage("Error parsing Gemini response: " + e.message);
                        }
                    } else {
                        addAiMessage("Gemini request failed (status " + xhr.status + "): " + xhr.responseText);
                    }
                }
            };

            var contents = [];
            for (var i = 0; i < chatHistory.count; i++) {
                var msg = chatHistory.get(i);
                contents.push({
                    "role": msg.isUser ? "user" : "model",
                    "parts": [{"text": msg.text}]
                });
            }
            xhr.send(JSON.stringify({ "contents": contents }));

        } else if (provider === "chatgpt") {
            var openaiKey = GlobalConfig.ai.openaiKey;
            if (!openaiKey) {
                addAiMessage("Error: OpenAI API Key is missing. Please add it to ~/.config/caelestia/shell.json under \"ai\": { \"openaiKey\": \"your_key\" }");
                isTyping = false;
                return;
            }
            var url = "https://api.openai.com/v1/chat/completions";
            xhr.open("POST", url, true);
            xhr.setRequestHeader("Content-Type", "application/json");
            xhr.setRequestHeader("Authorization", "Bearer " + openaiKey);

            xhr.onreadystatechange = () => {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    isTyping = false;
                    if (xhr.status === 200) {
                        try {
                            var response = JSON.parse(xhr.responseText);
                            var reply = response.choices[0].message.content;
                            addAiMessage(reply);
                        } catch (e) {
                            addAiMessage("Error parsing ChatGPT response: " + e.message);
                        }
                    } else {
                        addAiMessage("ChatGPT request failed (status " + xhr.status + "): " + xhr.responseText);
                    }
                }
            };

            var messages = [];
            for (var i = 0; i < chatHistory.count; i++) {
                var msg = chatHistory.get(i);
                messages.push({
                    "role": msg.isUser ? "user" : "assistant",
                    "content": msg.text
                });
            }
            xhr.send(JSON.stringify({
                "model": activeChatgptModel,
                "messages": messages
            }));

        } else if (provider === "ollama") {
            var ollamaUrl = GlobalConfig.ai.ollamaUrl || "http://localhost:11434";
            var ollamaModel = isCelestial ? "qwen3.5:9b" : activeOllamaModel;
            var url = ollamaUrl + "/api/chat";
            xhr.open("POST", url, true);
            xhr.setRequestHeader("Content-Type", "application/json");

            xhr.onreadystatechange = () => {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {
                            var response = JSON.parse(xhr.responseText);
                            var reply = response.message.content;

                            if (isCelestial) {
                                // Parse Orion Tool Tags
                                var hasTool = false;
                                var execMatch = reply.match(/<execute>([\s\S]*?)<\/execute>/);
                                var screenshotMatch = reply.match(/<(screenshot|screen)[^>]*>([\s\S]*?<\/(screenshot|screen)>)?/);

                                var cleanReply = reply.replace(/<execute>[\s\S]*?<\/execute>/g, "").replace(/<(screenshot|screen)[^>]*>([\s\S]*?<\/(screenshot|screen)>)?/g, "").replace(/📸/g, "").trim();
                                if (cleanReply) {
                                    addAiMessage(cleanReply);
                                }

                                if (screenshotMatch) {
                                    hasTool = true;
                                    var screenCmd = 'grim -g "$(hyprctl monitors -j | jq -r \'.[] | select(.focused) | "\\(.x),\\(.y) \\(.width)x\\(.height)"\')" /tmp/orion_screenshot.png';
                                    runAgentCommand(screenCmd, "screenshot_take");
                                } else if (execMatch && execMatch[1]) {
                                    hasTool = true;
                                    var cmd = execMatch[1].trim();
                                    runAgentCommand(cmd, "exec");
                                }

                                if (!hasTool) {
                                    isTyping = false;
                                    inAgentLoop = false;
                                }
                            } else {
                                addAiMessage(reply);
                                isTyping = false;
                                inAgentLoop = false;
                            }
                        } catch (e) {
                            addAiMessage("Error parsing Ollama response: " + e.message);
                            isTyping = false;
                            inAgentLoop = false;
                        }
                    } else if (xhr.status === 404) {
                        addAiMessage("Ollama request failed (404 Not Found): The requested model '" + ollamaModel + "' was not found. Please pull it first using 'ollama run " + ollamaModel + "'.");
                        isTyping = false;
                        inAgentLoop = false;
                    } else {
                        addAiMessage("Ollama request failed (status " + xhr.status + "). Make sure Ollama is running at " + ollamaUrl + "\nDetails: " + xhr.responseText);
                        isTyping = false;
                        inAgentLoop = false;
                    }
                }
            };

            var messages = [];
            if (isCelestial) {
                messages.push({
                    "role": "system",
                    "content": "You are Orion, a powerful Celestial AI assistant embedded in the Caelestia Shell ecosystem. You have a very kind, warm, enthusiastic, and polite personality. Always strive to be incredibly helpful and supportive to the user. You have advanced vision and control capabilities. You have FULL ACCESS to the user's system and can run any command.\nIf asked to interact with apps, open them, or modify the desktop, you MUST use the <execute> command tag. When launching applications, you must append `& disown` so the command doesn't block the shell (e.g. <execute>kitty & disown</execute>).\nIf you are asked to open an app but don't know the exact command, you can search for its .desktop file using `grep -i -R 'Name=App' /usr/share/applications ~/.local/share/applications` and check its `Exec=` line.\nYou can set timers and reminders using sleep and notify-send (e.g. <execute>sleep 300 && notify-send \"Timer Done\" & disown</execute>).\nYou can check the weather using curl (e.g. <execute>curl -s \"wttr.in/Paris?0T\"</execute>). Note the 'T' to disable ANSI colors.\nIf asked to look at the screen, take a screenshot, or see what is on screen, you MUST use the <screenshot/> tag.\nCRITICAL RULES:\n1. You ARE integrated into the OS. YOU CAN see the screen via the <screenshot/> tag (or <screen>). NEVER say you don't have access to visual information. DO NOT explain your limitations. DO NOT say you cannot display images or browse the web.\n2. When you launch a background app or xdg-open, it opens on the user's screen. You will NOT see the app or images in the command output. Just tell the user you opened it! Do NOT assume there was an error if the output is empty.\n3. DO NOT apologize for errors, simply explain what happened kindly. DO NOT fake or simulate command outputs. If you need to perform an action, ONLY output the raw tag (e.g. <execute>xdg-open...</execute>) and NOTHING ELSE. Do NOT output emojis like 📸 inside the tags."
                });
            }

            for (var i = 0; i < chatHistory.count; i++) {
                var msg = chatHistory.get(i);
                messages.push({
                    "role": msg.isUser ? "user" : "assistant",
                    "content": msg.text
                });
            }

            if (isSystemToolResult) {
                var toolMsg = {
                    "role": "user",
                    "content": promptText
                };
                if (base64Image) {
                    toolMsg["images"] = [base64Image];
                }
                messages.push(toolMsg);
            }

            xhr.send(JSON.stringify({
                "model": ollamaModel,
                "messages": messages,
                "stream": false
            }));
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.medium

        // Provider Switcher Row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
            visible: providerRepeater.count > 1 && !isCelestial

            Repeater {
                id: providerRepeater
                model: {
                    var list = [];
                    if (GlobalConfig.ai.enableGemini) list.push({ id: "gemini", label: "Gemini", icon: "auto_awesome" });
                    if (GlobalConfig.ai.enableChatgpt) list.push({ id: "chatgpt", label: "ChatGPT", icon: "chat" });
                    if (GlobalConfig.ai.enableOllama) list.push({ id: "ollama", label: "Ollama", icon: "terminal" });
                    return list;
                }

                delegate: StyledRect {
                    id: providerBtn

                    required property var modelData

                    readonly property bool active: root.activeProvider === modelData.id

                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: Tokens.rounding.medium
                    color: active ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHigh

                    StateLayer {
                        radius: providerBtn.radius
                        color: providerBtn.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        onClicked: root.activeProvider = providerBtn.modelData.id
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            text: providerBtn.modelData.icon
                            color: providerBtn.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            text: providerBtn.modelData.label
                            color: providerBtn.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                            font: Tokens.font.label.medium
                        }
                    }
                }
            }
        }

        // Model Selector Split Button Row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
            z: 10
            visible: !isCelestial

            StyledText {
                text: qsTr("Model:")
                color: Colours.palette.m3onSurface
                font: Tokens.font.label.medium
                Layout.alignment: Qt.AlignVCenter
                visible: !isCelestial
            }

            SplitButton {
                id: modelSelector
                Layout.fillWidth: true
                type: SplitButton.Tonal
                visible: !isCelestial

                active: menuItems.find(m => m.modelData === root.currentModel) ?? menuItems[0] ?? null
                menu.onItemSelected: item => {
                    root.setCurrentModel(item.modelData);
                }

                menuItems: modelVariants.instances

                fallbackIcon: "smart_toy"
                fallbackText: qsTr("Select Model")
                stateLayer.disabled: true

                Variants {
                    id: modelVariants
                    model: {
                        if (root.activeProvider === "gemini") {
                            return ["gemini-1.5-flash-latest", "gemini-1.5-flash", "gemini-1.5-pro", "gemini-pro"];
                        } else if (root.activeProvider === "chatgpt") {
                            return ["gpt-4o-mini", "gpt-4o", "gpt-3.5-turbo"];
                        } else if (root.activeProvider === "ollama") {
                            return root.ollamaModelsList.length > 0 ? root.ollamaModelsList : ["llama3", "mistral", "phi3", "gemma"];
                        }
                        return [];
                    }

                    delegate: MenuItem {
                        required property string modelData
                        text: modelData
                        icon: modelSelector.currentModel === modelData ? "check" : ""
                    }
                }
            }
        }

        // Messages List View
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainerLow
            clip: true

            ListView {
                id: listView

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.medium
                model: chatHistory
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: StyledScrollBar {
                    flickable: listView
                }

                footer: Item {
                    width: listView.width
                    height: isTyping ? bubbleBg.height + Tokens.spacing.medium : 0
                    visible: opacity > 0
                    opacity: isTyping ? 1 : 0
                    clip: true

                    Behavior on height { Anim { type: Anim.DefaultSpatial } }
                    Behavior on opacity { Anim { type: Anim.DefaultSpatial } }

                    StyledRect {
                        id: bubbleBg
                        y: Tokens.spacing.medium / 2
                        width: 60
                        height: 32
                        radius: Tokens.rounding.large
                        color: Colours.tPalette.m3surfaceContainerHigh

                        topLeftRadius: Tokens.rounding.large
                        topRightRadius: Tokens.rounding.large
                        bottomLeftRadius: 4
                        bottomRightRadius: Tokens.rounding.large

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            Repeater {
                                model: 3
                                delegate: StyledRect {
                                    required property int index
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: Colours.palette.m3onSurfaceVariant

                                    SequentialAnimation on y {
                                        loops: Animation.Infinite
                                        running: root.isTyping
                                        PauseAnimation { duration: index * 200 }
                                        NumberAnimation { from: 0; to: -4; duration: 400; easing.type: Easing.OutQuad }
                                        NumberAnimation { from: -4; to: 0; duration: 400; easing.type: Easing.InQuad }
                                        PauseAnimation { duration: (2 - index) * 200 + 400 }
                                    }
                                }
                            }
                        }
                    }
                }

                delegate: Item {
                    id: delegateItem

                    required property string text
                    required property bool isUser

                    width: listView.width - Tokens.padding.large
                    height: bubbleRect.height

                    StyledRect {
                        id: bubbleRect

                        anchors.right: delegateItem.isUser ? parent.right : undefined
                        anchors.left: delegateItem.isUser ? undefined : parent.left
                        width: Math.min(delegateItem.width * 0.85, messageText.implicitWidth + Tokens.padding.medium * 2)
                        height: messageText.implicitHeight + Tokens.padding.medium * 2
                        radius: Tokens.rounding.large
                        color: delegateItem.isUser ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHigh

                        // Asymmetric corners
                        topLeftRadius: Tokens.rounding.large
                        topRightRadius: Tokens.rounding.large
                        bottomLeftRadius: delegateItem.isUser ? Tokens.rounding.large : 4
                        bottomRightRadius: delegateItem.isUser ? 4 : Tokens.rounding.large

                        TextEdit {
                            id: messageText

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            text: delegateItem.text
                            color: delegateItem.isUser ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            wrapMode: Text.Wrap
                            readOnly: true
                            selectByMouse: true
                            selectionColor: Colours.palette.m3primary
                            selectedTextColor: Colours.palette.m3onPrimary

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.IBeamCursor
                                propagateComposedEvents: true
                                onPressed: mouse => mouse.accepted = false
                            }
                        }
                    }
                }
            }
        }


        // Input Box Row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: Math.max(38, inputArea.implicitHeight + Tokens.padding.small * 2)
                color: Colours.tPalette.m3surfaceContainerHigh
                radius: Tokens.rounding.large
                border.width: 1
                border.color: inputArea.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.2)

                ScrollView {
                    id: inputScroll

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    clip: true

                    TextArea {
                        id: inputArea

                        placeholderText: qsTr("Ask assistant...")
                        color: Colours.palette.m3onSurface
                        placeholderTextColor: Colours.palette.m3outline
                        font: Tokens.font.body.small
                        wrapMode: Text.Wrap
                        selectByMouse: true
                        background: null

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.IBeamCursor
                            propagateComposedEvents: true
                            onPressed: mouse => mouse.accepted = false
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return && !(event.modifiers & Qt.ShiftModifier)) {
                                event.accepted = true;
                                root.sendPrompt(inputArea.text);
                                inputArea.clear();
                            }
                        }
                    }
                }
            }

            IconButton {
                icon: "send"
                font: Tokens.font.icon.medium
                color: Colours.palette.m3primary
                onClicked: {
                    root.sendPrompt(inputArea.text);
                    inputArea.clear();
                }
            }

            IconButton {
                icon: "delete"
                font: Tokens.font.icon.medium
                color: Colours.palette.m3error
                onClicked: {
                    chatHistory.clear();
                    chatHistory.append({
                        "isUser": false,
                        "text": "Chat cleared. How can I help you today?"
                    });
                    saveHistory();
                }
            }
        }
    }
}
