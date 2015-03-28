QT += qmltest qml quick
QT -= gui
TEMPLATE = app
TARGET = tst_calculator
CONFIG += warn_on qmltestcase
SOURCES += tst_calculator.cpp
OTHER_FILES +=

DISTFILES += \
    tst_CalculatorEngine.qml
