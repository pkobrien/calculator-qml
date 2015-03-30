import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.3
import "." as App

GridLayout {
    id: keyGrid

//    width: dp(48) * columns

    property var engine
    property var model

    Repeater {
        model: keyGrid.model

        App.Key {
            engine: keyGrid.engine
            text: modelData.toString()
            value: modelData.toString()
        }
    }
}
