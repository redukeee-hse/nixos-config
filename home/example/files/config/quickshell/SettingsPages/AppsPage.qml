// Hub > Apps: the default application for each kind of file, after Ryoku's
// Default Apps page. The defaults live in mimeapps.list in the config (Home
// Manager keeps it read-only), so this page shows them and opens that file.
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: page

    readonly property var kinds: [
        { k: "Web browser", t: "x-scheme-handler/https" },
        { k: "Files", t: "inode/directory" },
        { k: "PDF", t: "application/pdf" },
        { k: "Images", t: "image/png" },
        { k: "Video", t: "video/mp4" },
        { k: "Audio", t: "audio/mpeg" },
        { k: "Text", t: "text/plain" },
        { k: "Archives", t: "application/zip" }
    ]
    property var names: ({})

    Process {
        running: true
        command: ["sh", "-c",
            "for t in \"$@\"; do d=$(xdg-mime query default \"$t\"); f=''; " +
            "for dir in ${XDG_DATA_HOME:-$HOME/.local/share} $(echo \"$XDG_DATA_DIRS\" | tr ':' ' '); do " +
            "[ -f \"$dir/applications/$d\" ] && f=\"$dir/applications/$d\" && break; done; " +
            "n=$( [ -n \"$f\" ] && grep -m1 '^Name=' \"$f\" | cut -d= -f2-); printf '%s\\t%s\\n' \"$t\" \"${n:-$d}\"; done",
            "sh"].concat(page.kinds.map(k => k.t))
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {}
                for (const l of text.trim().split("\n")) { const p = l.split("\t"); m[p[0]] = p[1] }
                page.names = m
            }
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.rightMargin: 20
        contentHeight: col.implicitHeight
        clip: true

        Column {
            id: col
            width: parent.width
            spacing: 2

            Text {
                text: "DEFAULT APPS"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.letterSpacing: 2
                bottomPadding: 8
            }

            Repeater {
                model: page.kinds
                Item {
                    required property var modelData
                    width: col.width
                    height: 44
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.modelData.k
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.names[parent.modelData.t] || "—"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.alpha(Theme.text, 0.06) }
                }
            }

            Rectangle {
                y: 10
                height: 34
                width: editLbl.implicitWidth + 28
                radius: Theme.radius
                color: editMa.containsMouse ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.text, 0.05)
                border.width: 1
                border.color: Theme.border
                Text {
                    id: editLbl
                    anchors.centerIn: parent
                    text: "Edit defaults in the config"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                MouseArea {
                    id: editMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["code", Quickshell.env("HOME") + "/nixos-config/home/example/files/config/mimeapps.list"])
                }
            }
        }
    }
}
