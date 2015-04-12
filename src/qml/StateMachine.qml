import QtQuick 2.4
import QtQml.StateMachine 1.0 as DSM

DSM.StateMachine {
    id: sm

    property alias config: config

    property real calculationResult
    property string calculationResultText: stringify(calculationResult)
    property string display
    property string expression: expressionBuilder.text
    property string errorMessage
    property string key
    property string operandBuffer
    property real operand1
    property real operand2
    property string operator1
    property string operator2

    property var groupKeysMap: ({})
    property var keyNoopMap: ({})
    property var keySignalMap: ({})

    property var keysList: [
        {group: "addsub", signal: addsubPressed, keys: ["+", "-"]},
        {group: "clear", signal: clearPressed, keys: ["c"]},
        {group: "digit", signal: digitPressed,
            keys: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]},
        {group: "equal", signal: equalPressed, keys: ["="]},
        {group: "function", signal: functionPressed,
            keys: ["acos", "asin", "atan", "cos", "exp", "log", "sqr", "sqrt"]},
        {group: "muldiv", signal: muldivPressed, keys: ["*", "/"]},
        {group: "point", signal: pointPressed, keys: ["."]},
        {group: "zero", signal: zeroPressed, keys: ["0"]},
    ]

    property var noopKeys: []

    readonly property int significantDigits: 13
    readonly property var trailingZerosRegExp: /0+$/
    readonly property var trailingPointRegExp: /\.$/

    signal addsubPressed()
    signal clearPressed()
    signal digitPressed()
    signal equalPressed()
    signal error()
    signal functionPressed()
    signal muldivPressed()
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
        if (Object.keys(keySignalMap).length) {
            return;
        }
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
    }

    function stringify(value) {
        var newValue = value;
        if (typeof value === "number") {
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
            id: accumulateState
            initialState: zeroState

            onEntered: {
                display = Qt.binding(show);
                expressionBuilder.push("");
            }

            function show() {
                return withTrailingPoint(operandBuffer);
            }

            DSM.SignalTransition {
                signal: error
                targetState: errorState
            }
            DSM.SignalTransition {
                signal: addsubPressed
                targetState: operatorState
                onTriggered: calculateAll(false);
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
            DSM.SignalTransition {
                signal: functionPressed
                guard: operandBuffer
                onTriggered: applyMathFunction();
            }

            DSM.State {
                id: digitState
                onEntered: {
                    operandBuffer = (operandBuffer === "0") ? "" : operandBuffer;
                    accumulate();
                    noopKeys = (operator1) ? [] : groupKeysMap["equal"];
                }
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
                onEntered: {
                    operandBuffer = (operandBuffer === "") ? "0" : operandBuffer;
                    accumulate();
                    noopKeys = (operator1) ? [] : [].concat(groupKeysMap["equal"],
                                                            groupKeysMap["point"]);
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
                    noopKeys = (operator1) ? [] : [].concat(groupKeysMap["equal"],
                                                            groupKeysMap["zero"]);
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
                }
            }
        }

        DSM.State {
            id: computeState

            DSM.SignalTransition {
                signal: error
                targetState: errorState
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
                id: errorState

                onEntered: {
                    display = errorMessage;
                    noopKeys = [].concat(groupKeysMap["addsub"],
                                         groupKeysMap["equal"],
                                         groupKeysMap["function"],
                                         groupKeysMap["muldiv"]);
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
                    noopKeys = groupKeysMap["function"];
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
                        operandBuffer = stringify(operand1);
                        operand2 = 0.00;
                        operator2 = "";
                    }
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
                                [] : groupKeysMap["equal"];
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
                    signal: equalPressed
                    guard: sm.config.equalKeyRepeatsLastOperation
                    onTriggered: {
                        // Repeat the last operation using the
                        // previous buffer and operator.
                        operator1 = resultState.lastOperator;
                        resultState.update();
                    }
                }
                DSM.SignalTransition {
                    signal: addsubPressed
                    targetState: operatorState
                    onTriggered: expressionBuilder.push(calculationResult);
                }
                DSM.SignalTransition {
                    signal: muldivPressed
                    targetState: operatorState
                    onTriggered: expressionBuilder.push(calculationResult);
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
            }
        }
    }
}
