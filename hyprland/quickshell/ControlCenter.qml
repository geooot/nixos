import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

// Action center: opened from the bar button (≡) or Super+/.
// Tabs for Wi-Fi / Sound / Power / Bluetooth / Keys; each tab is
// scrollable and keyboard navigable:
//   Tab / Shift+Tab   switch section
//   Up/Down or K/J    select row
//   Left/Right or H/L adjust slider, toggle row
//   Enter / Space     activate row
//   Esc               close
PanelWindow {
    id: cc

    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-control"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }
    margins {
        top: 34
        right: 8
    }
    implicitWidth: 400
    implicitHeight: 560

    Theme {
        id: theme
    }

    property int tabIndex: 0
    property var tabs: [
        {
            "id": "wifi",
            "label": "Wi-Fi"
        },
        {
            "id": "sound",
            "label": "Sound"
        },
        {
            "id": "power",
            "label": "Power"
        },
        {
            "id": "bluetooth",
            "label": "Bluetooth"
        },
        {
            "id": "keys",
            "label": "Keys"
        },
    ]
    readonly property string currentTab: tabs[tabIndex].id

    function panelFor(id) {
        switch (id) {
        case "wifi":
            return wifiPanel;
        case "sound":
            return soundPanel;
        case "power":
            return powerPanel;
        case "bluetooth":
            return bluetoothPanel;
        default:
            return keysPanel;
        }
    }

    function show(tab) {
        if (tab) {
            for (let i = 0; i < tabs.length; i++) {
                if (tabs[i].id === tab)
                    tabIndex = i;
            }
        }
        visible = true;
        keyHandler.forceActiveFocus();
    }

    HyprlandFocusGrab {
        active: cc.visible
        windows: [cc]
        onCleared: cc.visible = false
    }

    IpcHandler {
        target: "control"

        function toggle(): void {
            if (cc.visible)
                cc.visible = false;
            else
                cc.show("");
        }

        function open(tab: string): void {
            cc.show(tab);
        }

        function close(): void {
            cc.visible = false;
        }
    }

    onVisibleChanged: {
        if (visible)
            keyHandler.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent
        color: theme.panelBg
        border.width: 1
        border.color: theme.border

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // Tabs
            Row {
                spacing: 6

                Repeater {
                    model: cc.tabs

                    delegate: Rectangle {
                        id: tabButton

                        required property var modelData
                        required property int index

                        width: tabLabel.implicitWidth + 14
                        height: 24
                        color: cc.tabIndex === index ? theme.hoverBg : "transparent"
                        border.width: 1
                        border.color: cc.tabIndex === index ? theme.accent : theme.border

                        Text {
                            id: tabLabel

                            anchors.centerIn: parent
                            text: tabButton.modelData.label
                            color: cc.tabIndex === tabButton.index ? theme.fg : theme.dim
                            font.family: theme.fontFamily
                            font.pixelSize: theme.smallSize
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                cc.tabIndex = tabButton.index;
                                keyHandler.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: theme.border
            }

            // Active section
            Item {
                width: parent.width
                height: parent.height - 46

                WifiPanel {
                    id: wifiPanel

                    anchors.fill: parent
                    visible: cc.currentTab === "wifi"
                    active: cc.visible && cc.currentTab === "wifi"
                    onWantFocus: keyHandler.forceActiveFocus()
                }

                SoundPanel {
                    id: soundPanel

                    anchors.fill: parent
                    visible: cc.currentTab === "sound"
                    active: cc.visible && cc.currentTab === "sound"
                }

                PowerPanel {
                    id: powerPanel

                    anchors.fill: parent
                    visible: cc.currentTab === "power"
                    active: cc.visible && cc.currentTab === "power"
                }

                BluetoothPanel {
                    id: bluetoothPanel

                    anchors.fill: parent
                    visible: cc.currentTab === "bluetooth"
                    active: cc.visible && cc.currentTab === "bluetooth"
                }

                KeysPanel {
                    id: keysPanel

                    anchors.fill: parent
                    visible: cc.currentTab === "keys"
                    active: cc.visible && cc.currentTab === "keys"
                }
            }
        }

        Item {
            id: keyHandler

            focus: true
            width: 0
            height: 0

            Keys.onPressed: event => {
                const panel = cc.panelFor(cc.currentTab);
                let handled = true;
                switch (event.key) {
                case Qt.Key_Escape:
                    cc.visible = false;
                    break;
                case Qt.Key_Tab:
                    cc.tabIndex = (cc.tabIndex + 1) % cc.tabs.length;
                    break;
                case Qt.Key_Backtab:
                    cc.tabIndex = (cc.tabIndex + cc.tabs.length - 1) % cc.tabs.length;
                    break;
                case Qt.Key_Down:
                case Qt.Key_J:
                    panel.navMove(1);
                    break;
                case Qt.Key_Up:
                case Qt.Key_K:
                    panel.navMove(-1);
                    break;
                case Qt.Key_Right:
                case Qt.Key_L:
                    panel.navAdjust(1);
                    break;
                case Qt.Key_Left:
                case Qt.Key_H:
                    panel.navAdjust(-1);
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                case Qt.Key_Space:
                    panel.navActivate();
                    break;
                default:
                    handled = false;
                }
                event.accepted = handled;
            }
        }
    }
}
