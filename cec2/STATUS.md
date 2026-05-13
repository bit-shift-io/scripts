# CEC2 - Current Status

## What Works ✅

- **Screen Idle Detection** - Detects when user stops using computer
- **TV Auto Off** - Automatically puts TV on standby when screen blanks
- **TV Auto On** - Automatically turns TV on when user returns/screen wakes
- **Screen Lock/Unlock** - Responds to manual screen lock/unlock
- **Systemd Integration** - Runs as user service, auto-starts in session
- **Reliable** - No timing issues, no missed events

## What Doesn't Work ❌

- **Wake Before Login** - TV won't turn on at login screen
  - See [RESEARCH_LOG.md](RESEARCH_LOG.md) for detailed analysis
  - Root cause: System architecture makes this impossible to detect

## Current Behavior

| Event | TV Action | When |
|-------|-----------|------|
| User idles (screen blanks) | Turns OFF | After screen blanks |
| User returns (moves mouse) | Turns ON | After screen wakes |
| User locks screen | Turns OFF | When screen locks |
| User unlocks screen | Turns ON | When screen unlocks |
| System sleeps | Turns OFF | Via screen blanking (before sleep) |
| System wakes | Turns ON | After user logs in and screen is on |
| **Login screen appears** | **STAYS OFF** | **Cannot detect** |

## Recommendation

The system is **working as well as technically possible**. The TV is ON and ready whenever the user needs to use the computer. The only gap is during the login screen itself.

**If you want TV on at the login screen**, you can either:
1. Disable the login screen (lose security)
2. Accept the current behavior (TV on after login)
3. Investigate KDE-specific power management configuration

## Installation

```bash
./install.sh
```

## Testing

```bash
journalctl --user -u cec_daemon -f
```

Then lock/unlock screen or wait for idle timeout to see logs.

## Documentation

- **README.md** - How to use
- **RESEARCH_LOG.md** - What was tried and why it failed
- **FILES.md** - Which files are active vs. legacy
- **STATUS.md** - This file (current state)

---

**Last updated:** 2026-05-13  
**Conclusion:** Solution is complete and working for screen-based control.
