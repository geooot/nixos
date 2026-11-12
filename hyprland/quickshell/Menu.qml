import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

// Spotlight-style menu toggled with `qs ipc call menu toggle`:
//   - launch apps (DesktopEntries)
//   - focus open windows (Hyprland toplevels)
//   - calculator via qalc (type e.g. "2+3*4" or "10 km to miles", Enter copies)
//   - toggleable panels: wifi, sound, power profile, bluetooth, keybinds
PanelWindow {
    id: root

    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-menu"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Theme {
        id: theme
    }

    PersistentProperties {
        id: persist

        reloadableId: "menu-panels"
        property bool wifi: false
        property bool sound: false
        property bool power: false
        property bool bluetooth: false
        property bool keys: false
    }

    property var panels: [
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
    readonly property bool anyPanel: persist.wifi || persist.sound || persist.power || persist.bluetooth || persist.keys

    property var entries: []
    property int sel: 0
    property string calcResult: ""
    property string calcExpr: ""

    function iconForId(appId) {
        const entry = appId ? DesktopEntries.heuristicLookup(appId) : null;
        return Quickshell.iconPath(entry && entry.icon ? entry.icon : "application-x-executable");
    }

    function rebuild() {
        const q = search.text.trim().toLowerCase();
        const out = [];
        if (root.calcResult !== "")
            out.push({
                "type": "calc",
                "name": root.calcResult,
                "sub": "= " + root.calcExpr,
                "icon": ""
            });
        for (const tl of Hyprland.toplevels.values) {
            if (tl.workspace && tl.workspace.name === "special:minimized")
                continue;
            const appId = tl.wayland ? tl.wayland.appId : "";
            if (q === "" || (tl.title || "").toLowerCase().includes(q) || appId.toLowerCase().includes(q))
                out.push({
                    "type": "window",
                    "name": tl.title || appId,
                    "sub": "Window · " + appId,
                    "icon": root.iconForId(appId),
                    "address": tl.address
                });
        }
        const apps = DesktopEntries.applications.values.slice().sort((a, b) => a.name.localeCompare(b.name));
        for (const app of apps) {
            if (app.noDisplay)
                continue;
            if (q === "" || app.name.toLowerCase().includes(q) || (app.genericName || "").toLowerCase().includes(q) || (app.comment || "").toLowerCase().includes(q))
                out.push({
                    "type": "app",
                    "name": app.name,
                    "sub": app.genericName || app.comment || "",
                    "icon": app.icon || "",
                    "entry": app
                });
        }
        root.entries = out.slice(0, 60);
        if (root.sel >= root.entries.length)
            root.sel = Math.max(0, root.entries.length - 1);
    }

    function activate(entry) {
        if (!entry)
            return;
        if (entry.type === "calc")
            Quickshell.execDetached(["wl-copy", entry.name]);
        else if (entry.type === "window")
            Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:" + entry.address + "\" })"]);
        else if (entry.type === "app" && entry.entry)
            entry.entry.execute();
        root.closeMenu();
    }

    function openMenu(panel) {
        if (panel && persist.hasOwnProperty(panel))
            persist[panel] = true;
        root.visible = true;
        search.text = "";
        root.calcResult = "";
        root.sel = 0;
        root.rebuild();
        search.forceActiveFocus();
    }

    function closeMenu() {
        root.visible = false;
    }

    function queueCalc() {
        const expr = search.text.trim();
        root.calcExpr = expr;
        if (!/[0-9]/.test(expr) || !/[+\-*/^%()=.]/.test(expr)) {
            root.calcResult = "";
            root.rebuild();
            return;
        }
        calcTimer.restart();
    }

    Timer {
        id: calcTimer

        interval: 150
        onTriggered: {
            calcProc.command = ["qalc", "-t", root.calcExpr];
            calcProc.running = false;
            calcProc.running = true;
        }
    }

    Process {
        id: calcProc

        stdout: StdioCollector {
            onStreamFinished: {
                const result = text.trim();
                root.calcResult = (result !== "" && !result.startsWith("error") && result.toLowerCase() !== root.calcExpr.toLowerCase()) ? result : "";
                root.rebuild();
            }
        }
        stderr: StdioCollector {
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            root.rebuild();
        }
    }

    Component.onCompleted: root.rebuild()

    IpcHandler {
        target: "menu"

        function toggle(): void {
            if (root.visible)
                root.closeMenu();
            else
                root.openMenu("");
        }

        function open(panel: string): void {
            root.openMenu(panel);
        }

        function close(): void {
            root.closeMenu();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeMenu()

        Rectangle {
            anchors.centerIn: parent
            width: root.anyPanel ? 1020 : 680
            height: 600
            color: theme.panelBg
            border.width: 1
            border.color: theme.border

            MouseArea {
                anchors.fill: parent
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // Panel toggles
                Row {
                    spacing: 6

                    Repeater {
                        model: root.panels

                        delegate: Rectangle {
                            id: toggle

                            required property var modelData

                            width: toggleLabel.implicitWidth + 16
                            height: 24
                            color: persist[modelData.id] ? theme.hoverBg : "transparent"
                            border.width: 1
                            border.color: persist[modelData.id] ? theme.accent : theme.border

                            Text {
                                id: toggleLabel

                                anchors.centerIn: parent
                                text: toggle.modelData.label
                                color: persist[toggle.modelData.id] ? theme.fg : theme.dim
                                font.family: theme.fontFamily
                                font.pixelSize: theme.smallSize
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: persist[toggle.modelData.id] = !persist[toggle.modelData.id]
                            }
                        }
                    }
                }

                // Search
                TextInput {
                    id: search

                    width: parent.width
                    color: theme.fg
                    selectionColor: theme.accent
                    font.family: theme.fontFamily
                    font.pixelSize: 18
                    clip: true
                    onTextChanged: {
                        root.sel = 0;
                        root.queueCalc();
                        root.rebuild();
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.closeMenu();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            root.sel = Math.min(root.sel + 1, root.entries.length - 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.sel = Math.max(root.sel - 1, 0);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activate(root.entries[root.sel]);
                            event.accepted = true;
                        }
                    }

                    Text {
                        anchors.fill: parent
                        visible: search.text === ""
                        text: "Launch app, focus window, or calculate…"
                        color: theme.dim
                        font: search.font
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: theme.border
                }

                Row {
                    width: parent.width
                    height: parent.height - 110
                    spacing: 12

                    // Results
                    ListView {
                        id: results

                        width: root.anyPanel ? parent.width - 332 : parent.width
                        height: parent.height
                        clip: true
                        model: root.entries
                        currentIndex: root.sel

                        delegate: Rectangle {
                            id: row

                            required property var modelData
                            required property int index

                            width: results.width
                            height: 36
                            color: index === root.sel ? theme.hoverBg : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 8

                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 18
                                    source: row.modelData.type === "app" && row.modelData.icon ? Quickshell.iconPath(row.modelData.icon) : (row.modelData.icon || "")
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 30

                                    Text {
                                        width: parent.width
                                        text: row.modelData.name
                                        color: theme.fg
                                        font.family: theme.fontFamily
                                        font.pixelSize: theme.fontSize
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        visible: row.modelData.sub !== ""
                                        text: row.modelData.sub
                                        color: theme.dim
                                        font.family: theme.fontFamily
                                        font.pixelSize: theme.smallSize
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.sel = row.index
                                onClicked: root.activate(row.modelData)
                            }
                        }
                    }

                    // Panels
                    Column {
                        visible: root.anyPanel
                        width: 320
                        height: parent.height
                        spacing: 12

                        WifiPanel {
                            visible: persist.wifi
                            shown: persist.wifi
                            width: parent.width
                        }

                        SoundPanel {
                            visible: persist.sound
                            width: parent.width
                        }

                        PowerPanel {
                            visible: persist.power
                            shown: persist.power
                            width: parent.width
                        }

                        BluetoothPanel {
                            visible: persist.bluetooth
                            shown: persist.bluetooth
                            width: parent.width
                        }

                        KeysPanel {
                            visible: persist.keys
                            width: parent.width
                        }
                    }
                }
            }
        }
    }
}
