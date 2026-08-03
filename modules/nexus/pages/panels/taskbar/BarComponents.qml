pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var builtinComponents: ({
            logo: qsTr("Logo"),
            workspaces: qsTr("Workspaces"),
            github: qsTr("GitHub"),
            spacer: qsTr("Spacer"),
            activeWindow: qsTr("Active window"),
            tray: qsTr("System tray"),
            clock: qsTr("Clock"),
            statusIcons: qsTr("Status icons"),
            dock: qsTr("Dock"),
            power: qsTr("Power menu")
        })

    title: qsTr("Toggle & rearrange")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Visible components
        SectionHeader {
            first: true
            text: qsTr("Visible components")
        }

        ListEditor {
            function labelFor(item: var): string {
                const prettyName = root.builtinComponents[item.id];
                if (prettyName)
                    return prettyName;
                const label = item.id.replace(/([A-Z])/g, " $1");
                return label.charAt(0).toUpperCase() + label.slice(1).toLowerCase();
            }

            function toggledFor(item: var): bool {
                return item.enabled;
            }

            z: 1
            first: true
            values: Config.bar.entries.values
            onItemMoved: (from, to) => GlobalConfig.bar.entries.move(from, to)
            onItemRemoved: index => GlobalConfig.bar.entries.remove(index)
            onItemToggled: (index, checked) => GlobalConfig.bar.entries.at(index).enabled = checked
        }

        DialogSelectButton {
            id: addItemContainer

            rootParent: root.flickable
            icon: "add"
            label: qsTr("Add entry")
            header: qsTr("Add new entry")
            acceptLabel: qsTr("Add")

            model: {
                const builtins = Object.keys(root.builtinComponents).map(k => ({
                            id: k,
                            label: root.builtinComponents[k]
                        }));
                return builtins;
            }

            onAccepted: {
                if (!selectedItem) // Should never happen but just in case
                    return;

                GlobalConfig.bar.entries.insert({
                    id: selectedItem,
                    enabled: true
                });
            }
        }
    }
}

