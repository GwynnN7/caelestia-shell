pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Dock")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Enable component")
            checked: {
                for (let i = 0; i < Config.bar.entries.length; i++) {
                    if (Config.bar.entries[i].id === "dock")
                        return Config.bar.entries[i].enabled;
                }
                return false;
            }
            onToggled: {
                let entries = GlobalConfig.bar.entries;
                for (let i = 0; i < entries.length; i++) {
                    if (entries[i].id === "dock") {
                        entries[i].enabled = checked;
                        GlobalConfig.bar.entries = entries;
                        break;
                    }
                }
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Monitor center")
            subtext: qsTr("Center the dock relative to the physical monitor")
            checked: Config.bar.dock.monitorCenter
            onToggled: GlobalConfig.bar.dock.monitorCenter = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Recolour icons")
            subtext: qsTr("Recolour application icons using the system theme")
            checked: Config.bar.dock.recolourIcons
            onToggled: GlobalConfig.bar.dock.recolourIcons = checked
        }
    }
}
