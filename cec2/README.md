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

## How It's Designed

CEC2 uses **two complementary mechanisms**:

1. **User Service + ScreenSaver DBus** - Monitors screen on/off events (idle)
   - Runs when user is logged in
   - Catches screen blanking before it becomes a system sleep
   - Detects manual screen lock/unlock

2. **Systemd Sleep Hook** - Monitors system sleep/wake events
   - Runs at system level, works at login screen
   - Guaranteed to execute before and after sleep, even if services stop
   - Catches all sleep scenarios (suspend, hibernate, sleep)

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
3. Create a systemd **user** service for screen on/off detection
4. Create a systemd **sleep hook** for sleep/wake detection
5. Enable and start both components
6. Display the service status

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

4. **Create systemd sleep hook:**
   ```bash
   sudo cp cec-sleep /etc/systemd/system-sleep/
   sudo chmod +x /etc/systemd/system-sleep/cec-sleep
   # Update the script to use the correct path to your cec2 directory
   sudo sed -i "s|/path/to/cec2|$(pwd)|g" /etc/systemd/system-sleep/cec-sleep
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

**User service (screen on/off detection):**
```bash
systemctl --user status cec_daemon
```

**Sleep hook (sleep/wake detection):**
```bash
sudo systemctl status systemd-sleep
```

### View Live Logs

**User service:**
```bash
journalctl --user -u cec_daemon -f
```

**Sleep hook:**
```bash
sudo tail -f /var/log/cec_daemon.log
```

### View Historical Logs

**User service:**
```bash
journalctl --user -u cec_daemon
```

**Sleep hook:**
```bash
sudo tail -100 /var/log/cec_daemon.log
```

### Stop the User Service

```bash
systemctl --user stop cec_daemon
```

### Restart the User Service

```bash
systemctl --user restart cec_daemon
```

### Disable Auto-Start

```bash
systemctl --user disable cec_daemon
```

### Remove Everything

```bash
systemctl --user disable cec_daemon
systemctl --user stop cec_daemon
rm ~/.config/systemd/user/cec_daemon.service
systemctl --user daemon-reload

sudo rm /etc/systemd/system-sleep/cec-sleep
```

## Troubleshooting

### User Service Won't Start

Check user service logs:
```bash
journalctl --user -u cec_daemon -n 50
```

Common issues:
- Missing dependencies: Install python-dbus and python-gobject
- Script not executable: `chmod +x cec_daemon.py aboutToTurnOff.sh wakeUp.sh`
- Session bus unavailable: User service needs active user session (normal behavior)

### Sleep Hook Not Working

Check if hook is installed:
```bash
ls -la /etc/systemd/system-sleep/cec-sleep
```

Check logs:
```bash
sudo tail -50 /var/log/cec_daemon.log
```

Common issues:
- Hook not executable: `sudo chmod +x /etc/systemd/system-sleep/cec-sleep`
- Wrong path in script: Hook should have correct absolute path to cec2 directory
- cec-client not found: Install libcec/cec-utils

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
