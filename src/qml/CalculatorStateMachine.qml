import QtQuick 2.4
import QtQml.StateMachine 1.0 as DSM
import "." as App

DSM.StateMachine {
    id: calculatorStateMachine

    property string display: ""
    property string expression: ""
    property string key: ""
    property string operand: ""
    property real result

    readonly property list addsub: ["+", "-"]
    readonly property list digit: [".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    readonly property list equal: ["="]
//    readonly property list zero: ["0"]

    signal addsubPressed()
    signal digitPressed()
    signal equalPressed()

    onKeyChanged: {
        if (App.Active.logging) {
            console.log("calculatorStateMachine.onKeyChanged:", key);
        }
        if (!key) {
            return;
        }
        if (addsub.indexOf(key) !== -1) {
            addsubPressed();
        } else if (digit.indexOf(key) !== -1) {
            digitPressed();
        } else if (equal.indexOf(key) !== -1) {
            equalPressed();
        }
        key = "";
    }

    function keyPressed(event, source) {
        key = event.text;
//        event.accepted = true;
    }

    initialState: idle
    running: true

    DSM.State {
        id: idle

        DSM.SignalTransition {
            signal: digitPressed
            targetState: addToNumber
        }

    }

    DSM.State {
        id: addToNumber
        onEntered: {
            if (key === "." && !operand) {
                operand = "0.";
            } else if (key === "." && operand.indexOf(key) !== -1) {
                continue;  // Ignore duplicate decimal points.
            } else if (key === "0" && operand.indexOf(key) === 0) {
                continue;  // Ignore duplicate leading zeros.
            } else {
                operand += key;
            }
        }
    }

    DSM.State {
        id: number
    }

    DSM.State {
        id: error
    }

    DSM.State {
        id: errorClear
    }
}

//        DSM.SignalTransition {
//            targetState: selecting
//            signal: sceneMouseArea.onPressed
//            guard:
//        }

//        DSM.SignalTransition {
//            signal: sceneMouseArea.clicked
//            onTriggered: sceneMouseArea.clearSelection();
//        }

//        onEntered: {
//            sceneMouseArea.clearSelection();
//            selectionRectangle.state = "Active";
//        }

//        onExited: {
//            selectionRectangle.state = "";
//        }
