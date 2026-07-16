import re

files = [
    '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml',
    '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprVariablesPage.qml'
]

category_map_str = """let categoryMap = {"kbMoveWinToWs": "Workspaces", "kbMoveWinToWsGroup": "Workspaces", "kbGoToWs": "Workspaces", "kbGoToWsGroup": "Workspaces", "kbNextWs": "Workspaces", "kbPrevWs": "Workspaces", "kbWindowGroupCycleNext": "Window Group", "kbWindowGroupCyclePrev": "Window Group", "kbUngroup": "Window Group", "kbToggleGroup": "Window Group", "kbMoveWindow": "Window Action", "kbResizeWindow": "Window Action", "kbWindowPip": "Window Action", "kbPinWindow": "Window Action", "kbWindowFullscreen": "Window Action", "kbWindowBorderedFullscreen": "Window Action", "kbToggleWindowFloating": "Window Action", "kbCloseWindow": "Window Action", "kbSpecialWs": "Special Workspaces", "kbSystemMonitorWs": "Special Workspaces", "kbMusicWs": "Special Workspaces", "kbCommunicationWs": "Special Workspaces", "kbTodoWs": "Special Workspaces", "kbTerminal": "Apps", "kbBrowser": "Apps", "kbEditor": "Apps", "kbFileExplorer": "Apps", "kbSession": "Misc", "kbShowSidebar": "Misc", "kbClearNotifs": "Misc", "kbShowPanels": "Misc", "kbLock": "Misc", "kbRestoreLock": "Misc", "terminal": "Apps", "browser": "Apps", "editor": "Apps", "fileExplorer": "Apps", "audioSettings": "Apps", "touchpadDisableTyping": "Touchpad", "touchScrollFactor": "Touchpad", "gestureFingers": "Touchpad", "workspaceSwipeFingers": "Touchpad", "gestureFingersMore": "Touchpad", "blurEnabled": "Blur", "blurSpecialWs": "Blur", "blurPopups": "Blur", "blurInputMethods": "Blur", "blurSize": "Blur", "blurPasses": "Blur", "blurXray": "Blur", "shadowEnabled": "Shadow", "shadowRange": "Shadow", "shadowRenderPower": "Shadow", "shadowColour": "Shadow", "workspaceGaps": "Gaps", "windowGapsIn": "Gaps", "windowGapsOut": "Gaps", "singleWindowGapsOut": "Gaps", "windowOpacity": "Window styling", "windowRounding": "Window styling", "windowBorderSize": "Window styling", "activeWindowBorderColour": "Window styling", "inactiveWindowBorderColour": "Window styling", "volumeStep": "Misc", "cursorTheme": "Misc", "cursorSize": "Misc", "sleepGestureCmd": "Misc"};"""

new_logic = category_map_str + """
        let targetCategory = categoryMap[key] || "General";
        let categoryComment = "    -- " + targetCategory;
        
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i];
            let match = line.match(new RegExp("^(\\\\s*)" + key + "\\\\s*=.*"));
            if (match) {
                lines[i] = match[1] + key.padEnd(26) + " = " + val + ",";
                found = true;
            }
            if (lines[i].includes("scheme.") || (val.toString().includes("scheme.") && key && line.includes(key))) {
                needsScheme = true;
            }
        }
        
        if (!found) {
            let categoryFound = false;
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].trim() === categoryComment.trim()) {
                    lines.splice(i + 1, 0, "    " + key.padEnd(26) + " = " + val + ",");
                    categoryFound = true;
                    break;
                }
            }
            
            if (!categoryFound) {
                for (let i = lines.length - 1; i >= 0; i--) {
                    if (lines[i].includes("}")) {
                        if (i > 0 && lines[i-1].trim() !== "" && lines[i-1].trim() !== "{") {
                            lines.splice(i, 0, "");
                            i++;
                        }
                        lines.splice(i, 0, categoryComment);
                        lines.splice(i + 1, 0, "    " + key.padEnd(26) + " = " + val + ",");
                        break;
                    }
                }
            }
        }"""

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    old_logic = r"""        for \(let i = 0; i < lines\.length; i\+\+\) \{
            let line = lines\[i\];
            let match = line\.match\(new RegExp\("\^\(\\\\s\*\)" \+ key \+ "\\\\s\*=.*"\)\);
            if \(match\) \{
                lines\[i\] = match\[1\] \+ key\.padEnd\(26\) \+ " = " \+ val \+ ",";
                found = true;
            \}
            if \(lines\[i\]\.includes\("scheme\."\) \|\| \(val\.toString\(\)\.includes\("scheme\."\) && key && line\.includes\(key\)\)\) \{
                needsScheme = true;
            \}
        \}
        
        if \(!found\) \{
            for \(let i = lines\.length - 1; i >= 0; i--\) \{
                if \(lines\[i\]\.includes\("\}"\)\) \{
                    lines\.splice\(i, 0, "    " \+ key\.padEnd\(26\) \+ " = " \+ val \+ ","\);
                    break;
                \}
            \}
        \}"""
    
    content = re.sub(old_logic, new_logic, content)
    
    with open(f, 'w') as file:
        file.write(content)

