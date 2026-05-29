pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.normal : Tokens.padding.small

    property bool isHorizontal: false

    implicitWidth: isHorizontal ? (layout.implicitWidth + root.padding * 2) : Tokens.sizes.bar.innerWidth
    implicitHeight: isHorizontal ? Tokens.sizes.bar.innerWidth : (layout.implicitHeight + root.padding * 2)

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    GridLayout {
        id: layout

        anchors.centerIn: parent
        columnSpacing: Tokens.spacing.small
        rowSpacing: Tokens.spacing.small
        columns: isHorizontal ? -1 : 1
        rows: isHorizontal ? 1 : -1
        flow: isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom

        Loader {
            asynchronous: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            visible: Config.bar.clock.showDate

            horizontalAlignment: StyledText.AlignHCenter
            text: isHorizontal ? Time.format("ddd d") : Time.format("ddd\nd")
            font.pointSize: Tokens.font.size.smaller
            font.family: Tokens.font.family.sans
            color: root.colour
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            visible: Config.bar.clock.showDate
            Layout.preferredWidth: isHorizontal ? 1 : 16
            Layout.preferredHeight: isHorizontal ? 16 : 1

            color: root.colour
            opacity: 0.2
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            horizontalAlignment: StyledText.AlignHCenter
            text: isHorizontal ? Time.format(GlobalConfig.services.useTwelveHourClock ? "hh:mm A" : "hh:mm") : Time.format(GlobalConfig.services.useTwelveHourClock ? "hh\nmm\nA" : "hh\nmm")
            font.pointSize: Tokens.font.size.smaller
            font.family: Tokens.font.family.mono
            color: root.colour
        }
    }
}
