pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others

Item {
    id: root

    required property ShellScreen screen
    Config.screen: screen.name
    required property var bar
    required property real borderThickness
    required property var sidebar
    required property var utilities

    readonly property alias content: content
    readonly property bool isHorizontal: bar.isHorizontal
    property real offsetScale: content.isDetached || content.hasCurrent ? 0 : 1

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: {
        if (isHorizontal && sidebar && sidebar.visible)
            return sidebar.width;
        return isHorizontal ? content.implicitWidth : content.implicitWidth * (1 - offsetScale);
    }
    implicitHeight: isHorizontal ? content.implicitHeight * (1 - offsetScale) : content.implicitHeight

    readonly property real normalX: {
        if (content.isDetached)
            return (parent.width - content.popoutNaturalWidth) / 2;
        if (isHorizontal) {
            const off = content.currentCenter - parent.leftMargin - content.popoutNaturalWidth / 2;
            const diff = parent.width - Math.floor(off + content.popoutNaturalWidth);
            if (diff < 0)
                return off + diff;
            return Math.max(off, 0);
        }
        return 0;
    }

    x: {
        if (content.isDetached)
            return (parent.width - content.nonAnimWidth) / 2;
        if (isHorizontal) {
            if (sidebar && sidebar.visible)
                return parent.width - implicitWidth;
            return normalX;
        }
        if (bar.position === "right")
            return parent.width - implicitWidth;
        return 0;
    }
    y: {
        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;
        if (isHorizontal) {
            if (bar.position === "bottom")
                return parent.height - implicitHeight;
            return 0;
        }

        const off = content.currentCenter - parent.topMargin - content.nonAnimHeight / 2;
        const diff = parent.height - Math.floor(off + content.nonAnimHeight);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }

    Behavior on offsetScale {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Behavior on x {
        enabled: (content.isDetached || isHorizontal) && !(isHorizontal && sidebar && sidebar.visible)

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        enabled: content.isDetached || (!isHorizontal && root.offsetScale < 1)

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Wrapper {
        id: content

        screen: root.screen
        offsetScale: root.offsetScale
        sidebar: root.sidebar
        bar: root.bar
        utilities: root.utilities

        // Apply slide animation margins based on edge
        anchors.leftMargin: bar.position === "left" ? (-implicitWidth - 5) * root.offsetScale : 0
        anchors.rightMargin: bar.position === "right" ? (-implicitWidth - 5) * root.offsetScale : 0
        anchors.topMargin: bar.position === "top" ? (-implicitHeight - 5) * root.offsetScale : 0
        anchors.bottomMargin: bar.position === "bottom" ? (-implicitHeight - 5) * root.offsetScale : 0

        states: [
            State {
                name: "left"
                when: bar.position === "left"
                AnchorChanges {
                    target: content
                    anchors.left: parent.left
                    anchors.right: undefined
                    anchors.top: undefined
                    anchors.bottom: undefined
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: undefined
                }
            },
            State {
                name: "right"
                when: bar.position === "right"
                AnchorChanges {
                    target: content
                    anchors.left: undefined
                    anchors.right: parent.right
                    anchors.top: undefined
                    anchors.bottom: undefined
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: undefined
                }
            },
            State {
                name: "top"
                when: bar.position === "top"
                AnchorChanges {
                    target: content
                    anchors.left: undefined
                    anchors.right: undefined
                    anchors.top: parent.top
                    anchors.bottom: undefined
                    anchors.verticalCenter: undefined
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            },
            State {
                name: "bottom"
                when: bar.position === "bottom"
                AnchorChanges {
                    target: content
                    anchors.left: undefined
                    anchors.right: undefined
                    anchors.top: undefined
                    anchors.bottom: parent.bottom
                    anchors.verticalCenter: undefined
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        ]
    }
}
