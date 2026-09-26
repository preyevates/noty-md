import QtQuick
import QtWebEngine
import QtWebChannel

// The card's web editor: the local index.html deck in an off-the-record, link-routing view.
WebEngineView {
    id: web
    property var editorHost
    property WebChannel editorChannel
    backgroundColor: "transparent"
    function resume(index) { web.forceActiveFocus(); web.runJavaScript("window.fan && fan.select("+index+")") }
    function suspend() { web.runJavaScript("window.fan && fan.suspend()") }
    webChannel: editorChannel
    profile: WebEngineProfile { offTheRecord: true; httpCacheType: WebEngineProfile.MemoryHttpCache }
    settings.localContentCanAccessRemoteUrls: false
    settings.localContentCanAccessFileUrls: true
    settings.localStorageEnabled: true
    settings.javascriptCanOpenWindows: false
    settings.pdfViewerEnabled: false
    url: Qt.resolvedUrl("index.html")
    onNavigationRequested: function(request) {
        const target = request.url.toString().split("?")[0]
        const allowed = target === Qt.resolvedUrl("index.html").toString() || (!request.isMainFrame && target === Qt.resolvedUrl("editor.html").toString())
        if(allowed) return
        // Everything else is a LINK followed inside a note. It never navigates this
        // view — the card is an editor, not a browser — but it is not silently
        // dropped either: every scheme is routed by followLink().
        request.reject()
        editorHost.followLink(request.url.toString())
    }
    // Links inside a note render with target=_blank, so they arrive HERE rather than
    // at onNavigationRequested, where a note-to-note click only logs
    // BLOCK_NEW_WINDOW. Both entry points route through the same followLink().
    onNewWindowRequested: function(request) { editorHost.followLink(request.requestedUrl.toString()) }
    /** The toolbar's Record button calls getUserMedia({audio}), and Chromium waits on
     *  the EMBEDDER's answer — there is no page-side prompt. Microphone capture from
     *  the app's own local editor page is granted; every other permission is denied
     *  explicitly so nothing waits forever on a question nobody will be shown. */
    onPermissionRequested: function(permission) {
        // Numeric on purpose: QWebEnginePermission::MediaAudioCapture == 1, and the
        // QML name lookup (WebEnginePermission.MediaAudioCapture) resolves to
        // undefined in this Qt, so grant() never runs and Record stays dead.
        if (permission.permissionType === 1)
            permission.grant()
        else
            permission.deny()
    }
    onJavaScriptConsoleMessage: function(level,message) { console.warn("Fan Fold [editor]:", message) }
}
