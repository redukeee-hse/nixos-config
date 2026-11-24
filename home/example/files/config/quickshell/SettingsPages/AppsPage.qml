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
        { k: "Web browser", t: "x-scheme-handler/https", i: "󰖟" },
        { k: "Files", t: "inode/directory", i: "󰉋" },
        { k: "PDF", t: "application/pdf", i: "󰈦" },
        { k: "Images", t: "image/png", i: "󰋩" },
        { k: "Video", t: "video/mp4", i: "󰕧" },
        { k: "Audio", t: "audio/mpeg", i: "󰝚" },
        { k: "Text", t: "text/plain", i: "󰈙" },
        { k: "Archives", t: "application/zip", i: "󰛫" }
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
        anchors.rightMargin: 12
        contentHeight: col.implicitHeight
        clip: true

        Column {
            id: col
            width: parent.width
            spacing: 8

            HubHeader { title: "Default apps"; subtitle: "What opens each kind of file." }

            Repeater {
                model: page.kinds
                HubItem {
                    required property var modelData
                    width: col.width
                    height: 56
                    icon: modelData.i
                    title: modelData.k
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.names[parent.parent.modelData.t] || "—"
                        color: Theme.accent
                        font.family: Theme.uiFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                }
            }

            HubButton {
                kind: "outline"
                icon: "󰏫"
                text: "Edit defaults in the config"
                onClicked: Quickshell.execDetached(["code", Quickshell.env("HOME") + "/nixos-config/home/example/files/config/mimeapps.list"])
            }
        }
    }
}
