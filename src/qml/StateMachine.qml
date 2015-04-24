import QtQuick 2.4
import QtQml.StateMachine 1.0 as DSM

DSM.StateMachine {
    id: sm

    property alias config: config

    property double calculationResult
    property string calculationResultText: stringify(calculationResult)
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

    readonly property int significantDigits: 13
    readonly property var trailingPointRegExp: /\.$/
    readonly property var trailingZerosRegExp: /0+$/

    signal error()

    onCalculationResultChanged: validate(calculationResult);

    onOperandChanged: validate(operand);

    onStopped: reset();

    Component.onCompleted: reset();

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

    function stringify(value) {
        var newValue = value;
        if (value === undefined || value === null) {
            newValue = "";
        } else if (typeof value === "number") {
            newValue = value.toFixed(significantDigits);
            if (newValue.indexOf(".") !== -1) {
                newValue = newValue.replace(trailingZerosRegExp, "");
                newValue = newValue.replace(trailingPointRegExp, "");
            }
        }
        return newValue;
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

    function validate(num) {
        if (!isFinite(num)) {
            error();
        }
    }

    function withTrailingPoint(value) {
        var newValue = stringify(value);
        return (newValue.indexOf(".") === -1) ? newValue + "." : newValue;
    }

    QtObject {
        id: config

        property bool equalKeyRepeatsLastOperation: false
    }

    ExpressionBuilder {
        id: expressionBuilder

        property Connections __connections: Connections {
            target: sm
            onError: expressionBuilder.error();
        }
    }

    KeyManager {
        id: keyManager

        clearEntryOperable: operandBuffer.clearable
        equalKeyOperable: operators.length
        equalKeyRepeatsLastOperation: config.equalKeyRepeatsLastOperation
        memoryClearOperable: memory.active
        memoryRecallOperable: memory.active && !memoryRecallState.active

        property Connections __connections: Connections {
            target: sm
            onStarted: keyManager.reset();
        }
    }

    QtObject {
        id: memory

        property bool active: false
        property string text: (!active) ? "" : sm.stringify(value)
        property double value: 0.0

        function clear() {
            active = false;
            value = 0.0;
        }

        function recall() {
            operandBuffer.replace(value);
        }

        function update(num) {
            active = true;
            switch (keyManager.key) {
                case "ms": case "sm":
                    value = num;
                    break;
                case "m+":
                    value += num;
                    break;
                case "m-":
                    value -= num;
                    break;
            }
        }
    }

    QtObject {
        id: operandBuffer

        property bool clearable: (text !== "" && text !== "0")
        property double number: (text !== "") ? Number(text) : 0.0
        property string text: ""

        onNumberChanged: validate(number);

        function accumulate() {
            text += keyManager.key;
            expressionBuilder.pop();
            expressionBuilder.push(text.replace(sm.trailingPointRegExp, ""));
        }

        function clear() {
            expressionBuilder.pop();
            reset();
        }

        function clearEntry() {
            clear();
            keyManager.reset();
        }

        function replace(value) {
            expressionBuilder.pop();
            text = stringify(value);
            expressionBuilder.push(text);
        }

        function reset() {
            text = "";
        }

        function show() {
            return withTrailingPoint(text);
        }

        function swap(target, replacement) {
            var signed = (text.charAt(0) === "-");
            text = (signed) ? text.slice(1) : text;
            text = (text === target) ? replacement : text;
            text = (signed) ? "-" + text : text;
        }

        function toggleSign() {
            text = (text.charAt(0) === "-") ? text.slice(1) : "-" + text;
            expressionBuilder.pop();
            expressionBuilder.push(text);
        }

        function update(value) {
            text = stringify(value);
        }
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
            onTriggered: operandBuffer.clearEntry();
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
            onTriggered: operandBuffer.toggleSign();
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
                    onTriggered: operandBuffer.accumulate();
                }
                DSM.SignalTransition {
                    signal: keyManager.pointPressed
                    targetState: pointState
                }
                DSM.SignalTransition {
                    signal: keyManager.zeroPressed
                    onTriggered: operandBuffer.accumulate();
                }

                DSM.State {
                    id: digitState
                    onEntered: {
                        operandBuffer.swap("0", "");
                        operandBuffer.accumulate();
                    }
                }

                DSM.State {
                    id: pointState
                    onEntered: {
                        operandBuffer.swap("", "0");
                        operandBuffer.accumulate();
                    }
                    DSM.SignalTransition {
                        signal: keyManager.pointPressed
                    }
                }

                DSM.State {
                    id: zeroState
                    onEntered: {
                        operandBuffer.accumulate();
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
                    onTriggered: operandBuffer.clear();
                }
                DSM.SignalTransition {
                    signal: keyManager.pointPressed
                    targetState: pointState
                    onTriggered: operandBuffer.clear();
                }
                DSM.SignalTransition {
                    signal: keyManager.zeroPressed
                    targetState: zeroState
                    onTriggered: operandBuffer.clear();
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
                        memory.recall();
                    }
                    DSM.SignalTransition {
                        signal: keyManager.memoryRecallPressed
                    }
                }

                DSM.State {
                    id: memoryUpdateState
                    onEntered: {
                        memory.update(operandBuffer.number);
                    }
                    DSM.SignalTransition {
                        signal: keyManager.memoryUpdatePressed
                        onTriggered: memory.update(operandBuffer.number);
                    }
                }

                DSM.State {
                    id: signState
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
                    return withTrailingPoint(value);
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
                    expressionBuilder.clear();
                    operandBuffer.reset();
                }

                function show() {
                    return withTrailingPoint(calculationResult);
                }

                DSM.SignalTransition {
                    signal: keyManager.addSubPressed
                    targetState: operatorState
                    onTriggered: expressionBuilder.push(calculationResult);
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
                    onTriggered: {
                        expressionBuilder.push(calculationResult);
                        operandBuffer.update(calculationResult);
                    }
                }
                DSM.SignalTransition {
                    signal: keyManager.memoryUpdatePressed
                    targetState: memoryUpdateState
                    onTriggered: {
                        expressionBuilder.push(calculationResult);
                        operandBuffer.update(calculationResult);
                    }
                }
                DSM.SignalTransition {
                    signal: keyManager.mulDivPressed
                    targetState: operatorState
                    onTriggered: expressionBuilder.push(calculationResult);
                }
                DSM.SignalTransition {
                    signal: keyManager.signPressed
                    targetState: signState
                    onTriggered: {
                        expressionBuilder.push(calculationResult);
                        operandBuffer.update(calculationResult);
                        operandBuffer.toggleSign();
                    }
                }
            } // End of resultState
        } // End of operationState
    } // End of clearState
}
