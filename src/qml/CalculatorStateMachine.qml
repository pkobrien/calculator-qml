import QtQuick 2.4
import QtQml.StateMachine 1.0 as DSM
import "." as App

DSM.StateMachine {
    id: calculatorStateMachine

    property string acceptedKey: ""
    property string attemptedKey: ""
    property string buffer: ""
    property string display: ""
    property string errorMessage: ""
    property string key: ""
    property real operand1: 0.00
    property real operand2: 0.00
    property string operator1: ""
    property string operator2: ""
    property real result: 0.00
    property bool validKey: false

    signal addsubPressed()
    signal clearPressed()
    signal digitPressed()
    signal equalPressed()
    signal muldivPressed()
    signal pointPressed()
    signal zeroPressed()

    function keyPressed(event, source) {
        key = event.text;
        if (validKey) {
            event.accepted = true;
        }
    }

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

    initialState: clearState
    running: true

    DSM.State {
        id: clearState

        initialState: accumulateState

        DSM.SignalTransition {
            signal: clearPressed
            targetState: clearState
        }

        onEntered: {
            console.log("clear onEntered");
            reset();
        }

        DSM.State {
            id: accumulateState
            initialState: zeroState

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
                    if (operator2) {
                        switch (operator2) {
                            case "*":
                                operand2 *= Number(buffer.valueOf());
                                break;
                            case "/":
                                operand2 /= Number(buffer.valueOf());
                                break;
                        }
                        operator2 = "";
                        switch (operator1) {
                            case "+":
                                operand1 += operand2;
                                break;
                            case "-":
                                operand1 -= operand2;
                                break;
                        }
                        operand2 = 0.00;
                    } else if (operator1) {
                        switch (operator1) {
                            case "+":
                                operand1 += Number(buffer.valueOf());
                                break;
                            case "-":
                                operand1 -= Number(buffer.valueOf());
                                break;
                        }
                    } else {
                        operand1 = Number(buffer.valueOf());
                    }
                    buffer = "";
                    operator1 = key;
                }
            }
        }

        DSM.State {
            id: computedState

            onEntered: {
                if (operator2) {
                    display = operand2.toString();
                } else {
                    display = operand1.toString();
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
        }

        DSM.State {
            id: errorState
            onEntered: {
                display = errorMessage;
            }
        }
    }
}
