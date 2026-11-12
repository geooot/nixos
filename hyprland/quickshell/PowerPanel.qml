import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool shown: false

    Theme {
        id: theme
    }

    implicitHeight: content.implicitHeight

    property string current: ""

    property var profiles: [
        {
            "id": "performance",
            "label": "Performance"
        },
        {
            "id": "balanced",
            "label": "Balanced"
        },
        {
            "id": "power-saver",
            "label": "Power saver"
        },
    ]

    function refresh() {
        if (!getProc.running)
            getProc.running = true;
    }

    onShownChanged: {
        if (shown)
            refresh();
    }

    Process {
        id: getProc

        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: root.current = text.trim()
        }
        stderr: StdioCollector {
        }
    }

    Timer {
        interval: 5000
        running: root.shown
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: afterSet

        interval: 400
        onTriggered: root.refresh()
    }

    Column {
        id: content

        width: parent.width
        spacing: 6

        Text {
            text: "Power profile"
            color: theme.fg
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSize
            font.bold: true
        }

        Column {
            width: parent.width
            spacing: 4

            Repeater {
                model: root.profiles

                delegate: Rectangle {
                    id: profileRow

                    required property var modelData

                    width: content.width
                    height: 28
                    color: root.current === modelData.id ? theme.hoverBg : "transparent"
                    border.width: 1
                    border.color: root.current === modelData.id ? theme.accent : theme.border

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: (root.current === profileRow.modelData.id ? "● " : "○ ") + profileRow.modelData.label
                        color: root.current === profileRow.modelData.id ? theme.fg : theme.dim
                        font.family: theme.fontFamily
                        font.pixelSize: theme.smallSize
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Quickshell.execDetached(["powerprofilesctl", "set", profileRow.modelData.id]);
                            afterSet.restart();
                        }
                    }
                }
            }
        }

        Text {
            visible: root.current === ""
            text: "power-profiles-daemon unavailable"
            color: theme.dim
            font.family: theme.fontFamily
            font.pixelSize: theme.smallSize
        }
    }
}
