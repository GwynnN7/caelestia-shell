import re

file_path = '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml'

with open(file_path, 'r') as f:
    content = f.read()

# Replace the mods pushing logic
old_mods = r"""                let mods = \[\];
                if \(event\.modifiers & Qt\.ControlModifier\) mods\.push\("Ctrl"\);
                if \(event\.modifiers & Qt\.ShiftModifier\) mods\.push\("Shift"\);
                if \(event\.modifiers & Qt\.AltModifier\) mods\.push\("Alt"\);
                if \(event\.modifiers & Qt\.MetaModifier\) mods\.push\("Super"\);"""

new_mods = """                let mods = [];
                if (event.modifiers & Qt.ControlModifier) mods.push("CTRL");
                if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");
                if (event.modifiers & Qt.AltModifier) mods.push("ALT");
                if (event.modifiers & Qt.MetaModifier) mods.push("SUPER");"""

content = re.sub(old_mods, new_mods, content)

with open(file_path, 'w') as f:
    f.write(content)
