import QtQuick

Item {
    id: root

    Theme {
        id: theme
    }

    implicitHeight: 250

    property var binds: [
        ["Super+Return", "Terminal"],
        ["Super+B", "Browser"],
        ["Super+E", "Files (yazi)"],
        ["Super+Space", "Menu"],
        ["Super+/", "Menu (keys panel)"],
        ["Super+Q", "Close window"],
        ["Super+Shift+Q / Esc", "Lock"],
        ["Super+H/J/K/L, Arrows", "Focus window"],
        ["Super+Ctrl+H/J/K/L", "Move window"],
        ["Super+Shift+Arrows", "Focus monitor"],
        ["Super+Shift+Ctrl+Arrows", "Move window to monitor"],
        ["Super+Y / Super+Shift+Y", "Cycle workspace layout"],
        ["Super+Shift+M", "Toggle floating"],
        ["Super+M", "Minimize (floating ws only)"],
        ["Super+Alt+M", "Restore last minimized"],
        ["Super+F", "Maximize"],
        ["Super+Shift+F", "Fullscreen"],
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

    Column {
        width: parent.width
        spacing: 6

        Text {
            text: "Keybinds"
            color: theme.fg
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSize
            font.bold: true
        }

        ListView {
            width: parent.width
            height: 215
            clip: true
            model: root.binds

            delegate: Row {
                id: bindRow

                required property var modelData

                width: parent.width
                height: 20
                spacing: 8

                Text {
                    width: 190
                    text: bindRow.modelData[0]
                    color: theme.accent
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
}
