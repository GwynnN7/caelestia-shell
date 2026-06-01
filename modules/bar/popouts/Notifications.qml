pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    required property PopoutState popouts

    spacing: Tokens.spacing.small

    StyledText {
        Layout.topMargin: Tokens.padding.normal
        Layout.rightMargin: Tokens.padding.small
        text: {
            if (Notifs.dnd)
                return qsTr("Notifications off");
            const count = Notifs.notClosed.length;
            if (count === 0)
                return qsTr("No notifications");
            return qsTr("%1 unread").arg(count);
        }
        font.weight: 500
    }

    Toggle {
        label: qsTr("Do not disturb")
        checked: Notifs.dnd
        toggle.onToggled: Notifs.dnd = checked
    }

    IconTextButton {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        inactiveColour: Colours.palette.m3primaryContainer
        inactiveOnColour: Colours.palette.m3onPrimaryContainer
        verticalPadding: Tokens.padding.small
        text: qsTr("Clear all")
        icon: "clear_all"

        onClicked: Notifs.clear()
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.small
        spacing: Tokens.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle
        }
    }
}
