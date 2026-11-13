// Background apps (Super+T): the system tray as a card in the Hub's style.
// Every tray app gets a row with its icon and name; a click opens the app,
// the arrow (or Right / Space) unfolds its menu right inside the card,
// with submenus one level deep. Keys: ↑/↓ choose, Enter open, →/Space menu,
// ← fold, Esc close. The previous eww tray stays in config/eww
// (tray-toggle.sh) and keeps running as a second tray host.
//
// IPC: qs ipc call tray toggle|open|close
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Scope {
    id: root

    property bool open: false
    property int selected: 0
    property int expanded: -1
    readonly property var items: SystemTray.items.values

    function toggle() { open ? close() : show() }
    function show() { selected = 0; expanded = -1; open = true }
    function close() { open = false }
    // A readable name: the app's desktop entry first (tray ids are often
    // reverse-DNS or internal names), then what the app reports.
    function name(item) {
        // Apps put their desktop id in either field (Sota: a random id, the
        // desktop id in title).
        for (const key of [item.id, item.title, item.tooltipTitle]) {
            if (!key) continue
            const e = DesktopEntries.byId(key) || DesktopEntries.heuristicLookup(key)
            if (e && e.name) return e.name
        }
        return item.tooltipTitle || item.title || item.id || "App"
    }
    function activate(item) {
        if (item.onlyMenu && item.hasMenu) {
            const i = items.indexOf(item)
            expanded = expanded === i ? -1 : i
            return
        }
        item.activate()
        close()
    }

    IpcHandler {
        target: "tray"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.close() }
    }

    PanelWindow {
        id: win
        visible: root.open || card.opacity > 0
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "tray-panel"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Clicking anywhere outside the card closes it.
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            id: card
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 44
            anchors.rightMargin: 10
            width: 380
            height: Math.min(parent.height - 80, column.implicitHeight + 32)
            radius: 16
            // Same look as the Hub: white in light mode, dark otherwise, 60%.
            color: Theme._bgBase.hslLightness > 0.5 ? Qt.rgba(1, 1, 1, 0.6) : Theme.alpha(Theme._bgBase, 0.6)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.45)
            opacity: root.open ? 1 : 0
            transform: Translate { y: root.open ? 0 : -10; Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 180 } }

            MouseArea { anchors.fill: parent }   // keep clicks inside

            focus: root.open
            Keys.onPressed: e => {
                const n = root.items.length
                if (e.key === Qt.Key_Escape) root.close()
                else if (e.key === Qt.Key_Down) root.selected = Math.min(n - 1, root.selected + 1)
                else if (e.key === Qt.Key_Up) root.selected = Math.max(0, root.selected - 1)
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (n) root.activate(root.items[root.selected]) }
                else if (e.key === Qt.Key_Right || e.key === Qt.Key_Space) { if (n && root.items[root.selected].hasMenu) root.expanded = root.selected }
                else if (e.key === Qt.Key_Left) root.expanded = -1
                else return
                e.accepted = true
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 16
                contentHeight: column.implicitHeight
                clip: true

                Column {
                    id: column
                    width: parent.width
                    spacing: 4

                    Row {
                        width: parent.width
                        bottomPadding: 8
                        Text {
                            text: "BACKGROUND APPS"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.letterSpacing: 2.5
                        }
                        Text {
                            text: "  ·  " + root.items.length
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        visible: root.items.length === 0
                        width: parent.width
                        topPadding: 12; bottomPadding: 12
                        horizontalAlignment: Text.AlignHCenter
                        text: "Nothing running in the background"
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }

                    Repeater {
                        model: root.items
                        Column {
                            id: entry
                            required property var modelData
                            required property int index
                            readonly property bool isSel: root.selected === index
                            readonly property bool isOpen: root.expanded === index
                            width: column.width
                            spacing: 2

                            Rectangle {
                                width: parent.width
                                height: 48
                                radius: Theme.radius
                                color: entry.isSel || rowMouse.containsMouse ? Theme.alpha(Theme.accent, 0.14) : "transparent"
                                border.width: entry.isSel ? 1 : 0
                                border.color: Theme.alpha(Theme.accent, 0.6)
                                Behavior on color { ColorAnimation { duration: 120 } }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    onEntered: root.selected = entry.index
                                    onClicked: m => {
                                        if (m.button === Qt.RightButton) root.expanded = entry.isOpen ? -1 : entry.index
                                        else if (m.button === Qt.MiddleButton) entry.modelData.secondaryActivate()
                                        else root.activate(entry.modelData)
                                    }
                                }

                                IconImage {
                                    id: icon
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 28
                                    source: entry.modelData.icon
                                }
                                Column {
                                    anchors.left: icon.right
                                    anchors.leftMargin: 12
                                    anchors.right: menuBtn.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Text {
                                        width: parent.width
                                        // Re-evaluated once the desktop entries finish loading.
                                        text: DesktopEntries.applications.values.length >= 0 ? root.name(entry.modelData) : ""
                                        color: Theme.text
                                        font.family: "Inter"
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        visible: text !== ""
                                        text: (entry.modelData.tooltipDescription || "").replace(/<[^>]*>/g, "").split("\n")[0]
                                        color: Theme.textDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }
                                Rectangle {
                                    id: menuBtn
                                    visible: entry.modelData.hasMenu
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 30; height: 30; radius: 8
                                    color: menuMouse.containsMouse ? Theme.alpha(Theme.text, 0.1) : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        rotation: entry.isOpen ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 180 } }
                                        color: Theme.textDim
                                        font.family: "JetBrainsMono Nerd Font Mono"
                                        font.pixelSize: 16
                                    }
                                    MouseArea {
                                        id: menuMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.expanded = entry.isOpen ? -1 : entry.index
                                    }
                                }
                            }

                            // The app's menu, unfolded inside the card.
                            Loader {
                                width: parent.width
                                // Explicit: a Loader keeps its last height after
                                // its item is gone, which left a gap on fold.
                                height: active && item ? item.implicitHeight : 0
                                active: entry.isOpen && entry.modelData.hasMenu
                                sourceComponent: MenuList { handle: entry.modelData.menu; depth: 0 }
                            }
                        }
                    }
                }
            }
        }
    }

    component MenuList: Column {
        id: list
        property var handle: null
        property int depth: 0
        spacing: 1
        leftPadding: 46 + depth * 14
        bottomPadding: 6

        QsMenuOpener { id: opener; menu: list.handle }

        Repeater {
            model: opener.children
            Column {
                id: mitem
                required property var modelData
                property bool sub: false
                width: list.width - list.leftPadding - 8

                Rectangle {
                    visible: mitem.modelData.isSeparator
                    width: parent.width; height: 9
                    color: "transparent"
                    Rectangle { anchors.centerIn: parent; width: parent.width; height: 1; color: Theme.alpha(Theme.text, 0.12) }
                }
                Rectangle {
                    visible: !mitem.modelData.isSeparator
                    width: parent.width
                    height: 32
                    radius: 8
                    opacity: mitem.modelData.enabled ? 1 : 0.4
                    color: itemMouse.containsMouse ? Theme.alpha(Theme.accent, 0.16) : "transparent"
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Text {
                            visible: mitem.modelData.buttonType !== QsMenuButtonType.None
                            anchors.verticalCenter: parent.verticalCenter
                            text: mitem.modelData.checkState === Qt.Checked ? "󰄲" : "󰄱"
                            color: Theme.accent
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 14
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: mitem.modelData.text.replace(/_/g, "")
                            color: Theme.text
                            font.family: "Inter"; font.pixelSize: 12
                        }
                    }
                    Text {
                        visible: mitem.modelData.hasChildren
                        anchors.right: parent.right; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: mitem.sub ? "󰅃" : "󰅂"
                        color: Theme.textDim
                        font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 14
                    }
                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: mitem.modelData.enabled
                        onClicked: {
                            if (mitem.modelData.hasChildren) { mitem.sub = !mitem.sub; return }
                            mitem.modelData.triggered()
                            root.close()
                        }
                    }
                }
                Loader {
                    width: parent.width
                    height: active && item ? item.implicitHeight : 0
                    active: mitem.sub && mitem.modelData.hasChildren
                    sourceComponent: SubMenuList { handle: mitem.modelData; depth: list.depth + 1 }
                }
            }
        }
    }

    component SubMenuList: Column {
        id: list
        property var handle: null
        property int depth: 0
        spacing: 1
        leftPadding: 46 + depth * 14
        bottomPadding: 6

        QsMenuOpener { id: opener; menu: list.handle }

        Repeater {
            model: opener.children
            Column {
                id: mitem
                required property var modelData
                property bool sub: false
                width: list.width - list.leftPadding - 8

                Rectangle {
                    visible: mitem.modelData.isSeparator
                    width: parent.width; height: 9
                    color: "transparent"
                    Rectangle { anchors.centerIn: parent; width: parent.width; height: 1; color: Theme.alpha(Theme.text, 0.12) }
                }
                Rectangle {
                    visible: !mitem.modelData.isSeparator
                    width: parent.width
                    height: 32
                    radius: 8
                    opacity: mitem.modelData.enabled ? 1 : 0.4
                    color: itemMouse.containsMouse ? Theme.alpha(Theme.accent, 0.16) : "transparent"
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Text {
                            visible: mitem.modelData.buttonType !== QsMenuButtonType.None
                            anchors.verticalCenter: parent.verticalCenter
                            text: mitem.modelData.checkState === Qt.Checked ? "󰄲" : "󰄱"
                            color: Theme.accent
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 14
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: mitem.modelData.text.replace(/_/g, "")
                            color: Theme.text
                            font.family: "Inter"; font.pixelSize: 12
                        }
                    }
                    Text {
                        visible: mitem.modelData.hasChildren
                        anchors.right: parent.right; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: mitem.sub ? "󰅃" : "󰅂"
                        color: Theme.textDim
                        font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 14
                    }
                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: mitem.modelData.enabled
                        onClicked: {
                            if (mitem.modelData.hasChildren) { mitem.sub = !mitem.sub; return }
                            mitem.modelData.triggered()
                            root.close()
                        }
                    }
                }
            }
        }
    }
}
