// Clockwork SDDM theme: the login twin of the gtklock lock screen.
// Palette matches ~/.config/sway/clockwork. Needs Qt 6.5+ (QtQuick.Effects).

import QtQuick
import QtQuick.Effects
import QtMultimedia

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: c.base

    // ---------- Clockwork palette ----------
    QtObject {
        id: c
        readonly property color base:    "#050A14"
        readonly property color surface: "#0E1828"
        readonly property color line:    "#1E2C42"
        readonly property color muted:   "#8A9AB0"
        readonly property color text:    "#E9E4DF"
        readonly property color glow:    "#5FD4F0"
        readonly property color frost:   "#9EE8F8"
        readonly property color gold:    "#D4B072"
        readonly property color amber:   "#E8964A"
        readonly property color scarlet: "#E0485C"
    }

    // ---------- Config (theme.conf) ----------
    function cfg(key, fallback) {
        var v = config[key]
        return (v === undefined || v === null || v === "") ? fallback : String(v)
    }
    readonly property bool useVideo: cfg("useVideo", "true") === "true"
    readonly property real dim: parseFloat(cfg("dim", "0.25"))

    FontLoader { id: mono;     source: "fonts/JetBrainsMonoNerdFontMono-Regular.ttf" }
    FontLoader { id: monoBold; source: "fonts/JetBrainsMonoNerdFontMono-Bold.ttf" }
    readonly property string fontName: mono.status === FontLoader.Ready ? mono.name : "monospace"
    function icon(cp) { return String.fromCodePoint(cp) }

    // ---------- Users and sessions ----------
    property var users: []
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property var sessions: []
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

    Repeater {
        model: userModel
        Item {
            Component.onCompleted: {
                var u = root.users.slice()
                u[index] = { name: model.name, real: model.realName || model.name }
                root.users = u
            }
        }
    }
    Repeater {
        model: sessionModel
        Item {
            Component.onCompleted: {
                var s = root.sessions.slice()
                s[index] = model.name
                root.sessions = s
            }
        }
    }
    readonly property string userName: users.length ? users[userIndex].name : userModel.lastUser
    readonly property string userLabel: users.length ? users[userIndex].real : userModel.lastUser
    readonly property string sessionName: sessions.length ? sessions[sessionIndex] : "Session"

    // ---------- Background: still underneath, video on top ----------
    Item {
        id: background
        anchors.fill: parent

        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl(root.cfg("background", "background.png"))
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        Video {
            anchors.fill: parent
            visible: root.useVideo
            source: root.useVideo ? Qt.resolvedUrl(root.cfg("video", "background.webm")) : ""
            fillMode: VideoOutput.PreserveAspectCrop
            loops: MediaPlayer.Infinite
            muted: true
            autoPlay: true
        }
        Rectangle { anchors.fill: parent; color: c.base; opacity: root.dim }
    }


    // ---------- The glass box ----------
    Item {
        id: box
        width: 520
        height: column.implicitHeight + 72
        anchors.centerIn: parent
        transform: Translate { id: shake }

        // Frosted glass: the box's slice of the background, blurred and
        // masked to rounded corners, then tinted.
        ShaderEffectSource {
            id: boxSource
            sourceItem: background
            sourceRect: Qt.rect(box.x, box.y, box.width, box.height)
            live: true
            visible: false
        }
        Rectangle {
            id: glassMask
            anchors.fill: parent
            radius: 16
            visible: false
            layer.enabled: true
        }
        MultiEffect {
            anchors.fill: parent
            source: boxSource
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            maskEnabled: true
            maskSource: glassMask
        }
        Rectangle { anchors.fill: parent; radius: 16; color: c.base; opacity: 0.55 }
        Rectangle {
            anchors.fill: parent
            radius: 16
            color: "transparent"
            border.color: c.glow
            border.width: 2
        }

        Column {
            id: column
            anchors.centerIn: parent
            width: parent.width - 72
            spacing: 14

            // Avatar
            Item {
                width: 112; height: 112
                anchors.horizontalCenter: parent.horizontalCenter
                Image {
                    id: avatar
                    anchors.fill: parent
                    source: Qt.resolvedUrl(root.cfg("avatar", "avatar.png"))
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                    layer.enabled: true
                }
                Rectangle {
                    id: avatarMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {
                    anchors.fill: parent
                    source: avatar
                    maskEnabled: true
                    maskSource: avatarMask
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: c.glow
                    border.width: 2
                }
            }

            // User name (click the arrows to switch user when there are several)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                Text {
                    visible: root.users.length > 1
                    text: root.icon(0xf0141)
                    color: prevUser.containsMouse ? c.frost : c.muted
                    font { family: root.fontName; pixelSize: 18 }
                    MouseArea {
                        id: prevUser
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: root.userIndex = (root.userIndex - 1 + root.users.length) % root.users.length
                    }
                }
                Text {
                    text: root.userLabel
                    color: c.text
                    font { family: root.fontName; pixelSize: 18; bold: true }
                }
                Text {
                    visible: root.users.length > 1
                    text: root.icon(0xf0142)
                    color: nextUser.containsMouse ? c.frost : c.muted
                    font { family: root.fontName; pixelSize: 18 }
                    MouseArea {
                        id: nextUser
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: root.userIndex = (root.userIndex + 1) % root.users.length
                    }
                }
            }

            // Clock and date
            Text {
                id: clock
                anchors.horizontalCenter: parent.horizontalCenter
                color: c.frost
                font { family: monoBold.status === FontLoader.Ready ? monoBold.name : root.fontName; pixelSize: 72; bold: true }
                text: Qt.formatDateTime(new Date(), "HH:mm")
            }
            Text {
                id: date
                anchors.horizontalCenter: parent.horizontalCenter
                color: c.gold
                font { family: root.fontName; pixelSize: 18 }
                text: Qt.formatDateTime(new Date(), "dddd, dd MMMM")
            }
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: {
                    clock.text = Qt.formatDateTime(new Date(), "HH:mm")
                    date.text = Qt.formatDateTime(new Date(), "dddd, dd MMMM")
                }
            }

            Item { width: 1; height: 6 }

            // Password
            Rectangle {
                id: field
                width: parent.width
                height: 46
                radius: 8
                color: Qt.rgba(0.02, 0.04, 0.08, 0.9)
                border.color: password.activeFocus ? c.frost : c.line
                border.width: 2

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 52
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    color: c.frost
                    selectionColor: c.glow
                    selectedTextColor: c.base
                    font { family: root.fontName; pixelSize: 18 }
                    clip: true
                    focus: true
                    onAccepted: root.login()
                    onTextChanged: if (text.length) message.text = ""
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    visible: password.text.length === 0
                    text: "Password"
                    color: c.muted
                    font { family: root.fontName; pixelSize: 16 }
                }
                // Go button
                Rectangle {
                    width: 36; height: 36; radius: 6
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: go.containsMouse ? c.frost : c.glow
                    Text {
                        anchors.centerIn: parent
                        text: root.icon(0xf0054)
                        color: c.base
                        font { family: root.fontName; pixelSize: 20 }
                    }
                    MouseArea { id: go; anchors.fill: parent; hoverEnabled: true; onClicked: root.login() }
                }
            }

            // Errors and caps lock
            Text {
                id: message
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: c.scarlet
                font { family: root.fontName; pixelSize: 15; bold: true }
                text: ""
                visible: text.length > 0
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                visible: keyboard.capsLock
                text: root.icon(0xf030e) + "  Caps Lock is on"
                color: c.amber
                font { family: root.fontName; pixelSize: 15; bold: true }
            }
        }

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
            NumberAnimation { target: shake; property: "x"; to: 12; duration: 70 }
            NumberAnimation { target: shake; property: "x"; to: -8; duration: 70 }
            NumberAnimation { target: shake; property: "x"; to: 0; duration: 60 }
        }
    }

    // ---------- Bottom bar: session (left), power (right) ----------
    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 10
        Text {
            text: root.icon(0xf0379) + "  " + root.sessionName
            color: sessionArea.containsMouse ? c.frost : c.text
            font { family: root.fontName; pixelSize: 16 }
            MouseArea {
                id: sessionArea
                anchors.fill: parent; hoverEnabled: true
                onClicked: if (root.sessions.length) root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length
            }
        }
        Text {
            visible: root.sessions.length > 1
            text: "(click to change)"
            color: c.muted
            font { family: root.fontName; pixelSize: 13 }
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 22
        Repeater {
            model: [
                { glyph: 0xf0904, label: "Sleep",     ok: sddm.canSuspend,  run: function() { sddm.suspend() } },
                { glyph: 0xf0709, label: "Restart",   ok: sddm.canReboot,   run: function() { sddm.reboot() } },
                { glyph: 0xf0425, label: "Shut down", ok: sddm.canPowerOff, run: function() { sddm.powerOff() } }
            ]
            delegate: Item {
                visible: modelData.ok
                width: buttonCol.implicitWidth
                height: buttonCol.implicitHeight
                Column {
                    id: buttonCol
                    spacing: 4
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.icon(modelData.glyph)
                        color: area.containsMouse ? (index === 2 ? c.scarlet : c.frost) : c.text
                        font { family: root.fontName; pixelSize: 26 }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: c.muted
                        font { family: root.fontName; pixelSize: 12 }
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: modelData.run()
                }
            }
        }
    }

    // ---------- Login ----------
    function login() {
        message.text = ""
        sddm.login(root.userName, password.text, root.sessionIndex)
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            message.text = root.icon(0xf05d6) + "  Wrong password, try again"
            shakeAnim.restart()
            password.forceActiveFocus()
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
