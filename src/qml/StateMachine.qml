import QtQuick 2.4
import QtQml.StateMachine 1.0 as DSM

DSM.StateMachine {
    id: sm

    property alias config: config

    property real calculationResult
    property string display
    property string expression: expressionBuilder.text
    property string errorMessage
    property string key
    property string operandBuffer
    property real operand1
    property real operand2
    property string operator1
    property string operator2

    readonly property int significantDigits: 13
    readonly property var trailingZerosRegExp: /0+$/
    readonly property var trailingPointRegExp: /\.$/

    signal addsubPressed()
    signal clearPressed()
    signal digitPressed()
    signal equalPressed()
    signal functionPressed()
    signal muldivPressed()
    signal pointPressed()
    signal zeroPressed()

    function accumulate() {
        operandBuffer = (operandBuffer === "0") ? "" : operandBuffer;
        operandBuffer = (!operandBuffer && key === ".") ? "0" : operandBuffer;
        operandBuffer = (!key) ? "0" : operandBuffer;
        operandBuffer += key;
        var last = expressionBuilder.pop();
        last = (last === "0") ? "" : last;
        last += (operandBuffer === "0.") ? "0." : key;
        expressionBuilder.push(last);
    }

    function calculateAll() {
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
        calculationResult = operand1;
    }

    function calculateFunction() {
        var num = Number(operandBuffer);
        var mathFunction = Math[key];
        var newValue = mathFunction(num);
        operandBuffer = stringify(newValue);
        if (!operator1) {
            operand1 = newValue;
            calculationResult = newValue;
        }
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

    function process(input) {
        key = input.toLowerCase();
        var accepted = true;
        switch (key) {
            default:
                accepted = false;
                break;
            case "1": case "2": case "3":
            case "4": case "5": case "6":
            case "7": case "8": case "9":
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
            case "sqrt":
                functionPressed();
                break;
        }
        return accepted;
    }

    function reset() {
        calculationResult = 0.0;
        display = "";
        errorMessage = "";
        expressionBuilder.clear();
        key = "";
        operandBuffer = "";
        operand1 = 0.0;
        operand2 = 0.0;
        operator1 = "";
        operator2 = "";
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

    function withTrailingDecimal(value) {
        var newValue = stringify(value);
        return newValue.indexOf(".") === -1 ? newValue + "." : newValue;
    }

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

        property string text: ""

        property var __buffer: []

        function clear() {
            __buffer.length = 0;
            _updateText();
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
            id: errorState
            onEntered: {
                display = Qt.binding(show);
                expressionBuilder.clear();
                expressionBuilder.push("Press Clear to continue...");
            }

            function show() {
                return errorMessage;
            }
        }

        DSM.State {
            id: accumulateState
            initialState: zeroState

            onEntered: {
                display = Qt.binding(show);
                expressionBuilder.push("");
            }

            function show() {
                return withTrailingDecimal(operandBuffer);
            }

            DSM.SignalTransition {
                signal: addsubPressed
                targetState: operatorState
                onTriggered: calculateAll();
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
                targetState: functionState
            }

            DSM.State {
                id: digitState
                onEntered: accumulate();
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
                onEntered: accumulate();
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
                onEntered: accumulate();
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
                id: functionState

                onEntered: {
                    display = Qt.binding(show);
                    update();
                }

                function show() {
                    return withTrailingDecimal(operandBuffer);
                }

                function update() {
                    var exp = "%1(%2)".arg(key).arg(expressionBuilder.pop());
                    calculateFunction();
                    expressionBuilder.push(exp);
                }

                DSM.SignalTransition {
                    signal: functionPressed
                    onTriggered: {
                        functionState.update();
                    }
                }
                DSM.SignalTransition {
                    signal: addsubPressed
                    targetState: operatorState
                    onTriggered: calculateAll();
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
            }

            DSM.State {
                id: operatorState

                onEntered: {
                    updateOperator();
                    display = Qt.binding(show);
                }

                onExited: clear();

                function clear() {
                    operandBuffer = "";
                }

                function show() {
                    var value = operator2 ? operandBuffer : operand1;
                    return withTrailingDecimal(value);
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
                DSM.SignalTransition {
                    signal: functionPressed
                }
            }

            DSM.State {
                id: resultState

                property string lastOperator

                onEntered: {
                    display = Qt.binding(show);
                    lastOperator = operator1;
                    update();
                }

                onExited: clear();

                function clear() {
                    lastOperator = "";
                    operandBuffer = "";
                    operator1 = "";
                    expressionBuilder.clear();
                }

                function show() {
                    return withTrailingDecimal(calculationResult);
                }

                function update() {
                    calculateAll();
                    expressionBuilder.push("=");
                    expressionBuilder.push(calculationResult);
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
                    targetState: functionState
                    onTriggered: {
                        operandBuffer = stringify(calculationResult);
                        expressionBuilder.push(calculationResult);
                    }
                }
            }
        }
    }
}
