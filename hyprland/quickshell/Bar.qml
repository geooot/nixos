import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets

// Top bar styled after the old waybar config (26px tall):
//   left:   workspaces (bordered buttons, accent when active)
//   center: minimized window icons (special:minimized), truly centered
//   right:  tray, battery, clock, action-center button
Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: bar

        required property var modelData

        screen: modelData

        Theme {
            id: theme
        }

        // Per-workspace layout modes, written by hyprland.lua to
        // ~/.local/state/hypr/layouts.json ({ "1": "floating", ... }).
        property var layouts: ({})

        function layoutGlyph(wsId) {
            const mode = bar.layouts[String(wsId)] ?? "dwindle";
            if (mode === "floating")
                return "▲";
            if (mode === "scrolling")
                return "●";
            return "■";
        }

        function iconFor(toplevel) {
            const appId = toplevel.wayland ? toplevel.wayland.appId : "";
            const entry = appId ? DesktopEntries.heuristicLookup(appId) : null;
            return Quickshell.iconPath(entry && entry.icon ? entry.icon : "application-x-executable");
        }

        // HyprlandToplevel.address has no 0x prefix; hyprctl needs one.
        function normAddr(address) {
            if (!address)
                return "";
            return address.startsWith("0x") ? address : "0x" + address;
        }

        Process {
            id: layoutProc

            command: ["cat", Quickshell.env("HOME") + "/.local/state/hypr/layouts.json"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        bar.layouts = JSON.parse(text);
                    } catch (e) {
                    }
                }
            }
        }

        Timer {
            interval: 2000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                if (!layoutProc.running)
                    layoutProc.running = true;
            }
        }

        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 26
        color: theme.bg

        Item {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4

            // Left: workspaces
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Repeater {
                    model: Hyprland.workspaces

                    delegate: Rectangle {
                        id: wsButton

                        required property var modelData

                        visible: modelData.id > 0
                        width: wsLabel.implicitWidth + 18
                        height: 20
                        color: theme.bg
                        border.width: 1
                        border.color: modelData.focused ? theme.accent : theme.border

                        Row {
                            id: wsLabel

                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: wsButton.modelData.id
                                color: wsButton.modelData.focused ? theme.accent : theme.dim
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSize
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: bar.layoutGlyph(wsButton.modelData.id)
                                color: wsButton.modelData.focused ? theme.accent : theme.dim
                                font.family: theme.fontFamily
                                font.pixelSize: 9
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: wsButton.modelData.activate()
                        }
                    }
                }
            }

            // Center: minimized windows, centered on the bar itself
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: Hyprland.toplevels

                    delegate: Rectangle {
                        id: minButton

                        required property var modelData

                        visible: modelData.workspace !== null && modelData.workspace.name === "special:minimized"
                        width: 28
                        height: 20
                        color: minMouse.containsMouse ? theme.hoverBg : "transparent"
                        border.width: minMouse.containsMouse ? 1 : 0
                        border.color: theme.border

                        Text {
                            anchors.centerIn: parent
                            visible: minIcon.source == ""
                            text: (minButton.modelData.title || "?").charAt(0)
                            color: theme.dim
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSize
                        }

                        IconImage {
                            id: minIcon

                            anchors.centerIn: parent
                            implicitSize: 16
                            source: bar.iconFor(minButton.modelData)
                        }

                        MouseArea {
                            id: minMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/hypr-restore", bar.normAddr(minButton.modelData.address)])
                        }
                    }
                }
            }

            // Right: tray, battery, clock, action center
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Repeater {
                        model: SystemTray.items

                        delegate: Item {
                            id: trayItem

                            required property var modelData

                            width: 18
                            height: 20

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 16
                                source: trayItem.modelData.icon
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu)
                                        trayItem.modelData.secondaryActivate();
                                    else
                                        trayItem.modelData.activate();
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: UPower.displayDevice.isLaptopBattery
                    text: (UPower.onBattery ? "󰁹 " : "󱐋 ") + Math.round(UPower.displayDevice.percentage <= 1 ? UPower.displayDevice.percentage * 100 : UPower.displayDevice.percentage) + "%"
                    color: theme.fg
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSize
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "h:mm AP")
                    color: theme.fg
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSize

                    SystemClock {
                        id: clock

                        precision: SystemClock.Minutes
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 20
                    color: ccMouse.containsMouse ? theme.hoverBg : theme.bg
                    border.width: 1
                    border.color: theme.border

                    Text {
                        anchors.centerIn: parent
                        text: "≡"
                        color: theme.fg
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSize
                    }

                    MouseArea {
                        id: ccMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "control", "toggle"])
                    }
                }
            }
        }
    }
}
