import QtQuick 2.4

QtObject {
    id: memory
    
    property bool active: false
    property string key
    property double value: 0.0
    
    function clear() {
        active = false;
        value = 0.0;
    }
    
    function recall() {
        return value;
    }
    
    function update(num) {
        active = true;
        switch (key) {
            case "ms":
            case "sm":
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
