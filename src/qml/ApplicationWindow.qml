import QtQuick 2.4
import QtQuick.Window 2.2
import Candy 1.0 as Candy
import "." as App

Candy.ApplicationWindow {
    id: appWindow

    title: qsTr("Calculator")
    visible: true

    contentItem.implicitWidth: calculator.implicitWidth
    contentItem.implicitHeight: calculator.implicitHeight

    contentItem.maximumWidth: calculator.maximumWidth
    contentItem.maximumHeight: calculator.maximumHeight

    contentItem.minimumWidth: calculator.minimumWidth
    contentItem.minimumHeight: calculator.minimumHeight

    Component.onCompleted: {
        Candy.Units.scaleFactor = 3.0;
        App.Active.appWindow = appWindow;
        App.Active.calculator = calculator;
    }

    menuBar: App.MenuBar { }

//    toolBar: App.ToolBar { }

    App.Calculator {
        id: calculator
    }
}
