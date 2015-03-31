import QtQuick 2.4
import QtQml.StateMachine 1.0 as DSM

DSM.StateMachine {
    id: sm

    property alias config: config

    property string buffer
    property string display
    property string errorMessage
    property string expression
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

    function accumulate() {
        buffer = (buffer === "0") ? "" : buffer;
        buffer = (!buffer && key === ".") ? "0" : buffer;
        buffer = (!key) ? "0" : buffer;
        buffer += key;
        expression += key;
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

    function process(input) {
        key = input;
        var accepted = true;
        switch (key) {
            default:
                accepted = false;
                break;
            case "1": case "2": case "3":
            case "4": case "5": case "6":
            case "7": case "8": case "9":
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

    function reset() {
        display = "";
        expression = "";
        buffer = "";
        errorMessage = "";
        key = "";
        operand1 = 0.0;
        operand2 = 0.0;
        operator1 = "";
        operator2 = "";
        result = 0.0;
    }

    function updateOperator() {
        if (operand2) {
            if (operator2) {
                expression = (expression.slice(-2, -1) === operator2) ?
                             expression.slice(0, -3) : expression;
            }
            operator2 = key;
        } else {
            if (operator1) {
                expression = (expression.slice(-2, -1) === operator1) ?
                             expression.slice(0, -3) : expression;
            }
            operator1 = key;
        }
        expression += " %1 ".arg(key);
    }

    function withTrailingDecimal(value) {
        return value.indexOf(".") === -1 ? value + "." : value;
    }

    /* TODO

    Currently infix. Should also support postfix (RPN). And maybe Tenkey.

    "00" and "000" keys for entering large numbers.

    MC	Memory Clear
    M+	Memory Addition
    M-	Memory Subtraction
    MR	Memory Recall
    C or AC	All Clear
    CE	Clear (last) Entry; sometimes called CE/C:
        a first press clears the last entry (CE), a second press clears all (C)
    ±	Toggle positive/negative number

    */

    QtObject {
        id: config

        property bool equalKeyRepeatsLastOperation: false
    }

    initialState: clearState

    DSM.State {
        id: clearState

        initialState: accumulateState

        onEntered: reset();

        DSM.SignalTransition {
            signal: clearPressed
            targetState: clearState
        }

        DSM.State {
            id: errorState
            onEntered: display = Qt.binding(show);

            function show() {
                return errorMessage;
            }
        }

        DSM.State {
            id: accumulateState
            initialState: zeroState

            onEntered: {
                display = Qt.binding(show);
            }

            function show() {
                return withTrailingDecimal(buffer);
            }

            DSM.SignalTransition {
                signal: addsubPressed
                targetState: operatorState
                onTriggered: calculateAll();
            }
            DSM.SignalTransition {
                signal: muldivPressed
                targetState: operatorState
                onTriggered: calculateLast();
            }
            DSM.SignalTransition {
                signal: equalPressed
                guard: operator1
                targetState: resultState
            }

            DSM.State {
                id: digitState
                onEntered: accumulate();
                DSM.SignalTransition {
                    signal: digitPressed
                    onTriggered: accumulate();
                }
                DSM.SignalTransition {
                    signal: pointPressed
                    targetState: pointState
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                    onTriggered: accumulate();
                }
            }

            DSM.State {
                id: pointState
                onEntered: accumulate();
                DSM.SignalTransition {
                    signal: digitPressed
                    onTriggered: accumulate();
                }
                DSM.SignalTransition {
                    signal: pointPressed
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                    onTriggered: accumulate();
                }
            }

            DSM.State {
                id: zeroState
                onEntered: accumulate();
                DSM.SignalTransition {
                    signal: digitPressed
                    targetState: digitState
                }
                DSM.SignalTransition {
                    signal: pointPressed
                    targetState: pointState
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                }
            }
        }

        DSM.State {
            id: computeState

            DSM.SignalTransition {
                signal: digitPressed
                targetState: digitState
            }
            DSM.SignalTransition {
                signal: pointPressed
                targetState: pointState
            }
            DSM.SignalTransition {
                signal: zeroPressed
                targetState: zeroState
            }

            DSM.State {
                id: operatorState

                onEntered: {
                    updateOperator();
                    display = Qt.binding(show);
                }

                onExited: clear();

                function clear() {
                    buffer = "";
                }

                function show() {
                    var value = operator2 ? buffer : operand1.toString();
                    return withTrailingDecimal(value);
                }

                DSM.SignalTransition {
                    signal: addsubPressed
                    onTriggered: updateOperator();
                }
                DSM.SignalTransition {
                    signal: muldivPressed
                    onTriggered: updateOperator();
                }
                DSM.SignalTransition {
                    signal: equalPressed
                    targetState: resultState
                    onTriggered: {
                        buffer = operand1.toString();
                        operand2 = 0.00;
                        operator2 = "";
                    }
                }
            }

            DSM.State {
                id: resultState

                onEntered: {
                    calculateAll();
                    display = Qt.binding(show);
                    expression += " = " + result;
                }

                onExited: clear();

                function clear() {
                    buffer = "";
                    operator1 = "";
                    expression = result;
                }

                function show() {
                    return withTrailingDecimal(result.toString());
                }

                DSM.SignalTransition {
                    signal: equalPressed
                    guard: sm.config.equalKeyRepeatsLastOperation
                    onTriggered: {
                        // Repeat the last operation using the
                        // previous buffer and operator.
                        calculateAll();
                        expression = "= " + result;
                    }
                }
                DSM.SignalTransition {
                    signal: addsubPressed
                    targetState: operatorState
                }
                DSM.SignalTransition {
                    signal: muldivPressed
                    targetState: operatorState
                }
            }
        }
    }
}
