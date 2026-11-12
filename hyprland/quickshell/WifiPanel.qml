import QtQuick
import Quickshell.Networking

Item {
    id: root

    property bool active: false
    property int sel: 0

    signal wantFocus

    Theme {
        id: theme
    }

    property var wifiDev: {
        for (const dev of Networking.devices.values) {
            if (dev.type === DeviceType.Wifi)
                return dev;
        }
        return null;
    }
    property var pending: null
    readonly property int rowCount: 1 + (wifiDev ? wifiDev.networks.values.length : 0)

    function clampSel() {
        sel = Math.max(0, Math.min(sel, rowCount - 1));
    }

    function ensureVisible() {
        const y = sel * 30;
        if (y < flick.contentY)
            flick.contentY = y;
        else if (y + 30 > flick.contentY + flick.height)
            flick.contentY = y + 30 - flick.height;
    }

    function navMove(d) {
        sel += d;
        clampSel();
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
            Networking.wifiEnabled = !Networking.wifiEnabled;
            return;
        }
        const network = wifiDev.networks.values[i - 1];
        if (network)
            activateNetwork(network);
    }

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
        if (isSecured(network)) {
            pending = network;
            password.text = "";
            password.forceActiveFocus();
        } else {
            network.connect();
        }
    }

    onActiveChanged: {
        if (wifiDev)
            wifiDev.scannerEnabled = active;
        clampSel();
    }
    onWifiDevChanged: {
        if (wifiDev)
            wifiDev.scannerEnabled = active;
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

            // Row 0: Wi-Fi toggle
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
                        text: "Wi-Fi"
                        color: theme.fg
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSize
                    }

                    Item {
                        width: parent.width - 110
                        height: 1
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
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
                visible: !root.wifiDev
                text: "No Wi-Fi device (NetworkManager unavailable)"
                color: theme.dim
                font.family: theme.fontFamily
                font.pixelSize: theme.smallSize
                wrapMode: Text.Wrap
                width: parent.width
            }

            Repeater {
                model: root.wifiDev ? root.wifiDev.networks : null

                delegate: Rectangle {
                    id: netRow

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
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.sel = netRow.index + 1
                        onClicked: root.activateNetwork(netRow.modelData)
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
                            root.wantFocus();
                        }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.pending = null;
                                root.wantFocus();
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
