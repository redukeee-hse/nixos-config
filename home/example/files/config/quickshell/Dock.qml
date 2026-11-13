// Dock, after Ryoku's: pinned apps and running windows at the bottom edge.
// It hides itself and slides up when the pointer touches the bottom edge.
// On with ~/.config/current/dock = on (Hub > Appearance); pinned apps are
// desktop ids, one per line, in ~/.config/current/dock-pinned.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool enabled: false
    property var pinned: ["zen-beta", "org.telegram.desktop", "kitty", "code", "org.gnome.Nautilus", "spotify"]

    FileView {
        path: Quickshell.env("HOME") + "/.config/current/dock"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.enabled = text().trim() === "on"
    }
    FileView {
        path: Quickshell.env("HOME") + "/.config/current/dock-pinned"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const ids = text().split("\n").map(s => s.trim()).filter(s => s)
            if (ids.length) root.pinned = ids
        }
    }

    function entry(id) {
        return DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id)
    }
    // Pinned apps first, then any other running app class.
    readonly property var items: {
        const out = pinned.map(id => ({ id: id, entry: entry(id) })).filter(i => i.entry)
        const seen = new Set(out.map(i => i.entry.id))
        for (const t of Hyprland.toplevels.values) {
            const cls = t.lastIpcObject ? t.lastIpcObject.class : ""
            const e = cls ? entry(cls) : null
            if (e && !seen.has(e.id)) { seen.add(e.id); out.push({ id: e.id, entry: e }) }
        }
        return out
    }
    function running(e) {
        for (const t of Hyprland.toplevels.values) {
            const cls = t.lastIpcObject ? (t.lastIpcObject.class || "").toLowerCase() : ""
            if (cls && (cls === e.id.toLowerCase() || (e.startupClass || "").toLowerCase() === cls || e.id.toLowerCase().indexOf(cls) >= 0)) return t
        }
        return null
    }

    Variants {
        model: root.enabled ? Quickshell.screens : []
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            property bool shown: hot.hovered || dockHover.hovered
            anchors { bottom: true; left: true; right: true }
            implicitHeight: 96
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "shell-dock"
            mask: Region { item: win.shown ? dock : hotZone }

            Item {
                id: hotZone
                anchors.bottom: parent.bottom
                width: parent.width; height: 3
                HoverHandler { id: hot }
            }

            Rectangle {
                id: dock
                anchors.horizontalCenter: parent.horizontalCenter
                y: win.shown ? parent.height - height - 10 : parent.height + 4
                Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutExpo } }
                width: apps.width + 24
                height: 68
                radius: 20
                color: Theme.alpha(Theme._bgBase, 0.82)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.3)
                HoverHandler { id: dockHover }

                Row {
                    id: apps
                    anchors.centerIn: parent
                    spacing: 8
                    Repeater {
                        model: root.items
                        Item {
                            id: slot
                            required property var modelData
                            readonly property var win: root.running(modelData.entry)
                            width: 52; height: 60
                            scale: ma.containsMouse ? 1.18 : 1
                            transformOrigin: Item.Bottom
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 4
                                width: 44; height: 44
                                source: Quickshell.iconPath(slot.modelData.entry.icon, "application-x-executable")
                                sourceSize: Qt.size(88, 88)
                            }
                            Rectangle {
                                visible: slot.win !== null
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                width: 6; height: 6; radius: 3
                                color: Theme.accent
                            }
                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (slot.win) Hyprland.dispatch("focuswindow address:0x" + slot.win.address)
                                    else slot.modelData.entry.execute()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
