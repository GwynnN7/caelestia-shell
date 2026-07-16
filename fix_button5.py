import re

file_path = '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml'

with open(file_path, 'r') as f:
    content = f.read()

old_icon = r"""            Item \{
                id: recordBtn
                
                implicitWidth: icon\.implicitWidth \+ Tokens\.padding\.extraSmall \* 2
                implicitHeight: icon\.implicitHeight \+ Tokens\.padding\.extraSmall \* 2
                
                BlobGroup \{
                    id: blobGroup
                    color: kroot\.recording \|\| stateLayer\.containsMouse \? Colours\.palette\.m3secondaryContainer : Colours\.palette\.m3surfaceContainerHighest
                    smoothing: Tokens\.rounding\.medium
                    cornerFill: false

                    Behavior on color \{
                        CAnim \{\}
                    \}
                \}
                
                BlobRect \{
                    id: btnRect
                    anchors\.fill: parent
                    anchors\.margins: \(stateLayer\.containsMouse \? -Tokens\.padding\.extraSmall : 0\) \+ \(kroot\.recording \? -Tokens\.padding\.extraSmall : 0\)
                    group: blobGroup
                    radius: kroot\.recording \? Tokens\.rounding\.large : Tokens\.rounding\.medium

                    Behavior on anchors\.margins \{
                        Anim \{\}
                    \}

                    Behavior on radius \{
                        Anim \{
                            type: Anim\.DefaultEffects
                        \}
                    \}
                \}
                
                MaterialIcon \{
                    id: icon
                    anchors\.centerIn: parent
                    text: kroot\.recording \? "stop_circle" : "screen_record"
                    color: kroot\.recording \|\| stateLayer\.containsMouse \? Colours\.palette\.m3onSecondaryContainer : Colours\.palette\.m3onSurfaceVariant
                    fontStyle: Tokens\.font\.icon\.medium
                \}
            \}"""

new_icon = """            Item {
                id: recordBtn
                
                implicitWidth: btn.implicitWidth * 0.9
                implicitHeight: btn.implicitHeight * 0.9
                
                BlobGroup {
                    id: blobGroup
                    color: kroot.recording || stateLayer.containsMouse ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHighest
                    smoothing: kroot.Tokens.rounding.medium
                    cornerFill: false

                    Behavior on color {
                        CAnim {}
                    }
                }
                
                BlobRect {
                    id: btnRect
                    anchors.fill: parent
                    anchors.margins: (stateLayer.containsMouse ? -Tokens.padding.extraSmall : 0) + (kroot.recording ? -Tokens.padding.extraSmall : 0)
                    group: blobGroup
                    radius: kroot.recording ? Tokens.rounding.large : Tokens.rounding.medium

                    Behavior on anchors.margins {
                        Anim {}
                    }

                    Behavior on radius {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
                
                Item {
                    id: btn
                    anchors.centerIn: parent
                    implicitWidth: implicitHeight
                    implicitHeight: icon.implicitHeight + Tokens.padding.extraSmall * 2
                    
                    MaterialIcon {
                        id: icon
                        anchors.centerIn: parent
                        text: kroot.recording ? "stop_circle" : "screen_record"
                        color: kroot.recording || stateLayer.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }
                }
            }"""

new_content = re.sub(old_icon, new_icon, content)

with open(file_path, 'w') as f:
    f.write(new_content)
