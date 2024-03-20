function callDbusMethod(methodName, args) {
    print("callDbusMethod: ", methodName, " args:", args)
    callDBus("io.bitshift.dbus_service", "/io/bitshift/dbus_service", "io.bitshift.dbus_service", methodName, args);
}

function aboutToTurnOff() {
    callDbusMethod("aboutToTurnOff");
}

function wakeUp() {
    callDbusMethod("wakeUp");
}

let screens = workspace.screens
print("starting cec_kwin.", screens.length, " screens found.")

if (screens.length) {
    let firstScreen = screens[0]
    firstScreen.aboutToTurnOff.connect(aboutToTurnOff)
    firstScreen.wakeUp.connect(wakeUp)
}