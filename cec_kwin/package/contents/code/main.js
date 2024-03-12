

function aboutToTurnOff() {
    print("about to turn off")
}

function wakeUp() {
    print("wake up")
}

print("starting cec_kwin...")
//print(workspace)
let screens = workspace.screens
//print(screens)

screens.forEach(screen => {
    //print(screen)
    screen.aboutToTurnOff.connect(aboutToTurnOff)
    screen.wakeUp.connect(wakeUp)
})
