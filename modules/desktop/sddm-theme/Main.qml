import QtQuick 2.15

// "Orbit" login screen. It continues the boot splash: it opens on the same
// rotating dark planet, at the same size and place as Plymouth draws it.
// Then the planet drifts right into a starfield with two orbits, and an
// editorial interface fades in: a big clock with superscript minutes, a
// serif name card with the password line, small mono telemetry and a
// ghosted COSMOS behind everything. On login the interface goes away and the
// planet returns to the centre, back to the boot look.
Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#000000"

    property real unit: Math.max(0.5, root.height / 1080)
    property string loginUser: userModel.lastUser || "@defaultUser@"
    property string title: config.Title || root.loginUser
    property bool use24h: (config.Use24h || "true") === "true"
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string sans: "Montserrat"
    property string serif: "EB Garamond"
    property string mono: "JetBrainsMono Nerd Font Mono"
    property color ink: "#eef0f2"
    property color muted: "#8a9099"
    property color gold: "#e2b26a"
    property color danger: "#ff9b8a"
    // The interface waits for the planet to settle.
    property int introDelay: 1300
    property real uiOpacity: 1
    property string status: "AWAITING OPERATOR"
    Behavior on uiOpacity { NumberAnimation { duration: 300 } }

    FontLoader { source: "fonts/Montserrat-Light.ttf" }
    FontLoader { source: "fonts/Montserrat-Medium.ttf" }
    FontLoader { source: "fonts/Montserrat-SemiBold.ttf" }
    FontLoader { source: "fonts/EBGaramond12-Regular.ttf" }
    FontLoader { source: "fonts/EBGaramond12-Italic.ttf" }

    // ----- Time -----
    readonly property var locale: Qt.locale("en_GB")
    property date now: new Date()
    Timer {
        interval: 250
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
    function pad(v) { return (v < 10 ? "0" : "") + v }
    function utcOffset() {
        const m = -root.now.getTimezoneOffset()
        return "UTC" + (m >= 0 ? "+" : "−") + pad(Math.floor(Math.abs(m) / 60)) + ":" + pad(Math.abs(m) % 60)
    }
    function weekNumber() {
        const d = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()))
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7))
        return Math.ceil(((d - new Date(Date.UTC(d.getUTCFullYear(), 0, 1))) / 86400000 + 1) / 7)
    }

    // ----- Stars -----
    Item {
        id: sky
        anchors.fill: parent
        opacity: 0
        SequentialAnimation on opacity {
            PauseAnimation { duration: 700 }
            NumberAnimation { to: 1; duration: 2200; easing.type: Easing.InOutQuad }
        }
        Repeater {
            model: 190
            Rectangle {
                id: star
                readonly property real base: 0.15 + Math.pow(Math.random(), 2) * 0.8
                x: Math.random() * root.width
                y: Math.random() * root.height
                width: (0.8 + Math.pow(Math.random(), 3) * 2.2) * root.unit
                height: width
                radius: width / 2
                color: Math.random() < 0.12 ? "#ffe0b0" : (Math.random() < 0.15 ? "#c8d8ff" : "#ffffff")
                opacity: base
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    PauseAnimation { duration: Math.random() * 4000 }
                    NumberAnimation { to: star.base * 0.25; duration: 900 + Math.random() * 2200; easing.type: Easing.InOutSine }
                    NumberAnimation { to: star.base; duration: 900 + Math.random() * 2200; easing.type: Easing.InOutSine }
                }
            }
        }

        // An occasional shooting star.
        Rectangle {
            id: meteor
            width: 170 * root.unit
            height: Math.max(1, 1.2 * root.unit)
            rotation: 24
            opacity: 0
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00ffffff" }
                GradientStop { position: 1.0; color: "#ccffffff" }
            }
            ParallelAnimation {
                id: meteorRun
                NumberAnimation { id: meteorX; target: meteor; property: "x"; duration: 900; easing.type: Easing.InQuad }
                NumberAnimation { id: meteorY; target: meteor; property: "y"; duration: 900; easing.type: Easing.InQuad }
                SequentialAnimation {
                    NumberAnimation { target: meteor; property: "opacity"; to: 0.9; duration: 200 }
                    NumberAnimation { target: meteor; property: "opacity"; to: 0; duration: 700 }
                }
            }
            Timer {
                interval: 7000
                running: true
                repeat: true
                onTriggered: {
                    interval = 7000 + Math.random() * 6000
                    const sx = root.width * (0.15 + Math.random() * 0.6)
                    const sy = root.height * (0.05 + Math.random() * 0.3)
                    meteor.x = sx
                    meteor.y = sy
                    meteorX.to = sx + 420 * root.unit
                    meteorY.to = sy + 187 * root.unit
                    meteorRun.restart()
                }
            }
        }
    }

    // Ghosted word behind everything, like a magazine cover.
    Text {
        id: ghost
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20 * root.unit
        text: "COSMOS"
        color: root.ink
        opacity: 0
        scale: 1.04
        font.family: root.serif
        font.pixelSize: 430 * root.unit
        font.letterSpacing: 26 * root.unit
        SequentialAnimation on opacity {
            PauseAnimation { duration: root.introDelay }
            NumberAnimation { to: 0.045; duration: 2400; easing.type: Easing.OutCubic }
        }
        NumberAnimation on scale { to: 1; duration: 4000; easing.type: Easing.OutCubic }
    }

    // ----- Planet and orbits -----
    // Same frames, frame rate and scale as the Plymouth dark_planet theme
    // (boot.nix sets DeviceScale=2), so the handover from boot is seamless.
    // The frames get an alpha channel at build time (planet-alpha.py).
    property real planetScale: Number(config.PlanetScale) || 2
    property int planetFrame: 0
    property real orbitT: 0
    NumberAnimation on orbitT { from: 0; to: Math.PI * 2; duration: 46000; loops: Animation.Infinite }
    Timer {
        interval: 30
        running: true
        repeat: true
        onTriggered: root.planetFrame = (root.planetFrame + 1) % 160
    }

    // An elliptical orbit around the planet. Each orbit is drawn twice: the
    // far half below the planet and the near half (front: true) above it.
    component Orbit: Item {
        id: orbit
        property real a: 700 * root.unit      // half-width of the ellipse
        property real e: 0.26                  // vertical squash
        property real phase: 0
        property bool front: false
        property string label: ""
        x: planet.cx
        y: planet.cy
        rotation: -14
        opacity: 0
        SequentialAnimation on opacity {
            PauseAnimation { duration: root.introDelay + 300 }
            NumberAnimation { to: 1; duration: 1800; easing.type: Easing.OutCubic }
        }
        // Half an ellipse: the far (upper) half or the near (lower) one.
        Canvas {
            x: -orbit.a - 4
            y: -orbit.a * orbit.e - 4
            width: orbit.a * 2 + 8
            height: orbit.a * orbit.e * 2 + 8
            onWidthChanged: requestPaint()
            onPaint: {
                const c = getContext("2d")
                c.reset()
                c.strokeStyle = "rgba(255, 255, 255, 0.22)"
                c.lineWidth = Math.max(1, root.unit)
                c.beginPath()
                for (let i = 0; i <= 240; i++) {
                    const t = (orbit.front ? 0 : Math.PI) + Math.PI * i / 240
                    const px = width / 2 + orbit.a * Math.cos(t)
                    const py = height / 2 + orbit.a * orbit.e * Math.sin(t)
                    if (i === 0) c.moveTo(px, py)
                    else c.lineTo(px, py)
                }
                c.stroke()
            }
        }
        Item {
            readonly property real t: root.orbitT + orbit.phase
            visible: (Math.sin(t) > 0) === orbit.front
            x: orbit.a * Math.cos(t)
            y: orbit.a * orbit.e * Math.sin(t)
            rotation: -orbit.rotation
            Rectangle {
                x: -width / 2
                y: -height / 2
                width: 7 * root.unit
                height: width
                radius: width / 2
                color: root.gold
            }
            Rectangle {
                x: -width / 2
                y: -height / 2
                width: 19 * root.unit
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: "#66e2b26a"
            }
            Text {
                x: 14 * root.unit
                y: -height - 4 * root.unit
                text: orbit.label
                color: root.gold
                font.family: root.mono
                font.pixelSize: 10 * root.unit
                font.letterSpacing: 2 * root.unit
            }
        }
    }

    Orbit { a: 640 * root.unit; e: 0.24; label: "SAT-01" }
    Orbit { a: 430 * root.unit; e: 0.3; rotation: -22; phase: 2.4; label: "SAT-02" }

    Item {
        id: planet
        property real cx: root.width / 2
        property real cy: root.height / 2
        width: 467 * root.planetScale
        height: 350 * root.planetScale
        x: cx - width / 2
        y: cy - height / 2
        Image {
            anchors.fill: parent
            source: "planet/progress-" + root.planetFrame + ".png"
            smooth: true
            cache: false
        }
    }

    Orbit { a: 640 * root.unit; e: 0.24; front: true; label: "SAT-01" }
    Orbit { a: 430 * root.unit; e: 0.3; rotation: -22; phase: 2.4; front: true; label: "SAT-02" }

    ParallelAnimation {
        id: dockPlanet
        NumberAnimation { target: planet; property: "cx"; to: root.width * 0.66; duration: 1500; easing.type: Easing.InOutCubic }
        NumberAnimation { target: planet; property: "cy"; to: root.height * 0.47; duration: 1500; easing.type: Easing.InOutCubic }
    }
    Timer { interval: 450; running: true; onTriggered: dockPlanet.start() }
    ParallelAnimation {
        id: undockPlanet
        NumberAnimation { target: planet; property: "cx"; to: root.width / 2; duration: 800; easing.type: Easing.InOutCubic }
        NumberAnimation { target: planet; property: "cy"; to: root.height / 2; duration: 800; easing.type: Easing.InOutCubic }
        NumberAnimation { target: sky; property: "opacity"; to: 0; duration: 800 }
        NumberAnimation { target: ghost; property: "opacity"; to: 0; duration: 400 }
    }

    // Clicking anywhere returns focus to the password line.
    MouseArea {
        anchors.fill: parent
        onClicked: password.forceActiveFocus()
    }

    // ----- Building blocks -----
    // Fades and lifts its content in after `delay` ms (plus the intro).
    component Reveal: Item {
        id: r
        property int delay: 0
        opacity: 0
        transform: Translate { id: lift; y: 16 * root.unit }
        SequentialAnimation {
            running: true
            PauseAnimation { duration: r.delay + root.introDelay }
            ParallelAnimation {
                NumberAnimation { target: r; property: "opacity"; to: 1; duration: 1000; easing.type: Easing.OutCubic }
                NumberAnimation { target: lift; property: "y"; to: 0; duration: 1000; easing.type: Easing.OutCubic }
            }
        }
    }
    component Mono: Text {
        color: root.muted
        font.family: root.mono
        font.pixelSize: 11 * root.unit
        font.letterSpacing: 2.2 * root.unit
    }
    component Action: Mono {
        id: action
        signal activated()
        color: hover.containsMouse ? root.ink : root.muted
        Behavior on color { ColorAnimation { duration: 140 } }
        MouseArea {
            id: hover
            anchors.fill: parent
            anchors.margins: -8 * root.unit
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.activated()
        }
    }
    // A fixed pseudo-random barcode, purely decorative.
    component Barcode: Row {
        spacing: 2 * root.unit
        height: 22 * root.unit
        Repeater {
            model: [3,1,1,2,1,3,1,1,2,2,1,1,3,1,2,1,1,1,3,2,1,2,1,1,3,1,1,2,1,3,2,1,1,2]
            Rectangle {
                width: modelData * root.unit
                height: 22 * root.unit
                color: root.ink
                opacity: index % 7 === 3 ? 0.35 : 0.75
            }
        }
    }

    Item {
        id: ui
        anchors.fill: parent
        opacity: root.uiOpacity
        readonly property real margin: 112 * root.unit

        // ----- Top rail -----
        Reveal {
            delay: 500
            x: ui.margin
            y: 52 * root.unit
            width: parent.width - ui.margin * 2
            height: 30 * root.unit
            Mono {
                text: "◐  " + root.title.toUpperCase() + "  //  NIXOS"
                color: root.ink
            }
            Mono {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "ORBIT 01 — DARK PLANET"
            }
            Row {
                anchors.right: parent.right
                spacing: 26 * root.unit
                Action {
                    text: "[ SESSION ]"
                    onActivated: {
                        if (sessionModel.rowCount() > 0)
                            root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                    }
                }
                Action { text: "[ REBOOT ]"; onActivated: sddm.reboot() }
                Action { text: "[ SHUTDOWN ]"; onActivated: sddm.powerOff() }
            }
            // Hairline with ticks under the rail.
            Rectangle {
                y: 26 * root.unit
                width: parent.width
                height: 1
                color: "#22ffffff"
            }
            Repeater {
                model: 25
                Rectangle {
                    x: index * (parent.width - 1) / 24
                    y: 22 * root.unit
                    width: 1
                    height: (index % 6 === 0 ? 9 : 5) * root.unit
                    color: index % 6 === 0 ? "#66ffffff" : "#26ffffff"
                }
            }
        }

        // ----- Clock -----
        Reveal {
            id: clock
            delay: 150
            x: ui.margin - 10 * root.unit
            y: 150 * root.unit
            width: clockRow.width
            height: clockRow.height + dateText.height + metaText.height + 30 * root.unit

            Row {
                id: clockRow
                spacing: 10 * root.unit
                Text {
                    text: {
                        const h = root.now.getHours()
                        return root.pad(root.use24h ? h : ((h + 11) % 12 + 1))
                    }
                    color: root.ink
                    font.family: root.sans
                    font.weight: Font.Light
                    font.pixelSize: 250 * root.unit
                    font.letterSpacing: -10 * root.unit
                }
                Column {
                    y: 52 * root.unit
                    spacing: 6 * root.unit
                    Text {
                        text: root.pad(root.now.getMinutes())
                        color: root.ink
                        font.family: root.sans
                        font.weight: Font.Medium
                        font.pixelSize: 84 * root.unit
                    }
                    Mono {
                        text: "· " + root.pad(root.now.getSeconds()) + (root.use24h ? "" : (root.now.getHours() < 12 ? "  AM" : "  PM"))
                        color: root.gold
                        font.pixelSize: 14 * root.unit
                    }
                }
            }
            Text {
                id: dateText
                anchors.top: clockRow.bottom
                anchors.topMargin: -18 * root.unit
                x: 12 * root.unit
                text: {
                    const s = root.now.toLocaleDateString(root.locale, "dddd, d MMMM")
                    return s.charAt(0).toUpperCase() + s.slice(1)
                }
                color: root.ink
                font.family: root.serif
                font.italic: true
                font.pixelSize: 40 * root.unit
            }
            Mono {
                id: metaText
                anchors.top: dateText.bottom
                anchors.topMargin: 12 * root.unit
                x: 14 * root.unit
                text: root.utcOffset() + "  ·  " + root.now.getFullYear() + "  ·  WEEK " + root.pad(root.weekNumber())
            }
        }

        // ----- Name card -----
        Reveal {
            id: card
            delay: 450
            x: ui.margin
            width: 520 * root.unit
            height: cardColumn.height + 64 * root.unit
            y: parent.height - height - 104 * root.unit
            property bool denied: false

            Rectangle {
                anchors.fill: parent
                color: "#0affffff"
                border.width: 1
                border.color: card.denied ? "#99ff9b8a" : "#2effffff"
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }
            // Gold corner marks.
            Repeater {
                model: 4
                Item {
                    readonly property bool onLeft: index % 2 === 0
                    readonly property bool onTop: index < 2
                    x: onLeft ? -1 : card.width - width + 1
                    y: onTop ? -1 : card.height - height + 1
                    width: 11 * root.unit
                    height: width
                    Rectangle {
                        width: parent.width
                        height: Math.max(1, 1.5 * root.unit)
                        y: parent.onTop ? 0 : parent.height - height
                        color: root.gold
                    }
                    Rectangle {
                        width: Math.max(1, 1.5 * root.unit)
                        height: parent.height
                        x: parent.onLeft ? 0 : parent.width - width
                        color: root.gold
                    }
                }
            }

            Column {
                id: cardColumn
                x: 32 * root.unit
                y: 30 * root.unit
                width: card.width - 64 * root.unit
                spacing: 4 * root.unit

                Mono {
                    text: "OPERATOR — 01"
                    color: root.gold
                    font.pixelSize: 10 * root.unit
                }
                Text {
                    text: root.title
                    color: root.ink
                    font.family: root.serif
                    font.pixelSize: 78 * root.unit
                    font.letterSpacing: 1 * root.unit
                }
                Text {
                    text: "a quiet signal from the dark side of the planet"
                    color: root.muted
                    font.family: root.serif
                    font.italic: true
                    font.pixelSize: 19 * root.unit
                }
                Item { width: 1; height: 26 * root.unit }

                // Password line.
                Item {
                    id: passLine
                    width: parent.width
                    height: 34 * root.unit
                    property real shake: 0
                    transform: Translate { x: passLine.shake }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10 * root.unit
                        Mono {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "PASSPHRASE"
                            visible: password.text.length === 0
                            opacity: 0.6
                        }
                        Repeater {
                            model: Math.min(22, password.text.length)
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7 * root.unit
                                height: width
                                rotation: 45
                                color: root.gold
                            }
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(1, 1.5 * root.unit)
                            height: 20 * root.unit
                            color: root.ink
                            visible: password.activeFocus
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { to: 0; duration: 500; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: card.denied ? root.danger : "#40ffffff"
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: password.activeFocus ? parent.width : 0
                        height: Math.max(1, 1.5 * root.unit)
                        color: card.denied ? root.danger : root.gold
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    }
                }
                Item { width: 1; height: 18 * root.unit }

                Item {
                    width: parent.width
                    height: 24 * root.unit
                    Barcode { anchors.verticalCenter: parent.verticalCenter }
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 18 * root.unit
                        Mono {
                            visible: keyboard.capsLock
                            text: "CAPS"
                            color: root.danger
                        }
                        Mono {
                            visible: text.length > 0
                            text: keyboard.layouts.length > 1 ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : ""
                        }
                        Action {
                            text: card.denied ? "DENIED  ↺" : "UNLOCK  ↵"
                            color: card.denied ? root.danger : root.ink
                            onActivated: root.login()
                        }
                    }
                }
            }
        }

        // ----- Telemetry -----
        Reveal {
            delay: 700
            width: telemetry.width
            height: telemetry.height
            x: parent.width - width - ui.margin
            y: parent.height - height - 104 * root.unit
            Grid {
                id: telemetry
                columns: 2
                columnSpacing: 34 * root.unit
                rowSpacing: 10 * root.unit
                Mono { text: "TARGET" }
                Mono { text: "DARK PLANET"; color: root.ink }
                Mono { text: "PERIOD" }
                Mono { text: "4.80 S"; color: root.ink }
                Mono { text: "SATELLITES" }
                Mono { text: "02 IN ORBIT"; color: root.ink }
                Mono { text: "SESSION" }
                Mono {
                    color: root.ink
                    text: (sessionList.itemAt(root.sessionIndex) ? sessionList.itemAt(root.sessionIndex).name : "—").toUpperCase()
                }
                Mono { text: "STATUS" }
                Mono {
                    text: root.status
                    color: root.status === "ACCESS DENIED" ? root.danger : root.gold
                }
            }
        }

        // Vertical edge label.
        Reveal {
            delay: 900
            x: 44 * root.unit
            y: root.height * 0.62
            Mono {
                rotation: -90
                transformOrigin: Item.TopLeft
                text: "N 00°00′00″  ·  SECTOR 7G  ·  " + root.title.toUpperCase()
                opacity: 0.55
                font.pixelSize: 10 * root.unit
            }
        }
    }

    // Session names, read through a Repeater since the model has no getter.
    Repeater {
        id: sessionList
        model: sessionModel
        Item { property string name: model.name }
    }

    TextInput {
        id: password
        width: 1
        height: 1
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        Keys.onReturnPressed: root.login()
        Keys.onEnterPressed: root.login()
        Keys.onEscapePressed: text = ""
        onTextChanged: {
            card.denied = false
            if (root.status === "ACCESS DENIED") root.status = "AWAITING OPERATOR"
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: passLine; property: "shake"; to: -14 * root.unit; duration: 50 }
        NumberAnimation { target: passLine; property: "shake"; to: 12 * root.unit; duration: 70 }
        NumberAnimation { target: passLine; property: "shake"; to: -8 * root.unit; duration: 70 }
        NumberAnimation { target: passLine; property: "shake"; to: 4 * root.unit; duration: 60 }
        NumberAnimation { target: passLine; property: "shake"; to: 0; duration: 60 }
    }

    function login() {
        if (password.text.length === 0) {
            shakeAnim.restart()
            return
        }
        root.status = "AUTHENTICATING"
        sddm.login(root.loginUser, password.text, root.sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            root.status = "ACCESS GRANTED"
            root.uiOpacity = 0
            undockPlanet.start()
        }
        function onLoginFailed() {
            password.text = ""
            password.forceActiveFocus()
            card.denied = true
            root.status = "ACCESS DENIED"
            shakeAnim.restart()
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
