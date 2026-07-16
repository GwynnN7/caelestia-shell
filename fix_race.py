import re

file_path = '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml'

with open(file_path, 'r') as f:
    content = f.read()

# Replace onClicked in KeybindRow
old_onclick = r"""            onClicked: \{
                kroot\.recording = !kroot\.recording;
                if \(kroot\.recording\) \{
                    focusItem\.forceActiveFocus\(\);
                    Hypr\.dispatch\(Hypr\.usingLua \? 'hl\.dsp\.submap\("record"\)' : "submap record"\);
                \} else \{
                    Hypr\.dispatch\(Hypr\.usingLua \? 'hl\.dsp\.submap\("reset"\)' : "submap reset"\);
                \}
            \}"""

new_onclick = """            onClicked: {
                kroot.recording = !kroot.recording;
                if (kroot.recording) {
                    focusItem.forceActiveFocus();
                    if (Hypr.usingLua) {
                        Quickshell.execDetached(["hyprctl", "eval", "hl.define_submap('record', function() hl.bind('XF86LaunchA', hl.dsp.submap('reset')) end); hl.dispatch(hl.dsp.submap('record'))"]);
                    } else {
                        Hypr.extras.batchMessage([
                            "keyword submap record",
                            "keyword bind ,XF86LaunchA,submap,reset",
                            "keyword submap reset"
                        ]);
                        Hypr.dispatch("submap record");
                    }
                } else {
                    Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("reset")' : "submap reset");
                }
            }"""

content = re.sub(old_onclick, new_onclick, content)

with open(file_path, 'w') as f:
    f.write(content)
