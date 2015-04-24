import QtQuick 2.4
import QtQml.StateMachine 1.0 as DSM
import "." as App

DSM.StateMachine {
    id: sm

    property alias config: config

    property double calculationResult
    property string calculationResultText: App.Util.stringify(calculationResult)
    property string display
    property string errorMessage
    property string expression: expressionBuilder.text
    property string memoryText: memory.text

    property double operand
    property var operands: []
    property var operators: []

    readonly property var noop: keyManager.noop
    readonly property var process: keyManager.process
    readonly property var supports: keyManager.supports

    signal error()

    onCalculationResultChanged: validate(calculationResult);

    onOperandChanged: validate(operand);

    onStopped: reset();

    Component.onCompleted: reset();

    function accumulate() {
        expressionBuilder.pop();
        operandBuffer.text += keyManager.key;
        expressionBuilder.push(
            operandBuffer.text.replace(App.Util.trailingPointRegExp, ""));
    }

    function applyMathFunction() {
        expressionBuilder.push("%1(%2)".arg(keyManager.key).arg(
                                   expressionBuilder.pop()));
        operand = operandBuffer.number;
        var mathFunction
        switch (keyManager.key) {
            default:
                mathFunction = Math[keyManager.key];
                break;
            case "sqr": // We have to create our own function for square.
                mathFunction = function() { return operand * operand };
                break;
        }
        operand = mathFunction(operand);
        operandBuffer.update(operand);
        if (!operators.length) {
            operands.pop();
            operands.push(operand);
            calculationResult = operand;
        }
    }

    function calculateAll(updateExpression) {
        var num = operandBuffer.number;
        var operator;
        if (operators.length === 2) {
            operand = operands.pop();
            operator = operators.pop();
            switch (operator) {
                case "*":
                    operand *= num;
                    break;
                case "/":
                    operand /= num;
                    break;
            }
            num = operand;
            if (config.equalKeyRepeatsLastOperation) {
                operandBuffer.update(operand);
            }
        }
        if (operators.length === 1) {
            operand = operands.pop();
            operator = operators.pop();
            switch (operator) {
                case "+":
                    operand += num;
                    break;
                case "-":
                    operand -= num;
                    break;
                case "*":
                    operand *= num;
                    break;
                case "/":
                    operand /= num;
                    break;
            }
        } else {
            operands.pop();
            operand = operandBuffer.number;
        }
        operands.push(operand);
        calculationResult = operand;
        if (updateExpression) {
            expressionBuilder.push("=");
            expressionBuilder.push(operand);
        }
    }

    function calculateLast() {
        if (!operands.length) {
            operand = operandBuffer.number;
        } else {
            operand = operands.pop();
            var operator = operators.pop();
            switch (operator) {
                case "*":
                    operand *= operandBuffer.number;
                    break;
                case "/":
                    operand /= operandBuffer.number;
                    break;
                case "+": case "-":
                    operands.push(operand);
                    operators.push(operator);
                    operand = operandBuffer.number;
                    break;
            }
        }
        operands.push(operand);
    }

    function clearEntry() {
        expressionBuilder.pop();
        keyManager.reset();
        operandBuffer.clear();
    }

    function recallMemory() {
        expressionBuilder.pop();
        operandBuffer.update(memory.recall());
        expressionBuilder.push(operandBuffer.text);
    }

    function reset() {
        calculationResult = 0.0;
        display = "";
        errorMessage = "ERROR";
        expressionBuilder.reset();
        keyManager.reset();
        operandBuffer.reset();
        operands.length = 0;
        operators.length = 0;
    }

    function resetBeforeAccumulate() {
        expressionBuilder.pop();
        operandBuffer.clear();
    }

    function resetAfterResult() {
        expressionBuilder.clear();
        operandBuffer.clear();
    }

    function toggleSign() {
        expressionBuilder.pop();
        operandBuffer.toggleSign();
        expressionBuilder.push(operandBuffer.text);
    }

    function updateMemory() {
        memory.update(operandBuffer.number);
    }

    function updateOperator() {
        if (operators.length === operands.length) {
            operators.pop();
            expressionBuilder.pop();
        }
        operators.push(keyManager.key);
        expressionBuilder.push(keyManager.key);
        operators = operators;  // To trigger any bindings to this list.
    }

    function updateResult(updateOperandBuffer) {
        expressionBuilder.push(calculationResult);
        if (updateOperandBuffer) {
            operandBuffer.update(calculationResult);
        }
    }

    function validate(num) {
        if (!isFinite(num)) {
            error();
        }
    }

    QtObject {
        id: config

        property bool equalKeyRepeatsLastOperation: false
    }

    App.ExpressionBuilder {
        id: expressionBuilder

        property Connections __connections: Connections {
            target: sm
            onError: expressionBuilder.error();
        }
    }

    App.KeyManager {
        id: keyManager

        clearEntryOperable: operandBuffer.clearable
        equalKeyOperable: operators.length
        memoryClearOperable: memory.active
        memoryRecallOperable: memory.active && !memoryRecallState.active

        noopGroups: [
            // [state, equal-key-operable (or null for default), noop-groups]
            [digitState, null, []],
            [errorState, false, ["AddSub", "Function",
                                 "MemoryUpdate", "MulDiv", "Sign"]],
            [functionState, null, []],
            [memoryRecallState, null, ["MemoryRecall"]],
            [memoryUpdateState, null, []],
            [operatorState, true, ["Function", "MemoryUpdate", "Sign"]],
            [pointState, null, ["Point"]],
            [resultState, config.equalKeyRepeatsLastOperation, []],
            [signState, null, []],
            [zeroState, null, ["Zero"]],
        ]

        property Connections __connections: Connections {
            target: sm
            onStarted: keyManager.reset();
        }
    }

    App.Memory {
        id: memory

        property string text: (!active) ? "" : App.Util.stringify(value)

        key: keyManager.key
    }

    App.OperandBuffer {
        id: operandBuffer

        onNumberChanged: validate(number);
    }

    initialState: clearState

    DSM.State {
        id: clearState

        initialState: operandState

        DSM.SignalTransition {
            signal: keyManager.clearPressed
            targetState: clearState
            onTriggered: reset();
        }
        DSM.SignalTransition {
            signal: keyManager.clearEntryPressed
            guard: (operandBuffer.clearable)
            targetState: zeroState
            onTriggered: clearEntry();
        }
        DSM.SignalTransition {
            signal: error
            targetState: errorState
        }
        DSM.SignalTransition {
            signal: keyManager.memoryClearPressed
            guard: (memory.active)
            onTriggered: memory.clear();
        }
        DSM.SignalTransition {
            signal: keyManager.memoryRecallPressed
            guard: (memory.active)
            targetState: memoryRecallState
        }
        DSM.SignalTransition {
            signal: keyManager.signPressed
            guard: (operandBuffer.text !== "")
            onTriggered: toggleSign();
        }

        DSM.State {
            id: operandState

            initialState: accumulateState

            onEntered: {
                display = Qt.binding(operandBuffer.show);
                if (operandBuffer.text === "") {
                    expressionBuilder.push("");
                }
            }

            DSM.SignalTransition {
                signal: keyManager.addSubPressed
                targetState: operatorState
                onTriggered: calculateAll(false);
            }
            DSM.SignalTransition {
                signal: keyManager.equalPressed
                guard: (operators.length)
                targetState: resultState
            }
            DSM.SignalTransition {
                signal: keyManager.functionPressed
                targetState: functionState
            }
            DSM.SignalTransition {
                signal: keyManager.memoryUpdatePressed
                targetState: memoryUpdateState
            }
            DSM.SignalTransition {
                signal: keyManager.mulDivPressed
                targetState: operatorState
                onTriggered: calculateLast();
            }

            DSM.State {
                id: accumulateState

                initialState: zeroState

                DSM.SignalTransition {
                    signal: keyManager.digitPressed
                    onTriggered: accumulate();
                }
                DSM.SignalTransition {
                    signal: keyManager.pointPressed
                    targetState: pointState
                }
                DSM.SignalTransition {
                    signal: keyManager.zeroPressed
                    onTriggered: accumulate();
                }

                DSM.State {
                    id: digitState
                    onEntered: {
                        operandBuffer.swap("0", "");
                        accumulate();
                    }
                }

                DSM.State {
                    id: pointState
                    onEntered: {
                        operandBuffer.swap("", "0");
                        accumulate();
                    }
                    DSM.SignalTransition {
                        signal: keyManager.pointPressed
                    }
                }

                DSM.State {
                    id: zeroState
                    onEntered: {
                        accumulate();
                    }
                    DSM.SignalTransition {
                        signal: keyManager.digitPressed
                        targetState: digitState
                    }
                    DSM.SignalTransition {
                        signal: keyManager.zeroPressed
                    }
                }
            } // End of accumulateState

            DSM.State {
                id: manipulateState

                DSM.SignalTransition {
                    signal: keyManager.digitPressed
                    targetState: digitState
                    onTriggered: resetBeforeAccumulate();
                }
                DSM.SignalTransition {
                    signal: keyManager.pointPressed
                    targetState: pointState
                    onTriggered: resetBeforeAccumulate();
                }
                DSM.SignalTransition {
                    signal: keyManager.zeroPressed
                    targetState: zeroState
                    onTriggered: resetBeforeAccumulate();
                }

                DSM.State {
                    id: functionState
                    onEntered: {
                        applyMathFunction();
                    }
                    DSM.SignalTransition {
                        signal: keyManager.functionPressed
                        onTriggered: applyMathFunction();
                    }
                }

                DSM.State {
                    id: memoryRecallState
                    onEntered: {
                        recallMemory();
                    }
                    DSM.SignalTransition {
                        signal: keyManager.memoryRecallPressed
                    }
                }

                DSM.State {
                    id: memoryUpdateState
                    onEntered: {
                        updateMemory();
                    }
                    DSM.SignalTransition {
                        signal: keyManager.memoryUpdatePressed
                        onTriggered: updateMemory();
                    }
                }

                DSM.State {
                    id: signState
                    onEntered: {
                        toggleSign();
                    }
                }
            } // End of manipulateState
        } // End of operandState

        DSM.State {
            id: operationState

            DSM.SignalTransition {
                signal: keyManager.digitPressed
                targetState: digitState
            }
            DSM.SignalTransition {
                signal: keyManager.pointPressed
                targetState: pointState
            }
            DSM.SignalTransition {
                signal: keyManager.signPressed
            }
            DSM.SignalTransition {
                signal: keyManager.zeroPressed
                targetState: zeroState
            }

            DSM.State {
                id: errorState

                onEntered: {
                    display = errorMessage;
                    operandBuffer.reset();
                }

                onExited: {
                    var temp = keyManager.key;
                    reset();
                    keyManager.key = temp;
                }

                DSM.SignalTransition {
                    signal: error
                }
            } // End of errorState

            DSM.State {
                id: operatorState

                property string lastOperand

                onEntered: {
                    lastOperand = operandBuffer.text
                    display = Qt.binding(show);
                    operandBuffer.reset();
                    updateOperator();
                }

                function show() {
                    var value = (operators.length === 2) ?
                                lastOperand : operands[0];
                    return App.Util.withTrailingPoint(value);
                }

                DSM.SignalTransition {
                    signal: keyManager.addSubPressed
                    onTriggered: updateOperator();
                }
                DSM.SignalTransition {
                    signal: keyManager.equalPressed
                    targetState: resultState
                    onTriggered: {
                        operandBuffer.update(operands[0]);
//                        operand2 = 0.00;
//                        operator2 = "";
                    }
                }
                DSM.SignalTransition {
                    signal: keyManager.mulDivPressed
                    onTriggered: updateOperator();
                }
            } // End of operatorState

            DSM.State {
                id: resultState

                property string lastOperator

                onEntered: {
                    display = Qt.binding(show);
                    lastOperator = operators[0];
                    calculateAll(true);
                }

                onExited: {
                    lastOperator = "";
                    resetAfterResult();
                }

                function show() {
                    return App.Util.withTrailingPoint(calculationResult);
                }

                DSM.SignalTransition {
                    signal: keyManager.addSubPressed
                    targetState: operatorState
                    onTriggered: updateResult(false);
                }
                DSM.SignalTransition {
                    signal: keyManager.equalPressed
                    guard: (config.equalKeyRepeatsLastOperation)
                    onTriggered: {
                        // Repeat the last operation using the
                        // previous buffer and operator.
                        operators[0] = resultState.lastOperator;
                        calculateAll(true);
                    }
                }
                DSM.SignalTransition {
                    signal: keyManager.functionPressed
                    targetState: functionState
                    onTriggered: updateResult(true);
                }
                DSM.SignalTransition {
                    signal: keyManager.memoryUpdatePressed
                    targetState: memoryUpdateState
                    onTriggered: updateResult(true);
                }
                DSM.SignalTransition {
                    signal: keyManager.mulDivPressed
                    targetState: operatorState
                    onTriggered: updateResult(false);
                }
                DSM.SignalTransition {
                    signal: keyManager.signPressed
                    targetState: signState
                    onTriggered: updateResult(true);
                }
            } // End of resultState
        } // End of operationState
    } // End of clearState
}
