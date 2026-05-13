# CEC2 Daemon - Screen-Based TV Control

A simple, reliable replacement for the legacy KWin-based CEC control system. This daemon monitors screen on/off events via the freedesktop ScreenSaver DBus interface and automatically controls CEC devices (like TVs) through the `cec-client` utility.

## Overview

The CEC2 daemon monitors screen state changes via the **ScreenSaver DBus interface** (`org.freedesktop.ScreenSaver`):

- **Screen blanks/locks** (user idle) → Calls `aboutToTurnOff.sh` to put TV on standby
- **Screen activates** (user returns) → Calls `wakeUp.sh` to turn TV on
- **Works when logged in** → Responds to all screen state changes in the user session

For system sleep detection, see [RESEARCH_LOG.md](RESEARCH_LOG.md) for details on why system-level wake detection before login is not possible on this system.

## How It Works

CEC2 is a **user-level Python daemon** that:

1. Connects to the freedesktop ScreenSaver DBus interface
2. Listens for `ActiveChanged` signals
3. When screen blanks/locks → Turns off TV
4. When screen wakes/unlocks → Turns on TV
5. Runs as a systemd user service in your KDE session

**Simple, reliable, and works perfectly for screen-based control.**

## How It Works

### Event Flow

```
User stops using computer (idle timeout)
    ↓
Screen blanks
    ↓
ScreenSaver.ActiveChanged(true) signal
    ↓
Daemon calls: aboutToTurnOff.sh
    ↓
TV goes to standby
---
User moves mouse or presses key
    ↓
Screen wakes
    ↓
ScreenSaver.ActiveChanged(false) signal
    ↓
Daemon calls: wakeUp.sh
    ↓
TV turns on
```

### Debouncing

The daemon implements debounce logic to prevent rapid re-triggering:
- If the same action is triggered within 2 seconds, it's ignored
- Prevents duplicate commands to your TV

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
3. Create a systemd user service
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

3. **Create systemd user service:**
   ```bash
   mkdir -p ~/.config/systemd/user
   cp cec_daemon.service ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable cec_daemon.service
   systemctl --user start cec_daemon.service
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
systemctl --user status cec_daemon
```

### View Live Logs

```bash
journalctl --user -u cec_daemon -f
```

### View Historical Logs

```bash
journalctl --user -u cec_daemon
```

### Stop the Service

```bash
systemctl --user stop cec_daemon
```

### Restart the Service

```bash
systemctl --user restart cec_daemon
```

### Disable Auto-Start

```bash
systemctl --user disable cec_daemon
```

### Uninstall

```bash
systemctl --user disable cec_daemon
systemctl --user stop cec_daemon
rm ~/.config/systemd/user/cec_daemon.service
systemctl --user daemon-reload
```

## Troubleshooting

### Service Won't Start

Check logs:
```bash
journalctl --user -u cec_daemon -n 50
```

Common issues:
- Missing dependencies: Install python-dbus and python-gobject
- Script not executable: `chmod +x cec_daemon.py aboutToTurnOff.sh wakeUp.sh`
- cec-client not found: Install libcec or cec-utils

### TV Not Responding

Test cec-client directly:
```bash
echo 'scan' | cec-client -s
echo 'on 0' | cec-client -s   # Turn on device 0 (TV)
echo 'standby 0' | cec-client -s  # Put device 0 on standby
```

If commands don't work:
- Check TV supports CEC and has it enabled in settings
- Try different device IDs (0-15)
- Verify CEC cable/adapter is working

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
| **Detection method** | KWin QT signals (deprecated) | freedesktop ScreenSaver DBus |
| **KDE dependency** | Requires KWin installation | Works independent of KWin |
| **Screen detection** | ✓ Supported | ✓ Supported |
| **Systemd integration** | Manual setup | Built-in user service |
| **Logging** | Terminal output | systemd journal |
| **Compatibility** | KDE Plasma 5.x only | Any Linux with systemd |
| **Maintainability** | Breaks with KDE 6+ | Future-proof and simple |

## Credits

Based on the original `cec_kwin` implementation, modernized to use standard DBus interfaces instead of deprecated KWin signals.

## License

Same as original cec_kwin project.
