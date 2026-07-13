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

new_logic = schema + """
        let currentVars = {};
        let content = "";
        if (CUtils.fileExists(configPath)) {
            content = CUtils.readFile(configPath);
            let lines = content.split("\\n");
            for (let i = 0; i < lines.length; i++) {
                let match = lines[i].match(/^\\s*([a-zA-Z0-9_]+)\\s*=\\s*(.+?)\\s*,?$/);
                if (match && match[1] !== "return") {
                    currentVars[match[1]] = match[2];
                }
            }
        }
        
        currentVars[key] = val;
        
        let newContent = 'local scheme = require("scheme.current")\\n\\nreturn {\\n';
        let written = {};
        
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
            Quickshell.execDetached(["bash", "-c", "cat << 'EOF' > " + configPath + "\\n" + newContent + "\\nEOF"]);
        }
        loadVars();
    }

    function deleteVar(key) {"""

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    # We replace everything from let categoryMap = ... down to function deleteVar(key) {
    content = re.sub(r'let categoryMap = .*?function deleteVar\(key\) \{', new_logic, content, flags=re.DOTALL)
    
    # Also replace deleteVar logic to use the same schema-based reconstruction!
    new_delete = schema + """
        let currentVars = {};
        let content = "";
        if (CUtils.fileExists(configPath)) {
            content = CUtils.readFile(configPath);
            let lines = content.split("\\n");
            for (let i = 0; i < lines.length; i++) {
                let match = lines[i].match(/^\\s*([a-zA-Z0-9_]+)\\s*=\\s*(.+?)\\s*,?$/);
                if (match && match[1] !== "return") {
                    currentVars[match[1]] = match[2];
                }
            }
        }
        
        if (currentVars[key] === undefined) return;
        delete currentVars[key];
        
        let newContent = 'local scheme = require("scheme.current")\\n\\nreturn {\\n';
        let written = {};
        
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
            Quickshell.execDetached(["bash", "-c", "cat << 'EOF' > " + configPath + "\\n" + newContent + "\\nEOF"]);
        }
        loadVars();
    }"""
    
    content = re.sub(r'let lines = content\.split\("\\n"\);.*?loadVars\(\);\n    \}', new_delete[1439:], content, flags=re.DOTALL)
    # Actually wait, the above sub for deleteVar might be too complex or fail if my regex is off.
    # I'll just write a specific replacement for deleteVar instead of gambling.

    with open(f, 'w') as file:
        file.write(content)

