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
        anchors.rightMargin: 20
        contentHeight: col.implicitHeight
        clip: true

        Column {
            id: col
            width: parent.width
            spacing: 2

            Text {
                text: "POWER"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.letterSpacing: 2
                bottomPadding: 8
            }

            // Battery readout.
            Row {
                spacing: 28
                bottomPadding: 14
                Repeater {
                    model: [
                        { k: "CHARGE", v: (page.bat.capacity || "—") + "%" },
                        { k: "STATE", v: (page.bat.status || "—").toUpperCase() },
                        { k: "HEALTH", v: page.health() },
                        { k: "CYCLES", v: page.bat.cycle_count || "—" },
                        { k: "DRAW", v: page.bat.power_now ? (Number(page.bat.power_now) / 1e6).toFixed(1) + " W" : "—" }
                    ]
                    Column {
                        required property var modelData
                        spacing: 4
                        Text { text: parent.modelData.k; color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: 10; font.letterSpacing: 1.5 }
                        Text { text: parent.modelData.v; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 18 }
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
                topPadding: 14
                text: "Low-battery alerts come at 25% and 10% while discharging."
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
        }
    }
}
