pragma Singleton

import QtQuick 2.4

QtObject {
    id: activeSingleton

    property var appWindow
    property var calculator
    property bool logging: true
}
