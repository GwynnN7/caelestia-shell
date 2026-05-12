pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Column {
    id: root

    required property DrawerVisibilities visibilities

    padding: Tokens.padding.large
    spacing: Tokens.spacing.large

    SessionButton {
        id: shutdown

        icon: Config.session.icons.shutdown
        command: Config.session.commands.shutdown

        KeyNavigation.up: bios
        KeyNavigation.down: reboot

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.visibilities.launcher)
                    logout.forceActiveFocus();
            }

            target: root.visibilities
        }
    }

    SessionButton {
        id: reboot

        icon: Config.session.icons.reboot
        command: Config.session.commands.reboot

        KeyNavigation.up: shutdown
        KeyNavigation.down: suspend
    }


    SessionButton {
        id: suspend

        icon: Config.session.icons.suspend
        command: Config.session.commands.suspend

        KeyNavigation.up: reboot
        KeyNavigation.down: logout
    }

    Image {
        width: Tokens.sizes.session.button
        height: Tokens.sizes.session.button
        sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)

        source: Paths.absolutePath(Config.paths.cortanaPic)
        fillMode: Image.PreserveAspectCrop

        StateLayer {
            radius: width / 2
            
            onClicked: {
                Quickshell.execDetached(Config.session.commands.lamp);
            }
        }
    }

    SessionButton {
        id: logout

        icon: Config.session.icons.logout
        command: Config.session.commands.logout

        KeyNavigation.up: suspend
        KeyNavigation.down: windows
    }    

    SessionButton {
        id: windows

        icon: Config.session.icons.windows
        command: Config.session.commands.windows

        KeyNavigation.up: logout
        KeyNavigation.down: bios
    }

    SessionButton {
        id: bios

        icon: Config.session.icons.bios
        command: Config.session.commands.bios

        KeyNavigation.up: windows
        KeyNavigation.down: shutdown
    }

    component SessionButton: StyledRect {
        id: button

        required property string icon
        required property list<string> command

        implicitWidth: Tokens.sizes.session.button
        implicitHeight: Tokens.sizes.session.button

        radius: Tokens.rounding.large
        color: button.activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

        Keys.onEnterPressed: Quickshell.execDetached(button.command)
        Keys.onReturnPressed: Quickshell.execDetached(button.command)
        Keys.onEscapePressed: root.visibilities.session = false
        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if ((event.key === Qt.Key_J || event.key === Qt.Key_N) && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if ((event.key === Qt.Key_K || event.key === Qt.Key_P) && KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            }
        }

        StateLayer {
            radius: parent.radius
            color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            onClicked: Quickshell.execDetached(button.command)
        }

        MaterialIcon {
            anchors.centerIn: parent

            text: button.icon
            color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            font.pointSize: Tokens.font.size.extraLarge
            font.weight: 500
        }
    }
}
