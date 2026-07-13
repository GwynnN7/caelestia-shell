import Quickshell
import Caelestia
import qs.services
import QtQuick

ShellRoot {
    Component.onCompleted: {
        Hypr.extras.message('eval hl.define_submap("test555", function() hl.bind("XF86LaunchA", hl.dsp.submap("reset")) end)');
        console.log("Sent message!");
        Quickshell.exit(0);
    }
}
