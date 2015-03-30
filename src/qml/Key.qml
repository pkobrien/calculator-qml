import QtQuick 2.4
import QtQuick.Controls 1.3

Button {
    id: key

    width: dp(48)
    height: dp(48)

    property var engine
    property string value

    onClicked: engine.process(key.value);
}
