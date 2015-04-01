import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Controls.Styles 1.3

Button {
    id: key

    width: 48
    height: 48

    implicitWidth: 48
    implicitHeight: 48

    property real fontSize: 20

    text: "X"

    style: ButtonStyle {
        label: Label {
            font.pixelSize: key.fontSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: key.text
        }
    }
}

