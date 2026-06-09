import re

with open("modules/nexus/pages/WallpaperAndStyle.qml", "r") as f:
    lines = f.readlines()

new_lines = []
skip_next_brace = False
in_column = False
column_indent = ""

for i, line in enumerate(lines):
    if "ColumnLayout {" in line and "spacing: 0" in lines[i+2]:
        continue
    if "spacing: 0" in line and "ColumnLayout {" in lines[i-2]:
        continue
    if "Layout.fillWidth: true" in line and "spacing: 0" in lines[i-1]:
        continue
    if "ToggleRow {" in line:
        pass
        
    new_lines.append(line)
