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
    
    # Tokenize by finding SectionHeaders and varKeys
    for token in re.finditer(r'(SectionHeader\s*\{\s*(?:first:\s*true\s*)?text:\s*qsTr\("([^"]+)"\))|(varKey:\s*"([^"]+)")', content):
        if token.group(2):
            current_category = token.group(2)
        elif token.group(4):
            mapping[token.group(4)] = current_category

print("let categoryMap = " + str(mapping).replace("'", '"') + ";")
