import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.3
import "." as App

Rectangle {
    id: keypad

    property var engine

    width: main.childrenRect.width
    height: main.childrenRect.height

    Row {
        id: main

        spacing: 8

        App.KeyGrid {
            id: memoryGrid

            columns: 2
            engine: keypad.engine
            model: ["CM", "Up", "RM", "+/-", "M-", "CE", "M+", "C"]
        }

        App.KeyGrid {
            id: digitGrid

            columns: 3
            engine: keypad.engine
            model: ["7", "8", "9", "4", "5", "6", "1", "2", "3", "0", "0", "."]
        }

        App.KeyGrid {
            id: operatorGrid

            columns: 3
            engine: keypad.engine
            model: ["7", "8", "9", "4", "5", "6", "1", "2", "3", "0", "0", "."]
        }
    }
}
