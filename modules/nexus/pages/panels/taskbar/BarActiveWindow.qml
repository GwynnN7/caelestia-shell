pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Active window")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: qsTr("Enable component")
            checked: {
                for (let i = 0; i < Config.bar.entries.length; i++) {
                    if (Config.bar.entries[i].id === "activeWindow")
                        return Config.bar.entries[i].enabled;
                }
                return false;
            }
            onToggled: {
                let currentEntries = GlobalConfig.bar.entries;
                let newEntries = [
                    { "id": "logo", "enabled": true },
                    { "id": "workspaces", "enabled": true },
                    { "id": "spacer", "enabled": true },
                    { "id": "activeWindow", "enabled": true },
                    { "id": "dock", "enabled": false },
                    { "id": "spacer", "enabled": true },
                    { "id": "tray", "enabled": true },
                    { "id": "github", "enabled": true },
                    { "id": "clock", "enabled": true },
                    { "id": "statusIcons", "enabled": true },
                    { "id": "power", "enabled": true }
                ];
                for (let i = 0; i < newEntries.length; i++) {
                    if (newEntries[i].id === "activeWindow") {
                        newEntries[i].enabled = checked;
                    } else if (newEntries[i].id !== "spacer") {
                        let existing = currentEntries.find(e => e.id === newEntries[i].id);
                        if (existing !== undefined) newEntries[i].enabled = existing.enabled;
                    }
                }
                GlobalConfig.bar.entries = newEntries;
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Compact")
            configNode: root.targetConfig.bar.activeWindow
            propertyName: "compact"
            checked: root.targetConfig.bar.activeWindow.compact
            onToggled: {
                root.targetConfig.bar.activeWindow.compact = checked;
                root.targetConfig.save();
            }
        }

        ToggleRow {
            text: qsTr("Inverted")
            configNode: root.targetConfig.bar.activeWindow
            propertyName: "inverted"
            checked: root.targetConfig.bar.activeWindow.inverted
            onToggled: {
                root.targetConfig.bar.activeWindow.inverted = checked;
                root.targetConfig.save();
            }
        }

        ToggleRow {
            text: qsTr("Show on hover")
            subtext: qsTr("Only show the active window title while hovering")
            configNode: root.targetConfig.bar.activeWindow
            propertyName: "showOnHover"
            checked: root.targetConfig.bar.activeWindow.showOnHover
            onToggled: {
                root.targetConfig.bar.activeWindow.showOnHover = checked;
                root.targetConfig.save();
            }
        }

        ToggleRow {
            last: true
            text: qsTr("Popout on hover")
            subtext: qsTr("Show a window details popout when hovering")
            configNode: root.targetConfig.bar.popouts
            propertyName: "activeWindow"
            checked: root.targetConfig.bar.popouts.activeWindow
            onToggled: {
                root.targetConfig.bar.popouts.activeWindow = checked;
                root.targetConfig.save();
            }
        }
    }
}
