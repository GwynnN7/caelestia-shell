import re

file_path = '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml'

with open(file_path, 'r') as f:
    content = f.read()

# Add properties to focusItem
old_focusItem = r"""        Item \{
            id: focusItem
            focus: kroot\.recording
            Keys\.onPressed: \(event\) => \{"""

new_focusItem = """        Item {
            id: focusItem
            focus: kroot.recording
            property bool modifierOnly: false
            property var lastMods: []
            
            Keys.onPressed: (event) => {"""

content = re.sub(old_focusItem, new_focusItem, content)

# Modify Keys.onPressed end and add Keys.onReleased
old_pressed_end = r"""                if \(keyStr !== ""\) \{
                    mods\.push\(keyStr\);
                    let finalBind = mods\.join\(" \+ "\);
                    root\.saveVar\(kroot\.varKey, finalBind\);
                    kroot\.recording = false;
                    Hypr\.dispatch\(Hypr\.usingLua \? 'hl\.dsp\.submap\("reset"\)' : "submap reset"\);
                    event\.accepted = true;
                \}
            \}
        \}"""

new_pressed_end = """                let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);

                if (keyStr !== "" && !isModKey) {
                    modifierOnly = false;
                    mods.push(keyStr);
                    let finalBind = mods.join(" + ");
                    root.saveVar(kroot.varKey, finalBind);
                    kroot.recording = false;
                    Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("reset")' : "submap reset");
                    event.accepted = true;
                } else if (isModKey) {
                    modifierOnly = true;
                    let modStr = "";
                    if (k === Qt.Key_Control) modStr = "CTRL";
                    else if (k === Qt.Key_Shift) modStr = "SHIFT";
                    else if (k === Qt.Key_Alt) modStr = "ALT";
                    else if (k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R) modStr = "SUPER";
                    
                    if (!mods.includes(modStr) && modStr !== "") mods.push(modStr);
                    lastMods = mods;
                    event.accepted = true;
                }
            }
            
            Keys.onReleased: (event) => {
                if (!kroot.recording) return;
                let k = event.key;
                let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);
                
                if (isModKey && modifierOnly && lastMods.length > 0) {
                    let finalBind = lastMods.join(" + ");
                    root.saveVar(kroot.varKey, finalBind);
                    kroot.recording = false;
                    Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("reset")' : "submap reset");
                    event.accepted = true;
                }
            }
        }"""

content = re.sub(old_pressed_end, new_pressed_end, content)

with open(file_path, 'w') as f:
    f.write(content)
