# Download Recycler

<p align="center"><img src="docs/mascot.png" width="160" alt="Download Recycler mascot, from the Menubarn widget library"></p>

Menu-bar app that moves old files from `~/Downloads` to the **Trash**
(restorable — `FileManager.trashItem`, never a hard delete). Built on
[StatusItemKit](https://github.com/nicholaspsmith/StatusItemKit); replaces the
old `download_recycler.sh` + daily launchd agent.

- **Green dot** — active: sweeps at launch, then daily while running
- **Gray dot** — paused

## Menu

| Item | Purpose |
|---|---|
| Enabled | master on/off toggle |
| Run Now | sweep immediately (notifies with the count) |
| Keep Files For | 7 / 14 / 30 / 60 / 90 days (default 30) |
| Open Log | audit trail at `~/Library/Logs/download-recycler.log` |
| Start at Login | SMAppService — no launchd agent |

Settings persist in `defaults` domain `com.nicholaspsmith.DownloadRecycler`.

## Requirements

- macOS 13+ (SMAppService), Xcode Command Line Tools
- [StatusItemKit](https://github.com/nicholaspsmith/StatusItemKit) checked out
  as a **sibling** directory (local SPM path dependency)
- First run prompts for **Downloads folder access** (TCC) — allow it

## Install

```sh
git clone https://github.com/nicholaspsmith/StatusItemKit.git
git clone https://github.com/nicholaspsmith/download-recycler-menubar.git
cd download-recycler-menubar
./install.sh
```

`install.sh` builds the app, symlinks it into `~/Applications`, migrates the
retention setting from the legacy `download_recycler.conf` if present, retires
the legacy `com.user.downloadrecycler` launchd agent, and launches the app.

## Uninstall

```sh
osascript -e 'quit app "Download Recycler"'
rm "$HOME/Applications/Download Recycler.app"
defaults delete com.nicholaspsmith.DownloadRecycler
```

(Disable Start at Login from the menu first, or remove the entry under
System Settings ▸ General ▸ Login Items.)

## The menu-bar suite

Part of a suite of macOS menu-bar apps that share one framework, one
build-and-sign script, and one installer. They are designed to sit in the
same bar together: consistent menus, a common **Icon** picker for shape and
colour, and cooperative hiding so no icon strands another.

| App | What it does |
|---|---|
| [Claude Usage](https://github.com/nicholaspsmith/claude-usage-menubar) | Claude Code plan limits, resets, and live agent sessions |
| [Apollo Monitor](https://github.com/nicholaspsmith/apollo-monitor-menubar) | Universal Audio Apollo monitor level, plus a UA process watchdog |
| [Battery Time](https://github.com/nicholaspsmith/battery-time-menubar) | Time remaining, power mode, and 24h usage |
| [VPN & DNS](https://github.com/nicholaspsmith/vpn-dns-menubar) | One dot for Mullvad + Tailscale state, with a DNS watcher |
| [Process Monitor](https://github.com/nicholaspsmith/MacOS_Process_Monitor) | Process-count sparkline against the per-UID limit |
| [KeyLight](https://github.com/nicholaspsmith/keylight-menubar) | Ctrl+brightness keys remapped to keyboard backlight |
| [MacRecorder](https://github.com/nicholaspsmith/MacRecorder) | Screen recording with system audio |
| [Media Tracking Killer](https://github.com/nicholaspsmith/media-tracking-killer-menubar) | Kills Apple's media tracking daemons |
| **Download Recycler** | Sweeps stale files out of ~/Downloads |
| [Curtain](https://github.com/nicholaspsmith/menubar-curtain) | Hides a block of status icons by width, so it cannot strand one |

| Framework | |
|---|---|
| [StatusItemKit](https://github.com/nicholaspsmith/StatusItemKit) | Status-item lifecycle, polling, menus, meter icons, the shared Icon picker |
| [HotkeyKit](https://github.com/nicholaspsmith/HotkeyKit) | CGEventTap engine for intercepting and remapping global keys |

Install the whole suite on a fresh Mac with
[macOS Dev Environment Setup](https://github.com/nicholaspsmith/MacOS-Dev-Environment-Setup):

```bash
git clone https://github.com/nicholaspsmith/MacOS-Dev-Environment-Setup.git
cd MacOS-Dev-Environment-Setup && ./bootstrap.sh --all
```
