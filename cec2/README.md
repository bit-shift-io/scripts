# CEC2 Daemon - DBus-based Screen On/Off Detection

A modern replacement for the legacy KWin-based CEC control system. Instead of relying on KWin scripts with deprecated QT signals, this daemon monitors screen and sleep events via standard DBus interfaces and automatically controls CEC devices (like TVs) through the `cec-client` utility.

## Overview

The CEC2 daemon monitors two main DBus signal sources:

1. **systemd-logind** (`org.freedesktop.login1`) - Monitors system sleep/wake events
   - Detects when the system is about to suspend or has just woken up
   - Calls `aboutToTurnOff.sh` before sleep
   - Calls `wakeUp.sh` after wake-up

2. **ScreenSaver** (`org.freedesktop.ScreenSaver`) - Monitors screen on/off events
   - Detects when the screen is locked/blanked
   - Detects when the screen is unlocked/activated
   - Calls `aboutToTurnOff.sh` when screen blanks
   - Calls `wakeUp.sh` when screen turns on

## Why System Service?

The daemon runs as a **system service** rather than a user service. This is important because:

- **Works at login screen** - When your system wakes from sleep and shows the login screen, no user session is running yet. A user service wouldn't be active, so it couldn't call the wake script. The system service runs regardless of login state.
- **Handles all wake scenarios** - Works for wake-from-sleep before login, screen-unlock after idle, and any other wake event
- **Always available** - Started automatically at boot and continuously running
- **Proper signal handling** - Can receive system-level DBus signals that are only available to system services

## How It Works

### Event Flow

```
Screen idles/locks (no activity)
    ↓
ScreenSaver.ActiveChanged(true) signal
    ↓
Daemon calls: aboutToTurnOff.sh
    ↓
Your TV/device goes to standby
---
System suspends/hibernates
    ↓
systemd-logind PrepareForSleep(true) signal
    ↓
Daemon calls: aboutToTurnOff.sh
    ↓
Your TV/device goes to standby
---
User presses a key/mouse (screen wakes)
    ↓
ScreenSaver.ActiveChanged(false) signal
    ↓
Daemon calls: wakeUp.sh
    ↓
Your TV/device turns on
---
System wakes from sleep
    ↓
systemd-logind PrepareForSleep(false) signal
    ↓
Daemon calls: wakeUp.sh
    ↓
Your TV/device turns on
```

### Debouncing

To prevent double-execution when both ScreenSaver and sleep signals fire simultaneously, the daemon implements debounce logic:
- If the same action (screen_off, screen_on, sleep, wake) is triggered within 2 seconds, it's ignored
- This prevents your TV from receiving duplicate commands

## Installation

### Prerequisites

- Linux system with KDE Plasma
- cec-client utility (from libcec)
- Python 3.6+
- python-dbus
- python-gobject

### Automated Installation (Arch Linux)

```bash
cd cec2
./install.sh
```

This will:
1. Install required packages via pacman
2. Make scripts executable
3. Create a systemd **system** service (runs at boot, works at login screen)
4. Enable and start the service
5. Display the service status

### Manual Installation

1. **Install dependencies:**
   ```bash
   # Arch Linux
   sudo pacman -S cec-utils python-dbus python-gobject
   
   # Ubuntu/Debian
   sudo apt install cec-utils python3-dbus python3-gi
   
   # Fedora
   sudo dnf install libcec python3-dbus python3-gobject
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x cec_daemon.py aboutToTurnOff.sh wakeUp.sh
   ```

3. **Create systemd system service:**
   ```bash
   sudo cp cec_daemon.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable cec_daemon.service
   sudo systemctl start cec_daemon.service
   ```

4. **Create cache directory for logs:**
   ```bash
   mkdir -p ~/.cache
   ```

## Configuration

### Modifying Behavior

Edit `aboutToTurnOff.sh` and `wakeUp.sh` to control what happens:

**aboutToTurnOff.sh** (runs when screen turns off or system suspends):
```bash
#!/bin/bash
echo 'standby 0' | cec-client -s
```
- `standby 0` - Put device 0 (TV) on standby
- Other commands: `on 0`, `off 0`, `play 0`, `pause 0`

**wakeUp.sh** (runs when screen turns on or system wakes):
```bash
#!/bin/bash
echo 'on 0' | cec-client -s
```
- `on 0` - Turn on device 0 (TV)
- Adjust device numbers as needed for your setup

### Finding Your CEC Device ID

```bash
# List all connected CEC devices
echo 'scan' | cec-client -s

# Or monitor for activity
cec-client -s
```

Device IDs typically:
- `0` = TV
- `1` = Recording Device
- `3` = Tuner
- `4` = Playback Device
- `5` = Audio System

## Usage

### Check Service Status

```bash
sudo systemctl status cec_daemon
```

### View Live Logs

```bash
sudo journalctl -u cec_daemon -f
```

### View Historical Logs

```bash
sudo journalctl -u cec_daemon
# Or if running with fallback log location
cat /var/log/cec_daemon.log
```

### Stop the Service

```bash
sudo systemctl stop cec_daemon
```

### Restart the Service

```bash
sudo systemctl restart cec_daemon
```

### Disable Auto-Start

```bash
sudo systemctl disable cec_daemon
```

### Remove the Service

```bash
sudo systemctl disable cec_daemon
sudo systemctl stop cec_daemon
sudo rm /etc/systemd/system/cec_daemon.service
sudo systemctl daemon-reload
```

## Troubleshooting

### Service Won't Start

Check systemd logs:
```bash
sudo journalctl -u cec_daemon -n 50
```

Common issues:
- Missing dependencies: Install python-dbus and python-gobject
- Script not executable: `chmod +x cec_daemon.py aboutToTurnOff.sh wakeUp.sh`
- Wrong path in service file: Check `/etc/systemd/system/cec_daemon.service` has correct absolute path

### DBus Signals Not Being Received

Verify DBus services are available:
```bash
# Check ScreenSaver service
dbus-send --session --print-reply --dest=org.freedesktop.DBus \
  /org/freedesktop/DBus org.freedesktop.DBus.ListNames

# Should include org.freedesktop.ScreenSaver
```

### CEC Commands Not Working

Test cec-client directly:
```bash
# Find devices
echo 'scan' | cec-client -s

# Test command
echo 'on 0' | cec-client -s
```

If nothing happens:
- Check your TV supports CEC
- Verify CEC is enabled in TV settings
- Try different device IDs (0-15)
- Check CEC cable/adapter is working

### TV Turns On/Off at Wrong Times

The daemon respects these system settings:
- **Screen blanking** - Set in KDE System Settings > Power Management
- **Lock screen** - Set in KDE System Settings > Startup and Shutdown > Lock Screen
- **Sleep timing** - Set in KDE System Settings > Power Management

To prevent unwanted CEC commands, adjust these KDE settings rather than the daemon.

## Logs

The daemon logs to both:
1. **systemd journal:** `journalctl --user -u cec_daemon -f`
2. **File:** `~/.cache/cec_daemon.log`

Log levels include:
- INFO: Normal operation, signal received, command executed
- WARNING: Non-critical errors, command produced unexpected output
- ERROR: Failed to execute scripts, missing files, DBus errors
- DEBUG: Duplicate event filtering, subprocess output

## Differences from cec_kwin

| Feature | cec_kwin (KWin script) | cec2 (DBus daemon) |
|---------|------------------------|-------------------|
| **Detection method** | KWin QT signals (deprecated) | Standard DBus signals |
| **KDE dependency** | Requires KWin installation | Works independent of KWin |
| **Sleep detection** | Not supported | ✓ Supported |
| **Screen off detection** | ✓ Supported | ✓ Supported |
| **Systemd integration** | Manual service file | Built-in user service |
| **Logging** | Terminal output | systemd journal + file log |
| **Compatibility** | KDE Plasma 5.x only | Any Linux distro with systemd |
| **Maintainability** | Breaks with KDE 6+ | Future-proof |

## Credits

Based on the original `cec_kwin` implementation, modernized to use standard DBus interfaces instead of deprecated KWin signals.

## License

Same as original cec_kwin project.
