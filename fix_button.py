import re

file_path = '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml'

with open(file_path, 'r') as f:
    content = f.read()

# I will replace the MaterialIcon with an IconButton that has type IconButton.Filled
# I will also make sure the row is fully clickable by forwarding clicks to the button, or letting the StateLayer handle it

old_icon = r"""            MaterialIcon \{
                text: kroot.recording \? "stop_circle" : "screen_record"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            \}"""

new_icon = """            IconButton {
                id: recordBtn
                type: IconButton.Filled
                isToggle: true
                checked: kroot.recording
                icon: kroot.recording ? "stop_circle" : "screen_record"
                onClicked: {
                    kroot.recording = !kroot.recording;
                    if (kroot.recording) {
                        focusItem.forceActiveFocus();
                        Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("record")' : "submap record");
                    } else {
                        Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("reset")' : "submap reset");
                    }
                }
            }"""

new_content = re.sub(old_icon, new_icon, content)

with open(file_path, 'w') as f:
    f.write(new_content)
