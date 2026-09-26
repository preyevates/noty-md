import QtQuick
import QtQuick.Controls

Rectangle {
    id: emptyState
    property var dialog
    property var surface
    property var rootFolderDialog
    objectName: "empty-state"
    visible: dialog.order.length === 0 && !dialog.expanded
    y: surface.cardTop
    width: dialog.cardWidth; height: dialog.cardHeight
    radius: dialog.appearance.radius
    color: dialog.neutralBg
    border.width: 1
    border.color: dialog.neutralOutline
    z: 120
    /** One themed button rule for this panel: raised charcoal, accent on hover. */
    component WelcomeButton: Rectangle {
        id: wb
        property string label: ""
        property bool prominent: false
        signal activated()
        width: Math.max(140, wbText.implicitWidth + 32); height: 34; radius: 6
        color: wbArea.containsMouse ? Qt.lighter(dialog.neutralBg, 2.0)
                                    : (wb.prominent ? Qt.lighter(dialog.neutralBg, 1.7)
                                                    : Qt.lighter(dialog.neutralBg, 1.35))
        border.width: 1
        border.color: wbArea.containsMouse ? dialog.neutralAccent : dialog.neutralOutline
        Accessible.role: Accessible.Button
        Accessible.name: wb.label
        Text {
            id: wbText
            anchors.centerIn: parent
            font.family: dialog.neutralFont; font.pixelSize: 12
            font.weight: wb.prominent ? Font.DemiBold : Font.Normal
            color: dialog.neutralText
            text: wb.label
        }
        MouseArea {
            id: wbArea
            anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: wb.activated()
        }
    }
    Column {
        x: 28; y: 24; width: parent.width - 56; spacing: 10
        Row {
            spacing: 10
            Image {
                width: 34; height: 34
                source: appIconSource && appIconSource !== "" ? appIconSource : ""
                visible: String(source) !== ""
                sourceSize.width: 68; sourceSize.height: 68
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: dialog.neutralFont; font.pixelSize: 18; font.weight: Font.DemiBold
                color: dialog.neutralText
                text: "Fan Fold"
            }
        }
        Text {
            objectName: "empty-state-headline"
            width: parent.width; wrapMode: Text.Wrap
            font.family: dialog.neutralFont; font.pixelSize: 13
            color: dialog.neutralText
            text: dialog.searchActive
                ? ("No notes match “" + dialog.manifest.searchQuery + "”.")
                : dialog.libraryIsEmpty
                ? "This folder has no notes yet."
                : (dialog.folderIsEmpty
                    ? ("\u201C" + dialog.openFolderLabel + "\u201D has no notes yet.")
                    : ("Nothing from \u201C" + dialog.openFolderLabel + "\u201D is on the fan right now."))
        }
        Text {
            objectName: "empty-state-folder"
            width: parent.width; wrapMode: Text.Wrap; elide: Text.ElideMiddle
            font.family: dialog.neutralFont; font.pixelSize: 10
            color: dialog.neutralText; opacity: 0.7
            // The library root, plus the open subfolder when the fan is scoped
            // into one: "no notes here" is only answerable if you can see where
            // "here" is.
            text: shellControl.rootPath
                ? ("Notes folder:  " + shellControl.rootPath
                   + (dialog.openFolder === "" ? "" : ("/" + dialog.openFolder)))
                : "No folder has been chosen yet."
        }
        // What the application IS and how each part is reached, not one sentence
        // about files.
        Text {
            width: parent.width; wrapMode: Text.Wrap
            font.family: dialog.neutralFont; font.pixelSize: 11; color: dialog.neutralText
            opacity: 0.85
            lineHeight: 1.25
            text: dialog.searchActive
                ? "Clear the Library search to return to the folder that was open before."
                : dialog.libraryIsEmpty
                ? "Your notes live as ordinary Markdown files in the folder above — nothing is locked away.\n"
                  + "• Each note is a coloured tab on the fan at the screen edge; hover the edge to spread them.\n"
                  + "• The + above the fan creates a note; the footer inside a note holds colours, Library, pin, archive.\n"
                  + "• The tray icon gives New note, Show the fan and Quit at any time."
                : (dialog.folderIsEmpty
                    ? "The fan shows one folder at a time. Your other notes are safe in the Library — open a folder there to fan it.\n"
                      + "The + creates a note in this folder."
                    : "This folder's notes are still there — archived, or open in pinned windows.\n"
                      + "Open the Library to bring one back, or create a new note here.")
        }
        Row {
            spacing: 8
            WelcomeButton {
                objectName: "empty-state-create"
                prominent: true
                label: dialog.libraryIsEmpty ? "Create the first note" : "Create a note"
                onActivated: dialog.createNoteOnFan(true)
            }
            WelcomeButton {
                objectName: "empty-state-library"
                visible: !dialog.libraryIsEmpty
                label: "Open the Library"
                onActivated: dialog.toggleLibrary()
            }
            WelcomeButton {
                objectName: "empty-state-root"
                // One press back to the top-level notes, without hunting for the
                // Library's root row. Pointless when already at the root.
                visible: !dialog.libraryIsEmpty && dialog.openFolder !== ""
                label: "Back to all notes"
                onActivated: dialog.scopeToFolder("")
            }
            WelcomeButton {
                objectName: "empty-state-folder-btn"
                label: shellControl.rootPath ? "Change folder…" : "Choose folder…"
                onActivated: rootFolderDialog.open()
            }
        }
        Text {
            objectName: "empty-state-error"
            // Startup failures AND action refusals. createNoteOnFan reports through
            // saveStatus, which normally lives in the note footer — the footer this
            // panel exists precisely because you cannot see. Repeating it here makes a
            // failed "Create the first note" distinguishable from a dead button.
            readonly property bool actionError: dialog.saveStatus !== "" && dialog.saveStatus !== "Saved" && dialog.saveStatus !== "Unsaved"
            visible: startupError.length > 0 || actionError
            width: parent.width; wrapMode: Text.Wrap
            font.family: dialog.neutralFont; font.pixelSize: 10
            color: dialog.danger !== undefined ? dialog.danger : "#dd8a7c"
            text: startupError.length > 0 ? startupError : dialog.saveStatus
        }
    }
}
