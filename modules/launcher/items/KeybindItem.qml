import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var list
    required property var modelData

    function clicked() {
        if (!root.modelData || !root.modelData.action)
            return;
        root.list.visibilities.launcher = false;
        Quickshell.execDetached(["sh", "-c", "hyprctl dispatch " + root.modelData.action]);
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.clicked()
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        anchors.margins: Tokens.padding.extraSmall

        MaterialIcon {
            id: icon

            text: "keyboard"
            fontStyle: Tokens.font.icon.large

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
        }

        ColumnLayout {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            spacing: 0

            StyledText {
                text: (modelData && modelData.bind) ? modelData.bind : qsTr("No keybinds")
                font: Tokens.font.body.medium
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            StyledText {
                text: (modelData && modelData.action) ? modelData.action : ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }
    }
}
