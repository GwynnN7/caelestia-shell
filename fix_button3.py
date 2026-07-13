import re

file_path = '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml'

with open(file_path, 'r') as f:
    content = f.read()

old_icon = r"""            StateLayer \{
                id: recordBtn
                
                anchors.fill: undefined
                implicitWidth: implicitHeight
                implicitHeight: icon\.implicitHeight \+ Tokens\.padding\.extraSmall \* 2
                radius: Tokens\.rounding\.medium
                
                color: kroot\.recording \|\| containsMouse \|\| stateLayer\.containsMouse \? Colours\.palette\.m3secondaryContainer : Colours\.palette\.m3surfaceContainerHighest
                
                onClicked: \{
                    kroot\.recording = !kroot\.recording;
                    if \(kroot\.recording\) \{
                        focusItem\.forceActiveFocus\(\);
                        Hypr\.dispatch\(Hypr\.usingLua \? 'hl\.dsp\.submap\("record"\)' : "submap record"\);
                    \} else \{
                        Hypr\.dispatch\(Hypr\.usingLua \? 'hl\.dsp\.submap\("reset"\)' : "submap reset"\);
                    \}
                \}
                
                MaterialIcon \{
                    id: icon
                    anchors\.centerIn: parent
                    text: kroot\.recording \? "stop_circle" : "screen_record"
                    color: kroot\.recording \|\| recordBtn\.containsMouse \|\| stateLayer\.containsMouse \? Colours\.palette\.m3onSecondaryContainer : Colours\.palette\.m3onSurfaceVariant
                    fontStyle: Tokens\.font\.icon\.medium
                \}
            \}"""

new_icon = """            StyledRect {
                id: recordBtn
                
                implicitWidth: icon.implicitWidth + Tokens.padding.small * 2
                implicitHeight: icon.implicitHeight + Tokens.padding.small * 2
                radius: Tokens.rounding.medium
                
                color: kroot.recording || stateLayer.containsMouse ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHighest
                
                MaterialIcon {
                    id: icon
                    anchors.centerIn: parent
                    text: kroot.recording ? "stop_circle" : "screen_record"
                    color: kroot.recording || stateLayer.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }
            }"""

new_content = re.sub(old_icon, new_icon, content)

with open(file_path, 'w') as f:
    f.write(new_content)
