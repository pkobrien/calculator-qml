import QtQuick 2.4
import "." as App

QtObject {
    id: engine

    // Public API

    readonly property string display: __csm.display
    readonly property string expression: __csm.expression
    readonly property real result: __csm.result
    readonly property bool running: __csm.running

    readonly property var process: __csm.process
    readonly property var start: __csm.start
    readonly property var stop: __csm.stop

    readonly property var started: __csm.started
    readonly property var stopped: __csm.stopped

    // Private Internals

    property var __csm: App.CalculatorStateMachine {  }
}
