import QtQuick 2.4
import QtTest 1.1
import "../src/qml" as App


Item {

    TestCase {
        name: "engine-off"

        App.CalculatorEngine { id: engineOff }

        function test_not_running() {
            wait(10);
            verify(!engineOff.running);
        }
    }

    TestCase {
        name: "engine"

        App.CalculatorEngine { id: engine }

        SignalSpy {
            id: spy
            target: engine
            signalName: "started"
        }

        function init() {
            engine.start();
            spy.wait(10);
        }

        function cleanup() {
            engine.stop();
        }

        function test_running() {
            verify(engine.running);
        }

        function test_basic_addition() {
            engine.process("2");
            engine.process("+");
            engine.process("2");
            engine.process("=");
            compare(engine.display, "4.");
            compare(engine.result, 4);
        }

        function test_repeated_equals() {
            engine.process("2");
            engine.process("+");
            engine.process("3");
            engine.process("*");
            engine.process("4");
            engine.process("=");
            engine.process("=");
            engine.process("=");
            compare(engine.display, "38.");
            compare(engine.result, 38);
        }
    }
}
