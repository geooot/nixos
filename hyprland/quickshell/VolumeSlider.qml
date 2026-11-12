import QtQuick

Item {
    id: slider

    property real value: 0
    signal moved(real v)

    Theme {
        id: theme
    }

    height: 18

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        color: theme.border
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * Math.max(0, Math.min(1, slider.value))
        height: 4
        color: theme.accent
    }

    Rectangle {
        x: parent.width * Math.max(0, Math.min(1, slider.value)) - 5
        anchors.verticalCenter: parent.verticalCenter
        width: 10
        height: 10
        color: theme.fg
    }

    MouseArea {
        anchors.fill: parent
        onPressed: mouse => slider.moved(Math.max(0, Math.min(1, mouse.x / width)))
        onPositionChanged: mouse => {
            if (pressed)
                slider.moved(Math.max(0, Math.min(1, mouse.x / width)));
        }
    }
}
