// Notifications in the shell, after Ryoku (its notification server lives in
// the shell and groups by app) and drawn in the Orbit style: dark cards with
// a mono app line, a serif-free bold title, actions and a gold countdown;
// a notification centre grouped by app (Super+N) with Do Not Disturb; and
// the volume/brightness/microphone indicators as a pill at the bottom.
//
// Runs only when ~/.config/current/notification-daemon says "shell" (the
// default). With "swaync" it stays out of the way and SwayNC (rosa.css)
// takes over: `notifications.sh use swaync|shell` switches.
//
// IPC: qs ipc call notifications toggle|open|close|dnd|clear|status
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property string mode: "shell"
    property bool modeKnown: false
    readonly property bool active: modeKnown && mode !== "swaync"

    property bool dnd: false
    // Critical cards stay red whatever the wallpaper palette's "red" slot is.
    readonly property color alarm: "#ff6b5e"
    property bool centerOpen: false
    property var popupIds: []
    readonly property var tracked: srvLoader.item ? srvLoader.item.trackedNotifications.values : []
    readonly property int count: tracked.length

    FileView {
        path: root.home + "/.config/current/notification-daemon"
        printErrors: false
        onLoaded: { root.mode = text().trim() || "shell"; root.modeKnown = true }
        onLoadFailed: { root.mode = "shell"; root.modeKnown = true }
    }
    FileView {
        id: dndFile
        path: root.home + "/.config/current/notifications-dnd"
        printErrors: false
        onLoaded: root.dnd = text().trim() === "on"
    }
    // Waybar's notification module tails this file (notifications.sh status).
    FileView { id: statusFile; path: root.home + "/.cache/notifications-status.json"; printErrors: false }
    function writeStatus() {
        if (!active) return
        const alt = (dnd ? "dnd-" : "") + (count > 0 ? "notification" : "none")
        statusFile.setText(JSON.stringify({ text: "", alt: alt, class: alt, tooltip: count + " notifications" }) + "\n")
    }
    onCountChanged: writeStatus()
    onDndChanged: { writeStatus(); dndFile.setText(dnd ? "on\n" : "off\n") }
    onActiveChanged: writeStatus()

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.centerOpen = !root.centerOpen }
        function open(): void { root.centerOpen = true }
        function close(): void { root.centerOpen = false }
        function dnd(): void { root.dnd = !root.dnd }
        function clear(): void { root.clearAll() }
        function status(): string {
            return (root.dnd ? "dnd-" : "") + (root.count > 0 ? "notification" : "none")
        }
    }

    function clearAll() {
        for (const n of tracked.slice()) n.dismiss()
        popupIds = []
    }
    onTrackedChanged: {
        const liveIds = new Set(tracked.filter(n => n).map(n => n.id))
        const kept = popupIds.filter(id => liveIds.has(id))
        if (kept.length !== popupIds.length) popupIds = kept
    }
    function dropPopup(id) {
        if (popupIds.includes(id)) popupIds = popupIds.filter(value => value !== id)
    }
    function iconFor(n) {
        if (!n) return ""
        if (n.image) return n.image
        const i = n.appIcon || n.desktopEntry || ""
        if (i.startsWith("/") || i.startsWith("file:")) return i
        return i ? Quickshell.iconPath(i, true) : ""
    }

    function list(l) {
        const a = []
        if (l) for (let i = 0; i < l.length; i++) a.push(l[i])
        return a
    }

    LazyLoader {
        id: srvLoader
        active: root.active
        NotificationServer {
            keepOnReload: false
            actionsSupported: true
            bodyMarkupSupported: true
            bodyHyperlinksSupported: true
            imageSupported: true
            persistenceSupported: true
            onNotification: n => {
                if (n.appName === "osd") {
                    osd.show(n.summary, n.hints.value !== undefined ? Number(n.hints.value) : -1)
                    n.expire()
                    return
                }
                n.tracked = true
                if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                    root.popupIds = [n.id].concat(root.popupIds.filter(id => id !== n.id)).slice(0, 5)
            }
        }
    }

    // ---------- A single card, used by popups and the centre ----------
    component Card: Rectangle {
        id: card
        required property var notif
        property bool popup: false
        property int popupId: -1
        readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
        readonly property int timeout: critical ? 0 : (notif && notif.expireTimeout > 0 ? notif.expireTimeout : 6000)
        property real remaining: 1

        width: 384
        implicitHeight: body.implicitHeight + 28
        radius: 14
        color: critical ? Theme.alpha(Theme.mix(Theme._bgBase, root.alarm, 0.25), 0.94) : Theme.alpha(Theme._bgBase, 0.88)
        border.width: 1
        border.color: critical ? root.alarm : (hover.hovered ? Theme.borderAccent : Theme.alpha(Theme.accent, 0.28))
        clip: true

        HoverHandler { id: hover }
        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: {
                const def = root.list(card.notif?.actions).find(a => a && a.identifier === "default")
                if (def) def.invoke()
                if (card.popup) root.dropPopup(card.popupId)
            }
        }
        TapHandler {
            acceptedButtons: Qt.MiddleButton | Qt.RightButton
            onTapped: card.notif?.dismiss()
        }

        // Soft wash of the accent from the left edge, as in rosa/Orbit.
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.alpha(card.critical ? root.alarm : Theme.accent, 0.16) }
                GradientStop { position: 0.55; color: "transparent" }
            }
        }

        Column {
            id: body
            x: 14; y: 14
            width: parent.width - 28
            spacing: 6

            Row {
                width: parent.width
                spacing: 10
                Rectangle {
                    width: 36; height: 36; radius: 9
                    color: Theme.alpha(card.critical ? root.alarm : Theme.accent, 0.18)
                    Image {
                        anchors.centerIn: parent
                        width: card.notif?.image ? 36 : 22; height: width
                        source: root.iconFor(card.notif)
                        sourceSize: Qt.size(72, 72)
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                        layer.enabled: !!card.notif?.image
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: root.iconFor(card.notif) === ""
                        text: (card.notif?.appName || "?").charAt(0).toUpperCase()
                        color: Theme.text
                        font.family: "Inter"; font.pixelSize: 15; font.weight: Font.DemiBold
                    }
                }
                Column {
                    width: parent.width - 46
                    spacing: 3
                    Row {
                        width: parent.width
                        Text {
                            width: parent.width - stamp.width
                            text: (card.notif?.appName || "").toUpperCase()
                            color: card.critical ? root.alarm : Theme.accent
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10; font.letterSpacing: 1.6
                            elide: Text.ElideRight
                        }
                        Text {
                            id: stamp
                            text: Qt.formatTime(new Date(), "HH:mm")
                            color: Theme.textFaint
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10
                        }
                    }
                    Text {
                        width: parent.width
                        text: card.notif?.summary ?? ""
                        color: Theme.text
                        font.family: "Inter"; font.pixelSize: 14; font.weight: Font.DemiBold
                        wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: card.notif?.body ?? ""
                        textFormat: Text.StyledText
                        color: Theme.textDim
                        font.family: "Inter"; font.pixelSize: 12
                        wrapMode: Text.Wrap; maximumLineCount: card.popup ? 4 : 8; elide: Text.ElideRight
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
            }
            Flow {
                width: parent.width
                spacing: 6
                visible: actionsRep.count > 0
                Repeater {
                    id: actionsRep
                    model: root.list(card.notif?.actions).filter(a => a && a.identifier !== "default")
                    Rectangle {
                        required property var modelData
                        height: 26; width: lbl.implicitWidth + 22; radius: 8
                        color: actMouse.containsMouse ? Theme.alpha(Theme.accent, 0.3) : Theme.alpha(Theme.text, 0.07)
                        Text {
                            id: lbl
                            anchors.centerIn: parent
                            text: parent.modelData?.text ?? ""
                            color: Theme.text
                            font.family: "Inter"; font.pixelSize: 12
                        }
                        MouseArea {
                            id: actMouse
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: { parent.modelData?.invoke(); if (card.popup) root.dropPopup(card.popupId) }
                        }
                    }
                }
            }
        }

        // Close button.
        Text {
            anchors.right: parent.right; anchors.top: parent.top
            anchors.margins: 8
            visible: hover.hovered
            text: "󰅖"
            color: Theme.textDim
            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13
            MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: card.notif?.dismiss() }
        }

        // Countdown line along the bottom (popups only; pauses on hover).
        Rectangle {
            visible: card.popup && card.timeout > 0
            anchors.bottom: parent.bottom; anchors.left: parent.left
            anchors.leftMargin: 14; anchors.bottomMargin: 6
            width: (parent.width - 28) * card.remaining
            height: 2; radius: 1
            color: Theme.accent
        }
        NumberAnimation on remaining {
            running: card.popup && card.timeout > 0
            paused: hover.hovered
            from: 1; to: 0
            duration: card.timeout
            onFinished: Qt.callLater(root.dropPopup, card.popupId)
        }
    }

    // ---------- Popups, top right ----------
    Variants {
        model: root.active ? Quickshell.screens : []
        PanelWindow {
            id: popWin
            required property var modelData
            screen: modelData
            visible: root.popupIds.length > 0 && !root.centerOpen
            anchors { top: true; right: true }
            margins { top: 8; right: 10 }
            implicitWidth: 400
            implicitHeight: popCol.implicitHeight + 8
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell-notifications"
            Column {
                id: popCol
                x: 8; spacing: 10
                Repeater {
                    model: root.popupIds
                    Card {
                        id: popCard
                        required property var modelData
                        popupId: modelData
                        notif: root.tracked.find(n => n && n.id === popupId) ?? null
                        popup: true
                        // Slide in from the right edge.
                        transform: Translate { id: slide; x: 60 }
                        opacity: 0
                        Component.onCompleted: enter.start()
                        ParallelAnimation {
                            id: enter
                            NumberAnimation { target: slide; property: "x"; to: 0; duration: 460; easing.type: Easing.OutExpo }
                            NumberAnimation { target: popCard; property: "opacity"; to: 1; duration: 260 }
                        }
                    }
                }
            }
        }
    }

    // ---------- Notification centre (Super+N) ----------
    Variants {
        model: root.active ? Quickshell.screens : []
        PanelWindow {
            id: center
            required property var modelData
            screen: modelData
            visible: root.centerOpen || panel.x < width
            anchors { top: true; bottom: true; right: true }
            margins { top: 8; bottom: 10; right: 10 }
            implicitWidth: 420
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "shell-notification-center"
            WlrLayershell.keyboardFocus: root.centerOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            readonly property var groups: {
                const g = {}
                for (const n of root.tracked) (g[n.appName || "Other"] = g[n.appName || "Other"] || []).push(n)
                return Object.keys(g).map(k => ({ app: k, items: g[k].slice().reverse() }))
            }

            Rectangle {
                id: panel
                width: parent.width; height: parent.height
                x: root.centerOpen ? 0 : width + 20
                Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.OutExpo } }
                radius: 16
                color: Theme.alpha(Theme._bgBase, 0.9)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.3)
                focus: root.centerOpen
                Keys.onEscapePressed: root.centerOpen = false

                Column {
                    id: head
                    x: 18; y: 18
                    width: parent.width - 36
                    spacing: 14
                    Item {
                        width: parent.width; height: 28
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "NOTIFICATIONS"
                            color: Theme.text
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 12; font.letterSpacing: 3
                        }
                        Row {
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            Rectangle {
                                height: 26; width: dndLbl.implicitWidth + 22; radius: 13
                                color: root.dnd ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.text, 0.07)
                                Text { id: dndLbl; anchors.centerIn: parent; text: root.dnd ? "󰂛  DND" : "󰂚  DND"; color: Theme.text; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 11 }
                                MouseArea { anchors.fill: parent; onClicked: root.dnd = !root.dnd }
                            }
                            Rectangle {
                                height: 26; width: clrLbl.implicitWidth + 22; radius: 13
                                color: Theme.alpha(Theme.text, 0.07)
                                Text { id: clrLbl; anchors.centerIn: parent; text: "CLEAR"; color: Theme.text; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 11; font.letterSpacing: 1.5 }
                                MouseArea { anchors.fill: parent; onClicked: root.clearAll() }
                            }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.text, 0.1) }
                }

                Flickable {
                    anchors { top: head.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; topMargin: 12; bottomMargin: 12 }
                    contentHeight: groupsCol.implicitHeight
                    clip: true
                    Column {
                        id: groupsCol
                        x: 18
                        spacing: 16
                        Text {
                            visible: root.count === 0
                            width: 384; topPadding: 60
                            horizontalAlignment: Text.AlignHCenter
                            text: "<i>All quiet out here.</i>"
                            color: Theme.textFaint
                            font.family: "EB Garamond"; font.pixelSize: 22
                        }
                        Repeater {
                            model: center.groups
                            Column {
                                id: grp
                                required property var modelData
                                property bool expanded: modelData.items.length <= 2
                                spacing: 8
                                Item {
                                    width: 384; height: 18
                                    Text {
                                        text: grp.modelData.app.toUpperCase() + "  ·  " + grp.modelData.items.length
                                        color: Theme.textDim
                                        font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10; font.letterSpacing: 1.8
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        visible: grp.modelData.items.length > 2
                                        text: grp.expanded ? "LESS" : "ALL"
                                        color: Theme.accent
                                        font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10; font.letterSpacing: 1.5
                                        MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: grp.expanded = !grp.expanded }
                                    }
                                }
                                Repeater {
                                    model: grp.expanded ? grp.modelData.items : grp.modelData.items.slice(0, 1)
                                    Card { required property var modelData; notif: modelData }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- OSD pill (volume, brightness, microphone) ----------
    QtObject {
        id: osd
        property string label: ""
        property real value: -1
        property bool shown: false
        function show(text, v) {
            label = text
            value = v
            shown = true
            hideTimer.restart()
        }
    }
    Timer { id: hideTimer; interval: 1400; onTriggered: osd.shown = false }

    Variants {
        model: root.active ? Quickshell.screens : []
        PanelWindow {
            id: osdWin
            required property var modelData
            screen: modelData
            visible: osd.shown || pill.opacity > 0
            anchors { bottom: true }
            margins { bottom: 72 }
            implicitWidth: 320
            implicitHeight: 56
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell-osd"
            mask: Region {}

            readonly property string icon: {
                const l = osd.label.toLowerCase()
                if (l.indexOf("microphone") >= 0) return l.indexOf("unmuted") >= 0 ? "󰍬" : "󰍭"
                if (l.indexOf("bright") >= 0) return "󰃠"
                if (osd.value === 0 || l.indexOf("🔇") >= 0) return "󰖁"
                return osd.value < 34 ? "󰕿" : osd.value < 67 ? "󰖀" : "󰕾"
            }

            Rectangle {
                id: pill
                anchors.fill: parent
                radius: height / 2
                color: Theme.alpha(Theme._bgBase, 0.9)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.35)
                opacity: osd.shown ? 1 : 0
                scale: osd.shown ? 1 : 0.92
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }

                Row {
                    anchors.centerIn: parent
                    spacing: 14
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: osdWin.icon
                        color: Theme.accent
                        font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 20
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: osd.value >= 0
                        width: 190; height: 6; radius: 3
                        color: Theme.alpha(Theme.text, 0.12)
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, osd.value / 100))
                            height: parent.height; radius: 3
                            color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: osd.value >= 0 ? Math.round(osd.value) : osd.label
                        color: Theme.text
                        width: osd.value >= 0 ? 30 : implicitWidth
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13
                    }
                }
            }
        }
    }
}
