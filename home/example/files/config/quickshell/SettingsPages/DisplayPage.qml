import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: page

    property var monitors: []
    property real marginLeft: 0
    property real marginRight: 55
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
            width: flick.width
            spacing: 14

            Text {
                text: "DISPLAY"; color: Theme.text
                font.family: Theme.fontFamily; font.pixelSize: 19; font.letterSpacing: 3
            }

            Rectangle { width: parent.width; height: 1; color: Theme.border }

            Row {
                width: parent.width; height: 38; spacing: 8

                Rectangle {
                    width: 28; height: 28; radius: Theme.radius; anchors.verticalCenter: parent.verticalCenter
                    color: Theme.alpha(Theme.accent2, 0.10); border.width: 1; border.color: Theme.border
                    Text {
                        anchors.centerIn: parent; text: "\uf185"; color: Theme.accent2
                        font.family: Theme.iconFont; font.pixelSize: 12
                    }
                }

                Text {
                    width: page.labelWidth; anchors.verticalCenter: parent.verticalCenter
                    text: "BRIGHTNESS"; color: Theme.text
                    font.family: Theme.fontFamily; font.pixelSize: 15
                }

                Slider {
                    width: parent.width - 28 - page.labelWidth - 16 - page.sliderMarginRight
                    height: 72; anchors.verticalCenter: parent.verticalCenter
                    label: ""; icon: ""; value: page.brightnessValue; accentColor: Theme.accent2
                    onCommitted: value => page.commitBrightness(value)
                }
            }

            Row {
                width: parent.width; height: 38; spacing: 10

                Rectangle {
                    width: 28; height: 28; radius: Theme.radius; anchors.verticalCenter: parent.verticalCenter
                    color: page.nightlightEnabled ? Theme.alpha(Theme.accent, 0.10) : Theme.alpha("#A0A0A0", 0.15)
                    border.width: 1; border.color: page.nightlightEnabled ? Theme.accent : Theme.border
                    Text {
                        anchors.centerIn: parent; text: "\uf186"
                        color: page.nightlightEnabled ? Theme.accent : "#A0A0A0"
                        font.family: Theme.iconFont; font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: page.nightlightEnabled ? page.nightlightOff() : page.nightlightOn()
                    }
                }

                Text {
                    width: page.labelWidth; anchors.verticalCenter: parent.verticalCenter
                    text: "NIGHTLIGHT"; color: page.nightlightEnabled ? Theme.text : Theme.text
                    font.family: Theme.fontFamily; font.pixelSize: 15
                }

                Slider {
                    width: parent.width - 28 - page.labelWidth - 16 - page.sliderMarginRight
                    height: 72; anchors.verticalCenter: parent.verticalCenter
                    label: ""; icon: ""; value: page.nightlightValue; accentColor: Theme.accent2
                    onMoved: value => page.commitNightlight(value)
                }
            }

            Column {
                width: parent.width; spacing: 16

                Repeater {
                    model: page.monitors

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 46; radius: Theme.radius
                        color: "#00000000"; border.width: 1
                        border.color: modelData.focused ? "#454545" : Theme.border

                        Column {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8
                            Row {
                                spacing: 10

                                Text {
                                    text: modelData.name; color: Theme.text
                                    font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true
                                }

                                Text {
                                    text: modelData.width + "x" + modelData.height + " @ " + Math.round(modelData.refreshRate) + "Hz"
                                    color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 12
                                }

                                Text {
                                    visible: modelData.focused; text: "ACTIVE"; color: Theme.accent2
                                    font.family: Theme.fontFamily; font.pixelSize: 10
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        brightnessGet.running = true
        loadNightlight()
        nightlightCheck.running = true
    }
}