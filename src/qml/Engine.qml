import QtQuick 2.4
import "." as App

QtObject {
    id: engine

    // Public API

    readonly property var config: __sm.config

    readonly property string display: __sm.display
    readonly property string expression: __sm.expression
    readonly property real result: __sm.result
    readonly property bool running: __sm.running

    readonly property var process: __sm.process
    readonly property var start: __sm.start
    readonly property var stop: __sm.stop

    readonly property var started: __sm.started
    readonly property var stopped: __sm.stopped

    // Private Internals

    property var __sm: App.StateMachine {  }
}
