// Hub > Keys: a cheat sheet of the desktop's shortcuts.
import QtQuick
import "../"

Item {
    id: page

    readonly property var groups: [
        { g: "LAUNCH", items: [
            ["Super Space", "Launcher: apps, calculator, files, emoji, windows (Ctrl+Tab)"],
            ["Super Enter", "Terminal (kitty)"],
            ["Super Q", "Floating terminal with fastfetch"],
            ["Super B", "Browser"],
            ["Super F", "Files"],
            ["Super V", "VS Code"],
            ["Super Y", "Spotify"]
        ] },
        { g: "DESKTOP", items: [
            ["Super , / Super I", "Hub"],
            ["Super N", "Notifications"],
            ["Super W", "Wallpapers"],
            ["Super Shift Space", "Light / dark"],
            ["Super T", "Tray"],
            ["Super Esc", "Power menu"]
        ] },
        { g: "CAPTURE", items: [
            ["Super Shift S", "Capture menu: area, window, screen, OCR, QR, record"],
            ["Super Shift C", "Pick a colour"],
            ["Super Alt R", "Stop recording"],
            ["Print / Shift Print", "Area / screen to clipboard"],
            ["Super C", "Clipboard history"]
        ] },
        { g: "WINDOWS", items: [
            ["Super R", "Close"],
            ["Super M", "Maximize"],
            ["Super 1…0", "Workspace"],
            ["Super Shift 1…0", "Move window to workspace"],
            ["Super Shift arrows", "Move window"],
            ["Super ← / →", "Resize"],
            ["Super H", "Hidden workspace"],
            ["Alt Tab", "Next window"]
        ] }
    ]

    Flickable {
        anchors.fill: parent
        anchors.rightMargin: 20
        contentHeight: col.implicitHeight
        clip: true

        Column {
            id: col
            width: parent.width
            spacing: 14

            Repeater {
                model: page.groups
                Column {
                    required property var modelData
                    width: col.width
                    spacing: 2
                    Text {
                        text: parent.modelData.g
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.letterSpacing: 2
                        bottomPadding: 4
                    }
                    Repeater {
                        model: parent.modelData.items
                        Item {
                            required property var modelData
                            width: col.width
                            height: 30
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 22
                                width: keyLbl.implicitWidth + 16
                                radius: 6
                                color: Theme.alpha(Theme.accent, 0.14)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.35)
                                Text {
                                    id: keyLbl
                                    anchors.centerIn: parent
                                    text: parent.parent.modelData[0]
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }
                            }
                            Text {
                                x: 190
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 190
                                text: parent.modelData[1]
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
