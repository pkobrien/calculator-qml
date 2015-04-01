import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.3
import "." as App

Rectangle {
    id: display

    property var engine

    implicitHeight: main.implicitHeight

    ColumnLayout {
        id: main

        anchors.left: parent.left
        anchors.leftMargin: dp(4)
        anchors.right: parent.right
        anchors.rightMargin: dp(4)
        spacing: dp(4)

        Label {
            text: engine.display
            font.pixelSize: dp(28)
            horizontalAlignment: Text.AlignRight
            Layout.fillWidth: true
        }

        Label {
            text: engine.expression
            font.pixelSize: dp(12)
            Layout.fillWidth: true
        }

        Label {
            text: engine.result
            font.pixelSize: dp(18)
            Layout.fillWidth: true
        }
    }
}
