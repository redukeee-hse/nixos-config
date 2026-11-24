// Hub > Keys: a cheat sheet of the desktop's shortcuts.
import QtQuick
import "../"

Item {
    id: page

    readonly property var groups: [
        { g: "Launch", items: [
            ["Super Space", "Launcher: apps, calculator, files, emoji, windows (Ctrl+Tab)"],
            ["Super Enter", "Terminal (kitty)"],
            ["Super Q", "Floating terminal with fastfetch"],
            ["Super B", "Browser"],
            ["Super F", "Files"],
            ["Super V", "VS Code"],
            ["Super Y", "Spotify"]
        ] },
        { g: "Desktop", items: [
            ["Super , / Super I", "Hub"],
            ["Super N", "Notifications"],
            ["Super W", "Wallpapers"],
            ["Super Shift Space", "Light / dark"],
            ["Super T", "Tray"],
            ["Super Esc", "Power menu"]
        ] },
        { g: "Capture", items: [
            ["Super Shift S", "Capture menu: area, window, screen, OCR, QR, record"],
            ["Super Shift C", "Pick a colour"],
            ["Super Alt R", "Stop recording"],
            ["Print / Shift Print", "Area / screen to clipboard"],
            ["Super C", "Clipboard history"]
        ] },
        { g: "Windows", items: [
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
        anchors.rightMargin: 12
        contentHeight: col.implicitHeight
        clip: true

        Column {
            id: col
            width: parent.width
            spacing: 10

            HubHeader { title: "Keyboard shortcuts" }

            Repeater {
                model: page.groups
                Column {
                    required property var modelData
                    width: col.width
                    spacing: 2
                    HubLabel { text: parent.modelData.g }
                    Repeater {
                        model: parent.modelData.items
                        Item {
                            required property var modelData
                            width: col.width
                            height: 34
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 26
                                width: keyLbl.implicitWidth + 18
                                radius: 8
                                color: Theme.alpha(Theme.text, 0.08)
                                border.width: 1
                                border.color: Theme.outline
                                Text {
                                    id: keyLbl
                                    anchors.centerIn: parent
                                    text: parent.parent.modelData[0]
                                    color: Theme.text
                                    font.family: Theme.monoFont
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }
                            }
                            Text {
                                x: 190
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 190
                                text: parent.modelData[1]
                                color: Theme.text
                                font.family: Theme.uiFont
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
