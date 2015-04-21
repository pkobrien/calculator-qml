import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Window 2.2
import "." as App

ApplicationWindow {
    id: appWindow

    property var dp: App.Units.dp

    title: qsTr("Calculator")

    contentItem.implicitWidth: calculator.implicitWidth
    contentItem.implicitHeight: calculator.implicitHeight

    contentItem.maximumWidth: calculator.maximumWidth
    contentItem.maximumHeight: calculator.maximumHeight

    contentItem.minimumWidth: calculator.minimumWidth
    contentItem.minimumHeight: calculator.minimumHeight

    Component.onCompleted: {
        App.Units.pixelDensity = Qt.binding(function()
                                            { return Screen.pixelDensity; });
        App.Units.scaleFactor = 3.0;
        visible = true;
    }

    menuBar: App.MenuBar { }

//    toolBar: App.ToolBar { }

    App.Calculator {
        id: calculator
    }
}
