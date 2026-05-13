#!/usr/bin/env python3
"""
CEC Daemon - Monitors screen on/off and sleep/wake events via DBus.
Executes aboutToTurnOff.sh when screen turns off or system suspends.
Executes wakeUp.sh when screen turns on or system wakes.
"""

import subprocess
import sys
import os
import time
import logging
from pathlib import Path

try:
    import dbus
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import GLib
except ImportError as e:
    print(f"Error: Missing required module: {e}")
    print("Install dependencies with: ./install.sh")
    sys.exit(1)


class CECDaemon:
    def __init__(self):
        self.script_dir = Path(__file__).parent
        self.logger = self._setup_logging()
        self.last_action = None
        self.last_action_time = 0
        self.debounce_time = 2  # seconds
        self._loop = None

    def _setup_logging(self):
        log_dir = Path("/var/log")
        log_file = log_dir / "cec_daemon.log"

        # Fallback to home cache if /var/log isn't writable
        if not log_dir.exists() or not os.access(log_dir, os.W_OK):
            log_file = Path.home() / ".cache" / "cec_daemon.log"

        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            handlers=[
                logging.StreamHandler(sys.stdout),
                logging.FileHandler(log_file, mode="a"),
            ],
        )
        return logging.getLogger(__name__)

    def run(self):
        """Start the daemon and monitor DBus signals."""
        DBusGMainLoop(set_as_default=True)
        self._loop = GLib.MainLoop()

        try:
            bus = dbus.SystemBus()

            # Monitor systemd-logind for sleep/wake events
            bus.add_signal_receiver(
                self._on_prepare_for_sleep,
                dbus_interface="org.freedesktop.login1.Manager",
                signal_name="PrepareForSleep",
                bus_name="org.freedesktop.login1",
                path="/org/freedesktop/login1",
            )
            self.logger.info("Listening for systemd sleep signals")

            # Monitor ScreenSaver for screen on/off events
            session_bus = dbus.SessionBus()
            session_bus.add_signal_receiver(
                self._on_screen_saver_active,
                dbus_interface="org.freedesktop.ScreenSaver",
                signal_name="ActiveChanged",
                bus_name="org.freedesktop.ScreenSaver",
                path="/org/freedesktop/ScreenSaver",
            )
            self.logger.info("Listening for ScreenSaver signals")

            self.logger.info("CEC Daemon started successfully")
            self._loop.run()

        except dbus.DBusException as e:
            self.logger.error(f"DBus error: {e}")
            sys.exit(1)
        except KeyboardInterrupt:
            self.logger.info("Received interrupt signal, shutting down")
            self._loop.quit()
        except Exception as e:
            self.logger.error(f"Unexpected error: {e}", exc_info=True)
            sys.exit(1)

    def _should_trigger(self, action):
        """Check if enough time has passed since last action to avoid double-triggering."""
        now = time.time()
        if (
            self.last_action == action
            and (now - self.last_action_time) < self.debounce_time
        ):
            return False
        self.last_action = action
        self.last_action_time = now
        return True

    def _on_prepare_for_sleep(self, start):
        """Called when system is about to sleep or has just woken up."""
        action = "sleep" if start else "wake"
        self.logger.info(f"PrepareForSleep signal received: {action}")

        if not self._should_trigger(action):
            self.logger.debug(f"Ignoring duplicate {action} event")
            return

        if start:
            self._execute_about_to_turn_off()
        else:
            self._execute_wake_up()

    def _on_screen_saver_active(self, active):
        """Called when screen saver becomes active or inactive."""
        action = "screen_off" if active else "screen_on"
        self.logger.info(f"ScreenSaver ActiveChanged signal received: {action}")

        # Only handle screen-off if we haven't recently handled a sleep event
        if active:
            if self._should_trigger("screen_off"):
                self._execute_about_to_turn_off()
        else:
            if self._should_trigger("screen_on"):
                self._execute_wake_up()

    def _execute_about_to_turn_off(self):
        """Execute the aboutToTurnOff script."""
        script = self.script_dir / "aboutToTurnOff.sh"
        self._run_script(script, "aboutToTurnOff")

    def _execute_wake_up(self):
        """Execute the wakeUp script."""
        script = self.script_dir / "wakeUp.sh"
        self._run_script(script, "wakeUp")

    def _run_script(self, script_path, script_name):
        """Execute a shell script and log the results."""
        if not script_path.exists():
            self.logger.error(f"{script_name} script not found at {script_path}")
            return

        try:
            self.logger.info(f"Executing {script_name}...")
            result = subprocess.run(
                [str(script_path)],
                capture_output=True,
                text=True,
                timeout=10,
            )

            if result.returncode == 0:
                self.logger.info(
                    f"{script_name} executed successfully"
                )
            else:
                self.logger.error(
                    f"{script_name} failed with exit code {result.returncode}"
                )

            if result.stdout:
                self.logger.debug(f"{script_name} stdout: {result.stdout.strip()}")
            if result.stderr:
                self.logger.warning(f"{script_name} stderr: {result.stderr.strip()}")

        except subprocess.TimeoutExpired:
            self.logger.error(f"{script_name} timed out after 10 seconds")
        except Exception as e:
            self.logger.error(f"Error executing {script_name}: {e}")


if __name__ == "__main__":
    daemon = CECDaemon()
    daemon.run()
