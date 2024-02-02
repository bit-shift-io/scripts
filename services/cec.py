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
    return bool(pm.HasInhibit())
    

def run_command(command):
    result = ""
    try:
        result = subprocess.check_output(command, shell=True).decode("utf-8")
    except subprocess.CalledProcessError as e:
        log(e.output.decode("utf-8"))
    return result


def get_monitor():
    # assume monitor is on if inhibit is enabled/dpms disabled
	if not get_dpms():
		return True
    
	if run_command("xset -q").find("Monitor is On") != -1:
		return True

	return False


def get_dpms():
    if run_command("xset -q").find("DPMS is Enabled") != -1:
        return True
		
    return False


def send_cec_command(state):
    # commands will fail if cec device not found
    if (state):
        log("turning screen on")
        run_command("echo 'on 0' | cec-client -s")
    else:
        log("turning screen off")
        run_command("echo 'standby 0' | cec-client -s")
        
        
def set_defaults(): 
    # https://forum.kde.org/viewtopic.php?t=108974
    #run_command("xset dpms 360 420 480") # timeout standby, suspend, off in seconds
    #run_command("xset +dpms") # enable dpms
    return


def get_time():
    stamp = int(time.time())
    return stamp


def log(str=''):
    print(str)
    if not log_to_file:
        return

    with open("cec.log", "a") as f:
        f.write(str + '\n')
        f.close()
    return


def main():
    set_defaults()
    prev_monitor_state = get_monitor()
    prev_inhibit_state = has_inhibit()
    prev_dpms_state = get_dpms()
    max_screen_on_time = 3 * 60 * 60 # hours * minutes * seconds
    screen_on_time = get_time()
    
    log('initial state:')
    log('monitor: ' + str(prev_monitor_state))
    log('dpms: ' + str(prev_dpms_state))
    log('inhibit: ' + str(prev_inhibit_state))
    log()

    # turn on the screen when pc boots
    send_cec_command(True)

    # note:
    # is inhibit and dpms the same?
    
    while True:
        time.sleep(1)
        
        # set some variables
        inhibit_changed = False
        monitor_changed = False
        dpms_changed = False

        # get variables for current tick
        cur_time = get_time()
        cur_dpms = get_dpms()
        cur_monitor = get_monitor()
        cur_inhibit = has_inhibit()

        #
        # check for state changes
        #

        # if dpms is off, we assume the monitor is on
        if (cur_dpms != prev_dpms_state):
            prev_dpms_state = cur_dpms
            dpms_changed = True
            log('dpms state change')
        
        # get monitor state
        if (prev_monitor_state != cur_monitor):
            prev_monitor_state = cur_monitor
            monitor_changed = True
            log('monitor state change')
            
        # inhibit state
        if (prev_inhibit_state != cur_inhibit):
            prev_inhibit_state = cur_inhibit
            inhibit_changed = True
            log('inhibit state change')

        #
        # apply state changes
        #
    
        # toggle screen
        # dpms is on, and monitor changed state
        if (cur_dpms and monitor_changed):    
            # send cec command
            log("monitor on: " + str(cur_monitor))
            send_cec_command(cur_monitor)
            
        # restart sleep timer
        # monitor has turned on
        # monitor changed state and monitor is on 
        if (monitor_changed and cur_monitor == True):
            log("reset timer")
            screen_on_time = cur_time
            
        # restart timer
        # video/app started or stopped
        # inhibit has changed state
        if (inhibit_changed):
            log("reset timer")
            screen_on_time = cur_time
            
        # screen timer
        # if monitor is on and time is larger than max time
        # turn dpms off
        # turn off screen will occur next tick
        if (cur_monitor == True and (cur_time - screen_on_time) > max_screen_on_time):
            log("force dpms/sleep")
            screen_on_time = cur_time
            run_command("xset dpms force off")


def toggle_display():
    # get screen on/off state
    state = run_command("echo 'pow 0' | cec-client -s -d 1")
    if ('power status: on' in state):
        send_cec_command(False)
    else:
        send_cec_command(True)

    return


def help():
    result = run_command("echo help | cec-client -s -d 1")
    log(result)
    return


def set_source(src):
    run_command("echo 'tx 4F:82:{}0:00' | cec-client -s -d 1".format(src))
    return


if __name__ == '__main__':
    log('Started...')
    log('found device:')
    log(run_command('lsusb | grep "CEC"'))

    if (len(sys.argv) > 1):
        if (sys.argv[1] == 'toggle'):
            toggle_display()
        if (sys.argv[1] == 'list' or sys.argv[1] == 'help'):
            help()
        if (sys.argv[1] == 'source'):
            set_source(sys.argv[2])
    else:
        main()
