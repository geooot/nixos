import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root

    Theme {
        id: theme
    }

    implicitHeight: content.implicitHeight

    property var sinks: Pipewire.nodes.values.filter(n => n.isSink && n.audio && !n.isStream)
    property var sources: Pipewire.nodes.values.filter(n => !n.isSink && n.audio && !n.isStream)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].filter(n => n !== null)
    }

    function deviceLabel(node) {
        return node.description || node.nickname || node.name || "";
    }

    Column {
        id: content

        width: parent.width
        spacing: 6

        Text {
            text: "Sound"
            color: theme.fg
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSize
            font.bold: true
        }

        Text {
            text: "Output"
            color: theme.dim
            font.family: theme.fontFamily
            font.pixelSize: theme.smallSize
        }

        Row {
            width: parent.width
            spacing: 8

            Rectangle {
                width: 24
                height: 24
                color: root.sink && root.sink.audio.muted ? theme.accent : "transparent"
                border.width: 1
                border.color: theme.border

                Text {
                    anchors.centerIn: parent
                    text: "M"
                    color: theme.fg
                    font.family: theme.fontFamily
                    font.pixelSize: theme.smallSize
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.sink)
                            root.sink.audio.muted = !root.sink.audio.muted;
                    }
                }
            }

            VolumeSlider {
                width: parent.width - 76
                anchors.verticalCenter: parent.verticalCenter
                value: root.sink ? root.sink.audio.volume : 0
                onMoved: v => {
                    if (root.sink)
                        root.sink.audio.volume = v;
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                text: root.sink ? Math.round(root.sink.audio.volume * 100) + "%" : ""
                color: theme.dim
                font.family: theme.fontFamily
                font.pixelSize: theme.smallSize
            }
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: root.sinks

                delegate: Text {
                    id: sinkRow

                    required property var modelData

                    width: content.width
                    text: (modelData === Pipewire.defaultAudioSink ? "▸ " : "  ") + root.deviceLabel(modelData)
                    color: modelData === Pipewire.defaultAudioSink ? theme.accent : theme.dim
                    font.family: theme.fontFamily
                    font.pixelSize: theme.smallSize
                    elide: Text.ElideRight

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Pipewire.preferredDefaultAudioSink = sinkRow.modelData
                    }
                }
            }
        }

        Text {
            text: "Input"
            color: theme.dim
            font.family: theme.fontFamily
            font.pixelSize: theme.smallSize
        }

        Row {
            width: parent.width
            spacing: 8

            Rectangle {
                width: 24
                height: 24
                color: root.source && root.source.audio.muted ? theme.accent : "transparent"
                border.width: 1
                border.color: theme.border

                Text {
                    anchors.centerIn: parent
                    text: "M"
                    color: theme.fg
                    font.family: theme.fontFamily
                    font.pixelSize: theme.smallSize
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.source)
                            root.source.audio.muted = !root.source.audio.muted;
                    }
                }
            }

            VolumeSlider {
                width: parent.width - 76
                anchors.verticalCenter: parent.verticalCenter
                value: root.source ? root.source.audio.volume : 0
                onMoved: v => {
                    if (root.source)
                        root.source.audio.volume = v;
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                text: root.source ? Math.round(root.source.audio.volume * 100) + "%" : ""
                color: theme.dim
                font.family: theme.fontFamily
                font.pixelSize: theme.smallSize
            }
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: root.sources

                delegate: Text {
                    id: sourceRow

                    required property var modelData

                    width: content.width
                    text: (modelData === Pipewire.defaultAudioSource ? "▸ " : "  ") + root.deviceLabel(modelData)
                    color: modelData === Pipewire.defaultAudioSource ? theme.accent : theme.dim
                    font.family: theme.fontFamily
                    font.pixelSize: theme.smallSize
                    elide: Text.ElideRight

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Pipewire.preferredDefaultAudioSource = sourceRow.modelData
                    }
                }
            }
        }
    }
}
