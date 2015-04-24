import QtQuick 2.4
import "." as App

QtObject {
    id: expressionBuilder
    
    property bool errorMode: false
    
    property string text: ""
    
    property var __buffer: []

    signal error()
    
    onError: errorMode = true;
    
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
        __buffer.push(App.Util.stringify(value));
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
