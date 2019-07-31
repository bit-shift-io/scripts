#!/usr/bin/env python
#-*- coding: utf-8 -*-

#
#     ID=$(id -nu)
#    usermod -aG uucp,lock $ID
#    sudo pacman -S libcec

import os
import sys
import time
import subprocess
import dbus
import time

log_to_file = False

def has_inhibit():
    bus = dbus.SessionBus()
    pm = bus.get_object("org.freedesktop.PowerManagement", "/org/freedesktop/PowerManagement/Inhibit")
    return pm.HasInhibit()
    

def runCommand(command):
    result = ""
    try:
        result = subprocess.check_output(command, shell=True).decode("utf-8")
    except subprocess.CalledProcessError as e:
        log(e.output.decode("utf-8"))
    return result


def is_monitor_on():
    # assume monitor is on if inhibit is enabled/dpms disabled
	if not is_dpms_enabled():
		return True
    
	if runCommand("xset -q").find("Monitor is On") != -1:
		return True

	return False


def is_dpms_enabled():
    if runCommand("xset -q").find("DPMS is Enabled") != -1:
        return True
		
    return False


def send_cec_command(is_monitor_on):
    # commands will fail if cec device not found
    if (is_monitor_on):
        log("turning screen on")
        runCommand("echo 'on 0' | cec-client -s")
    else:
        log("turning screen off")
        runCommand("echo 'standby 0' | cec-client -s")
        
        
def set_defaults(): 
    # https://forum.kde.org/viewtopic.php?t=108974
    #runCommand("xset dpms 360 420 480") # timeout standby, suspend, off in seconds
    #runCommand("xset +dpms") # enable dpms
    return


def get_time():
    stamp = int(time.time())
    return stamp


def log(str=''):
    print(str)
    if not log_to_file:
        return

    with open("log.txt", "a") as f:
        f.write(str + '\n')
        f.close()
    return


		
if __name__ == '__main__':
    log('Started...')
    log('found device:')
    log(runCommand('lsusb | grep "CEC"'))

    set_defaults()
    prev_monitor_state = is_monitor_on()
    prev_inhibit_state = has_inhibit()
    prev_dpms_state = is_dpms_enabled()
    max_screen_on_time = 3 * 60 * 60 # hours * minutes * seconds
    screen_on_time = get_time()
    
    
    log('startup monitor on: ' + str(prev_monitor_state))
    log('startup dpms enabled: ' + str(prev_dpms_state))
    log()
    
    while True:
        time.sleep(1)
        
        # get dpms state
        # if dpms is off, we assume the monitor is on
        dpms_enabled = is_dpms_enabled()
        if (dpms_enabled != prev_dpms_state):
            prev_dpms_state = dpms_enabled
            log('dpms state change')
        
        # get monitor state
        monitor_state_changed = False
        monitor_on = is_monitor_on()
        
        if prev_monitor_state != monitor_on:
            prev_monitor_state = monitor_on
            monitor_state_changed = True
            log('monitor state change')
            
        # inhibit state
        inhibit_state_changed = False
        inhibit_state = has_inhibit()
        if prev_inhibit_state != inhibit_state:
            prev_inhibit_state = inhibit_state
            inhibit_state_changed = True
            log('inhibit state change')
            
        # toggle screen
        if (dpms_enabled and monitor_state_changed):    
            # send cec command
            log("Monitor on: " + str(monitor_on))
            send_cec_command(monitor_on)
            
        # restart sleep timer
        if (monitor_state_changed and monitor_on == True):
            screen_on_time = get_time()
            
        # restart timer
        # this can only happen if screen is on
        if inhibit_state_changed:
            screen_on_time = get_time()
            
        # screen screen timer
        if (monitor_on == True and (get_time() - screen_on_time) > max_screen_on_time):
            log("Force sleep")
            runCommand("xset dpms force off")
