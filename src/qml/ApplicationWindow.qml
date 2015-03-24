import QtQuick 2.4
import QtQuick.Window 2.2
import Candy 1.0 as Candy
import "." as App

Candy.ApplicationWindow {
    id: appWindow

    title: qsTr("Calculator")
    visible: true

    width: 800
    height: 600

//    x: Math.max(0, Math.round((Screen.width - width) / 2))
//    y: Math.max(0, Math.round((Screen.height - height) / 2))

    Component.onCompleted: {
        Candy.Units.scaleFactor = 2.0;
//        appWindow.width = Qt.binding(function() { return calculator.width + dp(100); });
//        appWindow.height = Qt.binding(function() { return calculator.height + dp(160); });
        App.Active.appWindow = appWindow;
        App.Active.calculator = calculator;
    }

    menuBar: App.MenuBar { }

//    toolBar: App.ToolBar { }

    App.Calculator {
        id: calculator
        anchors.centerIn: parent
    }
}
