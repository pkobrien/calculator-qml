import QtQuick 2.4
import "." as App

App.KeyForm {
    id: key

    implicitWidth: dp(48)
    implicitHeight: dp(48)

    fontSize: dp(20)

    property var engine
//    property bool noop: engine.isNoop(value)
    property bool noop: engine.noopKeys.indexOf(value.toLowerCase()) !== -1
    property string value

    onClicked: engine.process(key.value);
}
