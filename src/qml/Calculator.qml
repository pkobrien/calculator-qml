import QtQuick 2.4
import "." as App

App.CalculatorForm {
    id: calculator

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
