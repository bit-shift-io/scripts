#!/usr/bin/env python3
"""
CEC Sleep Daemon - System-level service for sleep/wake detection.
Runs as root and stays active through sleep cycles to detect wake events.
"""

import subprocess
import sys
import logging
from pathlib import Path

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
        """Start the daemon and monitor sleep/wake signals."""
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
            self.logger.info("CEC Sleep Daemon started - listening for sleep signals")
            self.logger.info("Waiting for PrepareForSleep signals from systemd-logind...")
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

    def _on_prepare_for_sleep(self, start):
        """Called when system is about to sleep or has just woken up."""
        if start:
            self.logger.info("System going to sleep - turning off TV")
            self._execute_script(self.script_dir / "aboutToTurnOff.sh")
        else:
            self.logger.info("System waking up - turning on TV")
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
