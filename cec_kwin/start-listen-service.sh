#!/bin/bash


# callDBus(QString service, QString path, QString interface, QString method, QVariant arg..., QScriptValue callback = QScriptValue())
interface=org.cec_kwin.Command

dbus-monitor --profile "interface='$interface'" |
while read -r line; do
    echo $line | grep aboutToTurnOff && ./aboutToTurnOff.sh
    echo $line | grep wakeUp && ./wakeUp.sh
done