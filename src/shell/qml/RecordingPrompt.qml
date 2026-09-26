import QtQuick
import QtQuick.Controls

/** "Name this recording" — shown every time a recording stops, before it is written.
 *  It covers the editor because the answer decides whether the clip is kept at all:
 *  Save writes it, Discard throws the audio away, no third outcome is left around. */
Rectangle {
    property var dialog
    property var surface
    property var bridge
    id: recordingPrompt
    function open(purpose) {
        bridge.recordingName = ""
        headline.text = purpose && purpose.length ? purpose : "Name this recording"
        nameField.text = ""
        visible = true
        nameField.forceActiveFocus()
    }
    function finish(name) {
        visible = false
        bridge.recordingName = name === "" ? "\u0000" : name
    }
    x: 42; y: surface.cardTop+46
    width: dialog.cardWidth-58; height: dialog.cardHeight-46-surface.actionSize-16
    visible: false; z: 60
    color: dialog.paperColor
    radius: dialog.appearance.radius
    // Swallow clicks so nothing reaches the editor behind the prompt.
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
    Column {
        anchors.centerIn: parent
        width: Math.min(360, parent.width-48)
        spacing: 12
        Text {
            id: headline
            text: "Name this recording"
            color: dialog.ink
            font.family: dialog.noteFont; font.pixelSize: 15; font.weight: Font.DemiBold
        }
        TextField {
            id: nameField
            objectName: "recording-name"
            width: parent.width
            color: dialog.ink
            font.family: dialog.noteFont; font.pixelSize: 14
            selectByMouse: true
            placeholderText: "what it is about"
            placeholderTextColor: Qt.rgba(dialog.ink.r, dialog.ink.g, dialog.ink.b, 0.45)
            leftPadding: 6; rightPadding: 6; topPadding: 4; bottomPadding: 4
            Accessible.name: "Recording name; Enter to save, Escape to discard"
            background: Rectangle {
                color: "transparent"; radius: 3
                border.width: 1
                border.color: Qt.rgba(dialog.ink.r, dialog.ink.g, dialog.ink.b, 0.30)
            }
            // Enter saves; Escape discards. Both work without the mouse because the
            // field already holds focus when the prompt opens.
            Keys.onReturnPressed: if(nameField.text.trim() !== "") recordingPrompt.finish(nameField.text.trim())
            Keys.onEnterPressed: if(nameField.text.trim() !== "") recordingPrompt.finish(nameField.text.trim())
            Keys.onEscapePressed: recordingPrompt.finish("")
        }
        Row {
            spacing: 8
            QuietButton {
                glyph: "document-save"; explanation: "Save recording"
                ink: dialog.ink; size: 28
                enabled: nameField.text.trim() !== ""
                opacity: enabled ? 1 : 0.4
                onClicked: recordingPrompt.finish(nameField.text.trim())
            }
            QuietButton {
                glyph: "edit-delete"; explanation: "Discard recording"
                ink: dialog.ink; size: 28
                onClicked: recordingPrompt.finish("")
            }
        }
    }
}
