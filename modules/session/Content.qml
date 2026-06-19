pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Column {
    id: root

    required property DrawerVisibilities visibilities

    padding: Tokens.padding.large
    rightPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
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

        source: Config.paths.sessionGif !== "" ? Paths.absolutePath(Config.paths.sessionGif) : ""
        fillMode: AnimatedImage.PreserveAspectFit
        visible: Config.paths.sessionGif !== ""

        StateLayer {
            radius: width / 2
            
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    Quickshell.execDetached(Config.session.commands.generic);
                } else if(mouse.button === Qt.MiddleButton) {
                    Quickshell.execDetached(Config.session.commands.automode);
                }
                else {
                    Quickshell.execDetached(Config.session.commands.lamp);
                }
                mouse.accepted = true;
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

    component SessionButton: IconButton {
        id: button

        required property list<string> command

        implicitWidth: Tokens.sizes.session.button
        implicitHeight: Tokens.sizes.session.button

        inactiveColour: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
        inactiveOnColour: activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        radius: pressed ? Tokens.rounding.medium : activeFocus ? Tokens.rounding.extraLarge : Tokens.rounding.largeIncreased
        font: Tokens.font.icon.builders.large.scale(1.3).build()
        function executeCmd() {
            let cmd = button.command.slice();
            if (!GlobalConfig.services.useSystemd && cmd.length > 0 && cmd[0] === "systemctl") {
                cmd[0] = "loginctl";
            }
            Quickshell.execDetached(cmd);
        }

        onClicked: executeCmd()

        Keys.onEnterPressed: executeCmd()
        Keys.onReturnPressed: executeCmd()
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
    }
}
