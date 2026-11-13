// Hub > Appearance: light/dark mode and the switches between the Ryoku-style
// parts and the previous ones (wallpaper transitions, notifications, lock).
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: page

    readonly property string cur: Quickshell.env("HOME") + "/.config/current/"
    readonly property string bin: Quickshell.env("HOME") + "/.local/share/custom/bin/"

    function readOr(file, fallback) { return (file.text() || "").trim() || fallback }

    FileView { id: modeFile; path: page.cur + "theme-mode"; watchChanges: true; onFileChanged: reload(); printErrors: false }
    FileView { id: transFile; path: page.cur + "wallpaper-transitions"; watchChanges: true; onFileChanged: reload(); printErrors: false }
    FileView { id: notifFile; path: page.cur + "notification-daemon"; watchChanges: true; onFileChanged: reload(); printErrors: false }
    FileView { id: dockFile; path: page.cur + "dock"; watchChanges: true; onFileChanged: reload(); printErrors: false }
    FileView { id: lockFile; path: page.cur + "lock-style"; watchChanges: true; onFileChanged: reload(); printErrors: false }

    function write(name, value) {
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && printf '%s\\n' \"$2\" > \"$1/$3\"", "sh", page.cur, value, name])
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
                text: "APPEARANCE"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.letterSpacing: 2
                bottomPadding: 8
            }

            HubRow {
                label: "Theme"
                hint: "Colours come from the wallpaper (pywal). Each mode keeps its own wallpapers. Super+Shift+Space"
                options: [{ value: "dark", text: "Dark" }, { value: "light", text: "Light" }]
                current: page.readOr(modeFile, "dark")
                onPicked: v => Quickshell.execDetached([page.bin + "theme-mode.sh", v])
            }
            HubRow {
                label: "Wallpaper transitions"
                hint: "Ryoku: grow, outer, wave, wipe or centre from the pointer, 2.2 s. Classic: a circle from the bottom."
                options: [{ value: "ryoku", text: "Ryoku" }, { value: "classic", text: "Classic" }]
                current: page.readOr(transFile, "ryoku")
                onPicked: v => page.write("wallpaper-transitions", v)
            }
            HubRow {
                label: "Notifications"
                hint: "Shell: cards, centre and OSD drawn by Quickshell. SwayNC: the rosa-style cards."
                options: [{ value: "shell", text: "Shell" }, { value: "swaync", text: "SwayNC" }]
                current: page.readOr(notifFile, "shell")
                onPicked: v => Quickshell.execDetached([page.bin + "notifications.sh", "use", v])
            }
            HubRow {
                label: "Lock screen"
                hint: "Orbit: like the login screen. Classic: the blurred wallpaper with a password field."
                options: [{ value: "orbit", text: "Orbit" }, { value: "classic", text: "Classic" }]
                current: page.readOr(lockFile, "orbit")
                onPicked: v => page.write("lock-style", v)
            }
            HubRow {
                label: "Dock"
                hint: "Pinned and running apps; touch the bottom edge to show it."
                options: [{ value: "on", text: "On" }, { value: "off", text: "Off" }]
                current: page.readOr(dockFile, "off")
                onPicked: v => page.write("dock", v)
            }
            HubRow {
                label: "Cursor motion"
                hint: "The cursor tilts as it moves; shake it to find it."
                property string cursorState: "on"
                options: [{ value: "on", text: "On" }, { value: "off", text: "Off" }]
                current: cursorState
                onPicked: v => {
                    cursorState = v
                    Quickshell.execDetached(["hyprctl", "keyword", "plugin:dynamic-cursors:enabled", v === "on" ? "true" : "false"])
                }
            }
        }
    }
}
