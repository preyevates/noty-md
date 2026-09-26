import QtQuick
import org.kde.iconthemes as KIconThemes

/** Note icon — destination chooser, then KDE's own picker.
 *
 * An inline grid can only ever show a render-capped slice of a theme holding tens of
 * thousands of names, and `KIconThemes.IconDialog` already provides search, category
 * filters and the whole theme. This panel asks the one question the platform dialog
 * cannot — where the icon should GO. */
Rectangle {
    property var dialog
    property var surface
    id: iconPanel; objectName: "icon-panel"
    visible: dialog.iconPanelOpen && dialog.expanded; z:400
    x:58; y:surface.cardTop+50; width:Math.min(300, dialog.cardWidth-84)
    height: iconPanelColumn.implicitHeight + 20; radius:8
    color: Qt.lighter(dialog.paperColor,1.04); border.width:1; border.color: Qt.darker(dialog.paperColor,1.3)
    Accessible.role: Accessible.Grouping
    Accessible.name: "Note icon"
    Column {
        id: iconPanelColumn
        x:12; y:10; width: parent.width-24; spacing:8
        Text {
            text: "Note icon"
            font.family:dialog.noteFont; font.pixelSize:11
            font.weight:Font.DemiBold; color:dialog.ink
        }
        Text {
            width: iconPanelColumn.width
            text: "Put the icon on:"
            wrapMode: Text.WordWrap
            font.family:dialog.noteFont; font.pixelSize:10
            color: dialog.derivedTone(dialog.paperColor, 0.45)
        }
        Row {
            spacing: 14
            Repeater {
                model: [{key:"tab", label:"Tab"}, {key:"note", label:"Into note"},
                        {key:"inline", label:"Wrap text"}]
                /** An Item root, not a Row: a Row delegate cannot host the
                 *  anchors.fill MouseArea a checkbox needs (positioner children
                 *  refuse fill anchors and the whole Row stops functioning). */
                delegate: Item {
                    required property var modelData
                    readonly property bool on: modelData.key === "tab" ? dialog.iconToTab
                        : modelData.key === "note" ? dialog.iconToNote : dialog.iconInline
                    // "Wrap text" only means something when the icon goes INTO the note.
                    opacity: modelData.key === "inline" && !dialog.iconToNote ? 0.45 : 1.0
                    width: box.width + 6 + tag.implicitWidth
                    height: 20
                    Rectangle {
                        id: box
                        width: 15; height: 15; radius: 3
                        y: 2
                        color: on ? dialog.ink : "transparent"
                        border.width: 1
                        border.color: on ? dialog.ink : dialog.derivedTone(dialog.paperColor, 0.35)
                        Text {
                            anchors.centerIn: parent; visible: on
                            text: "\u2713"; font.pixelSize: 11; color: dialog.paperColor
                        }
                    }
                    Text {
                        id: tag
                        x: box.width + 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        font.family: dialog.noteFont; font.pixelSize: 11; color: dialog.ink
                    }
                    Accessible.role: Accessible.CheckBox
                    Accessible.name: modelData.label + (on ? ", on" : ", off")
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: dialog.setIconDestination(modelData.key)
                    }
                }
            }
        }
        Item { width: 1; height: 2 }
        /** The primary action: hand off to the platform. */
        Rectangle {
            objectName: "icon-choose"
            width: iconPanelColumn.width; height: 30; radius: 5
            color: chooseHover.hovered ? dialog.derivedTone(dialog.paperColor, 0.16)
                                       : dialog.derivedTone(dialog.paperColor, 0.09)
            border.width: 1; border.color: dialog.derivedTone(dialog.paperColor, 0.3)
            Text {
                anchors.centerIn: parent
                text: "Choose icon\u2026"
                font.family: dialog.noteFont; font.pixelSize: 11
                font.weight: Font.DemiBold; color: dialog.ink
            }
            HoverHandler { id: chooseHover }
            Accessible.role: Accessible.Button
            Accessible.name: "Choose an icon"
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: kdeIconDialog.open()
            }
        }
        /** Clearing is a separate, quieter verb than choosing. */
        Text {
            objectName: "icon-clear"
            visible: dialog.iconOf(dialog.selectedId) !== ""
            text: "Remove this note\u2019s tab icon"
            font.family:dialog.noteFont; font.pixelSize:10
            font.underline: clearHover.hovered
            color: dialog.derivedTone(dialog.paperColor, 0.5)
            HoverHandler { id: clearHover }
            Accessible.role: Accessible.Button
            Accessible.name: "Remove this note's tab icon"
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: dialog.setNoteIcon("") }
        }
        KIconThemes.IconDialog {
            id: kdeIconDialog
            onIconNameChanged: function (iconName) {
                if (iconName === "") return   // cancelled
                dialog.applyIcon({relative: "theme:" + iconName, name: iconName})
                dialog.iconPanelOpen = false
            }
        }
    }
}
