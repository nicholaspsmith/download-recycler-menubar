import AppKit
import StatusItemKit

/// Menu-bar app that moves old files from ~/Downloads to the Trash
/// (restorable — uses FileManager.trashItem, not deletion). Replaces the old
/// download_recycler.sh + daily launchd agent. The icon is the recycling
/// triangle: green = active, gray = paused. Sweeps at launch and then daily
/// while running.
final class App: NSObject, NSApplicationDelegate {
    private var controller: StatusItemController!
    private let defaults = UserDefaults.standard
    private let notifier = Notifier()

    private let dayChoices = [7, 14, 30, 60, 90]
    private let sweepEvery: TimeInterval = 24 * 60 * 60
    private let logURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/download-recycler.log")

    private var trashedLastSweep = 0
    private var sweeping = false

    // MARK: - Settings (UserDefaults-backed)

    private var enabled: Bool {
        get { defaults.object(forKey: "enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "enabled"); refreshIcon() }
    }
    private var daysToKeep: Int {
        get {
            let v = defaults.integer(forKey: "daysToKeep")
            return v > 0 ? v : 30
        }
        set { defaults.set(newValue, forKey: "daysToKeep") }
    }
    private var lastSweep: Date {
        get { defaults.object(forKey: "lastSweep") as? Date ?? .distantPast }
        set { defaults.set(newValue, forKey: "lastSweep") }
    }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        notifier.requestAuthorization()
        controller = StatusItemController(
            pollInterval: 30 * 60,
            onPoll: { [weak self] in self?.poll() },
            onBuildMenu: { [weak self] menu in self?.buildMenu(menu) }
        )
        controller.start()
    }

    /// Every 30 min: sweep if a day has passed since the last one.
    private func poll() {
        if enabled && Date().timeIntervalSince(lastSweep) >= sweepEvery {
            sweep()
        }
        refreshIcon()
    }

    private func refreshIcon() {
        controller.setIcon(MeterIcon.symbol("arrow.3.trianglepath", color: enabled ? .systemGreen : .systemGray))
    }

    /// Move top-level Downloads items older than daysToKeep to the Trash.
    /// Runs on a background queue; file dates via contentModificationDateKey.
    private func sweep(manual: Bool = false) {
        guard !sweeping else { return }
        sweeping = true
        lastSweep = Date()
        let cutoff = Date().addingTimeInterval(-Double(daysToKeep) * 24 * 60 * 60)

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let fm = FileManager.default
            let downloads = fm.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
            var trashed = 0
            let items = (try? fm.contentsOfDirectory(
                at: downloads,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles])) ?? []
            for item in items {
                let modified = (try? item.resourceValues(forKeys: [.contentModificationDateKey]))?
                    .contentModificationDate ?? Date()
                guard modified < cutoff else { continue }
                do {
                    try fm.trashItem(at: item, resultingItemURL: nil)
                    trashed += 1
                    self.log("Trashed: \(item.lastPathComponent)")
                } catch {
                    self.log("FAILED to trash \(item.lastPathComponent): \(error.localizedDescription)")
                }
            }
            DispatchQueue.main.async {
                self.trashedLastSweep = trashed
                self.sweeping = false
                self.log("Sweep done (threshold \(self.daysToKeep)d): \(trashed) item(s) trashed")
                if trashed > 0 || manual {
                    self.notifier.post(title: "Download Recycler",
                                       body: "Moved \(trashed) old item(s) from Downloads to Trash.")
                }
            }
        }
    }

    private func log(_ message: String) {
        let formatter = ISO8601DateFormatter()
        let line = "[\(formatter.string(from: Date()))] \(message)\n"
        if let data = line.data(using: .utf8) {
            if let handle = try? FileHandle(forWritingTo: logURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            } else {
                try? data.write(to: logURL)
            }
        }
    }

    // MARK: - Menu

    private func buildMenu(_ menu: NSMenu) {
        let mono = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let last = lastSweep == .distantPast ? "never" : formatter.string(from: lastSweep)
        let status = enabled ? "active — keep \(daysToKeep) days" : "paused"
        let header = NSMenuItem()
        header.view = MenuBuilder.textView(
            "Download Recycler: \(status)\nlast sweep: \(last) (\(trashedLastSweep) trashed)",
            font: mono)
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())

        let toggle = NSMenuItem(title: "Enabled",
                                action: #selector(toggleEnabled), keyEquivalent: "e")
        toggle.target = self
        toggle.state = enabled ? .on : .off
        menu.addItem(toggle)

        let runNow = NSMenuItem(title: "Run Now",
                                action: #selector(runNow), keyEquivalent: "r")
        runNow.target = self
        menu.addItem(runNow)

        // Retention radio submenu
        let keepItem = NSMenuItem(title: "Keep Files For", action: nil, keyEquivalent: "")
        let keepMenu = NSMenu()
        for days in dayChoices {
            let item = NSMenuItem(title: "\(days) days",
                                  action: #selector(setDays(_:)), keyEquivalent: "")
            item.target = self
            item.tag = days
            item.state = days == daysToKeep ? .on : .off
            keepMenu.addItem(item)
        }
        keepItem.submenu = keepMenu
        menu.addItem(keepItem)

        let showLog = NSMenuItem(title: "Open Log",
                                 action: #selector(openLog), keyEquivalent: "l")
        showLog.target = self
        menu.addItem(showLog)

        menu.addItem(NSMenuItem.separator())

        let login = NSMenuItem(title: "Start at Login",
                               action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit",
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    // MARK: - Actions

    @objc private func toggleEnabled() { enabled.toggle() }
    @objc private func runNow() { sweep(manual: true) }
    @objc private func setDays(_ sender: NSMenuItem) { daysToKeep = sender.tag }
    @objc private func openLog() { NSWorkspace.shared.open(logURL) }
    @objc private func toggleLogin() { LoginItem.toggle() }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
