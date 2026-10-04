import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"

IconImage {
    id: root

    property string name: ""
    property int size: 24
    property color color: Theme.text

    implicitSize: size

    function getSystemIconName(iconName: string): string {
        switch (iconName) {
            case "screenshot":
                return "applets-screenshooter";
            case "content_cut":
                return "edit-cut";
            case "edit":
                return "document-edit";
            case "brush":
                return "draw-brush";
            case "search":
                return "system-search";
            case "image_search":
                return "insert-image";
            case "ocr":
                return "edit-find-replace";
            case "text_fields":
                return "draw-text";
            case "fullscreen":
                return "view-fullscreen";
            case "check":
                return "dialog-ok";
            case "close":
                return "window-close";
            case "desktop_windows":
                return "video-display";
            case "settings":
                return "preferences-system";
            default:
                return iconName;
        }
    }

    source: root.name ? Quickshell.iconPath(root.getSystemIconName(root.name), "image-missing") : ""
}
