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
    property string key
    property string memoryText: memory.text

    property double operand
    property var operands: []
    property var operators: []

    readonly property var noop: keyInfo.noop
    readonly property var process: keyInfo.process
    readonly property var supports: keyInfo.supports

    readonly property int significantDigits: 13
    readonly property var trailingPointRegExp: /\.$/
    readonly property var trailingZerosRegExp: /0+$/

    signal addSubPressed()
    signal clearPressed()
    signal clearEntryPressed()
    signal digitPressed()
    signal equalPressed()
    signal error()
    signal functionPressed()
    signal memoryClearPressed()
    signal memoryRecallPressed()
    signal memoryUpdatePressed()
    signal mulDivPressed()
    signal pointPressed()
    signal signPressed()
    signal zeroPressed()

    onCalculationResultChanged: validate(calculationResult);

    onError: expressionBuilder.errorMode = true;

    onOperandChanged: validate(operand);

    onStopped: reset();

    onStarted: keyInfo.reset();

    Component.onCompleted: reset();

    function applyMathFunction() {
        expressionBuilder.push("%1(%2)".arg(key).arg(expressionBuilder.pop()));
        operand = operandBuffer.number;
        var mathFunction
        switch (key) {
            default:
                mathFunction = Math[key];
                break;
            case "sqr":
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
        key = "0";
        keyInfo.reset();
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
        operators.push(key);
        expressionBuilder.push(key);
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

    QtObject {
        id: expressionBuilder

        property bool errorMode: false

        property string text: ""

        property var __buffer: []

        function clear() {
            if (!errorMode) {
                __buffer.length = 0;
                _updateText();
            }
        }

        function pop() {
            var value = __buffer.pop();
            _updateText();
            return value;
        }

        function push(value) {
            __buffer.push(stringify(value));
            _updateText();
        }

        function reset() {
            errorMode = false;
            clear();
        }

        function _updateText() {
            text = __buffer.join(" ");
        }
    }

    QtObject {
        id: keyInfo

        property var groupMap: ({})
        property var keyMap: ({})

        property var masterList: [
            {group: "AddSub", signal: addSubPressed, keys: ["+", "-"]},
            {group: "Clear", signal: clearPressed, keys: ["c"]},
            {group: "ClearEntry", signal: clearEntryPressed, keys: ["ce"]},
            {group: "Digit", signal: digitPressed,
                keys: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]},
            {group: "Equal", signal: equalPressed, keys: ["="]},
            {group: "Function", signal: functionPressed,
                keys: ["acos", "asin", "atan", "cos",
                       "exp", "log", "sin", "sqr", "sqrt", "tan"]},
            {group: "MemoryClear", signal: memoryClearPressed,
                keys: ["mc", "cm"]},
            {group: "MemoryRecall", signal: memoryRecallPressed,
                keys: ["mr", "rm"]},
            {group: "MemoryUpdate", signal: memoryUpdatePressed,
                keys: ["m+", "m-", "ms", "sm"]},
            {group: "MulDiv", signal: mulDivPressed, keys: ["*", "/"]},
            {group: "Point", signal: pointPressed, keys: ["."]},
            {group: "Sign", signal: signPressed, keys: ["+/-", "±"]},
            {group: "Zero", signal: zeroPressed, keys: ["0"]},
        ]

        property var noops

        property bool __setup: false

        property var states: [
            // state, equalCheck (or null for the default), noop groups:
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

        onNoopsChanged: {
            var specialKeys = groupMap["ClearEntry"].concat(
                              groupMap["MemoryClear"]).concat(
                              groupMap["MemoryRecall"]);
            var noopKeys = [];
            for (var i = 0; i < noops.length; i++) {
                noopKeys = noopKeys.concat(groupMap[noops[i]]);
            }
            for (var key in keyMap) {
                if (specialKeys.indexOf(key) !== -1) {
                    continue;
                }
                keyMap[key].noop = (noopKeys.indexOf(key) !== -1);
            }
        }

        function currentNoops() {
            for (var i = 0; i < states.length; i++) {
                if (states[i][0].active) {
                    var equalCheck = states[i][1];
                    if (equalCheck === null) {
                        equalCheck = operators.length; // Default.
                    }
                    var groups = states[i][2];
                    return (equalCheck) ? groups : groups.concat(["Equal"]);
                }
            }
            return [];
        }

        function noop(uiKey) {
            return (supports(uiKey)) ? keyMap[uiKey.toLowerCase()].noop : true;
        }

        function process(uiKey) {
            var accepted = false;
            sm.key = uiKey.toLowerCase();
            if (sm.key in keyMap) {
                accepted = true;
                keyMap[sm.key].signal();
                noops = currentNoops();
            }
            return accepted;
        }

        function reset() {
            setup();
            noops = currentNoops();
        }

        function setup() {
            if (__setup) {
                return;
            }
            var i;
            var key;
            var specialKeys;
            var qml = "import QtQuick 2.4;" +
                      "QtObject { property bool noop: false;" +
                                 "property var signal }"
            for (i = 0; i < masterList.length; i++) {
                var obj = masterList[i];
                groupMap[obj.group] = obj.keys;
                for (var j = 0; j < obj.keys.length; j++) {
                    key = obj.keys[j];
                    keyMap[key] = Qt.createQmlObject(qml, sm, "KeyDetails");
                    keyMap[key].signal = obj.signal;
                }
            }
            specialKeys = groupMap["ClearEntry"];
            for (i = 0; i < specialKeys.length; i++) {
                key = specialKeys[i];
                keyMap[key].noop = Qt.binding(
                    function() { return (!operandBuffer.clearable); });
            }
            specialKeys = groupMap["MemoryClear"];
            for (i = 0; i < specialKeys.length; i++) {
                key = specialKeys[i];
                keyMap[key].noop = Qt.binding(
                    function() { return (!memory.active); });
            }
            specialKeys = groupMap["MemoryRecall"];
            for (i = 0; i < specialKeys.length; i++) {
                key = specialKeys[i];
                keyMap[key].noop = Qt.binding(
                    function() { return (!memory.active || memory.recalled); });
            }
            __setup = true;
        }

        function supports(uiKey) {
            // We need to call setup() here because this function gets called
            // before Component.onCompleted() takes place, unfortunately.
            setup();
            return (uiKey.toLowerCase() in keyMap);
        }
    }

    QtObject {
        id: memory

        property bool active: false
        property bool recalled: false
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
            switch (key) {
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
            text += sm.key;
            expressionBuilder.pop();
            expressionBuilder.push(text.replace(sm.trailingPointRegExp, ""));
        }

        function clear() {
            expressionBuilder.pop();
            reset();
        }

        function clearEntry() {
            clear();
            sm.key = "0";
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
            signal: clearPressed
            targetState: clearState
            onTriggered: reset();
        }
        DSM.SignalTransition {
            signal: clearEntryPressed
            guard: (operandBuffer.clearable)
            targetState: zeroState
            onTriggered: operandBuffer.clearEntry();
        }
        DSM.SignalTransition {
            signal: error
            targetState: errorState
        }
        DSM.SignalTransition {
            signal: memoryClearPressed
            guard: (memory.active)
            onTriggered: memory.clear();
        }
        DSM.SignalTransition {
            signal: memoryRecallPressed
            guard: (memory.active)
            targetState: memoryRecallState
        }
        DSM.SignalTransition {
            signal: signPressed
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
                signal: addSubPressed
                targetState: operatorState
                onTriggered: calculateAll(false);
            }
            DSM.SignalTransition {
                signal: equalPressed
                guard: (operators.length)
                targetState: resultState
            }
            DSM.SignalTransition {
                signal: functionPressed
                targetState: functionState
            }
            DSM.SignalTransition {
                signal: memoryUpdatePressed
                targetState: memoryUpdateState
            }
            DSM.SignalTransition {
                signal: mulDivPressed
                targetState: operatorState
                onTriggered: calculateLast();
            }

            DSM.State {
                id: accumulateState

                initialState: zeroState

                DSM.SignalTransition {
                    signal: digitPressed
                    onTriggered: operandBuffer.accumulate();
                }
                DSM.SignalTransition {
                    signal: pointPressed
                    targetState: pointState
                }
                DSM.SignalTransition {
                    signal: zeroPressed
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
                        signal: pointPressed
                    }
                }

                DSM.State {
                    id: zeroState
                    onEntered: {
                        operandBuffer.accumulate();
                    }
                    DSM.SignalTransition {
                        signal: digitPressed
                        targetState: digitState
                    }
                    DSM.SignalTransition {
                        signal: zeroPressed
                    }
                }
            } // End of accumulateState

            DSM.State {
                id: manipulateState

                DSM.SignalTransition {
                    signal: digitPressed
                    targetState: digitState
                    onTriggered: operandBuffer.clear();
                }
                DSM.SignalTransition {
                    signal: pointPressed
                    targetState: pointState
                    onTriggered: operandBuffer.clear();
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                    targetState: zeroState
                    onTriggered: operandBuffer.clear();
                }

                DSM.State {
                    id: functionState
                    onEntered: {
                        applyMathFunction();
                    }
                    DSM.SignalTransition {
                        signal: functionPressed
                        onTriggered: applyMathFunction();
                    }
                }

                DSM.State {
                    id: memoryRecallState
                    onEntered: {
                        memory.recall();
                        memory.recalled = true;
                    }
                    onExited: memory.recalled = false;
                    DSM.SignalTransition {
                        signal: memoryRecallPressed
                    }
                }

                DSM.State {
                    id: memoryUpdateState
                    onEntered: {
                        memory.update(operandBuffer.number);
                    }
                    DSM.SignalTransition {
                        signal: memoryUpdatePressed
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
                signal: digitPressed
                targetState: digitState
            }
            DSM.SignalTransition {
                signal: pointPressed
                targetState: pointState
            }
            DSM.SignalTransition {
                signal: signPressed
            }
            DSM.SignalTransition {
                signal: zeroPressed
                targetState: zeroState
            }

            DSM.State {
                id: errorState

                onEntered: {
                    display = errorMessage;
                    operandBuffer.reset();
                }
                onExited: {
                    var temp = key;
                    reset();
                    key = temp;
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
                    signal: addSubPressed
                    onTriggered: updateOperator();
                }
                DSM.SignalTransition {
                    signal: equalPressed
                    targetState: resultState
                    onTriggered: {
                        operandBuffer.update(operands[0]);
//                        operand2 = 0.00;
//                        operator2 = "";
                    }
                }
                DSM.SignalTransition {
                    signal: mulDivPressed
                    onTriggered: updateOperator();
                }
            } // End of operatorState

            DSM.State {
                id: resultState

                property string lastOperator

                onEntered: {
                    display = Qt.binding(show);
                    lastOperator = operators[0];
                    update();
                }

                onExited: clear();

                function clear() {
                    lastOperator = "";
                    expressionBuilder.clear();
                    operandBuffer.reset();
                }

                function show() {
                    return withTrailingPoint(calculationResult);
                }

                function update() {
                    calculateAll(true);
                }

                DSM.SignalTransition {
                    signal: addSubPressed
                    targetState: operatorState
                    onTriggered: expressionBuilder.push(calculationResult);
                }
                DSM.SignalTransition {
                    signal: equalPressed
                    guard: (config.equalKeyRepeatsLastOperation)
                    onTriggered: {
                        // Repeat the last operation using the
                        // previous buffer and operator.
                        operators[0] = resultState.lastOperator;
                        resultState.update();
                    }
                }
                DSM.SignalTransition {
                    signal: functionPressed
                    targetState: functionState
                    onTriggered: {
                        expressionBuilder.push(calculationResult);
                        operandBuffer.update(calculationResult);
                    }
                }
                DSM.SignalTransition {
                    signal: memoryUpdatePressed
                    targetState: memoryUpdateState
                    onTriggered: {
                        expressionBuilder.push(calculationResult);
                        operandBuffer.update(calculationResult);
                    }
                }
                DSM.SignalTransition {
                    signal: mulDivPressed
                    targetState: operatorState
                    onTriggered: expressionBuilder.push(calculationResult);
                }
                DSM.SignalTransition {
                    signal: signPressed
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
