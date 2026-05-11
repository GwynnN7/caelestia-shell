pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import qs.utils
import Caelestia
import Quickshell
import Quickshell.Io as Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property TextField search
    required property PersistentProperties visibilities

    readonly property var categoryData: [
        { id: "recent", name: qsTr("Recent"), icon: "history" },
        { id: "people", name: qsTr("People"), icon: "mood" },
        { id: "nature", name: qsTr("Nature"), icon: "park" },
        { id: "food", name: qsTr("Food"), icon: "fastfood" },
        { id: "activity", name: qsTr("Activities"), icon: "sports_esports" },
        { id: "travel", name: qsTr("Travel"), icon: "flight" },
        { id: "objects", name: qsTr("Objects"), icon: "lightbulb" },
        { id: "symbols", name: qsTr("Symbols"), icon: "category" },
        { id: "flags", name: qsTr("Flags"), icon: "flag" }
    ]

    property string currentCategory: "people"
    property int categoryIndex: 1
    
    onCategoryIndexChanged: {
        currentCategory = categoryData[categoryIndex].id;
        grid.currentIndex = -1; // Reset selection on category change
    }

    PersistentProperties {
        id: recentEmojis
        reloadableId: "launcher_recent_emojis"
        property string list: "[]"
    }

    function addRecent(emoji): void {
        let current = [];
        try {
            current = JSON.parse(recentEmojis.list);
            if (!Array.isArray(current)) current = [];
        } catch (e) {
            current = [];
        }

        const index = current.findIndex(e => e.emoji === emoji.emoji);
        if (index !== -1) current.splice(index, 1);
        current.unshift(emoji);
        if (current.length > 30) current = current.slice(0, 30);
        recentEmojis.list = JSON.stringify(current);
    }

    property var _allEmojis: []
    property var _emojisByCategory: ({})

    Io.FileView {
        id: emojiFile
        path: Paths.toLocalFile(Qt.resolvedUrl("../../assets/emoji.json"))

        onLoaded: {
            try {
                const data = JSON.parse(text());
                root._allEmojis = data;

                const byCat = {};
                for (const item of data) {
                    if (!byCat[item.category]) byCat[item.category] = [];
                    byCat[item.category].push(item);
                }
                root._emojisByCategory = byCat;
            } catch (e) {
                console.error("EmojiList: Failed to parse emoji.json:", e.message);
            }
        }

        onLoadFailed: err => {
            console.error("EmojiList: Failed to load emoji.json:", err);
        }
    }

    property var _filteredEmojis: {
        const query = root.search.text.slice(`${GlobalConfig.launcher.actionPrefix}emoji `.length).toLowerCase();

        if (query === "") {
            if (currentCategory === "recent") {
                try {
                    const recent = JSON.parse(recentEmojis.list);
                    return Array.isArray(recent) ? recent : [];
                } catch (e) { return []; }
            }
            return _emojisByCategory[currentCategory] || [];
        }

        const results = _allEmojis.filter(e => 
            e.name.toLowerCase().includes(query) || 
            e.emoji.includes(query) ||
            (e.keywords && e.keywords.some(k => k.toLowerCase().includes(query)))
        );

        return results.filter((v, i, a) => a.findIndex(t => (t.emoji === v.emoji)) === i);
    }

    implicitWidth: Tokens.sizes.launcher.itemWidth
    implicitHeight: Tokens.sizes.launcher.maxShown * Tokens.sizes.launcher.itemHeight

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: Tokens.spacing.normal

        // Category Bar
        StyledRect {
            id: categoryHeader
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            color: Colours.tPalette.m3surfaceContainerLow
            radius: Tokens.rounding.small
            visible: root.search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}emoji `) && root.search.text.length <= `${GlobalConfig.launcher.actionPrefix}emoji `.length

            RowLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.large

                Repeater {
                    model: root.categoryData
                    delegate: Item {
                        id: catBtn
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        required property var modelData
                        required property int index
                        readonly property bool active: root.currentCategory === modelData.id
                        readonly property bool hovered: catStateLayer.containsMouse

                        // Background highlight on hover
                        StyledRect {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: Tokens.rounding.small
                            color: Colours.palette.m3onSurface
                            opacity: catBtn.hovered ? 0.08 : 0
                            Behavior on opacity { Anim { duration: Tokens.anim.durations.small } }
                        }

                        StateLayer {
                            id: catStateLayer
                            radius: Tokens.rounding.small
                            onClicked: {
                                root.categoryIndex = index;
                            }
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: catBtn.active ? -2 : 0
                            text: modelData.icon ?? ""
                            color: catBtn.active ? Colours.palette.m3primary : (catBtn.hovered ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant)
                            font.pointSize: Tokens.font.size.normal
                            
                            Behavior on color { CAnim {} }
                            Behavior on anchors.verticalCenterOffset { Anim { duration: Tokens.anim.durations.small } }
                        }

                        // Selection Indicator (Tab look)
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: catBtn.active ? parent.width : 0
                            height: 2
                            color: Colours.palette.m3primary
                            opacity: catBtn.active ? 1 : 0

                            Behavior on width { Anim { duration: Tokens.anim.durations.normal; easing.bezierCurve: Tokens.anim.curves.emphasized } }
                            Behavior on opacity { Anim { duration: Tokens.anim.durations.normal } }
                        }


                        Tooltip {
                            target: catBtn
                            text: modelData.name ?? ""
                            visible: catBtn.hovered
                        }
                    }
                }
            }
        }
        
        // Search Header
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "transparent"
            visible: !categoryHeader.visible
            
            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: Tokens.padding.normal
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Search Results")
                font.pointSize: Tokens.font.size.large
                font.weight: 600
                color: Colours.palette.m3primary
            }
        }

        // Main Grid Area
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.small
            clip: true

            GridView {
                id: grid
                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                cellWidth: width / 6
                cellHeight: cellWidth
                model: root._filteredEmojis
                
                currentIndex: -1
                
                highlightMoveDuration: Tokens.anim.durations.normal

                highlight: Rectangle {
                    radius: Tokens.rounding.small
                    color: Qt.alpha(Colours.palette.m3primary, 0.12)
                    border.width: 2
                    border.color: Colours.palette.m3primary
                    z: -1
                    antialiasing: true
                }

                delegate: Item {
                    id: emojiItem
                    width: grid.cellWidth
                    height: grid.cellHeight

                    required property var modelData
                    required property int index
                    readonly property bool hovered: emojiStateLayer.containsMouse
                    readonly property bool isCurrent: grid.currentIndex === index

                    function onClicked(): void {
                        Quickshell.execDetached(["sh", "-c", "echo -n '" + (modelData?.emoji ?? "") + "' | wl-copy"]);
                        if (modelData) root.addRecent(modelData);
                        root.visibilities.launcher = false;
                    }

                    StateLayer {
                        id: emojiStateLayer
                        radius: Tokens.rounding.small
                        onClicked: {
                            emojiItem.onClicked();
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData?.emoji ?? ""
                        font.pointSize: Tokens.font.size.large
                        color: Colours.palette.m3onSurface
                        renderType: Text.QtRendering
                    }

                    Tooltip {
                        target: emojiItem
                        text: modelData?.name ?? ""
                        visible: emojiItem.hovered
                    }
                }

                ScrollBar.vertical: StyledScrollBar {}
                
                // No Results View
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: grid.count === 0
                    spacing: Tokens.spacing.normal
                    opacity: 0.6

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "sentiment_dissatisfied"
                        font.pointSize: 48
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No emojis found")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Tokens.font.size.normal
                    }
                }
            }
        }

        // Preview Footer
        StyledRect {
            id: footer
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            color: Colours.tPalette.m3surfaceContainerLow
            radius: Tokens.rounding.small
            
            readonly property var activeEmoji: {
                if (grid.currentIndex !== -1 && grid.model && grid.model[grid.currentIndex]) 
                    return grid.model[grid.currentIndex];
                return null;
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.normal
                spacing: Tokens.padding.large

                Text {
                    text: footer.activeEmoji?.emoji ?? "✨"
                    font.pointSize: 24
                    color: Colours.palette.m3onSurface
                    opacity: footer.activeEmoji ? 1 : 0.3
                    renderType: Text.QtRendering
                    Behavior on opacity { Anim { duration: Tokens.anim.durations.small } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: footer.activeEmoji?.name ?? qsTr("Select an emoji")
                        font.pointSize: Tokens.font.size.large
                        font.weight: 600
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: (footer.activeEmoji?.keywords ?? []).join(", ")
                        font.pointSize: Tokens.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                        visible: text !== ""
                        textFormat: Text.PlainText
                    }
                }
                
                // Shortcut hints
                Row {
                    spacing: Tokens.spacing.normal
                    opacity: 0.5
                    visible: categoryHeader.visible

                    Row {
                        spacing: 4
                        MaterialIcon { text: "keyboard_arrow_up"; font.pointSize: 12 }
                        StyledText { text: "PgUp"; font.pointSize: 10 }
                    }
                    Row {
                        spacing: 4
                        MaterialIcon { text: "keyboard_arrow_down"; font.pointSize: 12 }
                        StyledText { text: "PgDn"; font.pointSize: 10 }
                    }
                }
            }
        }
    }

    // Navigation for keyboard
    function incrementCurrentIndex(): void { 
        if (grid.currentIndex === -1) grid.currentIndex = 0;
        else grid.moveCurrentIndexRight(); 
    }
    function decrementCurrentIndex(): void { 
        if (grid.currentIndex === -1) grid.currentIndex = 0;
        else grid.moveCurrentIndexLeft(); 
    }
    function moveUp(): void { 
        if (grid.currentIndex === -1) grid.currentIndex = 0;
        else grid.moveCurrentIndexUp(); 
    }
    function moveDown(): void { 
        if (grid.currentIndex === -1) grid.currentIndex = 0;
        else grid.moveCurrentIndexDown(); 
    }
    function moveLeft(): void { decrementCurrentIndex(); }
    function moveRight(): void { incrementCurrentIndex(); }
    
    function nextCategory(): void {
        root.categoryIndex = (root.categoryIndex + 1) % root.categoryData.length;
    }
    
    function prevCategory(): void {
        root.categoryIndex = (root.categoryIndex - 1 + root.categoryData.length) % root.categoryData.length;
    }

    readonly property alias currentItem: grid.currentItem
    readonly property alias count: grid.count
}