#!/usr/bin/env python

# Install:
#   yay dbus-python


# https://serverfault.com/questions/573379/system-suspend-dbus-upower-signals-are-not-seen#582440

# maybe we can inhibit sleep,
# but turn the tv off when this is requested?
# https://github.com/jnerin/dbus-listen-inhibit 

from datetime import datetime
import dbus
#import gobject
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

def handle_sleep(*args):
    print("%s    PrepareForSleep%s" % (datetime.now().ctime(), args))

DBusGMainLoop(set_as_default=True)     # integrate into gobject main loop
bus = dbus.SystemBus()                 # connect to system wide dbus
bus.add_signal_receiver(               # define the signal to listen to
    handle_sleep,                      # callback function
    'PrepareForSleep',                 # signal name
    'org.freedesktop.login1.Manager',  # interface
    'org.freedesktop.login1'           # bus name
)

loop = GLib.MainLoop() #loop = gobject.MainLoop()
loop.run()