import QtQuick 2.4
import QtQml.StateMachine 1.0 as DSM
import "." as App

DSM.StateMachine {
    id: calculatorStateMachine

    property string acceptedKey
    property string attemptedKey
    property string buffer
    property string display
    property string errorMessage
    property string key
    property real operand1
    property real operand2
    property string operator1
    property string operator2
    property real result
    property bool validKey

    signal addsubPressed()
    signal clearPressed()
    signal digitPressed()
    signal equalPressed()
    signal muldivPressed()
    signal pointPressed()
    signal zeroPressed()

    function reset() {
        acceptedKey = "";
        attemptedKey = "";
        buffer = "";
        display = "";
        errorMessage = "";
        key = "";
        operand1 = 0.00;
        operand2 = 0.00;
        operator1 = "";
        operator2 = "";
        result = 0.00;
        validKey = false;
    }

    function keyPressed(event, source) {
        key = event.text;
        if (validKey) {
            event.accepted = true;
        }
    }

    onKeyChanged: {
        if (!key) {
            return;
        }
        attemptedKey = key;
        validKey = true;
        switch (key) {
            default:
                validKey = false;
                break;
            case "1":
            case "2":
            case "3":
            case "4":
            case "5":
            case "6":
            case "7":
            case "8":
            case "9":
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
            case "+":
            case "-":
                addsubPressed();
                break;
            case "*":
            case "/":
                muldivPressed();
                break;
        }
        if (validKey) {
            acceptedKey = key;
        }
        // Set key to empty string so duplicated keys still trigger onKeyChanged.
        key = ""
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
            operator2 = "";
            operand2 = 0.00;
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
            operator2 = key;
        } else if (operator1) {
            switch (operator1) {
                case "*":
                    operand1 *= num;
                    operator1 = key;
                    break;
                case "/":
                    operand1 /= num;
                    operator1 = key;
                    break;
                case "+":
                case "-":
                    operand2 = num;
                    operator2 = key;
                    break;
            }
        } else {
            operand1 = num;
            operator1 = key;
        }
    }

    function replaceLastOperator() {
        if (operator2) {
            operator2 = key;
        } else {
            operator1 = key;
        }
    }

    initialState: clearState
    running: true

    DSM.State {
        id: clearState

        initialState: accumulateState

        onEntered: {
            reset();
        }

        DSM.SignalTransition {
            signal: clearPressed
            targetState: clearState
        }

        DSM.State {
            id: accumulateState
            initialState: zeroState

            DSM.SignalTransition {
                signal: digitPressed
                targetState: digitState
            }
            DSM.SignalTransition {
                signal: pointPressed
                targetState: pointState
            }
            DSM.SignalTransition {
                signal: addsubPressed
                targetState: computedState
                onTriggered: {
                    calculateAll();
                    operator1 = key;
                }
            }
            DSM.SignalTransition {
                signal: muldivPressed
                targetState: computedState
                onTriggered: {
                    calculateLast();
                }
            }
            DSM.SignalTransition {
                signal: equalPressed
                targetState: resultState
                onTriggered: {
                    calculateAll();
                }
            }

            DSM.State {
                id: digitState
                onEntered: {
                    buffer = (buffer === "0") ? key : buffer + key;
                    display = buffer;
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                    targetState: digitState
                }
            }

            DSM.State {
                id: pointState
                onEntered: {
                    buffer = buffer ? buffer : "0";
                    buffer += key;
                    display = buffer;
                }
                DSM.SignalTransition {
                    signal: digitPressed
                    targetState: pointState
                }
                DSM.SignalTransition {
                    signal: pointPressed
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                    targetState: pointState
                }
            }

            DSM.State {
                id: zeroState
                onEntered: {
                    buffer = "0";
                    display = "0.";
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                }
            }
        }

        DSM.State {
            id: computedState

            onEntered: {
                display = operator2 ? buffer : operand1.toString();
                buffer = "";
            }
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
            DSM.SignalTransition {
                signal: addsubPressed
                onTriggered: {
                    replaceLastOperator();
                }
            }
            DSM.SignalTransition {
                signal: muldivPressed
                onTriggered: {
                    replaceLastOperator();
                }
            }
            DSM.SignalTransition {
                signal: equalPressed
                targetState: resultState
                onTriggered: {
                    buffer = "0";
                    calculateAll();
                    buffer = "";
                }
            }
        }

        DSM.State {
            id: resultState

            onEntered: {
                buffer = buffer ? buffer : operand1.toString();
                display = result.toString();
            }
            onExited: {
                buffer = "0";
                operator1 = "";
            }
            DSM.SignalTransition {
                signal: equalPressed
                onTriggered: {
                    // Repeat the last operation using previous buffer and operator.
                    calculateAll();
                    display = result.toString();
                }
            }
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
            DSM.SignalTransition {
                signal: addsubPressed
                targetState: computedState
                onTriggered: {
                    calculateAll();
                    operator1 = key;
                }
            }
            DSM.SignalTransition {
                signal: muldivPressed
                targetState: computedState
                onTriggered: {
                    calculateLast();
                }
            }
        }

        DSM.State {
            id: errorState
            onEntered: {
                display = errorMessage;
            }
        }
    }
}
