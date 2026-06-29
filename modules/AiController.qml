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

    ListModel { id: internalChatModel }
    ListModel { id: internalHistoryModel }
    
    property var conversationsList: []
    property string activeConversationId: ""
    property var activeProcesses: []
    property var activeXhr: null
    property bool isGenerating: false
    property bool generationStopped: false
    property string ollamaHost: "http://127.0.0.1:11435"
    
    property int connectionRetries: 0
    property var availableModels: [GlobalConfig.ai.activeModel]

    signal chatLoaded()

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
            db.transaction(function(tx) {
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
        } catch(e) {
            console.log("Error loading from database:", e.toString());
            conversationsList = [];
            activeConversationId = "";
        }
    }

    function saveHistory() {
        if (!activeConversationId) return;

        var currentTitle = "New Chat";
        var msgsToSave = [];
        
        for (var j = 0; j < chatModel.count; j++) {
            var item = chatModel.get(j);
            if (item.loading) continue; 
            
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
            db.transaction(function(tx) {
                tx.executeSql('INSERT OR REPLACE INTO Settings(key, value) VALUES(?, ?)', ['activeConversationId', activeConversationId]);
                tx.executeSql('INSERT OR REPLACE INTO Conversations(id, title) VALUES(?, ?)', [activeConversationId, currentTitle]);

                tx.executeSql('DELETE FROM Messages WHERE convId=?', [activeConversationId]);
                for (var k = 0; k < msgsToSave.length; k++) {
                    var m = msgsToSave[k];
                    tx.executeSql('INSERT INTO Messages(convId, sender, text, thinking, model) VALUES(?, ?, ?, ?, ?)', 
                        [activeConversationId, m.sender, m.text, m.thinking, m.model]);
                }
            });
        } catch(e) { console.log("Save error:", e.toString()); }
    }

    function reloadHistoryList() {
        loadFromDB();
        historyModel.clear();
        try {
            var db = getDatabase();
            db.transaction(function(tx) {
                for (var i = 0; i < conversationsList.length; i++) {
                    var conv = conversationsList[i];
                    var lastResp = "New conversation";
                    
                    var rsMsg = tx.executeSql('SELECT text FROM Messages WHERE convId=? ORDER BY id DESC LIMIT 1', [conv.id]);
                    if (rsMsg.rows.length > 0) {
                        var snippet = rsMsg.rows.item(0).text;
                        if (snippet) lastResp = snippet.replace(/\r?\n/g, " ").trim();
                    }
                    
                    historyModel.append({ convId: conv.id, title: conv.title, subtitle: lastResp });
                }
            });
        } catch(e) {}
    }

    function reloadConversations() {
        loadFromDB();
        if (conversationsList.length === 0) {
            var newId = "conv-" + Date.now() + "-" + Math.floor(Math.random() * 1000);
            conversationsList = [{ id: newId, title: "New Chat", messages: [] }];
            activeConversationId = newId;
            chatModel.clear();
            try {
                var db = getDatabase();
                db.transaction(function(tx) {
                    tx.executeSql('INSERT OR REPLACE INTO Settings(key, value) VALUES(?, ?)', ['activeConversationId', activeConversationId]);
                    tx.executeSql('INSERT OR REPLACE INTO Conversations(id, title) VALUES(?, ?)', [newId, "New Chat"]);
                });
            } catch(e) {}
        }

        if (!activeConversationId || activeConversationId === "") {
            activeConversationId = conversationsList[0].id;
        }

        reloadHistoryList();
        chatModel.clear();

        try {
            var db2 = getDatabase();
            db2.transaction(function(tx) {
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
        } catch(e) { console.log(e); }

        chatLoaded();
    }

    function createNewChat() {
        saveHistory();
        
        var newId = "conv-" + Date.now() + "-" + Math.floor(Math.random() * 1000);
        
        try {
            var db = getDatabase();
            db.transaction(function(tx) {
                tx.executeSql('INSERT OR REPLACE INTO Conversations(id, title) VALUES(?, ?)', [newId, "New Chat"]);
                tx.executeSql('INSERT OR REPLACE INTO Settings(key, value) VALUES(?, ?)', ['activeConversationId', newId]);
            });
        } catch(e) {}
        
        activeConversationId = newId;
        reloadConversations();
    }

    function selectConversation(convId) {
        saveHistory();
        activeConversationId = convId;

        try {
            var db = getDatabase();
            db.transaction(function(tx) {
                tx.executeSql('INSERT OR REPLACE INTO Settings(key, value) VALUES(?, ?)', ['activeConversationId', activeConversationId]);
            });
        } catch(e) {}

        reloadConversations();
    }

    function deleteConversation(convId) {
        try {
            var db = getDatabase();
            db.transaction(function(tx) {
                tx.executeSql('DELETE FROM Conversations WHERE id=?', [convId]);
                tx.executeSql('DELETE FROM Messages WHERE convId=?', [convId]);
            });
        } catch(e) {}

        var list = conversationsList.slice();
        var idx = list.findIndex(c => c.id === convId);
        if (idx !== -1) {
            list.splice(idx, 1);
            conversationsList = list;
            if (activeConversationId === convId) {
                activeConversationId = conversationsList.length > 0 ? conversationsList[0].id : "";
                try {
                    var db2 = getDatabase();
                    db2.transaction(function(tx) {
                        tx.executeSql('INSERT OR REPLACE INTO Settings(key, value) VALUES(?, ?)', ['activeConversationId', activeConversationId]);
                    });
                } catch(e) {}
            }
            reloadConversations();
        }
    }

    function ensureOllamaRunning() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", ollamaHost, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 0) {
                    Quickshell.execDetached(["env", "OLLAMA_HOST=127.0.0.1:11435", "ollama", "serve"]);
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
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var res = JSON.parse(xhr.responseText);
                        if (res.models && res.models.length > 0) {
                            var modelsList = [];
                            for (var i = 0; i < res.models.length; i++) modelsList.push(res.models[i].name);
                            availableModels = modelsList;
                        }
                    } catch(e) {}
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

        if (GlobalConfig.ai.agentDateTime) instructions += "\n- Current Host Context Date/Time: " + new Date().toString();
        if (GlobalConfig.ai.agentLocation && (Weather.city || Weather.loc)) instructions += "\n- Geolocation Node: " + (Weather.city || "") + " (" + (Weather.loc || "") + ")";
        
        return instructions;
    }
    
    function getSystemTools() {
        let tools = [];
        if (GlobalConfig.ai.agentTakeScreenshot) tools.push({
            type: "function", function: { name: "take_screenshot", description: "Takes a screenshot of the user's screen and returns it for visual analysis.", parameters: { type: "object", properties: {} } }
        });
        if (GlobalConfig.ai.agentWebSearch) tools.push({
            type: "function", function: { name: "web_search", description: "Searches the web using a headless browser. Returns the top 5 results with snippets and URLs.", parameters: { type: "object", properties: { query: { type: "string" }, page: { type: "integer", description: "Page number to fetch (default 1)" } }, required: ["query"] } }
        });
        if (GlobalConfig.ai.agentReadWebpage) tools.push({
            type: "function", function: { name: "read_webpage", description: "Navigates to a specific URL and returns the main text content.", parameters: { type: "object", properties: { url: { type: "string" } }, required: ["url"] } }
        });
        if (GlobalConfig.ai.agentOpenApp) tools.push({
            type: "function", function: { name: "open_app", description: "Searches for and launches an application installed on the user's system.", parameters: { type: "object", properties: { app_name: { type: "string" } }, required: ["app_name"] } }
        });
        if (GlobalConfig.ai.agentSetTimer) tools.push({
            type: "function", function: { name: "set_timer", description: "Sets a timer that triggers a desktop notification when finished.", parameters: { type: "object", properties: { seconds: { type: "integer" }, message: { type: "string" } }, required: ["seconds", "message"] } }
        });
        if (GlobalConfig.ai.agentGetWeather) tools.push({
            type: "function", function: { name: "get_weather", description: "Gets the current weather for a specific location.", parameters: { type: "object", properties: { location: { type: "string" } }, required: ["location"] } }
        });
        if (GlobalConfig.ai.agentCaelestiaCommand) tools.push({
            type: "function", function: { name: "caelestia_command", description: "Execute a caelestia CLI command to manage the system. Valid commands: shell, toggle, scheme, search, screenshot, record, clipboard, emoji, wallpaper, resizer, install, update.", parameters: { type: "object", properties: { subcommand: { type: "string" }, args: { type: "string", description: "Additional arguments to pass" } }, required: ["subcommand"] } }
        });
        if (GlobalConfig.ai.agentCortanaApi) tools.push({
            type: "function", function: { name: "cortana_api", description: "Control smart automation and room sensors via Cortana API.", parameters: { type: "object", properties: { route: { type: "string", description: "Route like devices/Lamp, sensors/Temperature" }, action: { type: "string", description: "on, off, toggle" }, value: { type: "string", description: "Integer value or 1/0" } }, required: ["route"] } }
        });
        if (GlobalConfig.ai.agentRunCommand) tools.push({
            type: "function", function: { name: "run_command", description: "Run a non-blocking terminal sequence directly in the bash shell.", parameters: { type: "object", properties: { bash_cmd: { type: "string" } }, required: ["bash_cmd"] } }
        });
        if (GlobalConfig.ai.agentFileOps) {
            tools.push({
                type: "function", function: { name: "read_file", description: "Read content from local disk files.", parameters: { type: "object", properties: { path: { type: "string" } }, required: ["path"] } }
            });
            tools.push({
                type: "function", function: { name: "write_file", description: "Create or overwrite a file with specific content.", parameters: { type: "object", properties: { path: { type: "string" }, content: { type: "string" } }, required: ["path", "content"] } }
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
            try { args = JSON.parse(args); } catch(e) { args = {}; }
        }

        if (name === "web_search") {
            if (!GlobalConfig.ai.agentWebSearch) return callback("Error: Disabled.");
            runCommand(["python3", "/etc/xdg/quickshell/caelestia/utils/scripts/web_search.py", args.query || ""], callback);
        } else if (name === "read_webpage") {
            if (!GlobalConfig.ai.agentReadWebpage) return callback("Error: Disabled.");
            runCommand(["python3", "/etc/xdg/quickshell/caelestia/utils/scripts/fetch_url.py", args.url || ""], callback);
        } else if (name === "take_screenshot") {
            if (!GlobalConfig.ai.agentTakeScreenshot) return callback("Error: Disabled.");
            let screenCmd = 'grim -g "$(hyprctl monitors -j | jq -r \'.[] | select(.focused) | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"\')" /tmp/orion_screenshot.png && ' +
                            'magick /tmp/orion_screenshot.png -resize \'1024x1024>\' -quality 85 /tmp/orion_screenshot.jpg && ' +
                            'base64 -w 0 /tmp/orion_screenshot.jpg';
            runCommand(["sh", "-c", screenCmd], function(stdout) {
                var b64 = stdout.replace(/\n/g, "").trim();
                if (b64) callback({ text: "Screenshot taken. Analyze the attached image.", image: b64 });
                else callback("Error: Failed to capture or encode screenshot.");
            });
        } else if (name === "open_app") {
            if (!GlobalConfig.ai.agentOpenApp) return callback("Error: Disabled.");
            runCommand(["python3", "/etc/xdg/quickshell/caelestia/utils/scripts/safe_launcher.py", args.app_name || ""], callback);
        } else if (name === "set_timer") {
            if (!GlobalConfig.ai.agentSetTimer) return callback("Error: Disabled.");
            let timerCmd = 'sleep "$1" && echo "$2" | cortana notify & disown';
            runCommand(["sh", "-c", timerCmd, "sh", (args.seconds || 5).toString(), args.message || "Timer finished"], () => callback("Timer successfully set for " + (args.seconds || 5) + " seconds."));
        } else if (name === "get_weather") {
            if (!GlobalConfig.ai.agentGetWeather) return callback("Error: Disabled.");
            runCommand(["curl", "-s", "wttr.in/" + (args.location || "") + "?0T"], callback);
        } else if (name === "caelestia_command") {
            if (!GlobalConfig.ai.agentCaelestiaCommand) return callback("Error: Disabled.");
            let subArgs = args.args ? args.args.split(" ") : [];
            runCommand(["sh", "-c", 'caelestia "$@"', "sh", args.subcommand || ""].concat(subArgs), callback);
        } else if (name === "cortana_api") {
            if (!GlobalConfig.ai.agentCortanaApi) return callback("Error: Disabled.");
            let cApiArgs = ["cortana", "api", args.route || ""];
            if (args.action) cApiArgs.push("-act", args.action);
            if (args.value) cApiArgs.push("-val", args.value.toString());
            runCommand(cApiArgs, callback);
        } else if (name === "run_command") {
            if (!GlobalConfig.ai.agentRunCommand) return callback("Error: Disabled.");
            runCommand(["sh", "-c", args.bash_cmd || ""], callback);
        } else if (name === "read_file") {
            if (!GlobalConfig.ai.agentFileOps) return callback("Error: Disabled.");
            runCommand(["cat", args.path || ""], callback);
        } else if (name === "write_file") {
            if (!GlobalConfig.ai.agentFileOps) return callback("Error: Disabled.");
            runCommand(["python3", "-c", "import sys; open(sys.argv[1], 'w').write(sys.argv[2])", args.path || "", args.content || ""], () => callback("File payload saved."));
        } else {
            callback("Error: Unknown or disabled tool.");
        }
    }

    function queryOllama(aiIndex, iteration, messages, thinkingText, resetCount) {
        if (resetCount === undefined) resetCount = 0;
        if (iteration > 8) {
            chatModel.setProperty(aiIndex, "text", "Error: Agent reached maximum tool execution limit (8 iterations).");
            chatModel.setProperty(aiIndex, "thinking", thinkingText);
            chatModel.setProperty(aiIndex, "loading", false);
            
            saveHistory();
            reloadHistoryList();
            isGenerating = false;
            return;
        }

        var tempThinking = thinkingText !== "" ? thinkingText + "\n" : "";
        tempThinking += "- **Cortana Thinking (Step " + iteration + ")**: Querying LLM...";
        chatModel.setProperty(aiIndex, "thinking", tempThinking);

        var xhr = new XMLHttpRequest();
        aiController.activeXhr = xhr;
        xhr.open("POST", ollamaHost + "/api/chat", true);
        xhr.setRequestHeader("Content-Type", "application/json");

        var lastProcessedIndex = 0;
        var currentText = "";
        var currentReasoning = thinkingText;
        var toolCallsQueue = [];

        xhr.onreadystatechange = function() {
            if (aiController.generationStopped) return;

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
                            if (!line) continue;
                            try {
                                var data = JSON.parse(line);
                                if (data.message) {
                                    if (data.message.content) currentText += data.message.content;
                                    if (data.message.reasoning_content) currentReasoning += data.message.reasoning_content;
                                    if (data.message.tool_calls) {
                                        for (var tc = 0; tc < data.message.tool_calls.length; tc++) {
                                            toolCallsQueue.push(data.message.tool_calls[tc]);
                                        }
                                    }
                                }
                            } catch(e) {}
                        }

                        var displayThinking = currentReasoning !== "" ? currentReasoning : tempThinking;
                        chatModel.setProperty(aiIndex, "thinking", displayThinking);
                        if (xhr.readyState === 3) {
                            chatModel.setProperty(aiIndex, "text", currentText !== "" ? currentText : "Cortana Thinking...");
                        }
                    }
                }
            }

            if (xhr.readyState === XMLHttpRequest.DONE) {
                xhr.onreadystatechange = null;
                if (aiController.activeXhr === xhr) aiController.activeXhr = null;
                if (aiController.generationStopped) return;

                if (xhr.status === 200) {
                    if (!currentText && toolCallsQueue.length === 0) {
                        if (iteration < 7) {
                            var nudge = iteration < 3 ? "Please answer the user's question directly." : "Output your answer now. Do not include any preamble.";
                            messages.push({ role: "user", content: nudge });
                            queryOllama(aiIndex, iteration + 1, messages, currentReasoning, resetCount);
                            return;
                        } else if (resetCount < 3) {
                            var freshMsgs = [messages[0]];
                            var lastUserMsg = messages.slice().reverse().find(m => m.role === "user");
                            if (lastUserMsg) freshMsgs.push({ role: "user", content: lastUserMsg.content });
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

                        messages.push({ role: "assistant", content: currentText, tool_calls: toolCallsQueue });
                        var completedCount = 0;

                        function runParallelTool(index) {
                            let tCall = toolCallsQueue[index];
                            executeTool(tCall, function(toolResult) {
                                if (aiController.generationStopped) return;
                                
                                var textOutput = "";
                                if (typeof toolResult === 'object' && toolResult !== null && toolResult.image) {
                                    messages.push({ role: "tool", content: toolResult.text, images: [toolResult.image] });
                                } else {
                                    messages.push({ role: "tool", content: toolResult });
                                }
                                
                                completedCount++;
                                if (completedCount === toolCallsQueue.length) {
                                    var updatedThinking = currentReasoning + "\n" + stepText + "  > Completed.\n\n";
                                    queryOllama(aiIndex, iteration + 1, messages, updatedThinking, resetCount);
                                }
                            });
                        }
                        for (var tiq = 0; tiq < toolCallsQueue.length; tiq++) runParallelTool(tiq);
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
            tools: getSystemTools(),
            options: { num_ctx: GlobalConfig.ai.contextWindow }
        };
        xhr.send(JSON.stringify(requestData));
    }

    function sendMessage(text) {
        if (!text || text.trim() === "") return;
        isGenerating = true;
        generationStopped = false;
        ensureOllamaRunning();

        chatModel.append({ sender: "user", text: text, loading: false, thinking: "" });
        var userIndex = chatModel.count - 1;

        chatModel.append({
            sender: "ai", text: "Cortana Thinking...", loading: true, thinking: "", modelUsed: GlobalConfig.ai.activeModel
        });
        const aiIndex = chatModel.count - 1;

        var messages = [];
        messages.push({ role: "system", content: getSystemInstructions() });

        for (var i = 0; i < chatModel.count - 1; i++) {
            var msg = chatModel.get(i);
            if (msg.sender === "ai" && (msg.text === "Cortana Thinking..." || msg.text.startsWith("⚙️"))) continue;
            messages.push({ role: msg.sender === "user" ? "user" : "assistant", content: msg.text });
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
        
        var unloadXhr = new XMLHttpRequest();
        unloadXhr.open("POST", ollamaHost + "/api/generate", true);
        unloadXhr.setRequestHeader("Content-Type", "application/json");
        unloadXhr.send(JSON.stringify({ model: GlobalConfig.ai.activeModel, keep_alive: 0 }));

        isGenerating = false;
        for (var i = chatModel.count - 1; i >= 0; i--) {
            var msg = chatModel.get(i);
            if (msg && msg.sender === "ai" && msg.loading) {
                chatModel.setProperty(i, "loading", false);
                var currentText = msg.text || "";
                if (currentText === "Cortana Thinking..." || currentText.startsWith("⚙️")) {
                    chatModel.setProperty(i, "text", "Generation stopped.");
                } else if (currentText.trim() !== "") {
                    chatModel.setProperty(i, "text", currentText + "\n\n*— stopped*");
                }
            }
        }
        
        saveHistory();
        reloadHistoryList();
        
        Qt.callLater(function() { generationStopped = false; });
    }
}