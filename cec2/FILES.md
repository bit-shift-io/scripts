# CEC2 Files Reference

## Active Files (Use These)

### Core Scripts
- **cec_daemon.py** - Main daemon (Python 3)
  - Listens to ScreenSaver DBus interface
  - Detects screen on/off events
  - Calls shell scripts when screen state changes
  - Runs as systemd user service

- **aboutToTurnOff.sh** - Execute when screen turns off
  - Sends `standby 0` to cec-client
  - Puts TV on standby

- **wakeUp.sh** - Execute when screen turns on
  - Sends `on 0` to cec-client
  - Turns TV on

### Installation & Documentation
- **install.sh** - Automated installer
  - Installs dependencies (libcec, python-dbus, python-gobject)
  - Creates systemd user service
  - Enables and starts the service

- **README.md** - User documentation
  - Overview and features
  - Installation instructions
  - Usage and troubleshooting

- **RESEARCH_LOG.md** - Technical research document
  - Summary of all approaches tried
  - Why each approach failed
  - Root cause analysis
  - Future possibilities

### Configuration
- **cec_daemon.service** - Systemd service template
  - User-level service configuration
  - Auto-starts in user session

- **.gitignore** - Git configuration
  - Standard Python ignores

## Legacy/Unused Files (Can Delete)

The following files were created during development but are **not used** in the final solution:

- **cec-sleep-daemon.py** - System-level sleep detection daemon (DOESN'T WORK)
  - Attempted to detect system wake before login
  - Never fires (systemd-logind signals not emitted)
  - Replaced by accepting screen-based control only

- **cec-sleep-daemon.service** - System service for sleep daemon (DOESN'T WORK)
  - Never used because sleep daemon doesn't work

- **systemd-sleep-hook** - Systemd pre/post sleep hook (DOESN'T WORK)
  - Attempted to run on system wake
  - Never called by systemd (PowerDevil bypasses it)

- **acpi-wake-monitor.sh** - ACPI event listener (DOESN'T WORK)
  - Attempted to listen for ACPI power events
  - Only receives audio jack events, not power events

- **acpi-wake-monitor.service** - ACPI monitor systemd service (DOESN'T WORK)
  - System service for ACPI monitoring
  - Never receives wake-related ACPI events

- **diagnose.sh** - Old diagnostic script
  - Used for testing multiple approaches
  - No longer needed

- **setup-sleep-daemon.sh** - Old setup script
  - Used for testing sleep daemon
  - Replaced by simplified install.sh

## Directory Structure

```
cec2/
├── cec_daemon.py                 ✅ ACTIVE
├── aboutToTurnOff.sh             ✅ ACTIVE
├── wakeUp.sh                     ✅ ACTIVE
├── install.sh                    ✅ ACTIVE
├── cec_daemon.service            ✅ ACTIVE
├── README.md                     ✅ ACTIVE
├── RESEARCH_LOG.md               ✅ ACTIVE
├── FILES.md                      ✅ ACTIVE (this file)
├── .gitignore                    ✅ ACTIVE
│
├── cec-sleep-daemon.py           ❌ LEGACY (can delete)
├── cec-sleep-daemon.service      ❌ LEGACY (can delete)
├── systemd-sleep-hook            ❌ LEGACY (can delete)
├── acpi-wake-monitor.sh          ❌ LEGACY (can delete)
├── acpi-wake-monitor.service     ❌ LEGACY (can delete)
├── diagnose.sh                   ❌ LEGACY (can delete)
└── setup-sleep-daemon.sh         ❌ LEGACY (can delete)
```

## Recommended Cleanup

To simplify the repository, these legacy files can be deleted:

```bash
cd cec2
rm cec-sleep-daemon.py
rm cec-sleep-daemon.service
rm systemd-sleep-hook
rm acpi-wake-monitor.sh
rm acpi-wake-monitor.service
rm diagnose.sh
rm setup-sleep-daemon.sh
```

This leaves only the 9 essential files needed for the working solution.
