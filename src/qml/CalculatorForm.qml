import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.3
import "." as App

Rectangle {
    id: calculator
    width: 400
    height: 400

    property bool accepted
    property string acceptedKey: accepted ? attemptedKey : "";
    property string attemptedKey: ""

    property alias csm: csm

    App.CalculatorStateMachine {
        id: csm
        running: true
    }

    Grid {
        anchors.fill: parent
        columns: 2

        Label {
            text: qsTr("Attempted Key:")
        }
        Label {
            text: calculator.attemptedKey ? calculator.attemptedKey : "..."
        }

        Label {
            text: qsTr("Accepted Key:")
        }
        Label {
            text: calculator.acceptedKey ? calculator.acceptedKey : "..."
        }

        Label {
            text: qsTr("Display:")
        }
        Label {
            text: csm.display ? csm.display : "..."
        }

        Label {
            text: qsTr("Expression:")
        }
        Label {
            text: csm.expression ? csm.expression : "..."
        }

        Label {
            text: qsTr("Result:")
        }
        Label {
            text: csm.result
        }
    }
}
