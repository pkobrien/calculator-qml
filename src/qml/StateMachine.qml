import QtQuick 2.4
import QtQml.StateMachine 1.0 as DSM

DSM.StateMachine {
    id: sm

    property alias config: config

    property double calculationResult
    property string calculationResultText: stringify(calculationResult)
    property string display
    property string expression: expressionBuilder.text
    property string errorMessage
    property string key
    property string memoryText: memory.text
    property string operandBuffer
    property double operand1
    property double operand2
    property string operator1
    property string operator2

    property var groupKeysMap: ({})
    property var keyNoopMap: ({})
    property var keySignalMap: ({})

    property var keysList: [
        {group: "AddSub", signal: addSubPressed, keys: ["+", "-"]},
        {group: "Clear", signal: clearPressed, keys: ["c"]},
        {group: "Digit", signal: digitPressed,
            keys: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]},
        {group: "Equal", signal: equalPressed, keys: ["="]},
        {group: "Function", signal: functionPressed,
            keys: ["acos", "asin", "atan", "cos", "exp", "log", "sqr", "sqrt"]},
        {group: "MemoryClear", signal: memoryClearPressed, keys: ["mc", "cm"]},
        {group: "MemoryRecall", signal: memoryRecallPressed, keys: ["mr", "rm"]},
        {group: "MemoryUpdate", signal: memoryUpdatePressed, keys: ["m+", "m-", "ms", "sm"]},
        {group: "MulDiv", signal: mulDivPressed, keys: ["*", "/"]},
        {group: "Point", signal: pointPressed, keys: ["."]},
        {group: "Zero", signal: zeroPressed, keys: ["0"]},
    ]

    property var noopKeys: []

    readonly property int significantDigits: 13
    readonly property var trailingZerosRegExp: /0+$/
    readonly property var trailingPointRegExp: /\.$/

    property bool __setup: false

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
        operandBuffer = stringify(newValue);
        if (!operator1) {
            operand1 = newValue;
            calculationResult = newValue;
        }
    }

    function calculateAll(updateExpression) {
        var num = Number(operandBuffer);
        if (operator2) {
            switch (operator2) {
                case "*":
                    num *= operand2;
                    break;
                case "/":
                    num /= operand2;
                    break;
            }
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
    }

    function calculateLast() {
        var num = Number(operandBuffer);
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

    function clearOperandBuffer() {
        expressionBuilder.pop();
        operandBuffer = "";
    }

    function replaceOperandBuffer(value) {
        clearOperandBuffer();
        operandBuffer = stringify(value);
        expressionBuilder.push(operandBuffer);
    }

    function noop(uiKey) {
        return (supports(uiKey)) ? keyNoopMap[uiKey.toLowerCase()].noop : true;
    }

    function process(uiKey) {
        var accepted = false;
        key = uiKey.toLowerCase();
        if (key in keySignalMap) {
            accepted = true;
            keySignalMap[key]();
        }
        return accepted;
    }

    function reset() {
        calculationResult = 0.0;
        display = "";
        errorMessage = "ERROR";
        expressionBuilder.errorMode = false;
        expressionBuilder.clear();
        key = "0";
        noopKeys = [];
        operandBuffer = "";
        operand1 = 0.0;
        operand2 = 0.0;
        operator1 = "";
        operator2 = "";
    }

    function setup() {
        if (__setup) {
            return;
        }
        reset();
        var qml = "import QtQuick 2.4; QtObject { property bool noop: false }"
        for (var i = 0; i < keysList.length; i++) {
            var map = keysList[i];
            groupKeysMap[map.group] = map.keys;
            for (var j = 0; j < map.keys.length; j++) {
                var key = map.keys[j];
                keyNoopMap[key] = Qt.createQmlObject(qml, sm, "NoopQtObject");
                keySignalMap[key] = map.signal;
            }
        }
        __setup = true;
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

    function supports(uiKey) {
        // We need to call setup() here because this function can get called
        // before Component.onCompleted() takes place, unfortunately.
        setup();
        return (uiKey.toLowerCase() in keySignalMap);
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

    function withTrailingPoint(value) {
        var newValue = stringify(value);
        return (newValue.indexOf(".") === -1) ? newValue + "." : newValue;
    }

    onCalculationResultChanged: {
        if (!isFinite(calculationResult)) {
            error();
        }
    }

    onError: {
        expressionBuilder.errorMode = true;
    }

    onNoopKeysChanged: {
        for (var key in keyNoopMap) {
            keyNoopMap[key].noop = (noopKeys.indexOf(key) !== -1);
        }
    }

    onStopped: reset();

    Component.onCompleted: setup();

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

        function _updateText() {
            text = __buffer.join(" ");
        }
    }

    QtObject {
        id: memory

        property bool active: false
        property string text: (!active) ? "" : stringify(value)
        property double value: 0.0

        function clear() {
            active = false;
            value = 0.0;
        }

        function recall() {
            replaceOperandBuffer(value);
        }

        function update(input) {
            active = true;
            var num = Number(input);
            value = value || 0.0;
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
        id: noopGroups

        property var __buffer: []

        function clear() {
            __buffer.length = 0;
        }

        function remove(groups) {
            var index;
            for (var group in groups) {
                for (var noopKey in groupKeysMap[group]) {
                    index = __buffer.indexOf(noopKey);
                    if (index !== -1) {
                        __buffer.splice(index, 1);
                    }
                }
            }
            noopKeys = __buffer;
        }

        function add(groups) {
            for (var group in groups) {
                __buffer.concat(groupKeysMap[group]);
            }
            noopKeys = __buffer;
        }
    }

    initialState: clearState

    DSM.State {
        id: clearState

        initialState: accumulateState

        DSM.SignalTransition {
            signal: clearPressed
            targetState: clearState
            onTriggered: reset();
        }
        DSM.SignalTransition {
            signal: digitPressed
            targetState: digitState
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
            signal: pointPressed
            targetState: pointState
        }
        DSM.SignalTransition {
            signal: zeroPressed
            targetState: zeroState
        }

        DSM.State {
            id: accumulateState
            initialState: zeroState

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
                onTriggered: applyMathFunction();
            }
            DSM.SignalTransition {
                signal: memoryUpdatePressed
                targetState: memoryUpdateState
                onTriggered: memory.update(operandBuffer);
            }
            DSM.SignalTransition {
                signal: mulDivPressed
                targetState: operatorState
                onTriggered: calculateLast();
            }

            DSM.State {
                id: digitState
                property var noops: ["Equal"]
                onEntered: {
                    operandBuffer = (operandBuffer === "0") ? "" : operandBuffer;
                    accumulate();
                    if (!operator1) {
                        noopGroups.add(noops);
                    }
//                    noopKeys = (operator1) ? [] : groupKeysMap["Equal"];
                }
                onExited: {
                    noopGroups.remove(noops);
                }

                DSM.SignalTransition {
                    signal: digitPressed
                    onTriggered: accumulate();
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                    onTriggered: accumulate();
                }
            }

            DSM.State {
                id: memoryState
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
                    targetState: zeroState;
                    onTriggered: clearOperandBuffer();
                }

                DSM.State {
                    id: memoryRecallState
                    onEntered: {
                        memory.recall();
                        noopKeys = groupKeysMap["MemoryRecall"];
                    }
                    DSM.SignalTransition {
                        signal: memoryRecallPressed
                    }
                }

                DSM.State {
                    id: memoryUpdateState
                    DSM.SignalTransition {
                        signal: memoryUpdatePressed
                        onTriggered: memory.update(operandBuffer);
                    }
                }
            }

            DSM.State {
                id: pointState
                onEntered: {
                    operandBuffer = (operandBuffer === "") ? "0" : operandBuffer;
                    accumulate();
                    noopKeys = groupKeysMap["Point"];
                    if (!operator1) {
                        noopKeys.concat(groupKeysMap["Equal"]);
                    }
                }
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
                onEntered: {
                    accumulate();
                    noopKeys = groupKeysMap["Zero"];
                    if (!operator1) {
                        noopKeys.concat(groupKeysMap["Equal"]);
                    }
                }
                DSM.SignalTransition {
                    signal: zeroPressed
                }
            }
        }

        DSM.State {
            id: errorState

            onEntered: {
                display = errorMessage;
                noopKeys = [].concat(groupKeysMap["AddSub"],
                                     groupKeysMap["Equal"],
                                     groupKeysMap["Function"],
                                     groupKeysMap["MemoryUpdate"],
                                     groupKeysMap["MulDiv"]);
            }
            onExited: {
                var temp = key;
                reset();
                key = temp;
            }
        }

        DSM.State {
            id: operatorState

            onEntered: {
                display = Qt.binding(show);
                updateOperator();
                noopKeys = [].concat(groupKeysMap["Function"],
                                     groupKeysMap["MemoryUpdate"]);
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
        }

        DSM.State {
            id: resultState

            property string lastOperator

            onEntered: {
                display = Qt.binding(show);
                lastOperator = operator1;
                update();
                noopKeys = (sm.config.equalKeyRepeatsLastOperation) ?
                            [] : groupKeysMap["Equal"];
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
                guard: (sm.config.equalKeyRepeatsLastOperation)
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
        }
    }
}
