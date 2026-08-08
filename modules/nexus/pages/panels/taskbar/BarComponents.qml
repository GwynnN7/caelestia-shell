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
            spotify: qsTr("Spotify"),
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
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small

            StyledText {
                text: qsTr("Visible components")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
                elide: Text.ElideRight
            }

            PerMonitorStatusChip {
                configNode: root.targetConfig.bar
                propertyName: "entries"
            }

            Item {
                Layout.fillWidth: true
            }
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
            values: root.targetConfig.bar.entries.values
            onItemMoved: (from, to) => {
                root.targetConfig.bar.entries.move(from, to);
                root.targetConfig.save();
            }
            onItemRemoved: index => {
                root.targetConfig.bar.entries.remove(index);
                root.targetConfig.save();
            }
            onItemToggled: (index, checked) => {
                root.targetConfig.bar.entries.at(index).enabled = checked;
                root.targetConfig.save();
            }
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

                root.targetConfig.bar.entries.insert({
                    id: selectedItem,
                    enabled: true
                });
                root.targetConfig.save();
            }
        }
    }
}

