import re

file_path = '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml'

with open(file_path, 'r') as f:
    content = f.read()

# Replace Component.onCompleted
old_oncompleted = r"""    Component\.onCompleted: \{
        if \(Hypr\.usingLua\) \{
            Hypr\.extras\.message\('eval hl\.define_submap\("record", function\(\) hl\.bind\("", "XF86LaunchA", "submap", "reset"\) end\)'\);
        \} else \{
            Hypr\.extras\.batchMessage\(\[
                "keyword submap record",
                "keyword bind ,XF86LaunchA,submap,reset",
                "keyword submap reset"
            \]\);
        \}
        loadVars\(\);
    \}"""

new_oncompleted = """    Component.onCompleted: {
        Hypr.extras.batchMessage([
            "keyword submap record",
            "keyword bind ,XF86LaunchA,submap,reset",
            "keyword submap reset"
        ]);
        loadVars();
    }"""

content = re.sub(old_oncompleted, new_oncompleted, content)

# Replace all Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.submap("...")' : "submap ...")
content = re.sub(r"""Hypr\.dispatch\(Hypr\.usingLua \? 'hl\.dsp\.submap\("record"\)' : "submap record"\)""", 'Hypr.dispatch("submap record")', content)
content = re.sub(r"""Hypr\.dispatch\(Hypr\.usingLua \? 'hl\.dsp\.submap\("reset"\)' : "submap reset"\)""", 'Hypr.dispatch("submap reset")', content)

with open(file_path, 'w') as f:
    f.write(content)
