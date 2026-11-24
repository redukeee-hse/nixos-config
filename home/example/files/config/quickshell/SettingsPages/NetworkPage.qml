import QtQuick
import Quickshell.Io
import "../"

Item {
    id: page

    // ── State ────────────────────────────────────────────────────
    property bool wifiEnabled: true
    property var networks: []
    property string pendingSsid: ""

    // Ethernet status (device, connection state, active connection name)
    property var ethernet: ({
        device: "",
        state: "disconnected",
        connection: ""
    })

    // Fonts
    property string monoFont: "JetBrainsMono Nerd Font"

    // Speed stats (bytes / second)
    property real downSpeed: 0
    property real upSpeed: 0
    property real lastRx: -1
    property real lastTx: -1
    property real lastTs: 0

    property real marginLeft: 0
    property real marginRight: 12
    property real marginTop: 0
    property real marginBottom: 0

    // Nerd Font glyphs
    readonly property string icDown: "\uf019"
    readonly property string icUp: "\uf093"
    readonly property string icWifi: "\uf1eb"
    readonly property string icLock: "\uf023"
    readonly property string icEth: "\uf6ff"

    function formatSpeed(bps) {
        if (bps < 1024) return bps.toFixed(0) + " B/s"
        if (bps < 1024 * 1024) return (bps / 1024).toFixed(1) + " KB/s"
        if (bps < 1024 * 1024 * 1024) return (bps / 1024 / 1024).toFixed(2) + " MB/s"
        return (bps / 1024 / 1024 / 1024).toFixed(2) + " GB/s"
    }

    // ── Network speed (all real interfaces, wifi + ethernet) ───────
    Process {
        id: pNet
        command: ["cat", "/proc/net/dev"]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                var rx = 0
                var tx = 0

                for (var i = 2; i < lines.length; ++i) {
                    var line = lines[i].trim()
                    if (!line) continue

                    var idx = line.indexOf(":")
                    if (idx < 0) continue

                    var name = line.slice(0, idx).trim()
                    if (name === "lo"
                        || name.indexOf("veth") === 0
                        || name.indexOf("docker") === 0
                        || name.indexOf("br-") === 0
                        || name.indexOf("virbr") === 0) continue

                    var parts = line.slice(idx + 1).trim().split(/\s+/)
                    rx += parseFloat(parts[0]) || 0
                    tx += parseFloat(parts[8]) || 0
                }

                var now = Date.now()
                if (page.lastTs > 0) {
                    var dt = (now - page.lastTs) / 1000
                    if (dt > 0) {
                        page.downSpeed = Math.max(0, (rx - page.lastRx) / dt)
                        page.upSpeed = Math.max(0, (tx - page.lastTx) / dt)
                    }
                }

                page.lastRx = rx
                page.lastTx = tx
                page.lastTs = now
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!pNet.running) pNet.running = true
    }

    // ── Ethernet status (device / state / connection name) ─────────
    Process {
        id: pEthernet
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]

        stdout: StdioCollector {
            onStreamFinished: {
                var result = { device: "", state: "disconnected", connection: "" }
                var raw = text.trim()

                if (raw) {
                    var lines = raw.split("\n")

                    for (var i = 0; i < lines.length; ++i) {
                        var line = lines[i].trim()
                        if (!line) continue

                        var fields = line.split(":")
                        if (fields.length < 4) continue

                        if (fields[1] === "ethernet") {
                            result.device = fields[0]
                            result.state = fields[2]
                            result.connection = fields.slice(3).join(":")
                            break
                        }
                    }
                }

                page.ethernet = result
            }
        }

        stderr: StdioCollector {}
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!pEthernet.running) pEthernet.running = true
    }

    // ── Wi-Fi radio ──────────────────────────────────────────────
    Process {
        id: pRadioGet
        command: ["nmcli", "radio", "wifi"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: page.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: pRadioSet

        stdout: StdioCollector {
            onStreamFinished: {
                pRadioGet.running = true
                if (page.wifiEnabled) pList.running = true
                else page.networks = []
            }
        }
    }

    function setWifiEnabled(on) {
        pRadioSet.command = ["nmcli", "radio", "wifi", on ? "on" : "off"]
        pRadioSet.running = true
    }

    // ── Wi-Fi network list ───────────────────────────────────────
    Process {
        id: pList
        command: ["python3", decodeURIComponent(Qt.resolvedUrl("wifi-networks.py").toString().replace(/^file:\/\//, ""))]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim()) return
                try {
                    page.networks = JSON.parse(text)
                } catch (error) {
                    console.warn("Could not read Wi-Fi networks:", error)
                }
            }
        }

        stderr: StdioCollector {}
    }

    // Keep the list fresh so a network connected from elsewhere
    // (auto-connect, nmcli) moves to the top on its own. Paused while a
    // password is being typed, since a rebuild would clear the field.
    Timer {
        interval: 5000
        running: page.visible && page.wifiEnabled && page.pendingSsid === ""
        repeat: true
        onTriggered: if (!pList.running) pList.running = true
    }

    Process {
        id: pConnect

        function refresh() {
            page.pendingSsid = ""
            page.busySsid = ""
            pEthernet.running = true
            if (page.wifiEnabled) pList.running = true
        }

        stdout: StdioCollector { onStreamFinished: pConnect.refresh() }
        stderr: StdioCollector { onStreamFinished: pConnect.refresh() }
    }

    // The network a connect/disconnect is running for (spinner on its button).
    property string busySsid: ""

    function connectOpen(ssid) {
        page.busySsid = ssid
        pConnect.command = ["nmcli", "device", "wifi", "connect", ssid]
        pConnect.running = true
    }

    function connectSecured(ssid, password) {
        page.busySsid = ssid
        pConnect.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        pConnect.running = true
    }

    function disconnect(uuid) {
        pConnect.command = ["nmcli", "connection", "down", "uuid", uuid]
        pConnect.running = true
    }

    Component.onCompleted: {
        pRadioGet.running = true
        pList.running = true
        pEthernet.running = true
    }

    readonly property var current: networks.find(n => n.connected)

    function signalIcon(sig) {
        if (sig >= 75) return "󰤨"
        if (sig >= 50) return "󰤥"
        if (sig >= 25) return "󰤢"
        return "󰤟"
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: page.marginLeft; anchors.rightMargin: page.marginRight
        anchors.topMargin: page.marginTop; anchors.bottomMargin: page.marginBottom
        spacing: 12

        HubHeader { title: "Network" }

        HubSwitchRow {
            icon: page.wifiEnabled ? "󰤨" : "󰤭"
            title: "Wi-Fi"
            subtitle: !page.wifiEnabled ? "Off"
                : page.current ? "Connected to " + page.current.ssid : "Not connected"
            checked: page.wifiEnabled
            onToggled: on => page.setWifiEnabled(on)
        }

        // Ethernet and live traffic side by side.
        Row {
            id: statsRow
            width: parent.width
            spacing: 8

            HubItem {
                width: (statsRow.width - 16) / 3
                icon: "󰈀"
                tint: Theme.accent2
                active: page.ethernet.state === "connected"
                title: "Ethernet"
                subtitle: active ? (page.ethernet.connection || page.ethernet.device) : "Unplugged"
            }
            Repeater {
                model: [
                    { icon: "󰇚", label: "Download", value: page.downSpeed },
                    { icon: "󰕒", label: "Upload", value: page.upSpeed }
                ]
                HubItem {
                    required property var modelData
                    width: (statsRow.width - 16) / 3
                    icon: modelData.icon
                    title: page.formatSpeed(modelData.value)
                    subtitle: modelData.label
                }
            }
        }

        HubLabel {
            visible: page.wifiEnabled
            text: "Networks"
        }

        Flickable {
            width: parent.width
            height: parent.height - y
            clip: true
            contentWidth: width
            contentHeight: list.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: parent.width
                spacing: 8

                Text {
                    visible: !page.wifiEnabled || !page.networks.length
                    width: parent.width
                    topPadding: 30
                    text: !page.wifiEnabled ? "Turn Wi-Fi on to see networks." : "Scanning for networks…"
                    color: Theme.textDim
                    font.family: Theme.uiFont
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }

                Repeater {
                    model: page.wifiEnabled ? page.networks : []

                    delegate: Column {
                        id: net
                        required property var modelData
                        readonly property bool asking: page.pendingSsid === modelData.ssid
                        width: list.width
                        spacing: 6

                        HubItem {
                            active: net.modelData.connected
                            icon: page.signalIcon(net.modelData.signal)
                            title: net.modelData.ssid
                            subtitle: [
                                net.modelData.connected ? "Connected" : "",
                                net.modelData.secured ? "󰌾 Secured" : "Open",
                                net.modelData.signal + "%"
                            ].filter(x => x).join("  ·  ")

                            HubButton {
                                kind: net.modelData.connected ? "danger" : net.asking ? "tonal" : "filled"
                                busy: page.busySsid === net.modelData.ssid
                                text: net.modelData.connected ? "Disconnect" : net.asking ? "Cancel" : "Connect"
                                onClicked: {
                                    if (net.modelData.connected) {
                                        page.disconnect(net.modelData.uuid)
                                    } else if (net.modelData.secured) {
                                        page.pendingSsid = net.asking ? "" : net.modelData.ssid
                                    } else {
                                        page.connectOpen(net.modelData.ssid)
                                    }
                                }
                            }
                        }

                        // Password prompt for a secured network.
                        Rectangle {
                            visible: net.asking
                            width: parent.width
                            height: 56
                            radius: 14
                            color: Theme.surfaceCard
                            border.width: 1
                            border.color: Theme.outline

                            Rectangle {
                                id: field
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.right: join.left
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                height: 38
                                radius: 10
                                color: Theme.alpha(Theme.text, 0.06)
                                border.width: pwField.activeFocus ? 2 : 1
                                border.color: pwField.activeFocus ? Theme.accent : Theme.outline

                                TextInput {
                                    id: pwField
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.text
                                    font.family: Theme.uiFont
                                    font.pixelSize: 14
                                    echoMode: TextInput.Password
                                    focus: net.asking
                                    Keys.onReturnPressed: page.connectSecured(net.modelData.ssid, text)
                                    Keys.onEscapePressed: page.pendingSsid = ""
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: pwField.text === ""
                                    text: "Password for " + net.modelData.ssid
                                    color: Theme.textFaint
                                    font.family: Theme.uiFont
                                    font.pixelSize: 13
                                }
                            }

                            HubButton {
                                id: join
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                kind: "filled"
                                text: "Join"
                                enabled: pwField.text.length >= 8
                                busy: page.busySsid === net.modelData.ssid
                                onClicked: page.connectSecured(net.modelData.ssid, pwField.text)
                            }
                        }
                    }
                }
            }
        }
    }
}
