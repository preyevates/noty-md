import QtQuick
import QtQuick.Window

// Never discard dirty editors; always require an explicit decision. Fixed neutral charcoal
// and softwhite, frameless like the card, because the question is chrome: it looks the same
// over a cream note and a near-black one. Cancel is the focused default.
Window {
    id: closeWindow
    property var dialog
    property var interactiveLimit
    visible:dialog.closeRequested; transientParent:dialog; width:510; height:176
    // A frameless child, like the card, but it keeps its title for the window list and
    // the accessibility tree.
    flags: Qt.Dialog | Qt.FramelessWindowHint
    title:"Close Fan Fold?"; color:dialog.neutralBg
    onClosing: function(close) { if(!dialog.allowDiscard){close.accepted=false;dialog.closeRequested=false;interactiveLimit.restart()} }
    /** Cancel is the safe answer, so it is what Escape and the frameless window's
     *  absent close button both mean. Nothing is discarded on this path. */
    function cancel() { dialog.closeRequested=false; interactiveLimit.restart() }
    onVisibleChanged: if(visible) continueButton.forceActiveFocus()
    Rectangle {
        anchors.fill: parent; color: dialog.neutralBg
        border.width: 1; border.color: dialog.neutralOutline
        focus: true
        Keys.onEscapePressed: function(event) { closeWindow.cancel(); event.accepted=true }
        Text { objectName:"close-prompt-title"; x:18; y:14; width:474
               font.family:dialog.neutralFont; font.pixelSize:14; font.bold:true; color:dialog.neutralText
               text:"Close or continue?" }
        Text { objectName:"close-prompt-body"; x:18; y:40; width:474; wrapMode:Text.Wrap
               font.family:dialog.neutralFont; font.pixelSize:12; color:dialog.neutralText
               text:dialog.closeSaveError ? dialog.closeSaveError :
                    (dialog.dirty ? "Unsaved edits exist. Closing discards them; saved .md files remain. Cancel to save each edited note first." : "Close Fan Fold? Your saved .md files remain on disk.") }
        // The safe choice keeps the quiet, note-derived fill of every other control here.
        Rectangle {
            id: continueButton; objectName:"close-prompt-cancel"
            x:20; y:120; width:210; height:36; radius:6
            color: cancelArea.containsMouse ? Qt.lighter(dialog.neutralBg,1.9) : Qt.lighter(dialog.neutralBg,1.5)
            border.width:1; border.color: dialog.neutralOutline
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: "Continue · cancel close (Escape)"
            Accessible.onPressAction: closeWindow.cancel()
            Keys.onPressed: function(event) {
                if(event.key===Qt.Key_Space || event.key===Qt.Key_Return || event.key===Qt.Key_Enter) { closeWindow.cancel(); event.accepted=true }
            }
            Text { anchors.centerIn:parent; font.family:dialog.neutralFont; font.pixelSize:12; color:dialog.neutralText
                   text:"Continue / cancel close" }
            Rectangle { anchors.centerIn:parent; width:parent.width+8; height:parent.height+8; radius:8
                        color:"transparent"; visible:continueButton.activeFocus
                        border.width:2; border.color:dialog.neutralAccent }
            MouseArea { id: cancelArea; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
                        onClicked: closeWindow.cancel() }
        }
        // The destructive choice is never the focused default, and never hidden either:
        // it carries the heaviest edge in the panel and says exactly what it discards.
        Rectangle {
            id: discardButton; objectName:"close-prompt-discard"
            x:250; y:120; width:240; height:36; radius:6
            color: discardArea.containsMouse ? Qt.lighter(dialog.neutralBg,2.4) : Qt.lighter(dialog.neutralBg,2.0)
            border.width:2; border.color: dialog.neutralOutline
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: "Close and discard unsaved edits"
            Accessible.onPressAction: { dialog.requestDiscardClose() }
            Keys.onPressed: function(event) {
                if(event.key===Qt.Key_Space || event.key===Qt.Key_Return || event.key===Qt.Key_Enter) { dialog.requestDiscardClose(); event.accepted=true }
            }
            Text { anchors.centerIn:parent; font.family:dialog.neutralFont; font.pixelSize:12; font.bold:true
                   color:dialog.neutralText; text:"Close (discard unsaved edits)" }
            Rectangle { anchors.centerIn:parent; width:parent.width+8; height:parent.height+8; radius:8
                        color:"transparent"; visible:discardButton.activeFocus
                        border.width:2; border.color:dialog.neutralAccent }
            MouseArea { id: discardArea; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
                        onClicked: { dialog.requestDiscardClose() } }
        }
    }
}
