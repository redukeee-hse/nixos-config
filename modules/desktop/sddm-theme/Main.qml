import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Effects

// Glass login screen: the desktop wallpaper with a soft vignette, a large
// shadowed clock that stays readable on any image, and a frosted login card.
Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#010101"

    // Accent colours follow the desktop palette (sync-sddm-theme.sh);
    // text stays white so it reads on bright wallpapers too.
    property color accentColor: config.AccentColor || "#9ecbff"
    property color textColor: "#ffffff"
    property color mutedColor: "#d0ffffff"
    property string loginUser: userModel.lastUser || "@defaultUser@"
    property real unit: Math.max(1, root.height / 1080)

    Image {
        id: wallpaper
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }

    // Darken the top (clock) and bottom (card, buttons) without hiding the image.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#99000000" }
            GradientStop { position: 0.35; color: "#33000000" }
            GradientStop { position: 0.65; color: "#33000000" }
            GradientStop { position: 1.0; color: "#b3000000" }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            clock.text = Qt.formatDateTime(now, "HH:mm")
            date.text = Qt.formatDateTime(now, "dddd, d MMMM")
        }
    }

    // ----- Clock -----
    Item {
        id: clockBlock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.height * 0.11
        width: clockColumn.width
        height: clockColumn.height

        Column {
            id: clockColumn
            spacing: 4 * root.unit

            Text {
                id: clock
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.textColor
                font.family: "Noto Sans"
                font.pixelSize: 150 * root.unit
                font.weight: Font.Light
                font.letterSpacing: -2 * root.unit
            }
            Text {
                id: date
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.textColor
                opacity: 0.9
                font.family: "Noto Sans"
                font.pixelSize: 24 * root.unit
                font.weight: Font.Medium
                font.capitalization: Font.Capitalize
            }
        }
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.75
            shadowBlur: 1.0
            shadowVerticalOffset: 3
        }
    }

    // ----- Frosted login card -----
    Item {
        id: card
        width: 360 * root.unit
        height: cardColumn.height + 48 * root.unit
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        anchors.topMargin: root.height * 0.04

        // Blurred wallpaper behind the card, clipped to its rounded shape.
        ShaderEffectSource {
            id: cardBackdrop
            anchors.fill: parent
            sourceItem: wallpaper
            sourceRect: Qt.rect(card.x, card.y, card.width, card.height)
            visible: false
        }
        Rectangle {
            id: cardMask
            anchors.fill: parent
            radius: 24 * root.unit
            visible: false
            layer.enabled: true
        }
        MultiEffect {
            anchors.fill: parent
            source: cardBackdrop
            blurEnabled: true
            blurMax: 64
            blur: 1.0
            saturation: 0.2
            maskEnabled: true
            maskSource: cardMask
        }
        Rectangle {
            anchors.fill: parent
            radius: 24 * root.unit
            color: "#59000000"
            border.width: 1
            border.color: "#33ffffff"
        }

        Column {
            id: cardColumn
            anchors.centerIn: parent
            spacing: 14 * root.unit

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8 * root.unit

                Controls.TextField {
                    id: password
                    width: 230 * root.unit
                    height: 44 * root.unit
                    focus: true
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    placeholderText: "Password"
                    leftPadding: 16 * root.unit
                    color: root.textColor
                    placeholderTextColor: "#b3ffffff"
                    selectionColor: root.accentColor
                    selectedTextColor: "#ffffff"
                    font.family: "Noto Sans"
                    font.pixelSize: 16 * root.unit
                    background: Rectangle {
                        radius: height / 2
                        color: "#33ffffff"
                        border.width: password.activeFocus ? 2 : 1
                        border.color: password.activeFocus ? root.accentColor : "#40ffffff"
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    Keys.onReturnPressed: login()
                    Keys.onEnterPressed: login()
                }

                Controls.Button {
                    id: loginButton
                    width: 44 * root.unit
                    height: 44 * root.unit
                    hoverEnabled: true
                    onClicked: login()
                    contentItem: Text {
                        text: "→"
                        color: root.textColor
                        font.pixelSize: 22 * root.unit
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: height / 2
                        color: root.accentColor
                        opacity: loginButton.down ? 0.7 : loginButton.hovered ? 1.0 : 0.85
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                }
            }

            Text {
                id: warning
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text.length > 0
                color: "#ffb4a9"
                font.family: "Noto Sans"
                font.pixelSize: 14 * root.unit
            }
        }
    }

    // ----- Power buttons -----
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28 * root.unit
        width: powerRow.width + 16 * root.unit
        height: powerRow.height + 16 * root.unit
        radius: height / 2
        color: "#40000000"
        border.width: 1
        border.color: "#26ffffff"

        Row {
            id: powerRow
            anchors.centerIn: parent
            spacing: 6 * root.unit

            Repeater {
                model: [
                    ["⏾", "Sleep"],
                    ["↻", "Restart"],
                    ["⏻", "Power off"]
                ]
                delegate: Controls.Button {
                    id: powerButton
                    width: 44 * root.unit
                    height: 44 * root.unit
                    text: modelData[0]
                    font.pixelSize: 20 * root.unit
                    hoverEnabled: true
                    Controls.ToolTip.visible: hovered
                    Controls.ToolTip.delay: 450
                    Controls.ToolTip.text: modelData[1]
                    contentItem: Text {
                        text: powerButton.text
                        color: root.textColor
                        font: powerButton.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: height / 2
                        color: powerButton.down ? "#40ffffff" : powerButton.hovered ? "#26ffffff" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    onClicked: {
                        if (index === 0) sddm.suspend()
                        else if (index === 1) sddm.reboot()
                        else sddm.powerOff()
                    }
                }
            }
        }
    }

    // Keyboard layout indicator
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 24 * root.unit
        visible: layoutLabel.text.length > 0
        width: layoutLabel.width + 20 * root.unit
        height: layoutLabel.height + 10 * root.unit
        radius: height / 2
        color: "#40000000"
        border.width: 1
        border.color: "#26ffffff"

        Text {
            id: layoutLabel
            anchors.centerIn: parent
            text: keyboard.layouts.length > 0 ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : ""
            color: root.textColor
            font.family: "Noto Sans"
            font.pixelSize: 13 * root.unit
            font.weight: Font.DemiBold
        }
    }

    function login() {
        warning.text = ""
        sddm.login(root.loginUser, password.text, sessionModel.lastIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            password.forceActiveFocus()
            warning.text = "Wrong password"
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
