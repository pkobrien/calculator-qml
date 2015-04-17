import QtQuick 2.4
import QtQml.StateMachine 1.0 as DSM

/* TODO

Currently infix. Should also support postfix (RPN). And maybe Tenkey.

"00" and "000" keys for entering large numbers.

C or AC	All Clear
CE	Clear (last) Entry; sometimes called CE/C:
    a first press clears the last entry (CE), a second press clears all (C)
±	Toggle positive/negative number

*/

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
    property string operandBuffer
    property double operand1
    property double operand2
    property string operator1
    property string operator2

    readonly property var noop: keyInfo.noop
    readonly property var process: keyInfo.process
    readonly property var supports: keyInfo.supports

    readonly property int significantDigits: 13
    readonly property var trailingPointRegExp: /\.$/
    readonly property var trailingZerosRegExp: /0+$/

    signal addSubPressed()
    signal clearPressed()
    signal digitPressed()
    signal equalPressed()
    signal error()
    signal functionPressed()
    signal memoryClearPressed()
    signal memoryRecallPressed()
    signal memoryUpdatePressed()
    signal mulDivPressed()
    signal pointPressed()
    signal zeroPressed()

    function accumulate() {
        operandBuffer += key;
        expressionBuilder.pop();
        expressionBuilder.push(operandBuffer.replace(trailingPointRegExp, ""));
    }

    function applyMathFunction() {
        expressionBuilder.push("%1(%2)".arg(key).arg(expressionBuilder.pop()));
        var num = Number(operandBuffer);
        validate(num);
        var mathFunction
        switch (key) {
            default:
                mathFunction = Math[key];
                break;
            case "sqr":
                mathFunction = function() { return num * num };
                break;
        }
        var newValue = mathFunction(num);
        validate(newValue);
        operandBuffer = stringify(newValue);
        if (!operator1) {
            operand1 = newValue;
            calculationResult = newValue;
        }
    }

    function calculateAll(updateExpression) {
        var num = Number(operandBuffer);
        validate(num);
        if (operator2) {
            switch (operator2) {
                case "*":
                    num *= operand2;
                    break;
                case "/":
                    num = operand2 / num;
                    break;
            }
            validate(num);
            operandBuffer = stringify(num);
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
            operator1 = "";
        } else {
            operand1 = num;
        }
        if (updateExpression) {
            expressionBuilder.push("=");
            expressionBuilder.push(operand1);
        }
        calculationResult = operand1;
        validate(calculationResult);
    }

    function calculateLast() {
        var num = Number(operandBuffer);
        validate(num);
        if (operator2) {
            switch (operator2) {
                case "*":
                    operand2 *= num;
                    break;
                case "/":
                    operand2 /= num;
                    break;
            }
            validate(operand2);
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
            validate(operand1);
        } else {
            operand1 = num;
        }
    }

    function clearOperandBuffer() {
        expressionBuilder.pop();
        operandBuffer = "";
    }

    function replaceOperandBuffer(value) {
        expressionBuilder.pop();
        operandBuffer = stringify(value);
        expressionBuilder.push(operandBuffer);
    }

    function reset() {
        calculationResult = 0.0;
        display = "";
        errorMessage = "ERROR";
        expressionBuilder.reset();
        key = "0";
        keyInfo.reset();
        operandBuffer = "";
        operand1 = 0.0;
        operand2 = 0.0;
        operator1 = "";
        operator2 = "";
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
        if (operand2) {
            if (operator2) {
                expressionBuilder.pop();
            }
            operator2 = key;
            expressionBuilder.push(key);
        } else {
            if (operator1) {
                expressionBuilder.pop();
            }
            operator1 = key;
            expressionBuilder.push(key);
        }
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

    onError: expressionBuilder.errorMode = true;

    onStopped: reset();

    Component.onCompleted: reset();

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
            {group: "Zero", signal: zeroPressed, keys: ["0"]},
        ]

        property var noops

        property bool __setup: false

        function noop(uiKey) {
            return (supports(uiKey)) ? keyMap[uiKey.toLowerCase()].noop : true;
        }

        function process(uiKey) {
            var accepted = false;
            sm.key = uiKey.toLowerCase();
            if (sm.key in keyMap) {
                accepted = true;
                keyMap[sm.key].signal();
            }
            return accepted;
        }

        function reset() {
            setup();
            noops = [];
        }

        function setup() {
            if (__setup) {
                return;
            }
            var i;
            var key;
            var memKeys;
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
            memKeys = groupMap["MemoryClear"];
            for (i = 0; i < memKeys.length; i++) {
                key = memKeys[i];
                keyMap[key].noop = Qt.binding(function()
                                              { return !memory.active; });
            }
            memKeys = groupMap["MemoryRecall"];
            for (i = 0; i < memKeys.length; i++) {
                key = memKeys[i];
                keyMap[key].noop = Qt.binding(function()
                                              { return !memory.active
                                                || memory.recalled; });
            }
            __setup = true;
        }

        function supports(uiKey) {
            // We need to call setup() here because this function gets called
            // before Component.onCompleted() takes place, unfortunately.
            setup();
            return (uiKey.toLowerCase() in keyMap);
        }

        onNoopsChanged: {
            var memKeys = groupMap["MemoryClear"].concat(
                          groupMap["MemoryRecall"]);
            var noopKeys = [];
            for (var i = 0; i < noops.length; i++) {
                noopKeys = noopKeys.concat(groupMap[noops[i]]);
            }
            for (var key in keyMap) {
                if (memKeys.indexOf(key) !== -1) {
                    continue;
                }
                keyMap[key].noop = (noopKeys.indexOf(key) !== -1);
            }
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
            sm.replaceOperandBuffer(value);
        }

        function update(input) {
            active = true;
            var num = Number(input);
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

        DSM.State {
            id: operandState

            initialState: accumulateState

            onEntered: {
                display = Qt.binding(show);
                if (operandBuffer === "") {
                    expressionBuilder.push("");
                }
            }

            function show() {
                return withTrailingPoint(operandBuffer);
            }

            DSM.SignalTransition {
                signal: addSubPressed
                targetState: operatorState
                onTriggered: calculateAll(false);
            }
            DSM.SignalTransition {
                signal: equalPressed
                guard: (operator1)
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

                DSM.State {
                    id: digitState
                    onEntered: {
                        operandBuffer = (operandBuffer === "0") ?
                                        "" : operandBuffer;
                        accumulate();
                        keyInfo.noops = (operator1) ? [] : ["Equal"];
                    }
                }

                DSM.State {
                    id: pointState
                    onEntered: {
                        operandBuffer = (operandBuffer === "") ?
                                        "0" : operandBuffer;
                        accumulate();
                        keyInfo.noops = (operator1) ?
                                        ["Point"] : ["Equal", "Point"];
                    }
                    DSM.SignalTransition {
                        signal: pointPressed
                    }
                }

                DSM.State {
                    id: zeroState
                    onEntered: {
                        accumulate();
                        keyInfo.noops = (operator1) ?
                                        ["Zero"] : ["Equal", "Zero"];
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
                    onTriggered: clearOperandBuffer();
                }
                DSM.SignalTransition {
                    signal: pointPressed
                    targetState: pointState
                    onTriggered: clearOperandBuffer();
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                    targetState: zeroState
                    onTriggered: clearOperandBuffer();
                }

                DSM.State {
                    id: functionState
                    onEntered: {
                        applyMathFunction();
                        keyInfo.noops = [];
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
                        keyInfo.noops = ["MemoryRecall"];
                    }
                    onExited: memory.recalled = false;
                    DSM.SignalTransition {
                        signal: memoryRecallPressed
                    }
                }

                DSM.State {
                    id: memoryUpdateState
                    onEntered: {
                        memory.update(operandBuffer);
                        keyInfo.noops = [];
                    }
                    DSM.SignalTransition {
                        signal: memoryUpdatePressed
                        onTriggered: memory.update(operandBuffer);
                    }
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
                signal: zeroPressed
                targetState: zeroState
            }

            DSM.State {
                id: errorState

                onEntered: {
                    display = errorMessage;
                    keyInfo.noops = ["AddSub", "Equal", "Function",
                                     "MemoryUpdate", "MulDiv"];
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

                onEntered: {
                    display = Qt.binding(show);
                    updateOperator();
                    keyInfo.noops = ["Function", "MemoryUpdate"];
                }

                onExited: clear();

                function clear() {
                    operandBuffer = "";
                }

                function show() {
                    var value = (operator2) ? operandBuffer : operand1;
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
                        operandBuffer = stringify(operand1);
                        operand2 = 0.00;
                        operator2 = "";
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
                    lastOperator = operator1;
                    update();
                    keyInfo.noops = (config.equalKeyRepeatsLastOperation) ?
                                    [] : ["Equal"];
                }

                onExited: clear();

                function clear() {
                    lastOperator = "";
                    operandBuffer = "";
                    operator1 = "";
                    expressionBuilder.clear();
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
                        operator1 = resultState.lastOperator;
                        resultState.update();
                    }
                }
                DSM.SignalTransition {
                    signal: functionPressed
                    onTriggered: {
                        resultState.clear();
                        operandBuffer = stringify(calculationResult);
                        expressionBuilder.push(calculationResult);
                        applyMathFunction();
                    }
                }
                DSM.SignalTransition {
                    signal: memoryUpdatePressed
                    onTriggered: {
                        memory.update(calculationResult);
                    }
                }
                DSM.SignalTransition {
                    signal: mulDivPressed
                    targetState: operatorState
                    onTriggered: expressionBuilder.push(calculationResult);
                }
            } // End of resultState
        } // End of operationState
    } // End of clearState
}
