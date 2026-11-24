import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import "../"

Item {
    id: page

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter ? adapter.enabled : false
    readonly property bool scanning: adapter ? adapter.discovering : false
    property string statusText: ""
    property real marginLeft: 0
    property real marginRight: 12
    property real marginTop: 0
    property real marginBottom: 0

    // key -> timestamp (ms) the device was hidden after "unpair".
    // Entries are pruned automatically (see pruneRemovingDevices) so a
    // device reappears once it's actually gone or after a grace period,
    // instead of staying hidden forever.
    property var removingDevices: ({})
    property int removalHideDurationMs: 10000

    // Address of the device to connect once its pairing completes.
    property string pendingConnect: ""

    // Connected devices first, the rest in adapter order. Reading
    // d.state here makes the list re-sort as soon as a device connects.
    readonly property var sortedDevices: {
        if (!page.adapter || !page.powered) return []
        var src = page.adapter.devices.values
        var out = []
        for (var i = 0; i < src.length; i++)
            out.push({ dev: src[i], i: i, on: src[i].state === BluetoothDeviceState.Connected })
        out.sort(function(a, b) {
            if (a.on !== b.on) return a.on ? -1 : 1
            return a.i - b.i
        })
        return out.map(function(e) { return e.dev })
    }

    FileView {
        id: removedDevicesFile
        path: Quickshell.dataDir + "/removed-bluetooth-devices.json"
        blockLoading: true
        onLoaded: page.loadRemovingDevices()
    }

    function loadRemovingDevices() {
        var text = removedDevicesFile.text()
        if (!text) return
        try {
            var saved = JSON.parse(text)
            if (saved && typeof saved === "object")
                page.removingDevices = saved
        } catch (error) {
            console.log("Failed to load removed Bluetooth devices:", error)
        }
        // Drop anything stale/no-longer-present left over from a previous session.
        page.pruneRemovingDevices()
    }

    function saveRemovingDevices() {
        removedDevicesFile.setText(JSON.stringify(page.removingDevices))
    }

    // Clears removingDevices entries once the device is no longer known to
    // the adapter (forget actually completed) or after removalHideDurationMs
    // has elapsed, whichever comes first. This is what lets a device that
    // was unpaired show up again the next time it's discovered by a scan.
    function pruneRemovingDevices() {
        var now = Date.now()
        var present = ({})

        if (page.adapter) {
            var devs = page.adapter.devices
            for (var i = 0; i < devs.length; i++) {
                var d = devs[i]
                var key = d.address || d.name || ""
                if (key) present[key] = true
            }
        }

        var updated = {}
        var changed = false

        for (var k in page.removingDevices) {
            var ts = page.removingDevices[k]
            var stillPresent = !!present[k]
            var expired = (now - ts) > page.removalHideDurationMs

            if (stillPresent && !expired) {
                updated[k] = ts
            } else {
                changed = true
            }
        }

        if (changed) {
            page.removingDevices = updated
            page.saveRemovingDevices()
        }
    }

    function setStatus(text) {
        page.statusText = text
        statusTimer.restart()
    }

    Timer {
        id: statusTimer
        interval: 3000
        onTriggered: page.statusText = ""
    }

    function setDiscovering(on) {
        if (!page.adapter || !page.powered)
            return
        page.adapter.discovering = on
    }

    function togglePower() {
        if (!page.adapter)
            return

        var on = !page.adapter.enabled
        if (!on)
            setDiscovering(false)

        page.adapter.enabled = on
    }

    function deviceAction(dev) {
        if (!dev) return

        var name = dev.name || dev.address || "device"

        if (dev.state === BluetoothDeviceState.Connected) {
            setStatus("Disconnecting " + name + "…")
            dev.disconnect()
            return
        }

        if (dev.state === BluetoothDeviceState.Connecting) {
            setStatus("Connecting to " + name + "…")
            return
        }

        if (dev.state === BluetoothDeviceState.Disconnecting) {
            setStatus("Disconnecting " + name + "…")
            return
        }

        if (dev.pairing) {
            setStatus("Pairing with " + name + "…")
            return
        }

        setDiscovering(false)
        dev.trusted = true

        // A bare connect() on an unknown device leaves it trusted but
        // unbonded, and headsets refuse the profiles. Bond first; the
        // card's onPairedChanged connects once BlueZ stores the key.
        if (!dev.bonded) {
            page.adapter.pairable = true
            page.pendingConnect = dev.address || name
            setStatus("Pairing with " + name + "…")
            dev.pair()
            return
        }

        setStatus("Connecting to " + name + "…")
        dev.connect()
    }

    function removeDevice(dev) {
        if (!dev) return

        var name = dev.name || dev.address || "device"
        var key = dev.address || name
        var updated = Object.assign({}, page.removingDevices)

        updated[key] = Date.now()
        page.removingDevices = updated
        saveRemovingDevices()

        if (dev.state === BluetoothDeviceState.Connected ||
            dev.state === BluetoothDeviceState.Connecting ||
            dev.state === BluetoothDeviceState.Disconnecting) {
            dev.disconnect()
        }

        dev.forget()
    }

    function actionLabel(dev) {
        if (!dev) return ""
        if (dev.pairing) return "Pairing"

        switch (dev.state) {
        case BluetoothDeviceState.Connected:
            return "Disconnect"
        case BluetoothDeviceState.Connecting:
            return "Connecting"
        case BluetoothDeviceState.Disconnecting:
            return "Disconnecting"
        default:
            return "Connect"
        }
    }

    readonly property int connectedCount: sortedDevices.filter(d => d.state === BluetoothDeviceState.Connected).length

    // Icon from the BlueZ device class ("audio-headset", "input-mouse", …).
    function deviceIcon(dev) {
        const i = (dev && dev.icon) || ""
        if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0) return "󰋋"
        if (i.indexOf("audio") >= 0) return "󰓃"
        if (i.indexOf("mouse") >= 0) return "󰍽"
        if (i.indexOf("keyboard") >= 0) return "󰌌"
        if (i.indexOf("phone") >= 0) return "󰄜"
        if (i.indexOf("computer") >= 0) return "󰌢"
        if (i.indexOf("video") >= 0 || i.indexOf("tv") >= 0) return "󰔂"
        if (i.indexOf("gaming") >= 0) return "󰊴"
        return "󰂯"
    }

    onVisibleChanged: setDiscovering(page.visible && page.powered)
    onPoweredChanged: setDiscovering(page.visible && page.powered)
    Component.onCompleted: if (page.visible && page.powered) setDiscovering(true)
    Component.onDestruction: setDiscovering(false)

    // Reacts directly to adapter signals rather than only to the derived
    // "powered" property, and prunes the unpair-hide list whenever the
    // device list changes (e.g. once a forgotten device is actually gone).
    Connections {
        target: page.adapter
        function onEnabledChanged() {
            page.setDiscovering(page.visible && page.powered)
        }
        function onDevicesChanged() {
            page.pruneRemovingDevices()
        }
    }

    // Safety net: if the very first StartDiscovery call was sent before
    // BlueZ finished powering the adapter on, "discovering" can silently
    // stay false. Keep nudging it back on until it actually takes, instead
    // of requiring the user to leave and reopen the page.
    Timer {
        id: discoveryRetryTimer
        interval: 1500
        repeat: true
        running: page.visible && page.powered
        onTriggered: {
            if (page.adapter && page.powered && !page.adapter.discovering)
                page.adapter.discovering = true
        }
    }

    // Periodic safety net for the unpair-hide list, independent of
    // devicesChanged firing (covers adapters/backends that don't emit it
    // promptly after forget()).
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: page.pruneRemovingDevices()
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: page.marginLeft; anchors.rightMargin: page.marginRight
        anchors.topMargin: page.marginTop; anchors.bottomMargin: page.marginBottom
        spacing: 12

        HubHeader {
            title: "Bluetooth"
            subtitle: page.statusText !== "" ? page.statusText
                : page.scanning ? "Looking for devices nearby…" : ""
        }

        HubSwitchRow {
            icon: page.powered ? "󰂯" : "󰂲"
            title: "Bluetooth"
            subtitle: !page.adapter ? "No adapter found"
                : page.powered ? (page.connectedCount > 0 ? page.connectedCount + " connected" : "On") : "Off"
            checked: page.powered
            enabled: !!page.adapter
            onToggled: page.togglePower()
        }

        HubLabel {
            visible: page.powered
            text: "Devices"
        }

        Flickable {
            id: flick
            width: parent.width
            height: parent.height - y
            clip: true
            contentWidth: width
            contentHeight: list.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: flick.width
                spacing: 8

                Text {
                    width: list.width
                    visible: page.adapter && !page.powered
                    topPadding: 30
                    horizontalAlignment: Text.AlignHCenter
                    text: "Turn Bluetooth on to see devices."
                    color: Theme.textDim
                    font.family: Theme.uiFont
                    font.pixelSize: 13
                }

                Text {
                    width: list.width
                    visible: page.powered && repeater.count === 0
                    topPadding: 30
                    horizontalAlignment: Text.AlignHCenter
                    text: "Scanning… keep this open while devices appear."
                    color: Theme.textDim
                    font.family: Theme.uiFont
                    font.pixelSize: 13
                }

                Repeater {
                    id: repeater
                    // Empty while the adapter is off, so no device cards render
                    // even for devices that remain paired/known while BT is off.
                    model: page.sortedDevices

                    delegate: HubItem {
                        id: card

                        required property BluetoothDevice modelData

                        readonly property bool isConnected:
                            modelData.state === BluetoothDeviceState.Connected
                        readonly property bool isBusy: modelData.pairing
                            || modelData.state === BluetoothDeviceState.Connecting
                            || modelData.state === BluetoothDeviceState.Disconnecting

                        readonly property string deviceKey:
                            modelData.address || modelData.name || ""

                        Connections {
                            target: card.modelData
                            function onPairedChanged() {
                                if (!card.modelData.paired || page.pendingConnect !== card.deviceKey)
                                    return
                                page.pendingConnect = ""
                                page.setStatus("Connecting to " + (card.modelData.name || card.deviceKey) + "…")
                                card.modelData.connect()
                            }
                        }

                        visible: !page.removingDevices[deviceKey]
                        width: list.width
                        height: visible ? 60 : 0
                        active: isConnected
                        icon: page.deviceIcon(modelData)
                        title: modelData.name || modelData.address
                        subtitle: {
                            var parts = []
                            if (card.isConnected) parts.push("Connected")
                            else if (card.modelData.paired) parts.push("Paired")
                            else parts.push(card.modelData.address)
                            if (card.modelData.batteryAvailable)
                                parts.push("󰥉 " + Math.round(card.modelData.battery * 100) + "%")
                            return parts.join("  ·  ")
                        }

                        HubButton {
                            visible: card.modelData.paired || card.modelData.bonded
                            kind: "ghost"
                            icon: "󰆴"
                            tooltip: "Forget"
                            onClicked: page.removeDevice(card.modelData)
                        }
                        HubButton {
                            kind: card.isConnected ? "danger" : "filled"
                            busy: card.isBusy
                            text: page.actionLabel(card.modelData)
                            onClicked: page.deviceAction(card.modelData)
                        }
                    }
                }
            }
        }
    }
}
