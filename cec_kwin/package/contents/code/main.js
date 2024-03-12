function aboutToTurnOff() {
    print("about to turn off...")

    // qdbus6 org.kde.krunner /org/kde/krunner org.kde.KDBusService.CommandLine "[kconsole]" "/home/" ???
    // method int org.kde.KDBusService.CommandLine(QStringList arguments, QString working-dir, QVariantMap platform-data)
    // https://www.reddit.com/r/kde/comments/uvbt3i/comment/i9l90lu/

    //callDBus('org.kde.klauncher5', '/KLauncher', 'exec_blind', '/usr/bin/bash', "echo 'standby 0' | cec-client -s");
    callDBus('org.kde.krunner', '/org/kde/krunner', 'org.kde.KDBusService.CommandLine', ['/usr/bin/konsole'], '/home/', "echo 'standby 0' | cec-client -s");
    print("turned off?")
}

function wakeUp() {
    print("wake up....")
    //callDBus('org.kde.klauncher5', '/KLauncher', 'exec_blind', '/usr/bin/bash', "echo 'on 0' | cec-client -s");
    print("woken?")
}

let screens = workspace.screens
print("starting cec_kwin.", screens.length, " screens found.")

screens.forEach(screen => {
    screen.aboutToTurnOff.connect(aboutToTurnOff)
    screen.wakeUp.connect(wakeUp)
})
