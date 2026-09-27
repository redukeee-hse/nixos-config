import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#010101"

    property color textColor: config.TextColor || "#ffffff"
    property color accentColor: config.AccentColor || "#9ecbff"
    property color mutedColor: config.MutedColor || "#b0b5bd"
    property color overlayColor: config.OverlayColor || "#52010101"
    property color fieldColor: config.FieldColor || "#8010151e"
    property string loginUser: userModel.lastUser || "configuser"

    Image {
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }

    Rectangle {
        anchors.fill: parent
        color: root.overlayColor
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            hour.text = Qt.formatDateTime(now, "HH")
            minute.text = Qt.formatDateTime(now, "mm")
            date.text = Qt.formatDateTime(now, "dddd, d MMMM")
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(70, parent.height * 0.10)
        spacing: -10

        Text {
            id: hour
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.accentColor
            font.family: "DejaVu Sans"
            font.pixelSize: Math.max(70, root.height * 0.095)
            font.weight: Font.DemiBold
        }
        Text {
            id: minute
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.accentColor
            font.family: "DejaVu Sans"
            font.pixelSize: Math.max(70, root.height * 0.095)
            font.weight: Font.DemiBold
        }
        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 15
            color: root.textColor
            font.family: "DejaVu Sans Mono"
            font.pixelSize: 14
            font.weight: Font.Medium
        }
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.height * 0.08
        spacing: 10

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 72
            height: 72
            radius: 36
            color: root.fieldColor
            border.width: 2
            border.color: root.accentColor

            Text {
                anchors.centerIn: parent
                text: root.loginUser.length > 0 ? root.loginUser.charAt(0).toUpperCase() : "?"
                color: root.textColor
                font.pixelSize: 30
                font.weight: Font.DemiBold
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.loginUser
            color: root.textColor
            font.family: "DejaVu Sans Mono"
            font.pixelSize: 14
        }

        Controls.TextField {
            id: password
            anchors.horizontalCenter: parent.horizontalCenter
            width: 250
            height: 42
            focus: true
            echoMode: TextInput.Password
            placeholderText: "Password"
            horizontalAlignment: TextInput.AlignHCenter
            color: root.textColor
            placeholderTextColor: root.mutedColor
            selectionColor: root.accentColor
            selectedTextColor: "#ffffff"
            font.pixelSize: 14
            background: Rectangle {
                radius: 10
                color: root.fieldColor
                border.width: password.activeFocus ? 1 : 0
                border.color: root.accentColor
            }
            Keys.onReturnPressed: login()
        }

        Text {
            id: warning
            anchors.horizontalCenter: parent.horizontalCenter
            visible: text.length > 0
            color: "#ffb4a9"
            font.pixelSize: 12
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        spacing: 12

        Repeater {
            model: [
                ["☾", "Sleep"],
                ["↻", "Restart"],
                ["⏻", "Power off"]
            ]
            delegate: Controls.Button {
                id: powerButton
                width: 42
                height: 42
                text: modelData[0]
                font.pixelSize: 20
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
                    radius: 10
                    color: powerButton.down ? "#30ffffff" : powerButton.hovered ? "#18ffffff" : "transparent"
                    border.width: powerButton.activeFocus ? 1 : 0
                    border.color: root.accentColor
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

    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 18
        text: keyboard.layouts.length > 0 ? keyboard.layouts[keyboard.currentLayout].shortName : ""
        color: root.mutedColor
        font.family: "DejaVu Sans Mono"
        font.pixelSize: 12
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
            warning.text = "Incorrect password"
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
