import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.3
import "." as App

Rectangle {
    id: display

    property var calculator
    property var engine

    width: grid.childrenRect.width
    height: grid.childrenRect.height

    Grid {
        id: grid

        columns: 2
        spacing: 4

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
            text: engine.display ? engine.display : "..."
        }

        Label {
            text: qsTr("Expression:")
        }
        Label {
            text: engine.expression ? engine.expression : "..."
        }

        Label {
            text: qsTr("Result:")
        }
        Label {
            text: engine.result
        }
    }
}
