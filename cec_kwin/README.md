# CEC_KWIN

Connect your external CEC device in order to turn your TV/Monitor on and off when KDE attempts to do so.

## Install

Run ```./install.sh```

This will build the plugin into a distributable zip and install it on your system.

You then need to open "KWin Scripts" and enable the script.


Run ```./dbus_service.py``` which listens for the dbus events fired from the kwin plugin (this will need to be setup as a systemd service).

More info here: https://askubuntu.com/questions/150790/how-do-i-run-a-script-on-a-dbus-signal

More info here: https://develop.kde.org/docs/plasma/kwin/

## Develop

Open the script runner:

```plasma-interactiveconsole --kwin```

To view the script print outputs:

```journalctl -f QT_CATEGORY=js QT_CATEGORY=kwin_scripting```


More info here: https://develop.kde.org/docs/plasma/kwin/

## Notes