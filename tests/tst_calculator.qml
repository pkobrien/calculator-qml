import QtQuick 2.4
import QtTest 1.1
import "../src/qml" as App

TestCase {
    name: "csm"

    App.CalculatorStateMachine { id: csm }

    function init() {
    }

    function cleanup() {
    }

    function test_running() {
        verify(!csm.running, "!csm.running");
    }
}
