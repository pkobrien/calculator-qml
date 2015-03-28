import QtQuick 2.4
import QtQml.StateMachine 1.0 as DSM
import "." as App

DSM.StateMachine {
    id: external

    // Public API

    property string display
    property string expression

    property real result

    function process(input) {
        return internal.process(input);
    }

    // Private Internals

    QtObject {
        id: internal

        property string buffer
        property string errorMessage
        property string key
        property real operand1
        property real operand2
        property string operator1
        property string operator2
        property real result

        signal addsubPressed()
        signal clearPressed()
        signal digitPressed()
        signal equalPressed()
        signal muldivPressed()
        signal pointPressed()
        signal zeroPressed()

        onResultChanged: external.result = internal.result;

        function process(input) {
            key = input;
            var accepted = true;
            switch (key) {
                default:
                    accepted = false;
                    break;
                case "1": case "2": case "3": case "4": case "5": case "6": case "7": case "8": case "9":
                    digitPressed();
                    break;
                case "0":
                    zeroPressed();
                    break;
                case ".":
                    pointPressed();
                    break;
                case "c":
                    clearPressed();
                    break;
                case "=":
                    equalPressed();
                    break;
                case "+": case "-":
                    addsubPressed();
                    break;
                case "*": case "/":
                    muldivPressed();
                    break;
            }
            return accepted;
        }

        function calculateAll() {
            var num = Number(buffer.valueOf());
            if (operator2) {
                switch (operator2) {
                    case "*":
                        num *= operand2;
                        break;
                    case "/":
                        num /= operand2;
                        break;
                }
                buffer = num.toString();
                operand2 = 0.00;
                operator2 = "";
            }
            if (operator1) {
                switch (operator1) {
                    case "+":
                        operand1 += num;
                        break;
                    case "-":
                        operand1 -= num;
                        break;
                    case "*":
                        operand1 *= num;
                        break;
                    case "/":
                        operand1 /= num;
                        break;
                }
            } else {
                operand1 = num;
            }
            result = operand1;
        }

        function calculateLast() {
            var num = Number(buffer.valueOf());
            if (operator2) {
                switch (operator2) {
                    case "*":
                        operand2 *= num;
                        break;
                    case "/":
                        operand2 /= num;
                        break;
                }
                operator2 = "";
            } else if (operator1) {
                switch (operator1) {
                    case "*":
                        operand1 *= num;
                        operator1 = "";
                        break;
                    case "/":
                        operand1 /= num;
                        operator1 = "";
                        break;
                    case "+": case "-":
                        operand2 = num;
                        break;
                }
            } else {
                operand1 = num;
            }
        }
    }

    /* TODO

    Currently infix. Should also support postfix (RPN). And maybe Tenkey.

    "00" and "000" keys for entering large numbers.

    MC	Memory Clear
    M+	Memory Addition
    M-	Memory Subtraction
    MR	Memory Recall
    C or AC	All Clear
    CE	Clear (last) Entry; sometimes called CE/C: a first press clears the last entry (CE), a second press clears all (C)
    ±	Toggle positive/negative number

    */

    initialState: clearState

    DSM.State {
        id: clearState

        initialState: accumulateState

        onEntered: reset();

        function reset() {
            // Public
            external.display = "";
            external.expression = "";
            // Private
            internal.buffer = "";
            internal.errorMessage = "";
            internal.key = "";
            internal.operand1 = 0.0;
            internal.operand2 = 0.0;
            internal.operator1 = "";
            internal.operator2 = "";
            internal.result = 0.0;
        }

        DSM.SignalTransition {
            signal: internal.clearPressed
            targetState: clearState
        }

        DSM.State {
            id: errorState
            onEntered: external.display = Qt.binding(function() { return internal.errorMessage; });
        }

        DSM.State {
            id: accumulateState
            initialState: zeroState

            onEntered: external.display = Qt.binding(show);

            function accumulate() { internal.buffer += internal.key; }

            function show() {
                return internal.buffer.indexOf(".") === -1 ?
                       internal.buffer + "." : internal.buffer;
            }

            DSM.SignalTransition {
                signal: internal.digitPressed
                targetState: digitState
            }
            DSM.SignalTransition {
                signal: internal.pointPressed
                targetState: pointState
            }
            DSM.SignalTransition {
                signal: internal.addsubPressed
                targetState: operatorState
                onTriggered: internal.calculateAll();
            }
            DSM.SignalTransition {
                signal: internal.muldivPressed
                targetState: operatorState
                onTriggered: internal.calculateLast();
            }
            DSM.SignalTransition {
                signal: internal.equalPressed
                targetState: resultState
                guard: internal.operator1
            }

            DSM.State {
                id: digitState
                onEntered: {
                    internal.buffer = (internal.buffer === "0") ? internal.key : internal.buffer + internal.key;
                }
                DSM.SignalTransition {
                    signal: internal.zeroPressed
                    onTriggered: accumulateState.accumulate();
                }
            }

            DSM.State {
                id: pointState
                onEntered: {
                    internal.buffer = internal.buffer ? internal.buffer + "." : "0.";
                }
                DSM.SignalTransition {
                    signal: internal.digitPressed
                    onTriggered: accumulateState.accumulate();
                }
                DSM.SignalTransition {
                    signal: internal.pointPressed
                }
                DSM.SignalTransition {
                    signal: internal.zeroPressed
                    onTriggered: accumulateState.accumulate();
                }
            }

            DSM.State {
                id: zeroState
                onEntered: {
                    internal.buffer = "0";
                }
                DSM.SignalTransition {
                    signal: internal.zeroPressed
                }
            }
        }

        DSM.State {
            id: computeState

            DSM.SignalTransition {
                signal: internal.digitPressed
                targetState: digitState
            }
            DSM.SignalTransition {
                signal: internal.pointPressed
                targetState: pointState
            }
            DSM.SignalTransition {
                signal: internal.zeroPressed
                targetState: zeroState
            }

            DSM.State {
                id: operatorState

                onEntered: {
                    updateOperator();
                    external.display = Qt.binding(show);
                }
                onExited: {
                    internal.buffer = "";
                }

                function show() {
                    return internal.operator2 ? internal.buffer : internal.operand1.toString();
                }

                function updateOperator() {
                    if (internal.operand2) {
                        internal.operator2 = internal.key;
                    } else {
                        internal.operator1 = internal.key;
                    }
                }

                DSM.SignalTransition {
                    signal: internal.addsubPressed
                    onTriggered: operatorState.updateOperator();
                }
                DSM.SignalTransition {
                    signal: internal.muldivPressed
                    onTriggered: operatorState.updateOperator();
                }
                DSM.SignalTransition {
                    signal: internal.equalPressed
                    targetState: resultState
                    onTriggered: {
                        internal.buffer = internal.operand1.toString();
                        internal.operand2 = 0.00;
                        internal.operator2 = "";
                    }
                }
            }

            DSM.State {
                id: resultState

                onEntered: {
                    internal.calculateAll();
                    external.display = Qt.binding(function() { return internal.result.toString(); });
                }
                onExited: {
                    internal.buffer = "0";
                    internal.operator1 = "";
                }
                DSM.SignalTransition {
                    signal: internal.equalPressed
                    onTriggered: {
                        // Repeat the last operation using
                        // previous buffer and operator.
                        internal.calculateAll();
                    }
                }
                DSM.SignalTransition {
                    signal: internal.addsubPressed
                    targetState: operatorState
                }
                DSM.SignalTransition {
                    signal: internal.muldivPressed
                    targetState: operatorState
                }
            }
        }
    }
}
