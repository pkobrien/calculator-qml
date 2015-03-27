import QtQuick 2.4
import QtQml.StateMachine 1.0 as DSM
import "." as App

DSM.StateMachine {
    id: calculatorStateMachine

    property bool accepted
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

    signal addsubPressed()
    signal clearPressed()
    signal digitPressed()
    signal equalPressed()
    signal muldivPressed()
    signal pointPressed()
    signal zeroPressed()

    function keyPressed(event, source) {
        key = event.text;
        event.accepted = accepted;
    }

    onKeyChanged: {
        if (!key) {
            return;
        }
        attemptedKey = key;
        accepted = true;
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
        acceptedKey = accepted ? key : "";
        // Set key to empty string so duplicated keys still trigger onKeyChanged.
        key = ""
    }

    initialState: clearState

    DSM.State {
        id: clearState

        initialState: accumulateState

        onEntered: reset();

        function reset() {
            accepted = false;
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
        }

        DSM.SignalTransition {
            signal: clearPressed
            targetState: clearState
        }

        DSM.State {
            id: errorState
            onEntered: display = Qt.binding(function() { return errorMessage; });
        }

        DSM.State {
            id: accumulateState
            initialState: zeroState

            onEntered: {
                display = Qt.binding(function() { return buffer.indexOf(".") === -1? buffer + "." : buffer; });
            }

            function accumulate() { buffer += key; }

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
                targetState: operatorState
                onTriggered: computeState.calculateAll();
            }
            DSM.SignalTransition {
                signal: muldivPressed
                targetState: operatorState
                onTriggered: computeState.calculateLast();
            }
            DSM.SignalTransition {
                signal: equalPressed
                targetState: resultState
                guard: operator1
            }

            DSM.State {
                id: digitState
                onEntered: {
                    buffer = (buffer === "0") ? key : buffer + key;
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                    onTriggered: accumulateState.accumulate();
                }
            }

            DSM.State {
                id: pointState
                onEntered: {
                    buffer = buffer ? buffer + "." : "0.";
                }
                DSM.SignalTransition {
                    signal: digitPressed
                    onTriggered: accumulateState.accumulate();
                }
                DSM.SignalTransition {
                    signal: pointPressed
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                    onTriggered: accumulateState.accumulate();
                }
            }

            DSM.State {
                id: zeroState
                onEntered: {
                    buffer = "0";
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                }
            }
        }

        DSM.State {
            id: computeState

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
                    display = Qt.binding(function() { return operator2 ? buffer : operand1.toString(); });
                }
                onExited: {
                    buffer = "";
                }

                function updateOperator() {
                    if (operand2) {
                        operator2 = key;
                    } else {
                        operator1 = key;
                    }
                }

                DSM.SignalTransition {
                    signal: addsubPressed
                    onTriggered: operatorState.updateOperator();
                }
                DSM.SignalTransition {
                    signal: muldivPressed
                    onTriggered: operatorState.updateOperator();
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
                    computeState.calculateAll();
                    display = Qt.binding(function() { return result.toString(); });
                }
                onExited: {
                    buffer = "0";
                    operator1 = "";
                }
                DSM.SignalTransition {
                    signal: equalPressed
                    onTriggered: {
                        // Repeat the last operation using
                        // previous buffer and operator.
                        computeState.calculateAll();
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
