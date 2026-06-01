pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary
    readonly property alias items: iconColumn

    property bool isHorizontal: false

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    clip: true
    implicitWidth: isHorizontal ? (iconColumn.implicitWidth + Tokens.padding.normal * 2 - (Config.bar.status.showLockStatus && !Hypr.capsLock && !Hypr.numLock ? iconColumn.spacing : 0)) : Tokens.sizes.bar.innerWidth
    implicitHeight: isHorizontal ? Tokens.sizes.bar.innerWidth : (iconColumn.implicitHeight + Tokens.padding.normal * 2 - (Config.bar.status.showLockStatus && !Hypr.capsLock && !Hypr.numLock ? iconColumn.spacing : 0))

    GridLayout {
        id: iconColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: isHorizontal ? undefined : parent.bottom
        anchors.bottomMargin: isHorizontal ? 0 : Tokens.padding.normal
        anchors.top: undefined
        anchors.topMargin: isHorizontal ? Tokens.padding.normal : 0
        anchors.leftMargin: isHorizontal ? Tokens.padding.normal : 0
        anchors.rightMargin: isHorizontal ? Tokens.padding.normal : 0
        anchors.verticalCenter: isHorizontal ? parent.verticalCenter : undefined

        columns: isHorizontal ? -1 : 1
        rows: isHorizontal ? 1 : -1
        flow: isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom

        columnSpacing: Tokens.spacing.smaller / 2
        rowSpacing: Tokens.spacing.smaller / 2
        readonly property real spacing: isHorizontal ? columnSpacing : rowSpacing

        // Lock keys status
        WrappedLoader {
            name: "lockstatus"
            active: Config.bar.status.showLockStatus

            sourceComponent: GridLayout {
                columns: isHorizontal ? -1 : 1
                rows: isHorizontal ? 1 : -1
                flow: isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
                columnSpacing: 0
                rowSpacing: 0

                Item {
                    implicitWidth: isHorizontal ? (Hypr.capsLock ? capslockIcon.implicitWidth : 0) : capslockIcon.implicitWidth
                    implicitHeight: isHorizontal ? capslockIcon.implicitHeight : (Hypr.capsLock ? capslockIcon.implicitHeight : 0)

                    MaterialIcon {
                        id: capslockIcon

                        anchors.centerIn: parent

                        scale: Hypr.capsLock ? 1 : 0.5
                        opacity: Hypr.capsLock ? 1 : 0

                        text: "keyboard_capslock_badge"
                        color: root.colour

                        Behavior on opacity {
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {}
                        }
                    }

                    Behavior on implicitHeight {
                        enabled: !isHorizontal
                        Anim {}
                    }
                    Behavior on implicitWidth {
                        enabled: isHorizontal
                        Anim {}
                    }
                }

                Item {
                    Layout.topMargin: !isHorizontal && Hypr.capsLock && Hypr.numLock ? iconColumn.spacing : 0
                    Layout.leftMargin: isHorizontal && Hypr.capsLock && Hypr.numLock ? iconColumn.spacing : 0

                    implicitWidth: isHorizontal ? (Hypr.numLock ? numlockIcon.implicitWidth : 0) : numlockIcon.implicitWidth
                    implicitHeight: isHorizontal ? numlockIcon.implicitHeight : (Hypr.numLock ? numlockIcon.implicitHeight : 0)

                    MaterialIcon {
                        id: numlockIcon

                        anchors.centerIn: parent

                        scale: Hypr.numLock ? 1 : 0.5
                        opacity: Hypr.numLock ? 1 : 0

                        text: "looks_one"
                        color: root.colour

                        Behavior on opacity {
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {}
                        }
                    }

                    Behavior on implicitHeight {
                        enabled: !isHorizontal
                        Anim {}
                    }
                    Behavior on implicitWidth {
                        enabled: isHorizontal
                        Anim {}
                    }
                }
            }
        }

        // Audio icon
        WrappedLoader {
            name: "audio"
            active: Config.bar.status.showAudio

            sourceComponent: MaterialIcon {
                animate: true
                text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                color: root.colour
            }
        }

        // Microphone icon
        WrappedLoader {
            name: "audio"
            active: Config.bar.status.showMicrophone

            sourceComponent: MaterialIcon {
                animate: true
                text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                color: root.colour
            }
        }

        // Keyboard layout icon
        WrappedLoader {
            name: "kblayout"
            active: Config.bar.status.showKbLayout

            sourceComponent: StyledText {
                animate: true
                text: Hypr.kbLayout
                color: root.colour
                font.family: Tokens.font.family.mono
            }
        }

        // Network icon
        WrappedLoader {
            name: "network"
            active: Config.bar.status.showNetwork && (!Nmcli.activeEthernet || Config.bar.status.showWifi)

            sourceComponent: MaterialIcon {
                animate: true
                text: Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                color: root.colour
            }
        }

        // Ethernet icon
        WrappedLoader {
            name: "ethernet"
            active: Config.bar.status.showNetwork && Nmcli.activeEthernet

            sourceComponent: MaterialIcon {
                animate: true
                text: "cable"
                color: root.colour
            }
        }

        // Bluetooth section
        WrappedLoader {
            Layout.preferredWidth: isHorizontal ? implicitWidth : -1
            Layout.preferredHeight: isHorizontal ? -1 : implicitHeight

            name: "bluetooth"
            active: Config.bar.status.showBluetooth

            sourceComponent: GridLayout {
                columns: isHorizontal ? -1 : 1
                rows: isHorizontal ? 1 : -1
                flow: isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
                columnSpacing: Tokens.spacing.smaller / 2
                rowSpacing: Tokens.spacing.smaller / 2

                // Bluetooth icon
                MaterialIcon {
                    animate: true
                    text: {
                        if (!Bluetooth.defaultAdapter?.enabled) // qmllint disable unresolved-type
                            return "bluetooth_disabled";
                        if (Bluetooth.devices.values.some(d => d.connected)) // qmllint disable unresolved-type
                            return "bluetooth_connected";
                        return "bluetooth";
                    }
                    color: root.colour
                }

                // Connected bluetooth devices
                Repeater {
                    model: ScriptModel {
                        values: Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected) // qmllint disable unresolved-type
                    }

                    MaterialIcon {
                        id: device

                        required property BluetoothDevice modelData

                        animate: true
                        text: Icons.getBluetoothIcon(modelData?.icon)
                        color: root.colour
                        fill: 1

                        SequentialAnimation on opacity {
                            running: device.modelData?.state !== BluetoothDeviceState.Connected // qmllint disable unresolved-type
                            alwaysRunToEnd: true
                            loops: Animation.Infinite

                            Anim {
                                from: 1
                                to: 0
                                duration: Tokens.anim.durations.large
                                easing: Tokens.anim.standardAccel
                            }
                            Anim {
                                from: 0
                                to: 1
                                duration: Tokens.anim.durations.large
                                easing: Tokens.anim.standardDecel
                            }
                        }
                    }
                }
            }

            Behavior on Layout.preferredHeight {
                enabled: !isHorizontal
                Anim {}
            }
            Behavior on Layout.preferredWidth {
                enabled: isHorizontal
                Anim {}
            }
        }

        // Battery icon
        WrappedLoader {
            name: "battery"
            active: Config.bar.status.showBattery

            sourceComponent: MaterialIcon {
                animate: true
                text: {
                    if (!UPower.displayDevice.isLaptopBattery) {
                        if (PowerProfiles.profile === PowerProfile.PowerSaver)
                            return "energy_savings_leaf";
                        if (PowerProfiles.profile === PowerProfile.Performance)
                            return "rocket_launch";
                        return "balance";
                    }

                    const perc = UPower.displayDevice.percentage;
                    const charging = [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state);
                    if (perc === 1)
                        return charging ? "battery_charging_full" : "battery_full";
                    let level = Math.floor(perc * 7);
                    if (charging && (level === 4 || level === 1))
                        level--;
                    return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`;
                }
                color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? root.colour : Colours.palette.m3error
                fill: 1
            }
        }

        // Notifications icon
        WrappedLoader {
            name: "notifications"

            sourceComponent: MaterialIcon {
                id: notifIcon

                text: {
                    if (Notifs.dnd)
                        return "notifications_off";
                    if (Notifs.notClosed.length > 0)
                        return "notifications_unread";
                    return "notifications";
                }
                color: root.colour

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            Notifs.dnd = !Notifs.dnd;
                        } else {
                            const vis = Visibilities.getForActive();
                            vis.sidebar = !vis.sidebar;
                        }
                    }
                }
            }
        }
    }

    component WrappedLoader: Loader {
        required property string name

        asynchronous: false
        Layout.alignment: isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
        visible: active
    }
}
