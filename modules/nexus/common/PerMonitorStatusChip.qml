pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.services

IconButton {
    id: root

    property var configNode
    property string propertyName: ""

    readonly property bool isOverridden: {
        if (!configNode || !propertyName)
            return false;
        // Access property dynamically to force QML binding dependency on property change signals
        const _val = configNode[propertyName];
        return configNode.isPropertyLoaded(propertyName);
    }

    visible: isOverridden
    icon: "restart_alt"
    type: IconButton.Text
    font: Tokens.font.icon.small
    inactiveOnColour: Colours.palette.m3tertiary

    Layout.alignment: Qt.AlignVCenter

    onClicked: {
        if (root.configNode && root.propertyName !== "") {
            root.configNode.resetOption(root.propertyName);
            GlobalConfig.forScreen(Config.screen).save();
        }
    }
}
