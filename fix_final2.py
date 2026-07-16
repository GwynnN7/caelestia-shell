import re

file_path = '/home/dim/.config/quickshell/caelestia/modules/nexus/pages/hyprland/HyprKeybindsPage.qml'

with open(file_path, 'r') as f:
    content = f.read()

# Replace Component.onCompleted
old_oncompleted = r"""    Component\.onCompleted: \{
        if \(Hypr\.usingLua\) \{
            Hypr\.extras\.message\('eval hl\.define_submap\("record", function\(\) hl\.bind\("XF86LaunchA", hl\.dsp\.submap\("reset"\)\) end\)'\);
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
        if (Hypr.usingLua) {
            Hypr.dispatch("'exec', 'hyprctl eval \\\'hl.define_submap(\"record\", function() hl.bind(\"XF86LaunchA\", hl.dsp.submap(\"reset\")) end)\\\''");
        } else {
            Hypr.extras.batchMessage([
                "keyword submap record",
                "keyword bind ,XF86LaunchA,submap,reset",
                "keyword submap reset"
            ]);
        }
        loadVars();
    }"""

content = re.sub(old_oncompleted, new_oncompleted, content)

with open(file_path, 'w') as f:
    f.write(content)
