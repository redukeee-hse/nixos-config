import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: page

    property var monitors: []
    property real marginLeft: 0
    property real marginRight: 4
    property real marginTop: 0
    property real marginBottom: 0
    property real brightnessValue: 0.6
    property real nightlightValue: 0.5
    property bool nightlightEnabled: false
    property real sliderMarginRight: 10
    property real labelWidth: 96

    Process {
        id: brightnessGet
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length >= 4) {
                    const pct = parseInt(parts[3])
                    if (!isNaN(pct)) page.brightnessValue = pct / 100
                }
            }
        }
    }

    Process { id: brightnessSet }

    function commitBrightness(value) {
        const pct = Math.round(value * 100) + "%"
        brightnessSet.command = ["brightnessctl", "set", pct]
        brightnessSet.running = true
    }

    Process { id: nightlightProcess }

    // Slider to the right means a warmer screen: 0 is neutral 6500K, 1 is 2500K.
    function nightlightTemperature(value) { return Math.round(6500 - value * 4000) }

    // Restarting hyprsunset resets the screen for a moment, so a running instance is
    // retuned over its IPC and only started when it is not there yet.
    function startNightlight(value, delay) {
        const temp = nightlightTemperature(value)
        // Detached so quick slider moves never get dropped while a previous call runs.
        Quickshell.execDetached([
            "sh", "-c",
            "if pgrep -f '^[^ ]*hyprsunset -t' >/dev/null; then " +
            "hyprctl hyprsunset temperature " + temp + " >/dev/null; " +
            "else sleep " + delay + "; nohup hyprsunset -t " + temp + " >/dev/null 2>&1 & fi"
        ])
    }

    function nightlightOn() { nightlightEnabled = true; startNightlight(nightlightValue, "0.05") }

    function nightlightOff() {
        nightlightEnabled = false
        nightlightProcess.command = ["pkill", "-f", "^[^ ]*hyprsunset -t"]
        nightlightProcess.running = true
    }

    function commitNightlight(value) {
        nightlightValue = value
        nightlightSaveTimer.restart()
        if (nightlightEnabled) startNightlight(value, "0.03")
    }

    FileView {
        id: nightlightFile
        path: Quickshell.dataDir + "/nightlight.json"
        blockLoading: true
    }

    function loadNightlight() {
        try {
            const saved = JSON.parse(nightlightFile.text())
            if (typeof saved.value === "number") nightlightValue = saved.value
        } catch (error) {}
    }

    Timer {
        id: nightlightSaveTimer
        interval: 300
        onTriggered: {
            nightlightFile.setText(JSON.stringify({ value: page.nightlightValue }))
        }
    }

    Process {
        id: nightlightCheck
        command: ["pgrep", "-f", "^[^ ]*hyprsunset -t"]
        onExited: exitCode => {
            page.nightlightEnabled = exitCode === 0
        }
    }

    Process {
        id: pList
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.monitors = JSON.parse(text)
                } catch (error) {
                    page.monitors = []
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {}
        }
    }

    function refresh() {
        pList.running = true
    }

    Process {
        id: pEditConfig
        command: ["sh", "-c", "code ~/nixos-config/home/example/files/config/hypr/hyprland.conf"]
        onExited: exitCode => {}
    }

    function editConfig() {
        if (pEditConfig.running) {
            return
        }
        pEditConfig.running = true
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.leftMargin: page.marginLeft; anchors.rightMargin: page.marginRight
        anchors.topMargin: page.marginTop; anchors.bottomMargin: page.marginBottom
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: scrollBar

            background: Rectangle {
                color: "transparent"
                radius: width / 2
            }

            contentItem: Rectangle {
                color: "transparent"
                radius: width / 2
            }
        }

        Column {
            id: content
            width: flick.width - 10
            spacing: 10

            HubHeader { title: "Display" }

            LevelCard {
                icon: "󰃠"
                title: "Brightness"
                value: page.brightnessValue
                readout: Math.round(page.brightnessValue * 100) + "%"
                onMoving: v => page.brightnessValue = v
                onCommit: v => page.commitBrightness(v)
            }

            HubSwitchRow {
                icon: "󰖔"
                title: "Night light"
                subtitle: page.nightlightEnabled
                    ? "Warmer screen, " + page.nightlightTemperature(page.nightlightValue) + " K"
                    : "Off"
                checked: page.nightlightEnabled
                onToggled: on => on ? page.nightlightOn() : page.nightlightOff()
            }

            LevelCard {
                icon: "󰖨"
                title: "Warmth"
                enabled: page.nightlightEnabled
                opacity: enabled ? 1 : 0.5
                value: page.nightlightValue
                readout: page.nightlightTemperature(page.nightlightValue) + " K"
                onMoving: v => page.commitNightlight(v)
                onCommit: v => page.commitNightlight(v)
            }

            HubLabel { text: "Monitors" }

            Repeater {
                model: page.monitors
                delegate: HubItem {
                    required property var modelData
                    width: content.width
                    icon: "󰍹"
                    active: modelData.focused
                    title: modelData.name + (modelData.description ? "  ·  " + modelData.description.replace(/ [A-Z0-9]{8,}$/, "") : "")
                    subtitle: modelData.width + "×" + modelData.height + " @ " + Math.round(modelData.refreshRate) + " Hz  ·  scale " + modelData.scale
                        + (modelData.focused ? "  ·  focused" : "")
                }
            }

            HubButton {
                kind: "outline"
                icon: "󰏫"
                text: "Edit monitor layout"
                onClicked: page.editConfig()
            }
            Item { width: 1; height: 10 }
        }
    }

    // A card with an icon, a title, a slider and a readout on the right.
    component LevelCard: Rectangle {
        id: lc
        property string icon: ""
        property string title: ""
        property real value: 0
        property string readout: ""
        signal moving(real v)
        signal commit(real v)

        width: parent ? parent.width : 400
        height: 64
        radius: 16
        color: Theme.surfaceCard
        border.width: 1
        border.color: Theme.outline

        Rectangle {
            id: badge
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 40; height: 40; radius: 20
            color: Theme.alpha(Theme.accent, 0.2)
            Text {
                anchors.centerIn: parent
                text: lc.icon
                color: Theme.text
                font.family: Theme.iconFont
                font.pixelSize: 17
            }
        }
        Text {
            id: lcTitle
            anchors.left: badge.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 110
            text: lc.title
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Slider {
            anchors.left: lcTitle.right
            anchors.leftMargin: 10
            anchors.right: lcValue.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 40
            label: ""; icon: ""
            value: lc.value
            onMoved: v => lc.moving(v)
            onCommitted: v => lc.commit(v)
        }
        Text {
            id: lcValue
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 52
            horizontalAlignment: Text.AlignRight
            text: lc.readout
            color: Theme.textDim
            font.family: Theme.uiFont
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    Component.onCompleted: {
        brightnessGet.running = true
        loadNightlight()
        nightlightCheck.running = true
    }
}