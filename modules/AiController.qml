pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.LocalStorage 2.0 as Sql
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: aiController

    property alias chatModel: internalChatModel
    property alias historyModel: internalHistoryModel

    ListModel {
        id: internalChatModel
    }
    ListModel {
        id: internalHistoryModel
    }

    property var conversationsList: []
    property string activeConversationId: ""
    property var activeProcesses: []
    property var activeXhr: null
    property bool isGenerating: false
    property bool generationStopped: false
    property string ollamaHost: "http://127.0.0.1:11434"

    property int connectionRetries: 0
    property var availableModels: [GlobalConfig.ai.activeModel]

    signal chatLoaded

    Component.onCompleted: {
        loadFromDB();
        reloadConversations();
        ensureOllamaRunning();
    }

    Timer {
        id: retryTimer
        interval: 1000
        repeat: false
        onTriggered: updateModel()
    }

    Component {
        id: processComponent
        Process {
            id: proc
            property var callback: null
            stdout: StdioCollector {
                onStreamFinished: {
                    if (proc.callback) {
                        proc.callback(text);
                        proc.callback = null;
                    }
                    var arr = aiController.activeProcesses;
                    var idx = arr.indexOf(proc);
                    if (idx !== -1) {
                        arr.splice(idx, 1);
                        aiController.activeProcesses = arr;
                    }
                    proc.destroy();
                }
            }
        }
    }

    function getDatabase() {
        return Sql.LocalStorage.openDatabaseSync("CortanaAIChats", "", "Caelestia AI Chat Local Storage", 5000000);
    }

    function loadFromDB() {
        try {
            var db = getDatabase();
            db.transaction(function (tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS Settings(key TEXT UNIQUE, value TEXT)');
                tx.executeSql('CREATE TABLE IF NOT EXISTS Conversations(id TEXT UNIQUE, title TEXT)');
                tx.executeSql('CREATE TABLE IF NOT EXISTS Messages(id INTEGER PRIMARY KEY AUTOINCREMENT, convId TEXT, sender TEXT, text TEXT, thinking TEXT, model TEXT)');

                var rs2 = tx.executeSql('SELECT value FROM Settings WHERE key=?', ['activeConversationId']);
                activeConversationId = rs2.rows.length > 0 ? rs2.rows.item(0).value || "" : "";

                conversationsList = [];
                var rsConv = tx.executeSql('SELECT id, title FROM Conversations ORDER BY rowid DESC');
                for (var i = 0; i < rsConv.rows.length; i++) {
                    conversationsList.push({
                        id: rsConv.rows.item(i).id,
                        title: rsConv.rows.item(i).title,
                        messages: []
                    });
                }
            });
        } catch (e) {
            console.log("Error loading from database:", e.toString());
            conversationsList = [];
            activeConversationId = "";
        }
    }

    function saveHistory() {
        if (!activeConversationId)
            return;

        var currentTitle = "New Chat";
        var msgsToSave = [];

        for (var j = 0; j < chatModel.count; j++) {
            var item = chatModel.get(j);
            if (item.loading)
                continue;

            msgsToSave.push({
                sender: item.sender,
                text: item.text,
                thinking: item.thinking || "",
                model: item.modelUsed || ""
            });

            if (j === 0 && item.sender === "user" && currentTitle === "New Chat") {
                var firstLine = (item.text || "").split("\n")[0].trim();
                currentTitle = firstLine.length > 50 ? firstLine.substring(0, 47) + "..." : firstLine;
            }
        }

        var foundIndex = conversationsList.findIndex(c => c.id === activeConversationId);
        if (foundIndex !== -1) {
            conversationsList[foundIndex].title = currentTitle;
            conversationsList[foundIndex].messages = msgsToSave;
        }

        try {
            var db = getDatabase();
            db.transaction(function (tx) {
                tx.executeSql('INSERT OR REPLACE INTO Settings(key, value) VALUES(?, ?)', ['activeConversationId', activeConversationId]);
                tx.executeSql('INSERT OR REPLACE INTO Conversations(id, title) VALUES(?, ?)', [activeConversationId, currentTitle]);

                tx.executeSql('DELETE FROM Messages WHERE convId=?', [activeConversationId]);
                for (var k = 0; k < msgsToSave.length; k++) {
                    var m = msgsToSave[k];
                    tx.executeSql('INSERT INTO Messages(convId, sender, text, thinking, model) VALUES(?, ?, ?, ?, ?)', [activeConversationId, m.sender, m.text, m.thinking, m.model]);
                }
            });
        } catch (e) {
            console.log("Save error:", e.toString());
        }
    }

    function reloadHistoryList() {
        loadFromDB();
        historyModel.clear();
        try {
            var db = getDatabase();
            db.transaction(function (tx) {
                for (var i = 0; i < conversationsList.length; i++) {
                    var conv = conversationsList[i];
                    var lastResp = "New conversation";

                    var rsMsg = tx.executeSql('SELECT text FROM Messages WHERE convId=? ORDER BY id DESC LIMIT 1', [conv.id]);
                    if (rsMsg.rows.length > 0) {
                        var snippet = rsMsg.rows.item(0).text;
                        if (snippet)
                            lastResp = snippet.replace(/\r?\n/g, " ").trim();
                    }

                    historyModel.append({
                        convId: conv.id,
                        title: conv.title,
                        subtitle: lastResp
                    });
                }
            });
        } catch (e) {}
    }

    function reloadConversations() {
        loadFromDB();
        if (conversationsList.length === 0) {
            var newId = "conv-" + Date.now() + "-" + Math.floor(Math.random() * 1000);
            conversationsList = [
                {
                    id: newId,
                    title: "New Chat",
                    messages: []
                }
            ];
            activeConversationId = newId;
            chatModel.clear();
            try {
                var db = getDatabase();
                db.transaction(function (tx) {
                    tx.executeSql('INSERT OR REPLACE INTO Settings(key, value) VALUES(?, ?)', ['activeConversationId', activeConversationId]);
                    tx.executeSql('INSERT OR REPLACE INTO Conversations(id, title) VALUES(?, ?)', [newId, "New Chat"]);
                });
            } catch (e) {}
        }

        if (!activeConversationId || activeConversationId === "") {
            activeConversationId = conversationsList[0].id;
        }

        reloadHistoryList();
        chatModel.clear();

        try {
            var db2 = getDatabase();
            db2.transaction(function (tx) {
                var rsMsg = tx.executeSql('SELECT sender, text, thinking, model FROM Messages WHERE convId=? ORDER BY id ASC', [activeConversationId]);
                for (var i = 0; i < rsMsg.rows.length; i++) {
                    chatModel.append({
                        sender: rsMsg.rows.item(i).sender,
                        text: rsMsg.rows.item(i).text,
                        thinking: rsMsg.rows.item(i).thinking,
                        modelUsed: rsMsg.rows.item(i).model,
                        loading: false
                    });
                }
            });
        } catch (e) {
            console.log(e);
        }

        chatLoaded();
    }

    function createNewChat() {
        saveHistory();

        var newId = "conv-" + Date.now() + "-" + Math.floor(Math.random() * 1000);

        try {
            var db = getDatabase();
            db.transaction(function (tx) {
                tx.executeSql('INSERT OR REPLACE INTO Conversations(id, title) VALUES(?, ?)', [newId, "New Chat"]);
                tx.executeSql('INSERT OR REPLACE INTO Settings(key, value) VALUES(?, ?)', ['activeConversationId', newId]);
            });
        } catch (e) {}

        activeConversationId = newId;
        reloadConversations();
    }

    function selectConversation(convId) {
        saveHistory();
        activeConversationId = convId;

        try {
            var db = getDatabase();
            db.transaction(function (tx) {
                tx.executeSql('INSERT OR REPLACE INTO Settings(key, value) VALUES(?, ?)', ['activeConversationId', activeConversationId]);
            });
        } catch (e) {}

        reloadConversations();
    }

    function deleteConversation(convId) {
        try {
            var db = getDatabase();
            db.transaction(function (tx) {
                tx.executeSql('DELETE FROM Conversations WHERE id=?', [convId]);
                tx.executeSql('DELETE FROM Messages WHERE convId=?', [convId]);
            });
        } catch (e) {}

        var list = conversationsList.slice();
        var idx = list.findIndex(c => c.id === convId);
        if (idx !== -1) {
            list.splice(idx, 1);
            conversationsList = list;
            if (activeConversationId === convId) {
                activeConversationId = conversationsList.length > 0 ? conversationsList[0].id : "";
                try {
                    var db2 = getDatabase();
                    db2.transaction(function (tx) {
                        tx.executeSql('INSERT OR REPLACE INTO Settings(key, value) VALUES(?, ?)', ['activeConversationId', activeConversationId]);
                    });
                } catch (e) {}
            }
            reloadConversations();
        }
    }

    function ensureOllamaRunning() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", ollamaHost, true);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 0) {
                    Quickshell.execDetached(["env", "OLLAMA_HOST=127.0.0.1:11434", "ollama", "serve"]);
                    connectionRetries = 0;
                    retryTimer.start();
                } else {
                    updateModel();
                }
            }
        };
        xhr.send();
    }

    function updateModel() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", ollamaHost + "/api/tags", true);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var res = JSON.parse(xhr.responseText);
                        if (res.models && res.models.length > 0) {
                            var modelsList = [];
                            for (var i = 0; i < res.models.length; i++)
                                modelsList.push(res.models[i].name);
                            availableModels = modelsList;
                        }
                    } catch (e) {}
                } else if (connectionRetries < 20) {
                    connectionRetries++;
                    retryTimer.start();
                }
            }
        };
        xhr.send();
    }

    function getSystemInstructions() {
        let basePrompt = GlobalConfig.ai.systemPrompt || "You are a helpful AI assistant called Cortana, integrated into the user's OS. You can use tools to assist the user.";
        let instructions = basePrompt;

        if (GlobalConfig.ai.agentDateTime)
            instructions += "\n- [Context] Current Date/Time: " + new Date().toString();
        if (GlobalConfig.ai.agentLocation && (Weather.city || Weather.loc))
            instructions += "\n- [Context] Geolocation: " + (Weather.city || "") + " (" + (Weather.loc || "") + ")";

        return instructions;
    }

    function getSystemTools() {
        let tools = [];
        if (GlobalConfig.ai.agentTakeScreenshot)
            tools.push({
                type: "function",
                function: {
                    name: "take_screenshot",
                    description: "Takes a screenshot of the user's screen and returns it for visual analysis.",
                    parameters: {
                        type: "object",
                        properties: {}
                    }
                }
            });
        if (GlobalConfig.ai.agentWebSearch)
            tools.push({
                type: "function",
                function: {
                    name: "web_search",
                    description: "Searches the web using a headless browser. Returns the top 5 results with snippets and URLs.",
                    parameters: {
                        type: "object",
                        properties: {
                            query: {
                                type: "string"
                            },
                            page: {
                                type: "integer",
                                description: "Page number to fetch (default 1)"
                            }
                        },
                        required: ["query"]
                    }
                }
            });
        if (GlobalConfig.ai.agentReadWebpage)
            tools.push({
                type: "function",
                function: {
                    name: "read_webpage",
                    description: "Navigates to a specific URL and returns the main text content.",
                    parameters: {
                        type: "object",
                        properties: {
                            url: {
                                type: "string"
                            }
                        },
                        required: ["url"]
                    }
                }
            });
        if (GlobalConfig.ai.agentOpenApp)
            tools.push({
                type: "function",
                function: {
                    name: "open_app",
                    description: "Searches for and launches an application installed on the user's system.",
                    parameters: {
                        type: "object",
                        properties: {
                            app_name: {
                                type: "string"
                            }
                        },
                        required: ["app_name"]
                    }
                }
            });
        if (GlobalConfig.ai.agentSetTimer)
            tools.push({
                type: "function",
                function: {
                    name: "set_timer",
                    description: "Sets a timer that triggers a desktop notification when finished.",
                    parameters: {
                        type: "object",
                        properties: {
                            seconds: {
                                type: "integer"
                            },
                            message: {
                                type: "string"
                            }
                        },
                        required: ["seconds", "message"]
                    }
                }
            });
        if (GlobalConfig.ai.agentGetWeather)
            tools.push({
                type: "function",
                function: {
                    name: "get_weather",
                    description: "Gets the current weather for a specific location.",
                    parameters: {
                        type: "object",
                        properties: {
                            location: {
                                type: "string"
                            }
                        },
                        required: ["location"]
                    }
                }
            });
        if (GlobalConfig.ai.agentCaelestiaCommand)
            tools.push({
                type: "function",
                function: {
                    name: "caelestia_command",
                    description: "Execute a caelestia CLI command to manage the system. Valid commands: shell, toggle, scheme, search, screenshot, record, clipboard, emoji, wallpaper, resizer, install, update.",
                    parameters: {
                        type: "object",
                        properties: {
                            subcommand: {
                                type: "string"
                            },
                            args: {
                                type: "string",
                                description: "Additional arguments to pass"
                            }
                        },
                        required: ["subcommand"]
                    }
                }
            });
        if (GlobalConfig.ai.agentCortanaApi)
            tools.push({
                type: "function",
                function: {
                    name: "cortana_api",
                    description: "Control smart automation and room sensors via Cortana API. Use the 'route' parameter to specify the device, sensor or setting to interact with. If only the 'route' is provided, it will return the current status or value. Use the other parameters to perform actions or set values. For computer control, use the 'command' parameter.",
                    parameters: {
                        type: "object",
                        properties: {
                            route: {
                                type: "string",
                                description: "Route to call: devices/{device} (device: Computer, Lamp, Power, Generic), sensors/{sensor} (sensor: Temperature, Humidity, Light, Motion), raspberry/{info} (info: Temperature, Location, Ip), settings/{setting} (setting: LightThreshold, AutomaticMode), computer (use command parameter)"
                            },
                            action: {
                                type: "string",
                                description: "Action to perform on devices: on, off, toggle"
                            },
                            value: {
                                type: "string",
                                description: "Integer value to set for settings. For booleans use 1 or 0"
                            },
                            command: {
                                type: "string",
                                description: "Command string to pass to the computer: shutdown, restart, suspend, system (rebooting to Windows OS)"
                            }
                        },
                        required: ["route"]
                    }
                }
            });
        if (GlobalConfig.ai.agentRunCommand)
            tools.push({
                type: "function",
                function: {
                    name: "run_command",
                    description: "Run a non-blocking terminal sequence directly in the bash shell.",
                    parameters: {
                        type: "object",
                        properties: {
                            bash_cmd: {
                                type: "string"
                            }
                        },
                        required: ["bash_cmd"]
                    }
                }
            });
        if (GlobalConfig.ai.agentFileOps) {
            tools.push({
                type: "function",
                function: {
                    name: "read_file",
                    description: "Read content from local disk files.",
                    parameters: {
                        type: "object",
                        properties: {
                            path: {
                                type: "string"
                            }
                        },
                        required: ["path"]
                    }
                }
            });
            tools.push({
                type: "function",
                function: {
                    name: "write_file",
                    description: "Create or overwrite a file with specific content.",
                    parameters: {
                        type: "object",
                        properties: {
                            path: {
                                type: "string"
                            },
                            content: {
                                type: "string"
                            }
                        },
                        required: ["path", "content"]
                    }
                }
            });
        }
        return tools;
    }

    function changeModel(newModel) {
        if (availableModels.includes(newModel)) {
            var currentModel = GlobalConfig.ai.activeModel;

            if (currentModel && currentModel !== newModel) {
                var unloadXhr = new XMLHttpRequest();
                unloadXhr.open("POST", ollamaHost + "/api/generate", true);
                unloadXhr.setRequestHeader("Content-Type", "application/json");

                unloadXhr.send(JSON.stringify({
                    model: currentModel,
                    keep_alive: 0
                }));

                console.log("Unloaded model from VRAM: " + currentModel);
            }

            GlobalConfig.ai.activeModel = newModel;
            console.log("Switched active model to: " + newModel);
        }
    }

    function runCommand(cmdArgs, callback) {
        var proc = processComponent.createObject(aiController, {
            command: cmdArgs,
            callback: callback,
            running: true
        });
        var arr = aiController.activeProcesses;
        arr.push(proc);
        aiController.activeProcesses = arr;
    }

    function executeTool(toolCall, callback) {
        let name = toolCall.function.name;
        let args = toolCall.function.arguments || {};
        if (typeof args === "string") {
            try {
                args = JSON.parse(args);
            } catch (e) {
                args = {};
            }
        }

        if (name === "web_search") {
            if (!GlobalConfig.ai.agentWebSearch)
                return callback("Error: Disabled.");
            runCommand(["python3", `${Quickshell.shellDir}/scripts/web_search.py`, args.query || ""], callback);
        } else if (name === "read_webpage") {
            if (!GlobalConfig.ai.agentReadWebpage)
                return callback("Error: Disabled.");
            runCommand(["python3", `${Quickshell.shellDir}/scripts/fetch_url.py`, args.url || ""], callback);
        } else if (name === "take_screenshot") {
            if (!GlobalConfig.ai.agentTakeScreenshot)
                return callback("Error: Disabled.");
            let screenCmd = 'grim -g "$(hyprctl monitors -j | jq -r \'.[] | select(.focused) | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"\')" /tmp/orion_screenshot.png && ' + 'magick /tmp/orion_screenshot.png -resize \'1024x1024>\' -quality 85 /tmp/orion_screenshot.jpg && ' + 'base64 -w 0 /tmp/orion_screenshot.jpg';
            runCommand(["sh", "-c", screenCmd], function (stdout) {
                var b64 = stdout.replace(/\n/g, "").trim();
                if (b64)
                    callback({
                        text: "Screenshot taken. Analyze the attached image.",
                        image: b64
                    });
                else
                    callback("Error: Failed to capture or encode screenshot.");
            });
        } else if (name === "open_app") {
            if (!GlobalConfig.ai.agentOpenApp)
                return callback("Error: Disabled.");
            runCommand(["python3", `${Quickshell.shellDir}/scripts/safe_launcher.py`, args.app_name || ""], callback);
        } else if (name === "set_timer") {
            if (!GlobalConfig.ai.agentSetTimer)
                return callback("Error: Disabled.");
            let timerCmd = 'sleep "$1" && echo "$2" | cortana notify & disown';
            runCommand(["sh", "-c", timerCmd, "sh", (args.seconds || 5).toString(), args.message || "Timer finished"], () => callback("Timer successfully set for " + (args.seconds || 5) + " seconds."));
        } else if (name === "get_weather") {
            if (!GlobalConfig.ai.agentGetWeather)
                return callback("Error: Disabled.");
            runCommand(["curl", "-s", "wttr.in/" + (args.location || "") + "?0T"], callback);
        } else if (name === "caelestia_command") {
            if (!GlobalConfig.ai.agentCaelestiaCommand)
                return callback("Error: Disabled.");
            let subArgs = args.args ? args.args.split(" ") : [];
            runCommand(["sh", "-c", 'caelestia "$@"', "sh", args.subcommand || ""].concat(subArgs), callback);
        } else if (name === "cortana_api") {
            if (!GlobalConfig.ai.agentCortanaApi)
                return callback("Error: Disabled.");
            let cApiArgs = ["cortana", "api", args.route || ""];
            if (args.action)
                cApiArgs.push("-act", args.action);
            if (args.value)
                cApiArgs.push("-val", args.value.toString());
            runCommand(cApiArgs, callback);
        } else if (name === "run_command") {
            if (!GlobalConfig.ai.agentRunCommand)
                return callback("Error: Disabled.");
            runCommand(["sh", "-c", args.bash_cmd || ""], callback);
        } else if (name === "read_file") {
            if (!GlobalConfig.ai.agentFileOps)
                return callback("Error: Disabled.");
            runCommand(["cat", args.path || ""], callback);
        } else if (name === "write_file") {
            if (!GlobalConfig.ai.agentFileOps)
                return callback("Error: Disabled.");
            runCommand(["python3", "-c", "import sys; open(sys.argv[1], 'w').write(sys.argv[2])", args.path || "", args.content || ""], () => callback("File payload saved."));
        } else {
            callback("Error: Unknown or disabled tool.");
        }
    }

    function queryOllama(aiIndex, iteration, messages, thinkingText, resetCount) {
        if (resetCount === undefined)
            resetCount = 0;
        if (iteration > 4) {
            chatModel.setProperty(aiIndex, "text", "Error: Agent reached maximum tool execution limit (8 iterations).");
            chatModel.setProperty(aiIndex, "thinking", thinkingText);
            chatModel.setProperty(aiIndex, "loading", false);

            saveHistory();
            reloadHistoryList();
            isGenerating = false;
            return;
        }

        var xhr = new XMLHttpRequest();
        aiController.activeXhr = xhr;
        xhr.open("POST", ollamaHost + "/api/chat", true);
        xhr.setRequestHeader("Content-Type", "application/json");

        var lastProcessedIndex = 0;
        var currentText = "";
        var currentReasoning = thinkingText;
        var toolCallsQueue = [];

        xhr.onreadystatechange = function () {
            if (aiController.generationStopped)
                return;

            if (xhr.readyState === 3 || xhr.readyState === 4) {
                if (xhr.status === 200) {
                    var newText = xhr.responseText.substring(lastProcessedIndex);
                    var lastNewline = newText.lastIndexOf("\n");

                    if (lastNewline !== -1) {
                        var chunkToProcess = newText.substring(0, lastNewline);
                        lastProcessedIndex += lastNewline + 1;

                        var lines = chunkToProcess.split("\n");
                        for (var i = 0; i < lines.length; i++) {
                            var line = lines[i].trim();
                            if (!line)
                                continue;
                            try {
                                var data = JSON.parse(line);
                                if (data.message) {
                                    if (data.message.content)
                                        currentText += data.message.content;

                                    if (data.message.thinking)
                                        currentReasoning += data.message.thinking;
                                    else if (data.message.reasoning_content)
                                        currentReasoning += data.message.reasoning_content;

                                    if (data.message.tool_calls) {
                                        for (var tc = 0; tc < data.message.tool_calls.length; tc++) {
                                            toolCallsQueue.push(data.message.tool_calls[tc]);
                                        }
                                    }
                                }
                            } catch (e) {}
                        }

                        chatModel.setProperty(aiIndex, "thinking", currentReasoning);
                        if (xhr.readyState === 3) {
                            chatModel.setProperty(aiIndex, "text", currentText);
                        }
                    }
                }
            }

            if (xhr.readyState === XMLHttpRequest.DONE) {
                xhr.onreadystatechange = null;
                if (aiController.activeXhr === xhr)
                    aiController.activeXhr = null;
                if (aiController.generationStopped)
                    return;

                if (xhr.status === 200) {
                    if (!currentText && toolCallsQueue.length === 0) {
                        if (iteration < 7) {
                            var nudge = iteration < 3 ? "Please answer the user's question directly." : "Output your answer now. Do not include any preamble.";
                            messages.push({
                                role: "user",
                                content: nudge
                            });
                            queryOllama(aiIndex, iteration + 1, messages, currentReasoning, resetCount);
                            return;
                        } else if (resetCount < 3) {
                            var freshMsgs = [messages[0]];
                            var lastUserMsg = messages.slice().reverse().find(m => m.role === "user");
                            if (lastUserMsg)
                                freshMsgs.push({
                                    role: "user",
                                    content: lastUserMsg.content
                                });
                            queryOllama(aiIndex, 1, freshMsgs, currentReasoning, resetCount + 1);
                            return;
                        } else {
                            chatModel.remove(aiIndex);
                            saveHistory();
                            reloadHistoryList();
                            isGenerating = false;
                            return;
                        }
                    }

                    if (toolCallsQueue.length > 0) {
                        var stepText = "";
                        for (var ti = 0; ti < toolCallsQueue.length; ti++) {
                            stepText += "- **Tool Call**: " + toolCallsQueue[ti].function.name + "\n";
                        }
                        chatModel.setProperty(aiIndex, "text", "⚙️ Executing tools...");
                        chatModel.setProperty(aiIndex, "thinking", currentReasoning + "\n" + stepText + "  > *Executing tools...*");
                        chatModel.setProperty(aiIndex, "loading", true);

                        messages.push({
                            role: "assistant",
                            content: currentText,
                            tool_calls: toolCallsQueue
                        });
                        var completedCount = 0;

                        function runParallelTool(index) {
                            let tCall = toolCallsQueue[index];
                            executeTool(tCall, function (toolResult) {
                                if (aiController.generationStopped)
                                    return;

                                if (typeof toolResult === 'object' && toolResult !== null && toolResult.image) {
                                    messages.push({
                                        role: "tool",
                                        name: tCall.function.name,
                                        content: toolResult.text,
                                        images: [toolResult.image]
                                    });
                                } else {
                                    messages.push({
                                        role: "tool",
                                        name: tCall.function.name,
                                        content: String(toolResult)
                                    });
                                }

                                completedCount++;
                                if (completedCount === toolCallsQueue.length) {
                                    var updatedThinking = currentReasoning + "\n" + stepText + "  > Completed.\n\n";
                                    queryOllama(aiIndex, iteration + 1, messages, updatedThinking, resetCount);
                                }
                            });
                        }
                        for (var tiq = 0; tiq < toolCallsQueue.length; tiq++)
                            runParallelTool(tiq);
                    } else {
                        chatModel.setProperty(aiIndex, "text", currentText);
                        chatModel.setProperty(aiIndex, "thinking", currentReasoning);
                        chatModel.setProperty(aiIndex, "loading", false);

                        saveHistory();
                        reloadHistoryList();
                        isGenerating = false;
                    }
                } else {
                    chatModel.setProperty(aiIndex, "text", "Error: Could not connect to Ollama.");
                    chatModel.setProperty(aiIndex, "loading", false);
                    saveHistory();
                    reloadHistoryList();
                    isGenerating = false;
                }
            }
        };

        var requestData = {
            model: GlobalConfig.ai.activeModel,
            messages: messages,
            stream: true,
            think: true,
            tools: getSystemTools(),
            options: {
                num_ctx: GlobalConfig.ai.contextWindow
            }
        };
        xhr.send(JSON.stringify(requestData));
    }

    function sendMessage(text) {
        if (!text || text.trim() === "")
            return;
        isGenerating = true;
        generationStopped = false;
        ensureOllamaRunning();

        chatModel.append({
            sender: "user",
            text: text,
            loading: false,
            thinking: ""
        });
        var userIndex = chatModel.count - 1;

        chatModel.append({
            sender: "ai",
            text: "",
            loading: true,
            thinking: "",
            modelUsed: GlobalConfig.ai.activeModel
        });
        const aiIndex = chatModel.count - 1;

        var messages = [];
        messages.push({
            role: "system",
            content: getSystemInstructions()
        });

        for (var i = 0; i < chatModel.count - 1; i++) {
            var msg = chatModel.get(i);
            if (msg.sender === "ai" && (msg.text === "" || msg.text.startsWith("⚙️")))
                continue;
            messages.push({
                role: msg.sender === "user" ? "user" : "assistant",
                content: msg.text
            });
        }

        queryOllama(aiIndex, 1, messages, "", 0);
        return userIndex;
    }

    function stopGeneration() {
        generationStopped = true;
        if (activeXhr) {
            var xhrToAbort = activeXhr;
            activeXhr = null;
            xhrToAbort.onreadystatechange = null;
            xhrToAbort.abort();
        }
        if (activeProcesses && activeProcesses.length > 0) {
            for (var p = 0; p < activeProcesses.length; p++) {
                if (activeProcesses[p]) {
                    activeProcesses[p].callback = null;
                    activeProcesses[p].destroy();
                }
            }
            activeProcesses = [];
        }

        isGenerating = false;
        for (var i = chatModel.count - 1; i >= 0; i--) {
            var msg = chatModel.get(i);
            if (msg && msg.sender === "ai" && msg.loading) {
                chatModel.setProperty(i, "loading", false);
                var currentText = msg.text || "";
                if (currentText === "" || currentText.startsWith("⚙️")) {
                    chatModel.setProperty(i, "text", "Generation stopped.");
                } else if (currentText.trim() !== "") {
                    chatModel.setProperty(i, "text", currentText + "\n\n*— stopped*");
                }
            }
        }

        saveHistory();
        reloadHistoryList();

        Qt.callLater(function () {
            generationStopped = false;
        });
    }

    property var renderingInlineMath: ({})
    property var compiledInlineMath: ({})

    function parseStreamingBlocks(raw) {
        if (!raw || raw === "")
            return {
                committed: "",
                tail: ""
            };
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
                    if (blockEnd < tail.length && tail[blockEnd] === "\n")
                        blockEnd++;
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
        return {
            committed: committed.trim(),
            tail: tail
        };
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
                    blocks.push({
                        type: "text",
                        content: txt,
                        language: ""
                    });
            }
            if (match[1]) {
                blocks.push({
                    type: "code",
                    content: match[3] || "",
                    language: match[2] || "code"
                });
            } else if (match[4]) {
                blocks.push({
                    type: "math",
                    content: match[5] || "",
                    language: ""
                });
            }
            last = match.index + match[0].length;
        }
        if (last < raw.length) {
            var rest = raw.substring(last).trim();
            if (rest.length > 0)
                blocks.push({
                    type: "text",
                    content: rest,
                    language: ""
                });
        }
        return blocks.length > 0 ? blocks : [
            {
                type: "text",
                content: raw,
                language: ""
            }
        ];
    }

    function highlightCode(code, lang) {
        var l = (lang || "").toLowerCase();
        function bright(c, f) {
            return Qt.lighter(c, f || 2.0) + "";
        }
        var C = {
            keyword: bright(Colours.palette.m3primary, 2.0),
            builtin: bright(Colours.palette.m3primary, 1.7),
            string: bright(Colours.palette.m3tertiary, 2.0),
            number: bright(Colours.palette.m3error, 2.2),
            comment: Colours.palette.m3onSurfaceVariant + "",
            operator: bright(Colours.palette.m3secondary, 2.0),
            func: bright(Colours.palette.m3primary, 1.85),
            normal: Colours.palette.m3onSurface + ""
        };
        var keywords = {
            python: ["False", "None", "True", "and", "as", "assert", "async", "await", "break", "class", "continue", "def", "del", "elif", "else", "except", "finally", "for", "from", "global", "if", "import", "in", "is", "lambda", "nonlocal", "not", "or", "pass", "raise", "return", "try", "while", "with", "yield"],
            javascript: ["async", "await", "break", "case", "catch", "class", "const", "continue", "debugger", "default", "delete", "do", "else", "export", "extends", "finally", "for", "function", "if", "import", "in", "instanceof", "let", "new", "of", "return", "static", "super", "switch", "this", "throw", "try", "typeof", "var", "void", "while", "with", "yield", "true", "false", "null", "undefined"],
            typescript: ["abstract", "any", "as", "async", "await", "boolean", "break", "case", "catch", "class", "const", "constructor", "continue", "declare", "default", "delete", "do", "else", "enum", "export", "extends", "false", "finally", "for", "from", "function", "if", "implements", "import", "in", "instanceof", "interface", "let", "module", "namespace", "new", "null", "number", "of", "private", "protected", "public", "readonly", "return", "static", "string", "super", "switch", "this", "throw", "true", "try", "type", "typeof", "undefined", "var", "void", "while", "yield"],
            rust: ["as", "async", "await", "break", "const", "continue", "crate", "dyn", "else", "enum", "extern", "false", "fn", "for", "if", "impl", "in", "let", "loop", "match", "mod", "move", "mut", "pub", "ref", "return", "self", "Self", "static", "struct", "super", "trait", "true", "type", "union", "unsafe", "use", "where", "while"],
            go: ["break", "case", "chan", "const", "continue", "default", "defer", "else", "fallthrough", "for", "func", "go", "goto", "if", "import", "interface", "map", "package", "range", "return", "select", "struct", "switch", "type", "var", "true", "false", "nil"],
            java: ["abstract", "assert", "boolean", "break", "byte", "case", "catch", "char", "class", "const", "continue", "default", "do", "double", "else", "enum", "extends", "final", "finally", "float", "for", "goto", "if", "implements", "import", "instanceof", "int", "interface", "long", "native", "new", "null", "package", "private", "protected", "public", "return", "short", "static", "strictfp", "super", "switch", "synchronized", "this", "throw", "throws", "transient", "true", "try", "void", "volatile", "while"],
            kotlin: ["abstract", "actual", "annotation", "as", "break", "by", "catch", "class", "companion", "const", "constructor", "continue", "crossinline", "data", "do", "dynamic", "else", "enum", "expect", "external", "false", "field", "final", "finally", "for", "fun", "get", "if", "import", "in", "infix", "init", "inline", "inner", "interface", "internal", "is", "it", "lateinit", "noinline", "null", "object", "open", "operator", "out", "override", "package", "private", "protected", "public", "reified", "return", "sealed", "set", "super", "suspend", "tailrec", "this", "throw", "true", "try", "typealias", "typeof", "val", "var", "vararg", "when", "where", "while"],
            swift: ["as", "break", "case", "catch", "class", "continue", "default", "defer", "deinit", "do", "else", "enum", "extension", "fallthrough", "false", "fileprivate", "final", "for", "func", "guard", "if", "import", "in", "init", "inout", "internal", "is", "lazy", "let", "mutating", "nil", "open", "operator", "override", "private", "protocol", "public", "repeat", "required", "rethrows", "return", "self", "Self", "static", "struct", "subscript", "super", "switch", "throw", "throws", "true", "try", "typealias", "var", "weak", "where", "while"],
            bash: ["if", "then", "else", "elif", "fi", "for", "while", "do", "done", "case", "esac", "in", "function", "return", "export", "local", "readonly", "unset", "shift", "break", "continue", "exit", "echo", "source", "alias", "declare", "typeset", "true", "false"],
            cpp: ["alignas", "alignof", "and", "and_eq", "asm", "auto", "bitand", "bitor", "bool", "break", "case", "catch", "char", "char8_t", "char16_t", "char32_t", "class", "compl", "concept", "const", "consteval", "constexpr", "constinit", "const_cast", "continue", "co_await", "co_return", "co_yield", "decltype", "default", "delete", "do", "double", "dynamic_cast", "else", "enum", "explicit", "export", "extern", "false", "float", "for", "friend", "goto", "if", "inline", "int", "long", "mutable", "namespace", "new", "noexcept", "not", "not_eq", "nullptr", "operator", "or", "or_eq", "private", "protected", "public", "reinterpret_cast", "requires", "return", "short", "signed", "sizeof", "static", "static_assert", "static_cast", "struct", "switch", "template", "this", "thread_local", "throw", "true", "try", "typedef", "typeid", "typename", "union", "unsigned", "using", "virtual", "void", "volatile", "wchar_t", "while", "xor", "xor_eq"],
            sql: ["SELECT", "FROM", "WHERE", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "ALTER", "TABLE", "INDEX", "VIEW", "TRIGGER", "PROCEDURE", "FUNCTION", "DATABASE", "SCHEMA", "JOIN", "INNER", "LEFT", "RIGHT", "FULL", "OUTER", "ON", "AS", "GROUP", "BY", "ORDER", "HAVING", "LIMIT", "OFFSET", "UNION", "ALL", "DISTINCT", "AND", "OR", "NOT", "IN", "IS", "NULL", "LIKE", "BETWEEN", "CASE", "WHEN", "THEN", "ELSE", "END", "EXISTS", "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "UNIQUE", "CHECK", "DEFAULT", "AUTO_INCREMENT", "SET", "VALUES", "INTO", "BEGIN", "COMMIT", "ROLLBACK", "TRANSACTION", "INT", "VARCHAR", "TEXT", "BOOLEAN", "FLOAT", "DOUBLE", "DATETIME", "DATE", "TIMESTAMP"]
        };
        var kw = keywords[l] || keywords[l === "js" ? "javascript" : l === "ts" ? "typescript" : l === "sh" || l === "shell" ? "bash" : l === "c" || l === "c++" ? "cpp" : l === "kt" ? "kotlin" : ""] || [];
        var kwSet = {};
        for (var ki = 0; ki < kw.length; ki++)
            kwSet[kw[ki]] = true;
        function esc(s) {
            return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        }
        function span(color, text) {
            return '<font color="' + color + '">' + esc(text) + '</font>';
        }

        var lines = code.split("\n");
        var out = [];

        var lineComment = "//";
        var blockCommentStart = "/*";
        var blockCommentEnd = "*/";
        if (l === "python" || l === "py" || l === "bash" || l === "sh" || l === "shell" || l === "ruby" || l === "rb") {
            lineComment = "#";
            blockCommentStart = "";
            blockCommentEnd = "";
        } else if (l === "sql") {
            lineComment = "--";
        } else if (l === "html" || l === "xml") {
            lineComment = "";
            blockCommentStart = "";
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
                        if (line[j] === '\\') {
                            j += 2;
                            continue;
                        }
                        if (line[j] === quote) {
                            j++;
                            break;
                        }
                        j++;
                    }
                    result += span(C.string, line.substring(i, j));
                    i = j;
                    continue;
                }

                if (ch === '`' && (l === "javascript" || l === "js" || l === "typescript" || l === "ts")) {
                    var j2 = i + 1;
                    while (j2 < line.length) {
                        if (line[j2] === '\\') {
                            j2 += 2;
                            continue;
                        }
                        if (line[j2] === '`') {
                            j2++;
                            break;
                        }
                        j2++;
                    }
                    result += span(C.string, line.substring(i, j2));
                    i = j2;
                    continue;
                }

                if (/[0-9]/.test(ch) || (ch === '.' && /[0-9]/.test(line[i + 1] || ''))) {
                    var j3 = i;
                    while (j3 < line.length && /[0-9a-fA-FxXoObB_\.]/.test(line[j3]))
                        j3++;
                    result += span(C.number, line.substring(i, j3));
                    i = j3;
                    continue;
                }

                if (/[a-zA-Z_$]/.test(ch)) {
                    var j4 = i;
                    while (j4 < line.length && /[\w$]/.test(line[j4]))
                        j4++;
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
        if (!md)
            return "";
        function esc(s) {
            return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        }

        function inlineHtml(line) {
            var codePlaceholders = [];
            line = line.replace(/`([^`]+)`/g, function (m, code) {
                var idx = codePlaceholders.length;
                codePlaceholders.push("<code>" + esc(code) + "</code>");
                return "\x00CODE" + idx + "\x00";
            });
            var mathPlaceholders = [];
            line = line.replace(/\$([^\$\n]+)\$/g, function (m, formula) {
                var idx = mathPlaceholders.length;
                mathPlaceholders.push(m);
                return "\x00MATH" + idx + "\x00";
            });
            line = line.replace(/\\\([\s\S]*?\\\)/g, function (m) {
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
            line = line.replace(/\x00MATH(\d+)\x00/g, function (m, idx) {
                return mathPlaceholders[parseInt(idx)];
            });
            line = line.replace(/\x00CODE(\d+)\x00/g, function (m, idx) {
                return codePlaceholders[parseInt(idx)];
            });
            return line;
        }

        var lines = md.split("\n");
        var html = "";
        var inList = false;
        var inOList = false;
        var inTable = false;
        var tableHeaderActive = false;

        function closeList() {
            if (inList) {
                html += "</ul>";
                inList = false;
            }
            if (inOList) {
                html += "</ol>";
                inOList = false;
            }
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
                if (cells[0] === "")
                    cells.shift();
                if (cells[cells.length - 1] === "")
                    cells.pop();
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
                if (!inList) {
                    closeList();
                    html += "<ul>";
                    inList = true;
                }
                html += "<li>" + inlineHtml(ulm[1]) + "</li>";
                continue;
            }

            var olm = line.match(/^\d+\.\s+(.*)$/);
            if (olm) {
                if (!inOList) {
                    closeList();
                    html += "<ol>";
                    inOList = true;
                }
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
        if (!html)
            return "";
        var fg = colorStr;
        if (fg.startsWith("#") && fg.length === 9) {
            fg = "#" + fg.substring(3, 9) + fg.substring(1, 3);
        }

        var size = "18";
        var processed = html;
        processed = processed.replace(/\\\(([^\)]*?)\\\)/g, function (match, formula) {
            formula = formula.trim();
            if (formula.length === 0)
                return match;
            var cacheKey = formula + "|" + fg + "|" + size;
            if (root.compiledInlineMath[cacheKey]) {
                return '<img src="file://' + root.compiledInlineMath[cacheKey] + '" height="22" align="middle" style="vertical-align:middle;margin:0 1px" />';
            } else {
                if (!root.renderingInlineMath[cacheKey]) {
                    root.renderingInlineMath[cacheKey] = true;
                    var scriptPath = `${Quickshell.shellDir}/scripts/render_math.py`;
                    aiController.runCommand([scriptPath, formula, colorStr, size], function (stdout) {
                        var path = stdout.trim();
                        if (root) {
                            if (root.renderingInlineMath)
                                delete root.renderingInlineMath[cacheKey];
                            if (root.compiledInlineMath)
                                root.compiledInlineMath[cacheKey] = path;
                        }
                        if (callback)
                            callback();
                    });
                }
                return match;
            }
        });

        processed = processed.replace(/\$([^\$\n]+)\$/g, function (match, formula) {
            formula = formula.trim();
            if (formula.length === 0)
                return match;
            if (/^[0-9.,\s+\-*\/=()]+$/.test(formula) && !/[\^\\_{]/.test(formula)) {
                return match;
            }

            var cacheKey = formula + "|" + fg + "|" + size;
            if (root.compiledInlineMath[cacheKey]) {
                return '<img src="file://' + root.compiledInlineMath[cacheKey] + '" height="22" align="middle" style="vertical-align:middle;margin:0 1px" />';
            } else {
                if (!root.renderingInlineMath[cacheKey]) {
                    root.renderingInlineMath[cacheKey] = true;
                    var scriptPath = `${Quickshell.shellDir}/scripts/render_math.py`;
                    aiController.runCommand([scriptPath, formula, colorStr, size], function (stdout) {
                        var path = stdout.trim();
                        if (root) {
                            if (root.renderingInlineMath)
                                delete root.renderingInlineMath[cacheKey];
                            if (root.compiledInlineMath)
                                root.compiledInlineMath[cacheKey] = path;
                        }
                        if (callback)
                            callback();
                    });
                }
                return match;
            }
        });

        return processed;
    }

    function processInlineMath(content, colorStr, isUserMsg, callback) {
        if (!content)
            return "";
        var fg = colorStr;
        if (fg.startsWith("#") && fg.length === 9) {
            fg = "#" + fg.substring(3, 9) + fg.substring(1, 3);
        }

        var size = "18";
        var processed = content;
        processed = processed.replace(/\\\(([\s\S]*?)\\\)/g, function (match, formula) {
            formula = formula.trim();
            if (formula.length === 0)
                return match;

            var cacheKey = formula + "|" + fg + "|" + size;
            if (root.compiledInlineMath[cacheKey]) {
                return '<img src="file://' + root.compiledInlineMath[cacheKey] + '" height="22" align="middle" style="vertical-align:middle;margin:0 1px" />';
            } else {
                if (!root.renderingInlineMath[cacheKey]) {
                    root.renderingInlineMath[cacheKey] = true;
                    var scriptPath = `${Quickshell.shellDir}/scripts/render_math.py`;
                    aiController.runCommand([scriptPath, formula, colorStr, size], function (stdout) {
                        var path = stdout.trim();
                        if (root) {
                            if (root.renderingInlineMath)
                                delete root.renderingInlineMath[cacheKey];
                            if (root.compiledInlineMath)
                                root.compiledInlineMath[cacheKey] = path;
                        }
                        if (callback)
                            callback();
                    });
                }
                return match;
            }
        });

        processed = processed.replace(/\$([^\$\n]+)\$/g, function (match, formula) {
            formula = formula.trim();
            if (formula.length === 0)
                return match;
            if (/^[0-9.,\s+\-*\/=()]+$/.test(formula) && !/[\^\\_]/.test(formula)) {
                return match;
            }

            var cacheKey = formula + "|" + fg + "|" + size;
            if (root.compiledInlineMath[cacheKey]) {
                return '<img src="file://' + root.compiledInlineMath[cacheKey] + '" height="22" align="middle" style="vertical-align:middle;margin:0 1px" />';
            } else {
                if (!root.renderingInlineMath[cacheKey]) {
                    root.renderingInlineMath[cacheKey] = true;
                    var scriptPath = `${Quickshell.shellDir}/scripts/render_math.py`;
                    aiController.runCommand([scriptPath, formula, colorStr, size], function (stdout) {
                        var path = stdout.trim();
                        if (root) {
                            if (root.renderingInlineMath)
                                delete root.renderingInlineMath[cacheKey];
                            if (root.compiledInlineMath)
                                root.compiledInlineMath[cacheKey] = path;
                        }
                        if (callback)
                            callback();
                    });
                }
                return match;
            }
        });

        return processed;
    }
}
