pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Sidebar")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            configNode: root.targetConfig.sidebar
            propertyName: "enabled"
            checked: root.targetConfig.sidebar.enabled
            onToggled: {
                root.targetConfig.sidebar.enabled = checked;
                root.targetConfig.save();
            }
        }

        StepperRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the sidebar opens")
            configNode: root.targetConfig.sidebar
            propertyName: "dragThreshold"
            value: root.targetConfig.sidebar.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => {
                root.targetConfig.sidebar.dragThreshold = v;
                root.targetConfig.save();
            }
        }

        // News
        SectionHeader {
            text: qsTr("News")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            last: true
            text: qsTr("Show News Tab")
            subtext: qsTr("Show the Arch Linux news tab in the sidebar")
            configNode: root.targetConfig.sidebar
            propertyName: "showNews"
            checked: root.targetConfig.sidebar.showNews !== false
            onToggled: {
                root.targetConfig.sidebar.showNews = checked;
                root.targetConfig.save();
            }
        }
    }
}
