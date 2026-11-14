import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

// Spotlight-style launcher toggled with `qs ipc call menu toggle`:
//   - launch apps (DesktopEntries)
//   - focus open windows (Hyprland toplevels)
//   - calculator via qalc (type e.g. "2+3*4" or "10 km to miles", Enter copies)
// System controls live in the ControlCenter (bar ≡ button / Super+/).
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

    property var entries: []
    property int sel: 0
    property string entriesKey: ""
    property point lastMouse: Qt.point(-1, -1)
    property string calcResult: ""
    property string calcExpr: ""

    function iconForId(appId) {
        const entry = appId ? DesktopEntries.heuristicLookup(appId) : null;
        return Quickshell.iconPath(entry && entry.icon ? entry.icon : "application-x-executable");
    }

    // HyprlandToplevel.address has no 0x prefix; hyprctl needs one.
    function normAddr(address) {
        if (!address)
            return "";
        return address.startsWith("0x") ? address : "0x" + address;
    }

    // How well `text` matches query `q` (both lowercase): exact > prefix >
    // word prefix > substring. 0 means no match.
    function matchScore(text, q) {
        if (!text)
            return 0;
        const t = text.toLowerCase();
        if (t === q)
            return 4;
        if (t.startsWith(q))
            return 3;
        if (t.split(/[^a-z0-9]+/).some(w => w.startsWith(q)))
            return 2;
        return t.includes(q) ? 1 : 0;
    }

    // Name matches always outrank generic name / keyword matches, which
    // outrank description matches (e.g. "Play this game on Steam").
    function appScore(app, q) {
        const name = root.matchScore(app.name, q);
        if (name > 0)
            return 100 + name * 10;
        const generic = root.matchScore(app.genericName, q);
        if (generic > 0)
            return 60 + generic * 5;
        const keyword = Math.max(0, ...(app.keywords || []).map(k => root.matchScore(k, q)));
        if (keyword > 0)
            return 40 + keyword * 3;
        return root.matchScore(app.comment, q) >= 2 ? 10 : 0;
    }

    function windowScore(title, appId, q) {
        const s = Math.max(root.matchScore(title, q), root.matchScore(appId, q));
        return s > 0 ? 100 + s * 10 : 0;
    }

    function rebuild() {
        const q = search.text.trim().toLowerCase();
        const scored = [];
        for (const tl of Hyprland.toplevels.values) {
            if (tl.workspace && tl.workspace.name === "special:minimized")
                continue;
            const appId = tl.wayland ? tl.wayland.appId : "";
            const score = q === "" ? 1 : root.windowScore(tl.title, appId, q);
            if (score > 0)
                scored.push({
                    "score": score,
                    "rank": 0,
                    "item": {
                        "type": "window",
                        "name": tl.title || appId,
                        "sub": "Window · " + appId,
                        "icon": root.iconForId(appId),
                        "address": tl.address
                    }
                });
        }
        for (const app of DesktopEntries.applications.values) {
            if (app.noDisplay)
                continue;
            const score = q === "" ? 1 : root.appScore(app, q);
            if (score > 0)
                scored.push({
                    "score": score,
                    "rank": 1,
                    "item": {
                        "type": "app",
                        "name": app.name,
                        "sub": app.genericName || app.comment || "",
                        "icon": app.icon || "",
                        "entry": app
                    }
                });
        }
        // Higher score first; on ties windows before apps, then shorter
        // names (closer matches), then alphabetical.
        scored.sort((a, b) => b.score - a.score || a.rank - b.rank || (q === "" ? 0 : a.item.name.length - b.item.name.length) || a.item.name.localeCompare(b.item.name));

        const out = [];
        if (root.calcResult !== "")
            out.push({
                "type": "calc",
                "name": root.calcResult,
                "sub": "= " + root.calcExpr,
                "icon": ""
            });
        for (const s of scored.slice(0, 60))
            out.push(s.item);

        // Reassigning the model resets the ListView's scroll position, so
        // skip it when nothing visible changed (Hyprland events fire often).
        const key = out.map(e => e.type + "\u0001" + e.name + "\u0001" + e.sub + "\u0001" + (e.address || "")).join("\u0002");
        if (key !== root.entriesKey) {
            root.entriesKey = key;
            root.entries = out;
        }
        if (root.sel >= root.entries.length)
            root.sel = Math.max(0, root.entries.length - 1);
    }

    function activate(entry) {
        if (!entry)
            return;
        if (entry.type === "calc")
            Quickshell.execDetached(["wl-copy", entry.name]);
        else if (entry.type === "window")
            Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:" + root.normAddr(entry.address) + "\" })"]);
        else if (entry.type === "app" && entry.entry)
            entry.entry.execute();
        root.closeMenu();
    }

    function openMenu() {
        root.visible = true;
        search.text = "";
        root.calcResult = "";
        root.sel = 0;
        root.rebuild();
        results.positionViewAtBeginning();
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
            if (root.visible)
                root.rebuild();
        }
    }

    onSelChanged: results.positionViewAtIndex(root.sel, ListView.Contain)

    Component.onCompleted: root.rebuild()

    IpcHandler {
        target: "menu"

        function toggle(): void {
            if (root.visible)
                root.closeMenu();
            else
                root.openMenu();
        }

        function open(): void {
            root.openMenu();
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
            width: 680
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

                ListView {
                    id: results

                    width: parent.width
                    height: parent.height - 52
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.entries

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
                            // Only follow real mouse movement: when the list
                            // scrolls under a still cursor, rows get hover
                            // events too, which would steal the keyboard selection.
                            onPositionChanged: mouse => {
                                const p = mapToItem(null, mouse.x, mouse.y);
                                if (p.x === root.lastMouse.x && p.y === root.lastMouse.y)
                                    return;
                                root.lastMouse = p;
                                root.sel = row.index;
                            }
                            onClicked: root.activate(row.modelData)
                        }
                    }
                }
            }
        }
    }
}
