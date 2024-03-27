function callDbusMethod(methodName, args) {
    print("[cec_kwin] callDbusMethod: ", methodName, " args:", args)
    callDBus("io.bitshift.dbus_service", "/io/bitshift/dbus_service", "io.bitshift.dbus_service", methodName, args, function (r) {
        print("[cec_kwin]", methodName, "successfully called. Returned:", r)
    })
}

function aboutToTurnOff() {
    callDbusMethod("aboutToTurnOff")
}

function wakeUp() {
    callDbusMethod("wakeUp")
}

function screensChanged() {
    let screens = workspace.screens
    print("[cec_kwin] screensChanged.", screens.length, "screens found.")

    if (screens.length) {
        let firstScreen = screens[0]
        firstScreen.aboutToTurnOff.connect(aboutToTurnOff)
        firstScreen.wakeUp.connect(wakeUp)
    }
}


print("[cec_kwin] Starting.")
workspace.screensChanged.connect(screensChanged)
screensChanged()