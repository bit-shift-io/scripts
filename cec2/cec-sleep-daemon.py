#!/usr/bin/env python3
"""
CEC Sleep Daemon - Monitors system power state changes.
Detects sleep/wake by monitoring /sys/power/state and timing wake events.
Works with systemd, PowerDevil, and other power management systems.
"""

import subprocess
import sys
import logging
import time
from pathlib import Path
from datetime import datetime

try:
    import dbus
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import GLib
except ImportError as e:
    print(f"Error: Missing required module: {e}")
    sys.exit(1)


class CECSleepDaemon:
    def __init__(self):
        self.script_dir = Path("/home/server/Projects/scripts/cec2")
        self.logger = self._setup_logging()
        self._loop = None
        self.was_asleep = False
        self.last_wake_time = 0

    def _setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            handlers=[
                logging.StreamHandler(sys.stdout),
                logging.FileHandler("/var/log/cec-sleep-daemon.log", mode="a"),
            ],
        )
        return logging.getLogger(__name__)

    def run(self):
        """Start the daemon and monitor power state."""
        DBusGMainLoop(set_as_default=True)
        self._loop = GLib.MainLoop()

        try:
            # Try to listen to login1 signals as primary method
            try:
                bus = dbus.SystemBus()
                bus.add_signal_receiver(
                    self._on_prepare_for_sleep,
                    dbus_interface="org.freedesktop.login1.Manager",
                    signal_name="PrepareForSleep",
                    bus_name="org.freedesktop.login1",
                    path="/org/freedesktop/login1",
                )
                self.logger.info("Connected to systemd-logind signals")
            except dbus.DBusException as e:
                self.logger.warning(f"Could not connect to logind signals: {e}")

            # Also try UPower signals
            try:
                bus = dbus.SystemBus()
                bus.add_signal_receiver(
                    self._on_upower_changed,
                    dbus_interface="org.freedesktop.UPower",
                    signal_name="Resuming",
                )
                self.logger.info("Connected to UPower Resuming signal")
            except Exception as e:
                self.logger.debug(f"Could not connect to UPower: {e}")

            self.logger.info("CEC Sleep Daemon started - monitoring power state")

            # Fallback: periodically check /sys/power/state
            GLib.timeout_add_seconds(5, self._check_power_state)

            self._loop.run()

        except KeyboardInterrupt:
            self.logger.info("Received interrupt signal, shutting down")
            self._loop.quit()
        except Exception as e:
            self.logger.error(f"Unexpected error: {e}", exc_info=True)
            sys.exit(1)

    def _check_power_state(self):
        """Fallback: Check /sys/power/state to detect wake from sleep."""
        try:
            # Check uptime - if it's been very low, we just woke up
            with open("/proc/uptime") as f:
                uptime_seconds = int(float(f.read().split()[0]))

            current_time = time.time()

            # If uptime is low but system time jumped, we just woke from sleep
            # Detect wake if uptime is less than 10 seconds and we weren't checking before
            if uptime_seconds < 10 and not self.was_asleep:
                if current_time - self.last_wake_time > 30:  # Don't trigger twice in 30s
                    self.logger.info("System wake detected (uptime check) - turning on TV")
                    self._execute_script(self.script_dir / "wakeUp.sh")
                    self.last_wake_time = current_time

            self.was_asleep = uptime_seconds < 60

        except Exception as e:
            self.logger.debug(f"Error checking power state: {e}")

        return True  # Continue polling

    def _on_prepare_for_sleep(self, start):
        """Called when system is about to sleep or has just woken up (if signal is emitted)."""
        if start:
            self.logger.info("PrepareForSleep(true) - System going to sleep - turning off TV")
            self._execute_script(self.script_dir / "aboutToTurnOff.sh")
            self.was_asleep = True
        else:
            self.logger.info("PrepareForSleep(false) - System waking up - turning on TV")
            self._execute_script(self.script_dir / "wakeUp.sh")
            self.was_asleep = False

    def _on_upower_changed(self):
        """Called when UPower emits a Resuming signal."""
        self.logger.info("UPower Resuming signal - System waking up - turning on TV")
        self._execute_script(self.script_dir / "wakeUp.sh")

    def _execute_script(self, script_path):
        """Execute a shell script and log the results."""
        if not script_path.exists():
            self.logger.error(f"Script not found: {script_path}")
            return

        try:
            result = subprocess.run(
                [str(script_path)],
                capture_output=True,
                text=True,
                timeout=10,
            )

            if result.returncode == 0:
                self.logger.info(f"Script executed successfully: {script_path.name}")
            else:
                self.logger.error(
                    f"Script failed with exit code {result.returncode}: {script_path.name}"
                )

            if result.stderr:
                self.logger.warning(f"Script stderr: {result.stderr.strip()}")

        except subprocess.TimeoutExpired:
            self.logger.error(f"Script timeout: {script_path.name}")
        except Exception as e:
            self.logger.error(f"Error executing script: {e}")


if __name__ == "__main__":
    daemon = CECSleepDaemon()
    daemon.run()
