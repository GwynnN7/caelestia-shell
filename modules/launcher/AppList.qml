pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

StyledListView {
    id: root

    required property StyledTextField search
    required property DrawerVisibilities visibilities

    property string _debouncedText: search.text
    Timer {
        id: _searchDebounce
        interval: 120
        onTriggered: root._debouncedText = root.search.text
    }
    Connections {
        target: root.search
        function onTextChanged(): void {
            // Immediate update for short strings (mode detection), debounce for actual search
            if (root.search.text.length <= 1)
                root._debouncedText = root.search.text;
            else
                _searchDebounce.restart();
        }
    }

    ListModel { id: clipboardModel }

    property var _clipFilteredValues: {
        const query = search.text.slice(`${GlobalConfig.launcher.actionPrefix}clip `.length).toLowerCase();
        let result = [];
        for (let i = 0; i < clipboardModel.count; i++) {
            const item = clipboardModel.get(i);
            if (query === "" || item.entryText.toLowerCase().includes(query)) {
                result.push({ 
                    entryId: String(item.entryId), 
                    entryText: String(item.entryText), 
                    isImage: Boolean(item.isImage) 
                });
            }
        }
        return result;
    }

    Process {
        id: cliphistProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                clipboardModel.clear();
                const lines = text.trim().split("\n");
                for (const line of lines) {
                    if (!line) continue;
                    const parts = line.split("\t");
                    clipboardModel.append({
                        entryId: String(parts[0]),
                        entryText: String(parts.slice(1).join("\t")),
                        isImage: Boolean(line.includes("[[ binary data"))
                    });
                }
            }
        }
    }

    Process {
        id: cliphistDeleteProc
        property string exactLine: ""
        command: ["sh", "-c", "echo -E '" + exactLine.replace(/'/g, "'\\''") + "' | cliphist delete"]
    }

    function refreshClipboard(): void { cliphistProc.running = true; }

    function removeClipEntry(entryId: string): void {
        for (let i = 0; i < clipboardModel.count; i++) {
            const item = clipboardModel.get(i);
            if (item.entryId == entryId) {
                // Delete from DB, Remove from UI, Force Refresh
                cliphistDeleteProc.exactLine = item.entryId + "\t" + item.entryText;
                cliphistDeleteProc.running = true;
                clipboardModel.remove(i);
                model.values = root._clipFilteredValues;
                break;
            }
        }
    }

    model: ScriptModel {
        id: model
        onValuesChanged: root.currentIndex = 0
    }

    spacing: Tokens.spacing.small
    orientation: Qt.Vertical
    implicitHeight: {
        if (state === "emoji")
            return Math.min(GlobalConfig.launcher.maxShown * Tokens.sizes.launcher.itemHeight, 600);
        return (Tokens.sizes.launcher.itemHeight + spacing) * Math.min(GlobalConfig.launcher.maxShown, count) - spacing;
    }

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Tokens.rounding.normal
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {
                type: Anim.DefaultSpatial
            }
        }
    }

    state: {
        const text = search.text;
        const prefix = GlobalConfig.launcher.actionPrefix;
        if (text.startsWith(prefix)) {
            for (const action of ["calc", "scheme", "variant", "clip", "emoji"])
                if (text.startsWith(`${prefix}${action} `))
                    return action;

            return "actions";
        }

        return "apps";
    }

    onStateChanged: {
        if (state === "scheme" || state === "variant")
            Schemes.reload();
        if (state === "clip")
            refreshClipboard();
    }

    states: [
        State {
            name: "apps"

            PropertyChanges {
                model.values: Apps.search(search.text)
                root.delegate: appItem
            }
        },
        State {
            name: "actions"

            PropertyChanges {
                model.values: Actions.query(search.text)
                root.delegate: actionItem
            }
        },
        State {
            name: "calc"

            PropertyChanges {
                model.values: [0]
                root.delegate: calcItem
            }
        },
        State {
            name: "scheme"

            PropertyChanges {
                model.values: Schemes.query(search.text)
                root.delegate: schemeItem
            }
        },
        State {
            name: "variant"

            PropertyChanges {
                model.values: M3Variants.query(search.text)
                root.delegate: variantItem
            }
        },
        State {
            name: "clip"

            PropertyChanges {
                model.values: root._clipFilteredValues
                root.delegate: clipItem
            }
        },
         State {
            name: "emoji"

            PropertyChanges {
                model.values: [0]
                root.delegate: emojiItem
            }
        }
    ]

    transitions: Transition {
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 1
                    to: 0.9
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
            }
            PropertyAction {
                targets: [model, root]
                properties: "values,delegate"
            }
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 0.9
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
            }
            PropertyAction {
                targets: [root.add, root.remove]
                property: "enabled"
                value: true
            }
        }
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    add: Transition {
        enabled: !root.state

        Anim {
            properties: "opacity,scale"
            from: 0
            to: 1
        }
    }

    remove: Transition {
        enabled: !root.state

        Anim {
            properties: "opacity,scale"
            from: 1
            to: 0
        }
    }

    move: Transition {
        Anim {
            property: "y"
        }
        Anim {
            properties: "opacity,scale"
            to: 1
        }
    }

    addDisplaced: Transition {
        Anim {
            property: "y"
            type: Anim.StandardSmall
        }
        Anim {
            properties: "opacity,scale"
            to: 1
        }
    }

    displaced: Transition {
        Anim {
            property: "y"
        }
        Anim {
            properties: "opacity,scale"
            to: 1
        }
    }

    Component {
        id: appItem

        AppItem {
            visibilities: root.visibilities
        }
    }

    Component {
        id: actionItem

        ActionItem {
            list: root
        }
    }

    Component {
        id: calcItem

        CalcItem {
            list: root
        }
    }

    Component {
        id: schemeItem

        SchemeItem {
            list: root
        }
    }

    Component {
        id: variantItem

        VariantItem {
            list: root
        }
    }

    Component {
        id: clipItem

        ClipItem {
            list: root
        }
    }

     Component {
        id: emojiItem

        EmojiList {
            search: root.search
            visibilities: root.visibilities
        }
    }
}
