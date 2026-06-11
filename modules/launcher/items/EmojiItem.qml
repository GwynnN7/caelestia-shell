import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property var modelData
    required property var list

    function clicked() {
        if (!root.modelData)
            return;
        root.list.visibilities.launcher = false;
        Quickshell.execDetached(["wl-copy", root.modelData.char]);
        Emojis.recordUsage(root.modelData.char);
        Toaster.toast(qsTr("Copied to clipboard"), root.modelData.char + " " + root.modelData.name, "emoji_emotions");
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

        Item {
            id: iconContainer

            width: Math.max(1, parent.height * 0.8)
            height: width

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left

            StyledText {
                id: emojiChar

                text: root.modelData?.char ?? ""
                font.pixelSize: iconContainer.height * 0.7

                anchors.centerIn: parent
            }
        }

        StyledText {
            id: name

            anchors.left: iconContainer.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: parent.right
            anchors.rightMargin: 80
            anchors.verticalCenter: parent.verticalCenter

            text: root.modelData?.name ?? ""
            font: Tokens.font.body.medium
            elide: Text.ElideRight
        }

        MouseArea {
            id: favIcon

            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            hoverEnabled: true
            onClicked: {
                const emojiChar = root.modelData?.char;
                if (!emojiChar)
                    return;
                const favEmojis = GlobalConfig.launcher.favouriteEmojis ? [...GlobalConfig.launcher.favouriteEmojis] : [];
                if (favEmojis.includes(emojiChar)) {
                    const idx = favEmojis.indexOf(emojiChar);
                    if (idx !== -1)
                        favEmojis.splice(idx, 1);
                } else {
                    favEmojis.push(emojiChar);
                }
                GlobalConfig.launcher.favouriteEmojis = favEmojis;
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: GlobalConfig.launcher.favouriteEmojis && GlobalConfig.launcher.favouriteEmojis.includes(root.modelData?.char) ? "favorite" : "favorite_border"
                fill: GlobalConfig.launcher.favouriteEmojis && GlobalConfig.launcher.favouriteEmojis.includes(root.modelData?.char) ? 1 : 0
                color: favIcon.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
