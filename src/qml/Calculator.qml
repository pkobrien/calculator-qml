import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.3
import "." as App

Rectangle {
    id: calculator

    width: main.childrenRect.width
    height: main.childrenRect.height

    property bool accepted
    property string acceptedKey: accepted ? attemptedKey : "";
    property string attemptedKey: ""

    property alias engine: engine

    App.Engine {
        id: engine

        Component.onCompleted: engine.start();
    }

    Column {
        id: main

        spacing: dp(8)

        App.Display {
            calculator: calculator
            engine: engine
        }

        App.Keypad {
            engine: engine
        }
    }

    focus: true

    Keys.onPressed: {
        App.Actions.keyPressed(event, calculator);
        if (!event.accepted) {
            attemptedKey = event.text;
            accepted = engine.process(attemptedKey);
            event.accepted = accepted;
        }
    }
}
