import re

file_path = '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml'

with open(file_path, 'r') as f:
    content = f.read()

content = content.replace('Hypr.dispatch("submap record");', 'Hypr.dispatch(Hypr.usingLua ? "\'submap\', \'record\'" : "submap record");')
content = content.replace('Hypr.dispatch("submap reset");', 'Hypr.dispatch(Hypr.usingLua ? "\'submap\', \'reset\'" : "submap reset");')

with open(file_path, 'w') as f:
    f.write(content)
