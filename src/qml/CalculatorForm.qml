import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.3
import "." as App

Rectangle {
    id: calculator
    width: 400
    height: 400

    property alias calculatorStateMachine: csm

    App.CalculatorStateMachine {
        id: csm
        running: true
    }

    Grid {
        anchors.fill: parent
        columns: 2
        rows: 10

        Label {
            text: qsTr("Attempted Key:")
        }
        Label {
            text: csm.attemptedKey ? csm.attemptedKey : "..."
        }

        Label {
            text: qsTr("Accepted Key:")
        }
        Label {
            text: csm.acceptedKey ? csm.acceptedKey : "..."
        }

        Label {
            text: qsTr("Buffer:")
        }
        Label {
            text: csm.buffer ? csm.buffer : "..."
        }

        Label {
            text: qsTr("Display:")
        }
        Label {
            text: csm.display ? csm.display : "..."
        }

        Label {
            text: qsTr("Error Message:")
        }
        Label {
            text: csm.errorMessage ? csm.errorMessage : "..."
        }

        Label {
            text: qsTr("Operand 1:")
        }
        Label {
            text: csm.operand1 ? csm.operand1 : "..."
        }

        Label {
            text: qsTr("Operator 1:")
        }
        Label {
            text: csm.operator1 ? csm.operator1 : "..."
        }

        Label {
            text: qsTr("Operand 2:")
        }
        Label {
            text: csm.operand2 ? csm.operand2 : "..."
        }

        Label {
            text: qsTr("Operator 2:")
        }
        Label {
            text: csm.operator2 ? csm.operator2 : "..."
        }

        Label {
            text: qsTr("Result:")
        }
        Label {
            text: csm.result ? csm.result : "..."
        }
    }
}
