# Download Recycler

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
