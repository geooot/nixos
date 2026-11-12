import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root

    property bool active: false
    property int sel: 0

    Theme {
        id: theme
    }

    property var sinks: Pipewire.nodes.values.filter(n => n.isSink && n.audio && !n.isStream)
    property var sources: Pipewire.nodes.values.filter(n => !n.isSink && n.audio && !n.isStream)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    property var rows: []

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].filter(n => n !== null)
    }

    function deviceLabel(node) {
        return node.description || node.nickname || node.name || "";
    }

    function rebuildRows() {
        const r = [];
        if (sink) {
            r.push({
                "kind": "vol",
                "io": "out",
                "node": sink
            });
            r.push({
                "kind": "mute",
                "io": "out",
                "node": sink
            });
        }
        for (const n of sinks)
            r.push({
                "kind": "dev",
                "io": "out",
                "node": n
            });
        if (source) {
            r.push({
                "kind": "vol",
                "io": "in",
                "node": source
            });
            r.push({
                "kind": "mute",
                "io": "in",
                "node": source
            });
        }
        for (const n of sources)
            r.push({
                "kind": "dev",
                "io": "in",
                "node": n
            });
        rows = r;
        sel = Math.max(0, Math.min(sel, rows.length - 1));
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
        sel = Math.max(0, Math.min(sel, rows.length - 1));
        ensureVisible();
    }

    function navActivate() {
        activateRow(sel);
    }

    function navAdjust(d) {
        const row = rows[sel];
        if (!row)
            return;
        if (row.kind === "vol")
            row.node.audio.volume = Math.max(0, Math.min(1, row.node.audio.volume + d * 0.05));
        else
            activateRow(sel);
    }

    function activateRow(i) {
        const row = rows[i];
        if (!row)
            return;
        if (row.kind === "mute")
            row.node.audio.muted = !row.node.audio.muted;
        else if (row.kind === "dev") {
            if (row.io === "out")
                Pipewire.preferredDefaultAudioSink = row.node;
            else
                Pipewire.preferredDefaultAudioSource = row.node;
        } else if (row.kind === "vol")
            row.node.audio.muted = !row.node.audio.muted;
    }

    onSinksChanged: rebuildRows()
    onSourcesChanged: rebuildRows()
    onSinkChanged: rebuildRows()
    onSourceChanged: rebuildRows()
    onActiveChanged: {
        if (active)
            rebuildRows();
    }
    Component.onCompleted: rebuildRows()

    Flickable {
        id: flick

        anchors.fill: parent
        clip: true
        contentHeight: col.implicitHeight

        Column {
            id: col

            width: parent.width
            spacing: 2

            Repeater {
                model: root.rows

                delegate: Rectangle {
                    id: rowItem

                    required property var modelData
                    required property int index

                    width: col.width
                    height: 28
                    color: root.sel === index ? theme.hoverBg : "transparent"
                    border.width: root.sel === index ? 1 : 0
                    border.color: theme.accent

                    // Volume row
                    Row {
                        visible: rowItem.modelData.kind === "vol"
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 52
                            text: rowItem.modelData.io === "out" ? "Output" : "Input"
                            color: theme.fg
                            font.family: theme.fontFamily
                            font.pixelSize: theme.smallSize
                        }

                        VolumeSlider {
                            id: volVis

                            width: parent.width - 110
                            anchors.verticalCenter: parent.verticalCenter
                            enabled: false
                            value: rowItem.modelData.node.audio.volume
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36
                            text: Math.round(rowItem.modelData.node.audio.volume * 100) + "%"
                            color: theme.dim
                            font.family: theme.fontFamily
                            font.pixelSize: theme.smallSize
                        }
                    }

                    // Mute row
                    Text {
                        visible: rowItem.modelData.kind === "mute"
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        text: (rowItem.modelData.io === "out" ? "Output" : "Input") + " mute: " + (rowItem.modelData.node.audio.muted ? "on" : "off")
                        color: theme.fg
                        font.family: theme.fontFamily
                        font.pixelSize: theme.smallSize
                    }

                    // Device row
                    Text {
                        visible: rowItem.modelData.kind === "dev"
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        width: parent.width - 12
                        text: ((rowItem.modelData.io === "out" ? rowItem.modelData.node === Pipewire.defaultAudioSink : rowItem.modelData.node === Pipewire.defaultAudioSource) ? "▸ " : "  ") + root.deviceLabel(rowItem.modelData.node)
                        color: (rowItem.modelData.io === "out" ? rowItem.modelData.node === Pipewire.defaultAudioSink : rowItem.modelData.node === Pipewire.defaultAudioSource) ? theme.accent : theme.dim
                        font.family: theme.fontFamily
                        font.pixelSize: theme.smallSize
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.sel = rowItem.index
                        onClicked: mouse => {
                            root.sel = rowItem.index;
                            if (rowItem.modelData.kind === "vol") {
                                const row = rowItem.modelData;
                                row.node.audio.volume = Math.max(0, Math.min(1, (mouse.x - 66) / (rowItem.width - 124)));
                            } else {
                                root.activateRow(rowItem.index);
                            }
                        }
                    }
                }
            }
        }
    }
}
