import QtQuick
import QtQuick.Layouts
import qs.modules.nexus.common
import qs.modules.dashboard

PageBase {
    title: qsTr("Wallhaven")
    isSubPage: true
    scrollable: false

    WallhavenTab {
        anchors.fill: parent
    }
}
