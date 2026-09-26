import QtQuick

Rectangle {
    id: swatchPop; objectName: "swatch-popup"
    property var dialog
    property var surface
    property var paper
    property var footer
    // Main.qml walks these for the palette keyboard chain.
    property alias autoDot: autoDot
    property alias swatchRepeater: swatchRepeater
    visible: dialog.paletteOpen && dialog.expanded
    // Clamped into the card so a small window cannot push the row past either
    // border; the dots keep their size and the panel keeps its margin.
    readonly property int dotSize: 22
    // The gap clears two neighbouring focus rings (4 px outside each dot) instead of
    // letting them collide, so an out-of-row ring can never be mistaken for a border.
    readonly property int dotGap: 9
    // Every ring is drawn OUTSIDE its dot, so the scrolled content is inset by that
    // overhang and a ring on the first dot or the top row stays inside the clip.
    readonly property int ringInset: 5
    // The mode label gets a band of its own; the first row starts below it rather
    // than against it.
    readonly property int headerHeight: 21
    // An imported variant offers every token it publishes — around two dozen dots —
    // so the row WRAPS and, past the compact height bound, scrolls. The panel never
    // grows to fit its content, and the bound follows the footer so on a short window
    // the rows still end above it.
    readonly property bool inkMode: dialog.paletteMode === "ink"
    readonly property int maxBodyHeight:
        Math.max(dotSize+2*ringInset, Math.min(92, footer.y - headerHeight - 18))
    readonly property real fullWidth: 12 + 2*ringInset + 8*(dotSize+dotGap) - dotGap
    width: Math.min(fullWidth, paper.width-24)
    x: Math.max(8, Math.min(50, paper.width-width-8))
    // The theme list adds its own band between the header and the dots when open.
    height: headerHeight + 6 + (themeList.open ? themeList.height + 6 : 0)
            + Math.min(maxBodyHeight, swatchFlow.implicitHeight + 2*ringInset)
    y: Math.max(surface.cardTop+6, surface.cardTop + footer.y - height - 6)
    radius: 8; color: paper.color; border.width: 1; border.color: Qt.darker(paper.color,1.3); z: 300
    Accessible.role: Accessible.Grouping
    Accessible.name: (inkMode ? "Note ink · " : "Note paper · ") + dialog.activePalette.label
    // The mode label says which surface a press will assign. The palette name is a
    // CONTROL: clicking the header toggles the theme list, so the chooser lives
    // beside the swatches it repopulates rather than in Settings.
    Text {
        id: modeLabel; objectName: "swatch-mode-label"
        x: 8; y: 4; font.family: dialog.noteFont; font.pixelSize: 9; color: dialog.ink
        text: (swatchPop.inkMode ? "Ink" : "Paper") + " · " + dialog.activePalette.label
             + (swatchPop.inkMode && dialog.inkModes[dialog.selectedId]==="auto" ? " · Auto" : "")
             + (themeList.open ? "  ▴" : "  ▾")
        width: swatchPop.width-16-folderApply.width-10; elide: Text.ElideRight
        MouseArea {
            anchors.fill: parent; anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: themeList.open = !themeList.open
            Accessible.role: Accessible.Button
            Accessible.name: "Choose a colour theme · current " + dialog.activePalette.label
        }
    }
    /** One-time bulk write of THIS note's colour for the current mode into every live
     *  note of the open folder. Arm-then-confirm: the label itself turns into the
     *  question, and a lapse disarms (dialog.confirmFolderColour). */
    Text {
        id: folderApply; objectName: "swatch-apply-folder"
        readonly property int count: dialog.manifest.folderCount !== undefined ? dialog.manifest.folderCount : 0
        anchors.right: parent.right; anchors.rightMargin: 8; y: 4
        font.family: dialog.noteFont; font.pixelSize: 9; color: dialog.ink
        font.underline: dialog.confirmFolderColour
        text: dialog.confirmFolderColour
              ? "Apply to " + count + (count === 1 ? " note?" : " notes?")
              : "Apply to folder"
        MouseArea {
            objectName: "swatch-apply-folder-area"
            anchors.fill: parent; anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: dialog.applyColourToFolder()
            Accessible.role: Accessible.Button
            Accessible.name: dialog.confirmFolderColour
                ? "Confirm: apply this " + (swatchPop.inkMode ? "ink" : "paper") + " to " + folderApply.count + " notes"
                : "Apply this " + (swatchPop.inkMode ? "ink" : "paper") + " to every note in the folder"
            Accessible.onPressAction: dialog.applyColourToFolder()
        }
    }
    /** The theme chooser: every palette as name + its real colours. Mid grey ground,
     *  DELIBERATELY not the note's paper: a neutral mid tone is the only background
     *  that judges light and dark palettes fairly, the same reason photographic grey
     *  cards are 18% grey. */
    Rectangle {
        id: themeList; objectName: "theme-list"
        property bool open: false
        visible: open
        x: 6; y: swatchPop.headerHeight
        width: swatchPop.width-12
        height: Math.min(200, themeCol.implicitHeight + 10)
        radius: 6
        color: "#808080"
        border.width: 1; border.color: "#33ffffff"
        Flickable {
            anchors.fill: parent; anchors.margins: 5
            contentHeight: themeCol.implicitHeight; clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: themeCol
                width: parent.width
                Repeater {
                    model: {
                        // palettes with group separators, in catalog order
                        var rows = [], lastGroup = ""
                        var all = dialog.palettes || []
                        for (var i = 0; i < all.length; i++) {
                            if (all[i].group !== lastGroup) {
                                lastGroup = all[i].group
                                rows.push({header: true, label: lastGroup})
                            }
                            rows.push({header: false, palette: all[i]})
                        }
                        return rows
                    }
                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: themeCol.width
                        // Group captions breathe: a blank line above each later
                        // group so the two catalogs read as separate lists.
                        height: modelData.header ? (index === 0 ? 16 : 26) : 17
                        // group caption, seated at the BOTTOM of its row so the
                        // extra height of a later group reads as a gap above it
                        Text {
                            visible: modelData.header
                            x: 5; anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                            font.family: dialog.noteFont; font.pixelSize: 8
                            font.capitalization: Font.AllUppercase; font.letterSpacing: 0.8
                            color: "#f0f0f0"
                            text: modelData.header ? modelData.label : ""
                        }
                        Rectangle {
                            visible: !modelData.header
                            anchors.fill: parent; radius: 4
                            color: rowArea.containsMouse ? "#8d8d8d"
                                 : (!modelData.header && modelData.palette.key === dialog.palette
                                    ? "#747474" : "transparent")
                        }
                        Text {
                            visible: !modelData.header
                            x: 5; anchors.verticalCenter: parent.verticalCenter
                            width: 66; elide: Text.ElideRight
                            font.family: dialog.noteFont; font.pixelSize: 10
                            color: "#ffffff"
                            text: modelData.header ? "" : modelData.palette.label
                        }
                        Row {
                            visible: !modelData.header
                            x: 76; anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Repeater {
                                model: modelData.header ? [] : modelData.palette.colors
                                delegate: Rectangle {
                                    required property string modelData
                                    width: 10; height: 10; radius: 5
                                    color: modelData
                                    border.width: 1; border.color: "#38000000"
                                }
                            }
                        }
                        MouseArea {
                            id: rowArea
                            visible: !modelData.header
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                dialog.choosePalette(modelData.palette.key)
                                themeList.open = false
                            }
                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.header ? "" : ("Theme " + modelData.palette.label)
                        }
                    }
                }
            }
        }
    }
    Flickable {
        id: swatchScroll
        x: 6; y: swatchPop.headerHeight + (themeList.open ? themeList.height + 6 : 0)
        width: swatchPop.width-12
        height: swatchPop.height - y - 6
        contentHeight: swatchFlow.implicitHeight + 2*swatchPop.ringInset; clip: true
        boundsBehavior: Flickable.StopAtBounds
        Flow {
            id: swatchFlow
            x: swatchPop.ringInset; y: swatchPop.ringInset
            width: swatchScroll.width - 2*swatchPop.ringInset; spacing: swatchPop.dotGap
            // Ink mode leads with Auto, so restoring the derived ink is one press.
            Rectangle {
                id: autoDot; objectName: "swatch-auto"
                visible: swatchPop.inkMode
                readonly property bool selected: dialog.inkModes[dialog.selectedId]==="auto"
                width: swatchPop.dotSize; height: swatchPop.dotSize; radius: width/2
                // An empty library has no selected note, so the ink lookup is
                // undefined and unassignable to a colour; the card's ink stands in.
                color: dialog.inkOf(dialog.selectedId) !== undefined
                       ? dialog.inkOf(dialog.selectedId) : dialog.ink
                border.width: 1; border.color: dialog.neutralWhite
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: "Automatic ink" + (selected ? " · selected" : "")
                Accessible.onPressAction: dialog.chooseInk("auto")
                Keys.onPressed: function(event) {
                    if(event.key===Qt.Key_Space || event.key===Qt.Key_Return || event.key===Qt.Key_Enter) { dialog.chooseInk("auto"); event.accepted=true }
                    else if(event.key===Qt.Key_Right || event.key===Qt.Key_Down || event.key===Qt.Key_Tab) { dialog.moveSwatchFocus(1); event.accepted=true }
                    else if(event.key===Qt.Key_Left || event.key===Qt.Key_Up || event.key===Qt.Key_Backtab) { dialog.moveSwatchFocus(-1); event.accepted=true }
                }
                // No letter: the chip is simply the first dot, painted in the ink
                // Auto would derive. Selection is the same centre mark as any dot.
                Rectangle { objectName: "swatch-mark"
                            anchors.centerIn: parent; visible: autoDot.selected
                            width: 7; height: 7; radius: width/2; color: dialog.paperColor }
                Rectangle { objectName: "swatch-focus"
                            readonly property int dashCount: 3
                            readonly property color cueColor: dialog.neutralWhite
                            anchors.centerIn: parent; width: parent.width+8; height: parent.height+8
                            color: "transparent"; border.width: 0
                            visible: autoDot.activeFocus && dialog.swatchKeyboardCue
                            Row { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
                                  spacing: 3
                                  Repeater { model: 3; delegate: Rectangle { width: 4; height: 2; radius: 1; color: dialog.neutralWhite } } } }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onPressed: dialog.swatchKeyboardCue=false
                            onClicked: dialog.chooseInk("auto") }
            }
            Repeater {
                id: swatchRepeater
                // Ink mode leads with the NEUTRALS — white, light grey, dark grey,
                // black — in every palette: most text wants a neutral, and no theme
                // should take white or black away. Paper mode stays as published.
                model: swatchPop.inkMode
                    ? [{paper:"#ffffff",ink:"#000000",group:"neutral",role:"#ffffff",label:"White"},
                       {paper:"#bfbfbf",ink:"#000000",group:"neutral",role:"#bfbfbf",label:"Light grey"},
                       {paper:"#595959",ink:"#ffffff",group:"neutral",role:"#595959",label:"Dark grey"},
                       {paper:"#000000",ink:"#ffffff",group:"neutral",role:"#000000",label:"Black"}
                      ].concat(dialog.activePalette.swatches)
                    : dialog.activePalette.swatches
                delegate: Rectangle {
                    id: swatchDot
                    required property var modelData
                    // A literal string compare against the note's stored value. When
                    // that value is not in this theme nothing is marked, which is
                    // the honest answer rather than a nearest-match guess.
                    readonly property string current: swatchPop.inkMode
                        ? String(dialog.inkStored[dialog.selectedId])
                        : String(dialog.papers[dialog.selectedId])
                    readonly property bool selected: current===String(modelData.paper)
                    objectName: "swatch-dot"
                    width: swatchPop.dotSize; height: swatchPop.dotSize; radius: width/2
                    color: modelData.paper
                    // ONE ring rule for every dot: a single white hairline. Not a
                    // per-swatch derived tone, not a thicker ring when selected, and
                    // nothing black stamped over a chosen colour. Selection is said
                    // once, by the centre dot below.
                    border.width: 1
                    border.color: dialog.neutralWhite
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: (swatchPop.inkMode ? "Note ink " : "Note paper ")
                        + modelData.label + " " + modelData.paper + (selected ? " · selected" : "")
                    Accessible.onPressAction: dialog.chooseSwatch(swatchDot.modelData.paper)
                    Keys.onPressed: function(event) {
                        if(event.key===Qt.Key_Space || event.key===Qt.Key_Return || event.key===Qt.Key_Enter) {
                            dialog.chooseSwatch(swatchDot.modelData.paper); event.accepted=true
                        }
                        else if(event.key===Qt.Key_Right || event.key===Qt.Key_Down || event.key===Qt.Key_Tab) { dialog.moveSwatchFocus(1); event.accepted=true }
                        else if(event.key===Qt.Key_Left || event.key===Qt.Key_Up || event.key===Qt.Key_Backtab) { dialog.moveSwatchFocus(-1); event.accepted=true }
                    }
                    // Selection is a centre DOT and nothing else — no halo, no second
                    // ring, no checkmark — so at rest the row reads as colours
                    // rather than as decoration.
                    Rectangle {
                        objectName: "swatch-mark"
                        anchors.centerIn: parent; visible: swatchDot.selected
                        width: 7; height: 7; radius: width/2
                        color: swatchDot.modelData.ink
                    }
                    // KEYBOARD cue, and deliberately NOT a ring: a second circle is
                    // near-indistinguishable from the hairline the dot already
                    // carries, so a stale programmatic focus reads as "this swatch is
                    // special" instead of "the keyboard is here". Three short dashes
                    // UNDER the dot, inside the overhang ringInset already reserves,
                    // so they are never clipped and never mistaken for the border.
                    Rectangle {
                        objectName: "swatch-focus"
                        readonly property int dashCount: 3
                        readonly property color cueColor: dialog.neutralWhite
                        anchors.centerIn: parent; width: parent.width+8; height: parent.height+8
                        color: "transparent"; border.width: 0
                        visible: swatchDot.activeFocus && dialog.swatchKeyboardCue
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom; spacing: 3
                            Repeater { model: 3; delegate: Rectangle { width: 4; height: 2; radius: 1; color: dialog.neutralWhite } }
                        }
                    }
                    MouseArea {
                        id: dotArea
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        // A pointer press is never a keyboard action, so it clears the
                        // cue: hovering or clicking can no longer latch one on.
                        onPressed: dialog.swatchKeyboardCue=false
                        onClicked: dialog.chooseSwatch(swatchDot.modelData.paper)
                    }
                }
            }
            // Shown only when the current value is absent from this theme, so an
            // unmatched assignment stays visible rather than unrepresented.
            Rectangle {
                id: currentDot; objectName: "swatch-current"
                visible: swatchPop.inkMode
                    ? (dialog.inkModes[dialog.selectedId]==="explicit" && !dialog.manifest.inkInPalette[dialog.selectedId])
                    : !dialog.paperInPalette(dialog.selectedId)
                width: swatchPop.dotSize; height: swatchPop.dotSize; radius: width/2
                color: swatchPop.inkMode ? dialog.inkStored[dialog.selectedId] : dialog.paperColor
                border.width: 1; border.color: dialog.neutralWhite
                Accessible.role: Accessible.StaticText
                Accessible.name: "Current " + (swatchPop.inkMode ? "ink " : "paper ")
                    + (swatchPop.inkMode ? dialog.inkStored[dialog.selectedId] : dialog.papers[dialog.selectedId])
                    + " · not in " + dialog.activePalette.label
                Text { anchors.centerIn: parent; text: "●"; font.pixelSize: 8
                       color: swatchPop.inkMode ? dialog.paperColor : dialog.ink }
            }
        }
    }
}
