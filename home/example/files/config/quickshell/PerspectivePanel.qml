// PerspectivePanel.qml
// Flat card that fades in and out (the original 3D tilt is removed).
import QtQuick
Item {
    id: root

    default property alias content: contentContainer.data
    property bool open: false

    opacity: open ? 1 : 0
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
    }
}
