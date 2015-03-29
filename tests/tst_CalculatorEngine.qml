import QtQuick 2.4
import QtTest 1.1
import "../src/qml" as App


Item {

    TestCase {
        id: util
        name: "shared-functions"

        function calculate_and_compare(engine, data) {
            data.forEach(function(element, index) {
                var key = element[0];
                var display = element[1];
                var expression = element[2];
                var result = element[3];
                var msg = "data index " + index + "::";
                engine.process(key);
                compare(engine.display, display, msg + "wrong engine.display");
                compare(engine.expression, expression, msg + "wrong engine.expression");
                compare(engine.result, result, msg + "wrong engine.result");
            });
        }
    }

    TestCase {
        id: offCase
        name: "engine-off"

        property var engine: App.CalculatorEngine {  }

        function test_not_running() {
            wait(10);
            verify(!engine.running);
        }
    }

    TestCase {
        id: onOffCase

        name: "engine-on-off"

        property var engine: App.CalculatorEngine {  }

        property var start: SignalSpy {
            target: onOffCase.engine
            signalName: "started"
        }

        property var stop: SignalSpy {
            target: onOffCase.engine
            signalName: "stopped"
        }

        function test_start_stop() {
            engine.start();
            start.wait(10);
            verify(engine.running);
            compare(engine.display, "0.");
            compare(engine.expression, "");
            compare(engine.result, 0.0);
            engine.stop();
            stop.wait(10);
            verify(!engine.running);
        }
    }

    TestCase {
        id: basicsCase

        name: "engine-basics"

        property var engine: App.CalculatorEngine {  }

        property var start: SignalSpy {
            target: basicsCase.engine
            signalName: "started"
        }

        property var stop: SignalSpy {
            target: basicsCase.engine
            signalName: "stopped"
        }

        function init() {
            engine.start();
            start.wait(10);
        }

        function cleanup() {
            if (engine.running) {
                engine.stop();
                stop.wait(10);
            }
        }

        function test_accumulate() {
            var data = [
                ["1", "1.", "1", 0.0],
                ["2", "12.", "12", 0.0],
                ["3", "123.", "123", 0.0],
            ]
            util.calculate_and_compare(engine, data);
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
