#!/usr/bin/env python
#-*- coding: utf-8 -*-

"""
dbus service that listens for method calls sent from the kwin script. This will then try to take some action, 
typically attempt to execute a script sh script by the same name as the kwin script method.
"""

import subprocess
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import os

def script_path(): 
    return os.path.dirname(os.path.realpath(__file__))


class Service(dbus.service.Object):
    def __init__(self):
        self._loop = GLib.MainLoop()

    def run(self):
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        bus_name = dbus.service.BusName("io.bitshift.dbus_service", dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, "/io/bitshift/dbus_service")

        print("Service running from " + script_path() + "...")
        self._loop.run()
        print("Service stopped")

    @dbus.service.method("io.bitshift.dbus_service", in_signature="", out_signature="")
    def aboutToTurnOff(self):
        print(f"aboutToTurnOff")
        self.run_command(". " + script_path() + "/aboutToTurnOff.sh")

    @dbus.service.method("io.bitshift.dbus_service", in_signature="", out_signature="")
    def wakeUp(self):
        print(f"wakeUp")
        self.run_command(". " + script_path() + "/wakeUp.sh")

    @dbus.service.method("io.bitshift.dbus_service", in_signature="s", out_signature="i")
    def run_command(self, m):
        print(f"Running command '{m}'")
        command = m.split()
        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=True,
        )

        print(f"exit code: '{result.returncode}'")
        print(f"stdout: '{result.stdout.strip()}'")
        return result.returncode

    # @dbus.service.method("io.bitshift.dbus_service", in_signature="", out_signature="i")
    # def notify_send(self):
    #     command = ["notify-send", "Hello", "World"]
    #     command_str = " ".join(command)
    #     print(f"Running command '{command_str}'")
    #     result = subprocess.run(
    #         command,
    #         stdout=subprocess.PIPE,
    #         stderr=subprocess.STDOUT,
    #         text=True,
    #         check=True,
    #     )

    #     print(f"exit code: '{result.returncode}'")
    #     print(f"stdout: '{result.stdout.strip()}'")
    #     return result.returncode

    @dbus.service.method("io.bitshift.dbus_service", in_signature="", out_signature="")
    def quit(self):
        print("Shutting down")
        self._loop.quit()


if __name__ == "__main__":
    Service().run()