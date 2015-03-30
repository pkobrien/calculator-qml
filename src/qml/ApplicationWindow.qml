import QtQuick 2.4
import QtQuick.Window 2.2
import Candy 1.0 as Candy
import "." as App

Candy.ApplicationWindow {
    id: appWindow

    title: qsTr("Calculator")
    visible: true

    width: calculator.width + dp(16)
    height: calculator.height + dp(16)

    Component.onCompleted: {
        Candy.Units.scaleFactor = 2.0;
        App.Active.appWindow = appWindow;
        App.Active.calculator = calculator;
    }

//    menuBar: App.MenuBar { }

//    toolBar: App.ToolBar { }

    App.Calculator {
        id: calculator
        anchors.centerIn: parent
    }
}
