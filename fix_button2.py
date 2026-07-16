import re

file_path = '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml'

with open(file_path, 'r') as f:
    content = f.read()

# I will replace the IconButton with a StateLayer that matches PopupRow's BlobPopup color bindings
old_icon = r"""            IconButton \{
                id: recordBtn
                type: IconButton\.Tonal
                isToggle: true
                checked: kroot\.recording
                icon: kroot\.recording \? "stop_circle" : "screen_record"
                onClicked: \{
                    kroot\.recording = !kroot\.recording;
                    if \(kroot\.recording\) \{
                        focusItem\.forceActiveFocus\(\);
                        Hypr\.dispatch\(Hypr\.usingLua \? 'hl\.dsp\.submap\("record"\)' : "submap record"\);
                    \} else \{
                        Hypr\.dispatch\(Hypr\.usingLua \? 'hl\.dsp\.submap\("reset"\)' : "submap reset"\);
                    \}
                \}
            \}"""

new_icon = """            StateLayer {
                id: recordBtn
                
                implicitWidth: implicitHeight
                implicitHeight: icon.implicitHeight + Tokens.padding.extraSmall * 2
                radius: Tokens.rounding.medium
                
                color: kroot.recording || containsMouse || stateLayer.containsMouse ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHighest
                
                onClicked: {
                    kroot.recording = !kroot.recording;
                    if (kroot.recording) {
                        focusItem.forceActiveFocus();
                        Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("record")' : "submap record");
                    } else {
                        Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("reset")' : "submap reset");
                    }
                }
                
                MaterialIcon {
                    id: icon
                    anchors.centerIn: parent
                    text: kroot.recording ? "stop_circle" : "screen_record"
                    color: kroot.recording || recordBtn.containsMouse || stateLayer.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }
            }"""

new_content = re.sub(old_icon, new_icon, content)

with open(file_path, 'w') as f:
    f.write(new_content)
