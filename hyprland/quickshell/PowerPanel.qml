import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property int sel: 0

    Theme {
        id: theme
    }

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

    function navMove(d) {
        sel = Math.max(0, Math.min(sel + d, profiles.length - 1));
    }

    function navActivate() {
        setProfile(sel);
    }

    function navAdjust(d) {
        navMove(d);
    }

    function setProfile(i) {
        Quickshell.execDetached(["powerprofilesctl", "set", profiles[i].id]);
        afterSet.restart();
    }

    onActiveChanged: {
        if (active)
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
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: afterSet

        interval: 400
        onTriggered: root.refresh()
    }

    Column {
        width: parent.width
        spacing: 4

        Repeater {
            model: root.profiles

            delegate: Rectangle {
                id: profileRow

                required property var modelData
                required property int index

                width: parent.width
                height: 28
                color: root.sel === index ? theme.hoverBg : "transparent"
                border.width: 1
                border.color: root.sel === index || root.current === modelData.id ? theme.accent : theme.border

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
                    hoverEnabled: true
                    onEntered: root.sel = profileRow.index
                    onClicked: root.setProfile(profileRow.index)
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
