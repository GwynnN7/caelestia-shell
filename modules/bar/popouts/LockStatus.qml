import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    required property PopoutState popouts
    spacing: Tokens.spacing.small

    property bool _isSidebarOpen: popouts.sidebarOpen
    implicitWidth: _isSidebarOpen ? Tokens.sizes.sidebar.width - Tokens.padding.extraLargeIncreased : 0

    StyledText {
        text: qsTr("Capslock: %1").arg(Hypr.capsLock ? "Enabled" : "Disabled")
    }

    StyledText {
        text: qsTr("Numlock: %1").arg(Hypr.numLock ? "Enabled" : "Disabled")
    }
}
