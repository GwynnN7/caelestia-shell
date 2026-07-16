import re

file_path = '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml'

with open(file_path, 'r') as f:
    content = f.read()

new_keybind_row = """    component KeybindRow : ConnectedRect {
        id: kroot
        property string label
        property string varKey
        property bool recording: false

        Layout.fillWidth: true
        implicitHeight: contentRow.implicitHeight + contentRow.anchors.margins * 2
        
        StateLayer {
            id: stateLayer
            anchors.fill: parent
            onClicked: {
                kroot.recording = !kroot.recording;
                if (kroot.recording) {
                    focusItem.forceActiveFocus();
                    Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("record")' : "submap record");
                } else {
                    Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("reset")' : "submap reset");
                }
            }
        }
        
        RowLayout {
            id: contentRow
            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                
                StyledText {
                    text: kroot.label
                    font: Tokens.font.body.small
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                StyledText {
                    text: kroot.recording ? "Recording..." : (root.vars[kroot.varKey] !== undefined ? String(root.vars[kroot.varKey]) : (root.defaults[kroot.varKey] !== undefined ? String(root.defaults[kroot.varKey]) : "Unbound"))
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            
            MaterialIcon {
                text: kroot.recording ? "stop_circle" : "screen_record"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }
        }
        
        Item {
            id: focusItem
            focus: kroot.recording
            Keys.onPressed: (event) => {
                if (!kroot.recording) return;
                let k = event.key;
                if (k === Qt.Key_Escape) {
                    kroot.recording = false;
                    Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("reset")' : "submap reset");
                    event.accepted = true;
                    return;
                }
                
                let mods = [];
                if (event.modifiers & Qt.ControlModifier) mods.push("Ctrl");
                if (event.modifiers & Qt.ShiftModifier) mods.push("Shift");
                if (event.modifiers & Qt.AltModifier) mods.push("Alt");
                if (event.modifiers & Qt.MetaModifier) mods.push("Super");
                
                let keyStr = "";
                if (k >= Qt.Key_A && k <= Qt.Key_Z) {
                    keyStr = String.fromCharCode(k);
                } else if (k >= Qt.Key_0 && k <= Qt.Key_9) {
                    keyStr = String.fromCharCode(k);
                } else {
                    let map = {
                        [Qt.Key_Return]: "Return",
                        [Qt.Key_Enter]: "Return",
                        [Qt.Key_Space]: "Space",
                        [Qt.Key_Tab]: "Tab",
                        [Qt.Key_Backtab]: "Tab",
                        [Qt.Key_Backspace]: "Backspace",
                        [Qt.Key_Minus]: "minus",
                        [Qt.Key_Equal]: "equal",
                        [Qt.Key_BracketLeft]: "bracketleft",
                        [Qt.Key_BracketRight]: "bracketright",
                        [Qt.Key_Semicolon]: "semicolon",
                        [Qt.Key_Apostrophe]: "apostrophe",
                        [Qt.Key_Grave]: "grave",
                        [Qt.Key_Slash]: "slash",
                        [Qt.Key_Period]: "period",
                        [Qt.Key_Backslash]: "backslash",
                        [Qt.Key_Comma]: "comma",
                        [Qt.Key_Right]: "Right",
                        [Qt.Key_Left]: "Left",
                        [Qt.Key_Up]: "Up",
                        [Qt.Key_Down]: "Down",
                        [Qt.Key_Delete]: "Delete"
                    };
                    if (map[k] !== undefined) keyStr = map[k];
                    else keyStr = event.text.toUpperCase();
                }

                if (keyStr !== "") {
                    mods.push(keyStr);
                    let finalBind = mods.join(" + ");
                    root.saveVar(kroot.varKey, finalBind);
                    kroot.recording = false;
                    Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("reset")' : "submap reset");
                    event.accepted = true;
                }
            }
        }
    }"""

pattern = re.compile(r"    component KeybindRow : ConnectedRect \{.*?        }\n    }", re.DOTALL)
new_content = pattern.sub(new_keybind_row, content)

with open(file_path, 'w') as f:
    f.write(new_content)
