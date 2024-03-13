function aboutToTurnOff() {
    print("about to turn off...7")

    // qdbus6 org.kde.krunner /org/kde/krunner org.kde.KDBusService.CommandLine "[kconsole]" "/home/" ???
    // method int org.kde.KDBusService.CommandLine(QStringList arguments, QString working-dir, QVariantMap platform-data)
    // https://www.reddit.com/r/kde/comments/uvbt3i/comment/i9l90lu/

    //callDBus('org.kde.klauncher5', '/KLauncher', 'exec_blind', '/usr/bin/bash', "echo 'standby 0' | cec-client -s");
    // ['/usr/bin/konsole']
    /*
    callDBus('org.kde.krunner', '/org/kde/krunner', 'org.kde.KDBusService.CommandLine', ['konsole'], '/home/', "bash -c \"echo 'standby 0' | cec-client -s\"", (res) => {
        print('krunner result 4:', res)
    });
    */

    // callDBus(QString service, QString path, QString interface, QString method, QVariant arg..., QScriptValue callback = QScriptValue())
    callDBus('org.cec_kwin', '/org/cec_kwin', 'org.cec_kwin.Command', 'aboutToTurnOff', [], (res) => {
        print('krunner result 6:', res)
    });
    print("turned off?")
}

function wakeUp() {
    print("wake up....")

    callDBus('org.cec_kwin', '/org/cec_kwin', 'org.cec_kwin.Command', 'wakeUp', [], (res) => {
        print('krunner result 6:', res)
    });

    //callDBus('org.kde.klauncher5', '/KLauncher', 'exec_blind', '/usr/bin/bash', "echo 'on 0' | cec-client -s");
    print("woken?")
}

let screens = workspace.screens
print("starting cec_kwin.", screens.length, " screens found.")

screens.forEach(screen => {
    screen.aboutToTurnOff.connect(aboutToTurnOff)
    screen.wakeUp.connect(wakeUp)
})
