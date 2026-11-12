// Login-to-desktop transition. The SDDM login screen ends on the dark planet
// alone on black; this overlay picks up from exactly that picture when the
// session starts, then opens a circle from the planet's centre that reveals
// the desktop, with a gold eclipse ring on its edge, while the planet flies
// towards the camera and fades out.
// Plays once per login: the marker sits in XDG_RUNTIME_DIR, emptied on logout,
// so restarting quickshell during the session doesn't replay it.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: intro

    property bool playing: false
    // Hyprland's own scale per monitor. Qt reports a rounded device pixel
    // ratio (2 for Hyprland's 1.5), which would shrink the planet.
    property var scales: ({})
    readonly property string marker: Quickshell.env("XDG_RUNTIME_DIR") + "/nixos-session-intro"
    // The SDDM theme ships the planet frames with an alpha channel.
    readonly property string frames: "file:///run/current-system/sw/share/sddm/themes/nixos/planet/progress-"

    Process {
        running: true
        command: ["sh", "-c", "[ -e \"$1\" ] && echo skip || { touch \"$1\"; echo play; }; hyprctl -j monitors", "sh", intro.marker]
        stdout: StdioCollector {
            onStreamFinished: {
                const nl = this.text.indexOf("\n")
                try {
                    const map = {}
                    for (const m of JSON.parse(this.text.slice(nl + 1))) map[m.name] = m.scale
                    intro.scales = map
                } catch (e) {}
                if (this.text.slice(0, nl).trim() === "play") intro.playing = true
            }
        }
    }

    // Never leave a black screen behind, whatever happens to the animation.
    Timer {
        running: intro.playing
        interval: 6000
        onTriggered: intro.playing = false
    }

    Variants {
        model: intro.playing ? Quickshell.screens : []

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "session-intro"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            // Clicks and typing go straight to the desktop underneath.
            mask: Region {}

            // SDDM draws the 467x350 frames at 2x physical pixels; match that
            // in logical pixels so the planet doesn't change size.
            readonly property real dpr: intro.scales[modelData.name] || modelData.devicePixelRatio || 1
            readonly property real planetW: 467 * 2 / dpr
            readonly property real planetH: 350 * 2 / dpr
            readonly property real cx: width / 2
            readonly property real cy: height / 2
            readonly property real fullRadius: Math.sqrt(width * width + height * height) / 2 + 40

            property real hole: 0
            property int frame: 0

            Timer {
                interval: 30
                running: true
                repeat: true
                onTriggered: win.frame = (win.frame + 1) % 160
            }

            // Black cover with a growing round hole in it.
            Rectangle {
                id: cover
                anchors.fill: parent
                color: "#000000"
                visible: false
                layer.enabled: true
            }
            Item {
                id: holeShape
                anchors.fill: parent
                visible: false
                layer.enabled: true
                Rectangle {
                    x: win.cx - win.hole
                    y: win.cy - win.hole
                    width: win.hole * 2
                    height: width
                    radius: win.hole
                    color: "#ffffff"
                }
            }
            MultiEffect {
                anchors.fill: parent
                source: cover
                maskEnabled: true
                maskSource: holeShape
                maskInverted: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            // Gold eclipse ring riding the edge of the hole.
            Rectangle {
                id: ring
                x: win.cx - width / 2
                y: win.cy - height / 2
                width: win.hole * 2 + 6
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: "#e2b26a"
                opacity: 0
            }
            Rectangle {
                x: win.cx - width / 2
                y: win.cy - height / 2
                width: win.hole * 2 + 26
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 10
                border.color: "#e2b26a"
                opacity: ring.opacity * 0.18
            }

            Image {
                id: planet
                x: win.cx - width / 2
                y: win.cy - height / 2
                width: win.planetW
                height: win.planetH
                source: intro.frames + win.frame + ".png"
                smooth: true
                cache: false
            }

            SequentialAnimation {
                running: true
                // Hold the login screen's last picture while the wallpaper loads.
                PauseAnimation { duration: 650 }
                ParallelAnimation {
                    NumberAnimation { target: win; property: "hole"; from: 0; to: win.fullRadius; duration: 1500; easing.type: Easing.InOutCubic }
                    SequentialAnimation {
                        NumberAnimation { target: ring; property: "opacity"; to: 0.95; duration: 250 }
                        NumberAnimation { target: ring; property: "opacity"; to: 0; duration: 1250; easing.type: Easing.InQuad }
                    }
                    NumberAnimation { target: planet; property: "scale"; to: 1.7; duration: 1100; easing.type: Easing.InCubic }
                    NumberAnimation { target: planet; property: "opacity"; to: 0; duration: 1100; easing.type: Easing.InQuad }
                }
                ScriptAction { script: intro.playing = false }
            }
        }
    }
}
