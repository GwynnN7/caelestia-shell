pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia

Singleton {
    id: root

    readonly property alias active: props.active
    readonly property var sunsetCmd: ["systemctl", "--user"]

    function nightLightToast(message: string): void {
        Toaster.toast(qsTr("Automatic Night Light"), qsTr(message), "dark_mode");
    }

    function toggle(): void {
        if (props.active)
            runAction("stop");
        else
            runAction("start");
    }

    function runAction(action: string): void {
        actionProc.command = root.sunsetCmd.concat((action === "start" ? ["restart"] : ["stop"])).concat(["hyprsunset"]);
        actionProc.running = true;
    }

    function refresh(): void {
        if (!serviceEnabledProc.running)
            serviceEnabledProc.running = true;
    }

    Component.onCompleted: refresh()

    PersistentProperties {
        id: props

        property bool active: false

        reloadableId: "hyprSunset"
    }

    Process {
        id: serviceEnabledProc

        command: root.sunsetCmd.concat(["is-active", "--quiet", "hyprsunset"])
        onExited: code => { // qmllint disable signal-handler-parameters
            if(props.active !== (code === 0))
            {
                props.active = code === 0;
                root.nightLightToast(props.active ? "Enabled" : "Disabled");
            }
        }
    }

    Process {
        id: actionProc

        onExited: code => { // qmllint disable signal-handler-parameters
            root.refresh()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}