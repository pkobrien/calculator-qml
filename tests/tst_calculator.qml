import QtQuick 2.4
import QtTest 1.1
import "../src/qml" as App


Item {

    TestCase {
        name: "csm-off"

        App.CalculatorStateMachine { id: csmOff }

        function test_not_running() {
            wait(10);
            verify(!csmOff.running);
        }
    }

    TestCase {
        name: "csm"

        App.CalculatorStateMachine { id: csm }

        SignalSpy {
            id: spy
            target: csm
            signalName: "started"
        }

        function init() {
            csm.start();
            spy.wait(10);
        }

        function cleanup() {
            csm.stop();
        }

        function test_running() {
            verify(csm.running);
        }

        function test_basic_addition() {
            csm.process("2");
            csm.process("+");
            csm.process("2");
            csm.process("=");
            compare(csm.display, "4");
            compare(csm.result, 4);
        }

        function test_repeated_equals() {
            csm.process("2");
            csm.process("+");
            csm.process("3");
            csm.process("*");
            csm.process("4");
            csm.process("=");
            csm.process("=");
            csm.process("=");
            compare(csm.display, "38");
            compare(csm.result, 38);
        }
    }
}
