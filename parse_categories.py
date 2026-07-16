import re

files = [
    '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml',
    '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprVariablesPage.qml'
]

mapping = {}

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    current_category = "General"
    lines = content.split('\n')
    for line in lines:
        cat_match = re.search(r'SectionHeader\s*\{.*text:\s*qsTr\("([^"]+)"\)', line)
        if cat_match:
            current_category = cat_match.group(1)
        
        var_match = re.search(r'varKey:\s*"([^"]+)"', line)
        if var_match:
            mapping[var_match.group(1)] = current_category

print(mapping)
