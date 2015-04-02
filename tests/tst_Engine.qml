import QtQuick 2.4
import QtTest 1.1
import "../src/qml" as App


Item {

    TestCase {
        id: util
        name: "shared-functions"

        function calculate_and_compare(engine, data) {
            // data is an array of arrays with [key, display, expression, result].
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

        function process(engine, keys) {
            // keys can be a string, which will be split, or an array of strings.
            if (typeof keys == "string") {
                keys = keys.split(" ");
            }
            keys.forEach(function(key, index) {
                engine.process(key);
            });
        }
    }

    TestCase {
        id: offCase
        name: "engine-off"

        property var engine: App.Engine {  }

        function test_not_running() {
            wait(10);
            verify(!engine.running);
        }
    }

    TestCase {
        id: onOffCase
        name: "engine-on-off"

        property var engine: App.Engine {  }

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

        property var engine: App.Engine {  }

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

        function test_max_significant_digits() {
            util.process(engine, "0 . 0 0 0 2 + 6 4 =");
            // Max is 13 because at 14 significant digits
            // this evaluates to: 64.00020000000001
            compare(engine.display, "64.0002");
            compare(engine.result, 64.0002);
            util.process(engine, "c");
        }

        function test_basic_accumulate() {
            var data = [ // key, display, expression, result // index
                ["1", "1.", "1", 0], // 0
                ["+", "1.", "1 +", 1], // 1
                ["2", "2.", "1 + 2", 1], // 2
                ["=", "3.", "1 + 2 = 3", 3], // 3
                ["*", "3.", "3 *", 3], // 4
                ["4", "4.", "3 * 4", 3], // 5
                ["=", "12.", "3 * 4 = 12", 12], // 6
            ];
            util.calculate_and_compare(engine, data);
        }

        function test_accumulate() {
            var data = [ // key, display, expression, result // index
                ["0", "0.", "", 0], // 0
                ["1", "1.", "1", 0], // 1
                ["2", "12.", "12", 0], // 2
                ["3", "123.", "123", 0], // 3
                [".", "123.", "123.", 0], // 4
                ["4", "123.4", "123.4", 0], // 5
                ["5", "123.45", "123.45", 0], // 6
                ["0", "123.450", "123.450", 0], // 7
                ["6", "123.4506", "123.4506", 0], // 8
                ["7", "123.45067", "123.45067", 0], // 9
                ["7", "123.450677", "123.450677", 0], // 10
                ["7", "123.4506777", "123.4506777", 0], // 11
                ["+", "123.4506777", "123.4506777 +", 123.4506777], // 12
                ["-", "123.4506777", "123.4506777 -", 123.4506777], // 13
                ["*", "123.4506777", "123.4506777 *", 123.4506777], // 14
                ["8", "8.", "123.4506777 * 8", 123.4506777], // 15
                ["=", "987.6054216", "123.4506777 * 8 = 987.6054216", 987.6054216], // 16
                ["0", "0.", "0", 987.6054216], // 17
                ["=", "0.", "0", 987.6054216], // 18
                ["C", "0.", "", 0], // 19
                ["1", "1.", "1", 0], // 20
                ["+", "1.", "1 +", 1], // 21
                ["2", "2.", "1 + 2", 1], // 22
                ["=", "3.", "1 + 2 = 3", 3], // 23
                ["4", "4.", "4", 3], // 24
                ["5", "45.", "45", 3], // 25
                ["C", "0.", "", 0], // 26
                [".", "0.", "0.", 0], // 27
                ["1", "0.1", "0.1", 0], // 28
                ["+", "0.1", "0.1 +", 0.1], // 29
                ["0", "0.", "0.1 + 0", 0.1], // 30
                [".", "0.", "0.1 + 0.", 0.1], // 31
                ["2", "0.2", "0.1 + 0.2", 0.1], // 32
                ["=", "0.3", "0.1 + 0.2 = 0.3", 0.3], // 33
            ];
            util.calculate_and_compare(engine, data);
        }

        function test_basic_addition() {
            util.process(engine, "2 + 2 =");
            compare(engine.display, "4.");
            compare(engine.result, 4);
        }

        function test_addition_subtraction() {
            util.process(engine, "2 . 3 4 + 5 . 0 0 0 1 =");
            compare(engine.display, "7.3401");
            compare(engine.result, 7.3401);
            util.process(engine, "- 6 . 0 0 0 1 =");
            compare(engine.display, "1.34");
            compare(engine.result, 1.34);
        }

        function test_repeated_equals() {
            var keys = "2 + 3 * 4 = = =";
            util.process(engine, keys);
            compare(engine.display, "14.");
            compare(engine.result, 14);
            engine.config.equalKeyRepeatsLastOperation = true;
            util.process(engine, "c");
            util.process(engine, keys);
            compare(engine.display, "38.");
            compare(engine.result, 38);
        }
    }
}
