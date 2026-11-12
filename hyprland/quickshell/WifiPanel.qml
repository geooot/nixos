import QtQuick
import Quickshell.Networking

Item {
    id: root

    property bool shown: false

    Theme {
        id: theme
    }

    implicitHeight: content.implicitHeight

    property var wifiDev: {
        for (const dev of Networking.devices.values) {
            if (dev.type === DeviceType.Wifi)
                return dev;
        }
        return null;
    }
    property var pending: null

    function updateScanner() {
        if (root.wifiDev)
            root.wifiDev.scannerEnabled = root.shown;
    }

    onShownChanged: updateScanner()
    onWifiDevChanged: updateScanner()

    function isSecured(network) {
        return network.security !== WifiSecurityType.Open;
    }

    function activateNetwork(network) {
        if (network.connected) {
            network.disconnect();
            return;
        }
        if (network.known) {
            network.connect();
            return;
        }
        if (root.isSecured(network)) {
            root.pending = network;
            password.text = "";
            password.forceActiveFocus();
        } else {
            network.connect();
        }
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
                text: "Wi-Fi"
                color: theme.fg
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSize
                font.bold: true
            }

            Item {
                width: parent.width - 120
                height: 1
            }

            Rectangle {
                width: 36
                height: 18
                color: Networking.wifiEnabled ? theme.accent : theme.border

                Rectangle {
                    x: Networking.wifiEnabled ? parent.width - width - 2 : 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    color: theme.fg
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }
        }

        Text {
            visible: !root.wifiDev
            text: "No Wi-Fi device (NetworkManager unavailable)"
            color: theme.dim
            font.family: theme.fontFamily
            font.pixelSize: theme.smallSize
            wrapMode: Text.Wrap
            width: parent.width
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: root.wifiDev ? root.wifiDev.networks : null

                delegate: Rectangle {
                    id: netRow

                    required property var modelData

                    width: content.width
                    height: 26
                    color: netMouse.containsMouse ? theme.hoverBg : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 110
                            text: netRow.modelData.name
                            color: netRow.modelData.connected ? theme.accent : theme.fg
                            font.family: theme.fontFamily
                            font.pixelSize: theme.smallSize
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.isSecured(netRow.modelData)
                            text: "secured"
                            color: theme.dim
                            font.family: theme.fontFamily
                            font.pixelSize: theme.smallSize
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(netRow.modelData.signalStrength * 100) + "%"
                            color: theme.dim
                            font.family: theme.fontFamily
                            font.pixelSize: theme.smallSize
                        }
                    }

                    MouseArea {
                        id: netMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.activateNetwork(netRow.modelData)
                    }
                }
            }
        }

        Column {
            visible: root.pending !== null
            width: parent.width
            spacing: 4

            Text {
                text: "Password for " + (root.pending ? root.pending.name : "")
                color: theme.dim
                font.family: theme.fontFamily
                font.pixelSize: theme.smallSize
            }

            Rectangle {
                width: parent.width
                height: 28
                color: theme.bg
                border.width: 1
                border.color: theme.border

                TextInput {
                    id: password

                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: theme.fg
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSize
                    onAccepted: {
                        if (root.pending)
                            root.pending.connectWithPsk(text);
                        root.pending = null;
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.pending = null;
                            event.accepted = true;
                        }
                    }
                }
            }
        }
    }
}
