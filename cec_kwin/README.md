# CEC_KWIN

This is a KWin script that connects your external CEC device in order to turn your TV/Monitor on and off when KDE attempts to do so.

## Install

Run ```./install.sh```

This will build the plugin into a distributable zip and install it on your system.


More info here: https://develop.kde.org/docs/plasma/kwin/

## Develop

Open the script runner:

```plasma-interactiveconsole --kwin```

To view the script print outputs:

```journalctl -f QT_CATEGORY=js QT_CATEGORY=kwin_scripting```


More info here: https://develop.kde.org/docs/plasma/kwin/

## Notes