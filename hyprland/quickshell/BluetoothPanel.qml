import QtQuick
import Quickshell.Bluetooth

Item {
    id: root

    property bool shown: false

    Theme {
        id: theme
    }

    implicitHeight: content.implicitHeight

    readonly property var adapter: Bluetooth.defaultAdapter

    onShownChanged: {
        if (shown && adapter && adapter.enabled)
            adapter.discovering = true;
    }

    Column {
        id: content

        width: parent.width
        spacing: 6

        Row {
            width: parent.width
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Bluetooth"
                color: theme.fg
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSize
                font.bold: true
            }

            Item {
                width: parent.width - 140
                height: 1
            }

            Rectangle {
                width: 36
                height: 18
                color: root.adapter && root.adapter.enabled ? theme.accent : theme.border

                Rectangle {
                    x: root.adapter && root.adapter.enabled ? parent.width - width - 2 : 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    color: theme.fg
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.adapter)
                            root.adapter.enabled = !root.adapter.enabled;
                    }
                }
            }
        }

        Text {
            visible: !root.adapter
            text: "No Bluetooth adapter"
            color: theme.dim
            font.family: theme.fontFamily
            font.pixelSize: theme.smallSize
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: Bluetooth.devices

                delegate: Rectangle {
                    id: devRow

                    required property var modelData

                    width: content.width
                    height: 26
                    color: devMouse.containsMouse ? theme.hoverBg : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 120
                            text: devRow.modelData.name || devRow.modelData.deviceName || devRow.modelData.address
                            color: devRow.modelData.connected ? theme.accent : theme.fg
                            font.family: theme.fontFamily
                            font.pixelSize: theme.smallSize
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: devRow.modelData.batteryAvailable
                            text: Math.round(devRow.modelData.battery * 100) + "%"
                            color: theme.dim
                            font.family: theme.fontFamily
                            font.pixelSize: theme.smallSize
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: devRow.modelData.connected ? "Connected" : (devRow.modelData.paired ? "Paired" : "")
                            color: theme.dim
                            font.family: theme.fontFamily
                            font.pixelSize: theme.smallSize
                        }
                    }

                    MouseArea {
                        id: devMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (devRow.modelData.connected)
                                devRow.modelData.disconnect();
                            else if (devRow.modelData.paired)
                                devRow.modelData.connect();
                            else
                                devRow.modelData.pair();
                        }
                    }
                }
            }
        }
    }
}
