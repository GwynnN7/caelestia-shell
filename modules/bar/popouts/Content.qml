pragma ComponentBehavior: Bound

import "./kblayout"
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components

Item {
    id: root

    required property PopoutState popouts
    required property var sidebar
    required property var utilities
    readonly property bool isSidebarOpen: sidebar && sidebar.visible && (Config.bar.position === "bottom" || Config.bar.position === "top")

    readonly property Popout currentPopout: content.children.find(c => c.shouldBeActive) ?? null
    readonly property Item current: currentPopout?.item ?? null

    readonly property real naturalWidth: {
        const itemWidth = currentPopout ? (currentPopout.implicitWidth || currentPopout.width || 0) : 0;
        return itemWidth + Tokens.padding.large * 2;
    }

    implicitWidth: isSidebarOpen ? sidebar.width : naturalWidth
    implicitHeight: (currentPopout?.implicitHeight ?? 0) + (isSidebarOpen ? Tokens.padding.large : Tokens.padding.large * 2)

    Item {
        id: content

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        anchors.topMargin: {
            if (isSidebarOpen && Config.bar.position === "bottom")
                return 0;
            return Tokens.padding.large;
        }
        anchors.bottomMargin: {
            if (isSidebarOpen && Config.bar.position === "top")
                return 0;
            return Tokens.padding.large;
        }

        Popout {
            name: "activewindow"
            sourceComponent: ActiveWindow {
                popouts: root.popouts
            }
        }

        Popout {
            id: networkPopout

            name: "network"
            sourceComponent: Network {
                popouts: root.popouts
                view: "wireless"
            }
        }

        Popout {
            name: "ethernet"
            sourceComponent: Network {
                popouts: root.popouts
                view: "ethernet"
            }
        }

        Popout {
            id: passwordPopout

            name: "wirelesspassword"
            sourceComponent: WirelessPassword {
                id: passwordComponent

                popouts: root.popouts
                network: (networkPopout.item as Network)?.passwordNetwork ?? null
            }

            Connections {
                function onCurrentNameChanged() {
                    // Update network immediately when password popout becomes active
                    if (root.popouts.currentName === "wirelesspassword") {
                        // Set network immediately if available
                        if ((networkPopout.item as Network)?.passwordNetwork) {
                            if (passwordPopout.item) {
                                (passwordPopout.item as WirelessPassword).network = (networkPopout.item as Network).passwordNetwork;
                            }
                        }
                        // Also try after a short delay in case networkPopout.item wasn't ready
                        Qt.callLater(() => {
                            if (passwordPopout.item && (networkPopout.item as Network)?.passwordNetwork) {
                                (passwordPopout.item as WirelessPassword).network = (networkPopout.item as Network).passwordNetwork;
                            }
                        }, 100);
                    }
                }

                target: root.popouts
            }

            Connections {
                function onItemChanged() {
                    // When network popout loads, update password popout if it's active
                    if (root.popouts.currentName === "wirelesspassword" && passwordPopout.item) {
                        Qt.callLater(() => {
                            if ((networkPopout.item as Network)?.passwordNetwork) {
                                (passwordPopout.item as WirelessPassword).network = (networkPopout.item as Network).passwordNetwork;
                            }
                        });
                    }
                }

                target: networkPopout
            }
        }

        Popout {
            name: "bluetooth"
            sourceComponent: Bluetooth {
                popouts: root.popouts
            }
        }

        Popout {
            name: "battery"
            sourceComponent: Battery {}
        }

        Popout {
            name: "audio"
            sourceComponent: Audio {
                popouts: root.popouts
            }
        }

        Popout {
            name: "kblayout"
            sourceComponent: KbLayout {}
        }

        Popout {
            name: "lockstatus"
            sourceComponent: LockStatus {}
        }

        Popout {
            name: "notifications"
            sourceComponent: Notifications {
                popouts: root.popouts
            }
        }

        Repeater {
            model: ScriptModel {
                values: SystemTray.items.values.filter(i => !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }

            Popout {
                id: trayMenu

                required property SystemTrayItem modelData
                required property int index

                name: `traymenu${index}`
                sourceComponent: trayMenuComp

                Connections {
                    function onHasCurrentChanged(): void {
                        if (root.popouts.hasCurrent && trayMenu.shouldBeActive) {
                            trayMenu.sourceComponent = null;
                            trayMenu.sourceComponent = trayMenuComp;
                        }
                    }

                    target: root.popouts
                }

                Component {
                    id: trayMenuComp

                    TrayMenu {
                        popouts: root.popouts
                        trayItem: trayMenu.modelData.menu // qmllint disable unresolved-type
                    }
                }
            }
        }
    }

    component Popout: Loader {
        id: popout

        required property string name
        readonly property bool shouldBeActive: root.popouts.currentName === name

        anchors.centerIn: isSidebarOpen ? undefined : parent
        anchors.left: isSidebarOpen ? parent.left : undefined
        anchors.right: isSidebarOpen ? parent.right : undefined
        anchors.top: (isSidebarOpen && Config.bar.position === "top") ? parent.top : undefined
        anchors.bottom: (isSidebarOpen && Config.bar.position === "bottom") ? parent.bottom : undefined

        Binding {
            when: popout.status === Loader.Ready && isSidebarOpen
            target: popout.item
            property: "width"
            value: popout.width
        }

        opacity: 0
        scale: 0.8
        active: false

        states: State {
            name: "active"
            when: popout.shouldBeActive

            PropertyChanges {
                popout.active: true
                popout.opacity: 1
                popout.scale: 1
            }
        }

        transitions: [
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
                        properties: "opacity,scale"
                        type: Anim.StandardSmall
                    }
                    PropertyAction {
                        target: popout
                        property: "active"
                    }
                }
            },
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        target: popout
                        property: "active"
                    }
                    Anim {
                        properties: "opacity,scale"
                    }
                }
            }
        ]
    }
}
