import QtQuick
import Quickshell.Bluetooth

Item {
    id: root

    property bool active: false
    property int sel: 0

    Theme {
        id: theme
    }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property int rowCount: 1 + Bluetooth.devices.values.length

    function ensureVisible() {
        const y = sel * 30;
        if (y < flick.contentY)
            flick.contentY = y;
        else if (y + 30 > flick.contentY + flick.height)
            flick.contentY = y + 30 - flick.height;
    }

    function navMove(d) {
        sel = Math.max(0, Math.min(sel + d, rowCount - 1));
        ensureVisible();
    }

    function navActivate() {
        activateRow(sel);
    }

    function navAdjust(d) {
        activateRow(sel);
    }

    function activateRow(i) {
        if (i === 0) {
            if (adapter)
                adapter.enabled = !adapter.enabled;
            return;
        }
        const dev = Bluetooth.devices.values[i - 1];
        if (!dev)
            return;
        if (dev.connected)
            dev.disconnect();
        else if (dev.paired)
            dev.connect();
        else
            dev.pair();
    }

    onActiveChanged: {
        if (active && adapter && adapter.enabled)
            adapter.discovering = true;
    }

    Flickable {
        id: flick

        anchors.fill: parent
        clip: true
        contentHeight: col.implicitHeight

        Column {
            id: col

            width: parent.width
            spacing: 2

            // Row 0: adapter toggle
            Rectangle {
                width: parent.width
                height: 28
                color: root.sel === 0 ? theme.hoverBg : "transparent"
                border.width: root.sel === 0 ? 1 : 0
                border.color: theme.accent

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Bluetooth"
                        color: theme.fg
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSize
                    }

                    Item {
                        width: parent.width - 130
                        height: 1
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
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
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.sel = 0
                    onClicked: root.activateRow(0)
                }
            }

            Text {
                visible: !root.adapter
                text: "No Bluetooth adapter"
                color: theme.dim
                font.family: theme.fontFamily
                font.pixelSize: theme.smallSize
            }

            Repeater {
                model: Bluetooth.devices

                delegate: Rectangle {
                    id: devRow

                    required property var modelData
                    required property int index

                    width: col.width
                    height: 28
                    color: root.sel === index + 1 ? theme.hoverBg : "transparent"
                    border.width: root.sel === index + 1 ? 1 : 0
                    border.color: theme.accent

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
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
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.sel = devRow.index + 1
                        onClicked: root.activateRow(devRow.index + 1)
                    }
                }
            }
        }
    }
}
