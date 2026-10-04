// Wallpaper picker from github.com/43PR/dotfiles, based on github.com/iamsurjog/hyprquickpaper.
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell.Wayland

PanelWindow {
    id: main

    property int speed: 5000
    property int animDuration: 1000
    property real zoomScale: 0.8
    property real edgeScale: 0.3
    property real skewFactor: 0
    property real baseSpacing: 0
    property real edgeSpacing: 80
    property int startPosition: 4
    property real glideFriction: 0.965   // per 16 ms; closer to 1 glides further
    property bool shadowEnabled: true
    property color shadowColor: "#000000"
    property real shadowOpacity: 0.4
    property real shadowBlur: 0.45
    property real shadowX: 6
    property real shadowY: 6
    property string wallpaperPath: configs.wallpaper_path.replace("$HOME", Quickshell.env("HOME"))
    property string cachePath: configs.cache_path.replace("$HOME", Quickshell.env("HOME"))

    property bool showEmpty: false
    readonly property bool looksEmpty: wallpaperPath !== ""
                                       && folderModel.status === FolderListModel.Ready
                                       && folderModel.count === 0

    onLooksEmptyChanged: {
        if (looksEmpty) {
            emptyDelay.restart()
        } else {
            emptyDelay.stop()
            showEmpty = false
        }
    }

    // Fill the output; Screen.* is in physical pixels and breaks centering on scaled displays.
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    aboveWindows: true
    exclusionMode: "Ignore"
    exclusiveZone: 1
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: Quickshell.execDetached(["bash", Quickshell.shellPath("cache.sh"), Quickshell.shellDir])

    FileView {
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: configs
            property string wallpaper_path
            property string cache_path
            property int number_of_pictures
            property string border_color
        }
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + main.wallpaperPath
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        sortField: FolderListModel.Name
    }

    MouseArea {
        id: outsideClickArea
        anchors.fill: parent
        z: 0
        onClicked: Qt.quit()
    }

    Timer {
        id: emptyDelay
        interval: 300
        onTriggered: main.showEmpty = main.looksEmpty
    }

    Column {
        id: emptyState
        anchors.centerIn: parent
        spacing: 10
        z: 2
        visible: main.showEmpty

        Text {
            text: "No wallpapers found"
            color: "#ffffff"
            font.pixelSize: 22
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Add images to:"
            color: "#aaaaaa"
            font.pixelSize: 13
            anchors.horizontalCenter: parent.horizontalCenter
        }

        TextEdit {
            id: pathText
            text: main.wallpaperPath
            color: "#dddddd"
            font.pixelSize: 14
            readOnly: true
            selectByMouse: true
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ListView {
        id: list
        width: parent.width
        height: 500
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        z: 1
        focus: true
        model: folderModel
        orientation: ListView.Horizontal
        spacing: 0
        clip: true
        cacheBuffer: 400
        boundsBehavior: Flickable.StopAtBounds

        property int selectedIndex: main.startPosition
        readonly property real tileWidth: width / configs.number_of_pictures - 10
        readonly property real viewportCenterX: width / 2
        readonly property real step: tileWidth + main.baseSpacing
        readonly property real sideMargin: Math.max(0, viewportCenterX - tileWidth / 2)
        property bool ready: false
        property bool userMoved: false
        property bool scrolling: false
        property real velocity: 0      // px per ms, from the last finger movement
        property real lastScrollTime: 0

        leftMargin: sideMargin
        rightMargin: sideMargin

        function clampIndex(i) { return Math.max(0, Math.min(i, count - 1)) }
        function centerX(i) { return i * step + step / 2 - viewportCenterX }
        function ensureVisibleAnimated(i) { contentX = centerX(i) }

        function centerOnStart() {
            if (userMoved || count <= 0 || configs.number_of_pictures <= 0) return
            selectedIndex = clampIndex(Math.min(main.startPosition, Math.floor(count / 2)))
            contentX = centerX(selectedIndex)
            ready = true
        }

        function activateCurrent() {
            Quickshell.execDetached(["bash", Quickshell.shellPath("commands.sh"), folderModel.get(selectedIndex, "filePath")])
            Qt.quit()
        }

        // Touchpad: the strip follows two fingers 1:1. When the fingers lift it
        // keeps gliding with the swipe's speed, slows down, and snaps to the
        // wallpaper closest to the center.
        function setScroll(x) {
            const lo = centerX(0), hi = centerX(count - 1)
            contentX = Math.max(lo, Math.min(hi, x))
            selectedIndex = clampIndex(Math.round((contentX + viewportCenterX - step / 2) / step))
            return contentX > lo && contentX < hi
        }

        function scrollBy(dx) {
            if (count <= 0) return
            const now = Date.now()
            const dt = now - lastScrollTime
            lastScrollTime = now
            velocity = dt > 0 && dt < 100 ? 0.6 * (dx / dt) + 0.4 * velocity : 0
            userMoved = true
            scrolling = true
            glideTimer.stop()
            setScroll(contentX + dx)
            liftTimer.restart()
        }

        function finishScroll() {
            glideTimer.stop()
            scrolling = false
            ensureVisibleAnimated(selectedIndex)
        }

        // No events for a moment means the fingers left the touchpad.
        Timer {
            id: liftTimer
            interval: 50
            onTriggered: Math.abs(list.velocity) > 0.3 ? glideTimer.start() : list.finishScroll()
        }

        Timer {
            id: glideTimer
            interval: 16
            repeat: true
            onTriggered: {
                if (!list.setScroll(list.contentX + list.velocity * interval)) return list.finishScroll()
                list.velocity *= main.glideFriction
                if (Math.abs(list.velocity) < 0.3) list.finishScroll()
            }
        }

        function moveSelection(delta, speedMultiplier) {
            anim.velocity = main.speed * speedMultiplier
            selectedIndex = clampIndex(selectedIndex + delta)
            ensureVisibleAnimated(selectedIndex)
        }

        onCountChanged: centerOnStart()
        onWidthChanged: centerOnStart()

        Connections {
            target: configs
            function onNumber_of_picturesChanged() { list.centerOnStart() }
        }

        Behavior on contentX {
            enabled: list.ready && !list.scrolling
            SmoothedAnimation { id: anim; property real velocity: main.speed; duration: main.animDuration }
        }

        delegate: Item {
            id: delegateItem
            width: list.tileWidth
            height: 500

            property bool active: index === list.selectedIndex
            readonly property real baseWidth: list.tileWidth
            readonly property real baseCenterX: x - list.contentX + baseWidth / 2
            readonly property real distance: Math.abs(baseCenterX - list.viewportCenterX)
            readonly property real fraction: Math.min(1, distance / list.viewportCenterX)
            readonly property real compression: { const t = fraction; return t * t * t * t }
            readonly property real edgeOffset: {
                const amount = main.edgeSpacing * compression
                return baseCenterX < list.viewportCenterX ? amount : -amount
            }
            readonly property real scaleFactor: {
                const t = 1 - fraction * fraction * (3 - 2 * fraction)
                return main.edgeScale + (main.zoomScale - main.edgeScale) * t
            }

            Item {
                id: content
                anchors.verticalCenter: parent.verticalCenter
                width: delegateItem.baseWidth * delegateItem.scaleFactor
                height: delegateItem.height * Math.min(1, delegateItem.scaleFactor)
                x: (delegateItem.baseWidth - width) / 2 + delegateItem.edgeOffset

                Image {
                    id: shadowImage
                    x: main.shadowX
                    y: main.shadowY
                    width: parent.width
                    height: parent.height
                    source: img.source
                    sourceSize.width: img.sourceSize.width
                    sourceSize.height: img.sourceSize.height
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    smooth: true
                    visible: main.shadowEnabled
                    opacity: main.shadowOpacity
                    layer.enabled: true
                    layer.effect: MultiEffect { brightness: -1; blurEnabled: true; blur: main.shadowBlur }
                    transform: Shear { xFactor: main.skewFactor }
                }

                Text {
                    id: alt
                    text: ""
                    color: configs.border_color
                    anchors.centerIn: parent
                    font.pixelSize: 16
                    transform: Shear { xFactor: main.skewFactor }
                }

                Image {
                    id: img
                    anchors.fill: parent
                    opacity: 0.95
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    smooth: true
                    source: "file://" + main.cachePath + fileName
                    sourceSize.width: delegateItem.baseWidth * main.zoomScale
                    sourceSize.height: delegateItem.height
                    transform: Shear { xFactor: main.skewFactor }

                    Timer {
                        id: retryTimer
                        interval: 1000
                        repeat: false
                        onTriggered: { const s = img.source; img.source = ""; img.source = s }
                    }

                    onStatusChanged: {
                        if (status === Image.Error) { alt.text = "Caching"; retryTimer.start() }
                    }
                }

                Rectangle {
                    z: 10
                    anchors.fill: parent
                    visible: delegateItem.active
                    color: "transparent"
                    border.width: 2
                    border.color: configs.border_color
                    transform: Shear { xFactor: main.skewFactor }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: list.ready
                onEntered: if (!list.scrolling) { list.userMoved = true; list.selectedIndex = index }
                onClicked: list.activateCurrent()
            }
        }

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Space) {
                activateCurrent()
            } else if (event.key === Qt.Key_W || event.key === Qt.Key_Escape) {
                Qt.quit()
            } else {
                return
            }
            event.accepted = true
        }
    }

    // Horizontal two-finger scrolling over the strip; vertical scrolling is ignored.
    // NoButton lets hover and clicks through to the tiles.
    MouseArea {
        anchors.fill: list
        z: 2
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
            const dx = wheel.pixelDelta.x !== 0 ? wheel.pixelDelta.x : wheel.angleDelta.x / 4
            if (dx !== 0) list.scrollBy(-dx)
            wheel.accepted = true
        }
    }
}