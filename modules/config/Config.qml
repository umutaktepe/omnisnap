pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string configDir: `${Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")}/omnisnap`
    readonly property string configPath: `${configDir}/config.json`

    // Configuration Properties with defaults
    property string maxResolution: ""          // "" = Unlimited, or "1920x1080>", "2560x1440>"
    property string saveDirectory: "~/Pictures/Screenshots"
    property string fileFormat: "png"          // "png", "jpg", "webp"
    property int imageQuality: 90              // 1 - 100
    property bool copyToClipboard: true
    property bool saveToFile: true
    property bool showGuides: true
    property bool inhibitScreenEdges: true
    property string defaultAction: "copy"      // "copy", "edit", "search", "ocr"
    property string ocrLanguages: ""           // "" = auto-detect all
    property bool shutterSound: false

    // Shortcut Properties with defaults
    property string shortcutRegion: "Print"
    property string shortcutWindow: "Meta+Print"
    property string shortcutFullScreen: "Shift+Print"
    property string shortcutSettings: "Meta+Shift+Print"

    property bool loaded: false

    function shortcutsBin() {
        const base = Quickshell.shellDir || ".";
        return base + "/bin/omnisnap-shortcuts";
    }

    function applyKdeShortcuts() {
        Quickshell.execDetached([root.shortcutsBin(), "apply-defaults"]);
    }

    function setKdeShortcut(action, key) {
        Quickshell.execDetached([root.shortcutsBin(), "set", action, key]);
    }

    function toJsonString() {
        const obj = {
            "maxResolution": root.maxResolution,
            "saveDirectory": root.saveDirectory,
            "fileFormat": root.fileFormat,
            "imageQuality": root.imageQuality,
            "copyToClipboard": root.copyToClipboard,
            "saveToFile": root.saveToFile,
            "showGuides": root.showGuides,
            "inhibitScreenEdges": root.inhibitScreenEdges,
            "defaultAction": root.defaultAction,
            "ocrLanguages": root.ocrLanguages,
            "shutterSound": root.shutterSound,
            "shortcutRegion": root.shortcutRegion,
            "shortcutWindow": root.shortcutWindow,
            "shortcutFullScreen": root.shortcutFullScreen,
            "shortcutSettings": root.shortcutSettings
        };
        return JSON.stringify(obj, null, 2);
    }

    function applyJson(jsonStr) {
        if (!jsonStr || jsonStr.trim() === "") return;
        try {
            const data = JSON.parse(jsonStr);
            if (data.maxResolution !== undefined) root.maxResolution = data.maxResolution;
            if (data.saveDirectory !== undefined) root.saveDirectory = data.saveDirectory;
            if (data.fileFormat !== undefined) root.fileFormat = data.fileFormat;
            if (data.imageQuality !== undefined) root.imageQuality = data.imageQuality;
            if (data.copyToClipboard !== undefined) root.copyToClipboard = data.copyToClipboard;
            if (data.saveToFile !== undefined) root.saveToFile = data.saveToFile;
            if (data.showGuides !== undefined) root.showGuides = data.showGuides;
            if (data.inhibitScreenEdges !== undefined) root.inhibitScreenEdges = data.inhibitScreenEdges;
            if (data.defaultAction !== undefined) root.defaultAction = data.defaultAction;
            if (data.ocrLanguages !== undefined) root.ocrLanguages = data.ocrLanguages;
            if (data.shutterSound !== undefined) root.shutterSound = data.shutterSound;
            if (data.shortcutRegion !== undefined) root.shortcutRegion = data.shortcutRegion;
            if (data.shortcutWindow !== undefined) root.shortcutWindow = data.shortcutWindow;
            if (data.shortcutFullScreen !== undefined) root.shortcutFullScreen = data.shortcutFullScreen;
            if (data.shortcutSettings !== undefined) root.shortcutSettings = data.shortcutSettings;
        } catch (e) {
            console.warn("[Omnisnap Config] Failed to parse config.json:", e);
        }
    }

    function save() {
        const safeDir = root.configDir.replace(/'/g, "'\\''");
        const safePath = root.configPath.replace(/'/g, "'\\''");
        const jsonContent = root.toJsonString().replace(/'/g, "'\\''");

        Quickshell.execDetached([
            "bash", "-c",
            `mkdir -p '${safeDir}' && printf '%s\n' '${jsonContent}' > '${safePath}'`
        ]);
    }

    function load() {
        loadProcess.running = true;
    }

    property Process _loadProcess: Process {
        id: loadProcess
        command: [
            "bash", "-c",
            `if [ -f '${root.configPath.replace(/'/g, "'\\''")}' ]; then cat '${root.configPath.replace(/'/g, "'\\''")}'; else echo '{}'; fi`
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.applyJson(text);
                root.loaded = true;
            }
        }
    }

    Component.onCompleted: {
        root.load();
        Quickshell.execDetached([root.shortcutsBin(), "install-desktop"]);
    }
}
