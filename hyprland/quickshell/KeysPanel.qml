import QtQuick

Item {
    id: root

    property bool active: false

    Theme {
        id: theme
    }

    property var binds: [
        ["Super+Return", "Terminal"],
        ["Super+B", "Browser"],
        ["Super+E", "Files (yazi)"],
        ["Super+Space", "Menu (apps / windows / calc)"],
        ["Super+/", "Action center"],
        ["Tab / Shift+Tab", "Switch action-center section"],
        ["Up/Down or K/J", "Select row in section"],
        ["Left/Right or H/L", "Adjust slider / toggle row"],
        ["Enter / Space", "Activate row"],
        ["Super+Q", "Close window"],
        ["Super+Shift+Q / Esc", "Lock"],
        ["Super+H/J/K/L, Arrows", "Focus window"],
        ["Super+Ctrl+H/J/K/L", "Move window"],
        ["Super+Shift+Arrows", "Focus monitor"],
        ["Super+Shift+Ctrl+Arrows", "Move window to monitor"],
        ["Super+Y / Super+Shift+Y", "Cycle workspace layout"],
        ["Super+Shift+M", "Toggle floating"],
        ["Super+drag to edge", "Snap floating window to half"],
        ["Super+Alt+Left/Right", "Snap floating window to half"],
        ["Super+Shift+H", "Minimize"],
        ["Super+Alt+M", "Restore last minimized"],
        ["Super+M", "Maximize"],
        ["Super+F", "Fullscreen"],
        ["Super+1..0", "Workspace 1..10"],
        ["Super+Alt+1..0", "Move window to workspace"],
        ["Super+Shift+1..0", "Move silently to workspace"],
        ["Super+U/O, PgUp/PgDn", "Prev/next workspace"],
        ["Super+Ctrl+U/O", "Move window to prev/next ws"],
        ["Super+, / .", "Consume / expel column"],
        ["Super+\\", "Cycle preset width"],
        ["Super+C", "Center column/window"],
        ["Super+- / =", "Resize width"],
        ["Super+Shift+- / =", "Resize height"],
        ["Print / Ctrl+Print / Alt+Print", "Screenshot region/screen/window"],
    ]

    function navMove(d) {
        list.currentIndex = Math.max(0, Math.min(list.currentIndex + d, binds.length - 1));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    function navActivate() {
    }

    function navAdjust(d) {
        navMove(d * 5);
    }

    ListView {
        id: list

        anchors.fill: parent
        clip: true
        model: root.binds

        delegate: Row {
            id: bindRow

            required property var modelData
            required property int index

            width: list.width
            height: 20
            spacing: 8

            Text {
                width: 175
                text: bindRow.modelData[0]
                color: bindRow.index === list.currentIndex ? theme.fg : theme.accent
                font.family: theme.fontFamily
                font.pixelSize: theme.smallSize
                elide: Text.ElideRight
            }

            Text {
                text: bindRow.modelData[1]
                color: theme.dim
                font.family: theme.fontFamily
                font.pixelSize: theme.smallSize
                elide: Text.ElideRight
            }
        }
    }
}
