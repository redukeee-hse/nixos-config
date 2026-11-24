// Hub > Power: power profile, charge limit and battery health, after Ryoku's
// Machine and Graphics & Power > Battery pages.
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: page

    readonly property string bin: Quickshell.env("HOME") + "/.local/share/custom/bin/"
    property string profile: "balanced"
    property string limit: "100"
    property var bat: ({})

    Process {
        id: readAll
        running: true
        command: ["sh", "-c",
            "powerprofilesctl get 2>/dev/null; " +
            "b=$(ls -d /sys/class/power_supply/BAT* | head -n1); " +
            "for f in capacity status cycle_count energy_full energy_full_design charge_control_end_threshold power_now; do " +
            "  printf '%s=%s\\n' $f \"$(cat $b/$f 2>/dev/null)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                page.profile = lines.shift() || "balanced"
                const b = {}
                for (const l of lines) { const i = l.indexOf("="); b[l.slice(0, i)] = l.slice(i + 1) }
                page.bat = b
                page.limit = b.charge_control_end_threshold || "100"
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: readAll.running = true }

    function health() {
        const f = Number(bat.energy_full), d = Number(bat.energy_full_design)
        return f > 0 && d > 0 ? Math.round(f / d * 100) + "%" : "—"
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

            HubHeader { title: "Power" }

            // Battery readout.
            Row {
                id: stats
                width: parent.width
                spacing: 8
                bottomPadding: 4
                Repeater {
                    model: [
                        { k: "Charge", v: (page.bat.capacity || "—") + "%" },
                        { k: "State", v: page.bat.status || "—" },
                        { k: "Health", v: page.health() },
                        { k: "Cycles", v: page.bat.cycle_count || "—" },
                        { k: "Draw", v: page.bat.power_now ? (Number(page.bat.power_now) / 1e6).toFixed(1) + " W" : "—" }
                    ]
                    Rectangle {
                        required property var modelData
                        width: (stats.width - 4 * stats.spacing) / 5
                        height: 72
                        radius: 16
                        color: Theme.surfaceCard
                        border.width: 1
                        border.color: Theme.outline
                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text { text: parent.parent.modelData.v; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: 20; font.weight: Font.DemiBold }
                            Text { text: parent.parent.modelData.k; color: Theme.textDim; font.family: Theme.uiFont; font.pixelSize: 12 }
                        }
                    }
                }
            }

            HubRow {
                label: "Power profile"
                hint: "power-profiles-daemon. Super+AltGr+Esc toggles power saver."
                options: [
                    { value: "power-saver", text: "Saver" },
                    { value: "balanced", text: "Balanced" },
                    { value: "performance", text: "Performance" }
                ]
                current: page.profile
                onPicked: v => {
                    page.profile = v
                    Quickshell.execDetached(["sh", "-c", "powerprofilesctl set \"$1\"; pkill -RTMIN+8 waybar", "sh", v])
                }
            }
            HubRow {
                label: "Charge limit"
                hint: "Stops charging at the limit to keep the battery healthy when plugged in most of the day. Reapplied at login."
                options: [{ value: "80", text: "80%" }, { value: "90", text: "90%" }, { value: "100", text: "Off" }]
                current: page.limit
                onPicked: v => {
                    page.limit = v
                    Quickshell.execDetached([page.bin + "battery-care.sh", "limit", v])
                }
            }
            Text {
                width: parent.width
                topPadding: 6
                text: "Low-battery alerts come at 25% and 10% while discharging."
                color: Theme.textDim
                font.family: Theme.uiFont
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
        }
    }
}
