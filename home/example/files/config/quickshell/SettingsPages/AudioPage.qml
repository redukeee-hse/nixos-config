import QtQuick
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../"

Item {
    id: page
    property real marginLeft: 0
    property real marginRight: 4
    property real marginTop: 0
    property real marginBottom: 0
    property real sliderMarginRight: 10
    property real sectionSpacing: 6
    PwObjectTracker { objects: Pipewire.nodes.values }
    property var sink: Pipewire.defaultAudioSink
    property real volume: sink?.audio?.volume ?? 0
    property bool muted: sink?.audio?.muted ?? false
    property var source: Pipewire.defaultAudioSource
    property real inputVolume: source?.audio?.volume ?? 0
    property bool inputMuted: source?.audio?.muted ?? false
    property var outputSinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    property var inputSources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)
    property var appStreams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink)

    Flickable {
        id: flick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: page.marginLeft
        anchors.rightMargin: page.marginRight
        anchors.topMargin: page.marginTop
        anchors.bottomMargin: page.marginBottom
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            policy: ScrollBar.AsNeeded
            width: 6

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

            HubHeader { title: "Sound" }

            VolumeCard {
                icon: page.muted ? "󰖁" : "󰕾"
                title: "Output"
                muted: page.muted
                volume: page.volume
                onToggleMute: if (page.sink?.audio) page.sink.audio.muted = !page.sink.audio.muted
                onCommit: v => { if (page.sink?.audio) { page.sink.audio.muted = false; page.sink.audio.volume = v } }
            }

            Repeater {
                model: page.outputSinks
                delegate: HubItem {
                    required property var modelData
                    width: content.width
                    height: 52
                    clickable: !active
                    active: page.sink?.id === modelData?.id
                    icon: page.outputIcon(modelData)
                    title: modelData?.description || modelData?.nickname || modelData?.name || "Unknown output"
                    subtitle: active ? "In use" : ""
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
            Text {
                visible: page.outputSinks.length === 0
                text: "No outputs"
                color: Theme.textDim
                font.family: Theme.uiFont; font.pixelSize: 13
            }

            Item { width: 1; height: 6 }

            VolumeCard {
                icon: page.inputMuted ? "󰍭" : "󰍬"
                title: "Input"
                muted: page.inputMuted
                volume: page.inputVolume
                onToggleMute: if (page.source?.audio) page.source.audio.muted = !page.source.audio.muted
                onCommit: v => { if (page.source?.audio) { page.source.audio.muted = false; page.source.audio.volume = v } }
            }

            Repeater {
                model: page.inputSources
                delegate: HubItem {
                    required property var modelData
                    width: content.width
                    height: 52
                    clickable: !active
                    active: page.source?.id === modelData?.id
                    icon: "󰍬"
                    title: modelData?.description || modelData?.nickname || modelData?.name || "Unknown input"
                    subtitle: active ? "In use" : ""
                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }
            Text {
                visible: page.inputSources.length === 0
                text: "No inputs"
                color: Theme.textDim
                font.family: Theme.uiFont; font.pixelSize: 13
            }

            HubLabel { text: "Apps" + (page.appStreams.length ? "  ·  " + page.appStreams.length : "") }

            Repeater {
                model: page.appStreams
                delegate: VolumeCard {
                    required property var modelData
                    icon: (modelData?.audio?.muted ?? false) ? "󰖁" : "󰝚"
                    title: modelData?.properties?.["application.name"] || modelData?.description || modelData?.name || "App"
                    muted: modelData?.audio?.muted ?? false
                    volume: modelData?.audio?.volume ?? 0
                    onToggleMute: if (modelData?.audio) modelData.audio.muted = !modelData.audio.muted
                    onCommit: v => { if (modelData?.audio) { modelData.audio.muted = false; modelData.audio.volume = v } }
                }
            }
            Text {
                visible: page.appStreams.length === 0
                text: "Nothing is playing."
                color: Theme.textDim
                font.family: Theme.uiFont; font.pixelSize: 13
                bottomPadding: 10
            }
        }
    }

    // Speakers, headphones, HDMI/DisplayPort from the node name.
    function outputIcon(n) {
        const s = ((n?.description || "") + " " + (n?.name || "")).toLowerCase()
        if (s.indexOf("bluez") >= 0 || s.indexOf("headphone") >= 0 || s.indexOf("headset") >= 0) return "󰋋"
        if (s.indexOf("hdmi") >= 0 || s.indexOf("displayport") >= 0) return "󰍹"
        return "󰓃"
    }

    // A card with a mute button, a title with the level and a slider.
    component VolumeCard: Rectangle {
        id: vc
        property string icon: ""
        property string title: ""
        property bool muted: false
        property real volume: 0
        signal toggleMute()
        signal commit(real v)

        width: parent ? parent.width : 400
        height: 64
        radius: 16
        color: Theme.surfaceCard
        border.width: 1
        border.color: Theme.outline

        HubButton {
            id: muteBtn
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: 40
            kind: vc.muted ? "danger" : "tonal"
            icon: vc.icon
            tooltip: vc.muted ? "Unmute" : "Mute"
            onClicked: vc.toggleMute()
        }
        Text {
            id: vcTitle
            anchors.left: muteBtn.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 130
            text: vc.title
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: 14
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Slider {
            anchors.left: vcTitle.right
            anchors.leftMargin: 10
            anchors.right: pct.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 40
            label: ""; icon: ""
            value: vc.muted ? 0 : vc.volume
            accentColor: vc.muted ? Theme.textFaint : Theme.accent
            onCommitted: v => vc.commit(v)
        }
        Text {
            id: pct
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            horizontalAlignment: Text.AlignRight
            text: vc.muted ? "Muted" : Math.round(vc.volume * 100) + "%"
            color: Theme.textDim
            font.family: Theme.uiFont
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }
}
