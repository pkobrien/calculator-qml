import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.3
import "." as App

Rectangle {
    id: keypad

    property var engine

    implicitWidth: main.implicitWidth
    implicitHeight: main.implicitHeight

    color: "transparent"

    RowLayout {
        id: main

        spacing: dp(8)

        GridLayout {

            columns: 2
            columnSpacing: dp(2)
            rowSpacing: dp(2)

            Repeater {
                model: ["CM", "Up", "RM", "+/-", "M-", "CE", "M+", "C"]

                App.Key {
                    engine: keypad.engine
                    text: modelData
                    value: modelData
                }
            }
        }

        GridLayout {

            columns: 3
            columnSpacing: dp(2)
            rowSpacing: dp(2)

            Repeater {
                model: ["7", "8", "9", "4", "5", "6", "1", "2", "3", "0", "."]

                App.Key {
                    engine: keypad.engine
                    text: modelData
                    value: modelData

                    Binding on Layout.columnSpan {
                        when: modelData == "0"
                        value: 2
                    }

                    Binding on Layout.fillWidth {
                        when: modelData == "0"
                        value: true
                    }
                }
            }
        }
    }
}
