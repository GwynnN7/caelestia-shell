import re

files = [
    '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml',
    '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprVariablesPage.qml'
]

schema = """let schema = [
    { cat: "Apps", keys: ["terminal", "browser", "editor", "fileExplorer", "audioSettings"] },
    { cat: "Touchpad", keys: ["touchpadDisableTyping", "touchScrollFactor", "gestureFingers", "workspaceSwipeFingers", "gestureFingersMore"] },
    { cat: "Blur", keys: ["blurEnabled", "blurSpecialWs", "blurPopups", "blurInputMethods", "blurSize", "blurPasses", "blurXray"] },
    { cat: "Shadow", keys: ["shadowEnabled", "shadowRange", "shadowRenderPower", "shadowColour"] },
    { cat: "Gaps", keys: ["workspaceGaps", "windowGapsIn", "windowGapsOut", "singleWindowGapsOut"] },
    { cat: "Window styling", keys: ["windowOpacity", "windowRounding", "windowBorderSize", "activeWindowBorderColour", "inactiveWindowBorderColour"] },
    { cat: "Misc", keys: ["volumeStep", "cursorTheme", "cursorSize", "sleepGestureCmd"] },
    
    { cat: "Workspaces", keys: ["kbMoveWinToWs", "kbMoveWinToWsGroup", "kbGoToWs", "kbGoToWsGroup", "kbNextWs", "kbPrevWs"] },
    { cat: "Window Group", keys: ["kbWindowGroupCycleNext", "kbWindowGroupCyclePrev", "kbUngroup", "kbToggleGroup"] },
    { cat: "Window Action", keys: ["kbMoveWindow", "kbResizeWindow", "kbWindowPip", "kbPinWindow", "kbWindowFullscreen", "kbWindowBorderedFullscreen", "kbToggleWindowFloating", "kbCloseWindow"] },
    { cat: "Special workspaces toggles", keys: ["kbSpecialWs", "kbSystemMonitorWs", "kbMusicWs", "kbCommunicationWs", "kbTodoWs"] },
    { cat: "Apps (Keybinds)", keys: ["kbTerminal", "kbBrowser", "kbEditor", "kbFileExplorer"] },
    { cat: "Misc (Keybinds)", keys: ["kbSession", "kbShowSidebar", "kbClearNotifs", "kbShowPanels", "kbLock", "kbRestoreLock"] }
];"""

new_logic = """
        let currentVars = {};
        let lines = content.split("\\n");
        for (let i = 0; i < lines.length; i++) {
            let match = lines[i].match(/^\\s*([a-zA-Z0-9_]+)\\s*=\\s*(.+?)\\s*,?$/);
            if (match && match[1] !== "return" && match[1] !== "local") {
                currentVars[match[1]] = match[2];
            }
        }
        
        currentVars[key] = val;
        
        let newContent = 'local scheme = require("scheme.current")\\n\\nreturn {\\n';
        let written = {};
        
""" + schema + """
        
        for (let c = 0; c < schema.length; c++) {
            let cat = schema[c];
            let catHasVars = false;
            
            for (let k = 0; k < cat.keys.length; k++) {
                let kName = cat.keys[k];
                if (currentVars[kName] !== undefined) {
                    if (!catHasVars) {
                        newContent += "    -- " + cat.cat + "\\n";
                        catHasVars = true;
                    }
                    newContent += "    " + kName.padEnd(26) + " = " + currentVars[kName] + ",\\n";
                    written[kName] = true;
                }
            }
            if (catHasVars) newContent += "\\n";
        }
        
        let customHasVars = false;
        for (let kName in currentVars) {
            if (!written[kName]) {
                if (!customHasVars) {
                    newContent += "    -- Custom\\n";
                    customHasVars = true;
                }
                newContent += "    " + kName.padEnd(26) + " = " + currentVars[kName] + ",\\n";
            }
        }
        
        newContent += "}\\n";
        
        try {
            CUtils.writeFile(configPath, newContent);
        } catch (e) {
            console.log("Could not write file natively yet: " + e);
            Quickshell.execDetached(["bash", "-c", "cat << 'EOF' > " + configPath + "\\n" + newContent + "\\nEOF"]);
        }
        loadVars();
    }

    function deleteVar(key) {
        if (!CUtils.fileExists(configPath)) return;
        let content = CUtils.readFile(configPath);
        if (!content) return;
        
        let currentVars = {};
        let lines = content.split("\\n");
        for (let i = 0; i < lines.length; i++) {
            let match = lines[i].match(/^\\s*([a-zA-Z0-9_]+)\\s*=\\s*(.+?)\\s*,?$/);
            if (match && match[1] !== "return" && match[1] !== "local") {
                currentVars[match[1]] = match[2];
            }
        }
        
        if (currentVars[key] === undefined) return;
        delete currentVars[key];
        
        let newContent = 'local scheme = require("scheme.current")\\n\\nreturn {\\n';
        let written = {};
        
""" + schema + """
        
        for (let c = 0; c < schema.length; c++) {
            let cat = schema[c];
            let catHasVars = false;
            
            for (let k = 0; k < cat.keys.length; k++) {
                let kName = cat.keys[k];
                if (currentVars[kName] !== undefined) {
                    if (!catHasVars) {
                        newContent += "    -- " + cat.cat + "\\n";
                        catHasVars = true;
                    }
                    newContent += "    " + kName.padEnd(26) + " = " + currentVars[kName] + ",\\n";
                    written[kName] = true;
                }
            }
            if (catHasVars) newContent += "\\n";
        }
        
        let customHasVars = false;
        for (let kName in currentVars) {
            if (!written[kName]) {
                if (!customHasVars) {
                    newContent += "    -- Custom\\n";
                    customHasVars = true;
                }
                newContent += "    " + kName.padEnd(26) + " = " + currentVars[kName] + ",\\n";
            }
        }
        
        newContent += "}\\n";
        
        try {
            CUtils.writeFile(configPath, newContent);
        } catch (e) {
            console.log("Could not write file natively yet: " + e);
            Quickshell.execDetached(["bash", "-c", "cat << 'EOF' > " + configPath + "\\n" + newContent + "\\nEOF"]);
        }
"""

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    # We replace from let lines = content.split("\n"); to the end of the try catch block in deleteVar
    content = re.sub(r'let lines = content\.split\("\\n"\);.*?Quickshell\.execDetached\(\["bash", "-c", "cat << \'EOF\' > " \+ configPath \+ "\\n" \+ content \+ "\\nEOF"\]\);\n            \}\n        \}', new_logic, content, flags=re.DOTALL)
    
    # Since we replaced the `let categoryMap = ...` block, let's remove it if it's there before `let lines = ...`
    content = re.sub(r'let categoryMap = .*?;\n        let targetCategory = categoryMap\[key\] \|\| "General";\n        let categoryComment = "    -- " \+ targetCategory;\n        \n        ', '', content, flags=re.DOTALL)

    with open(f, 'w') as file:
        file.write(content)

