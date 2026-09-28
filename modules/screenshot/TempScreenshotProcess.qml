import QtQuick
import Quickshell
import Quickshell.Io

Process {
    id: screenshotProc

    required property ShellScreen screen

    property string screenshotDir: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/omnisnap`
    property string screenshotPath: `${screenshotDir}/screen-${screen.name}.png`

    readonly property string _safeDir: screenshotDir.split("'").join("'\\''")
    readonly property string _safePath: screenshotPath.split("'").join("'\\''")

    running: true
    command: [
        "bash", "-c",
        `mkdir -p '${_safeDir}' && spectacle -b -n -m -o '${_safePath}'`
    ]
}
