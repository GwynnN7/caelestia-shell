files = [
    '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml',
    '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprVariablesPage.qml'
]

schema = """        let schema = [
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

new_saveVar = """        let currentVars = {};
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
    }"""

new_deleteVar = """    function deleteVar(key) {
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
        loadVars();
    }"""

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    # Isolate saveVar body
    start_save_str = "        let lines = content.split(\"\\n\");"
    end_save_str = "        loadVars();\n    }"
    
    start_idx = content.find(start_save_str)
    end_idx = content.find(end_save_str, start_idx) + len(end_save_str)
    
    # also remove categoryMap block since it's before start_save_str
    catmap_str = 'let categoryMap = {"kbMove'
    catmap_idx = content.find(catmap_str)
    if catmap_idx != -1:
        catmap_end_idx = content.find('categoryComment.trim()) {', catmap_idx)
        # instead of fragile substring, I will use find and replace
    
    # Better approach: find function saveVar(key, val) { ... function deleteVar
    save_start = content.find('function saveVar(key, val) {')
    delete_start = content.find('function deleteVar(key) {')
    delete_end = content.find('function loadVars() {')
    
    # Reconstruct from scratch
    # the code before saveVar
    pre = content[:save_start]
    
    # We want everything before let lines = content.split("\\n");
    # Let's extract that exactly
    old_save_start = content[save_start:content.find('let lines = content.split("\\n");', save_start)]
    
    # If categoryMap is in old_save_start, strip it
    old_save_start = old_save_start.split('let categoryMap =')[0]
    
    post = content[delete_end:]
    
    final_content = pre + old_save_start + new_saveVar + "\n\n" + new_deleteVar + "\n    \n    " + post
    
    with open(f, 'w') as file:
        file.write(final_content)

