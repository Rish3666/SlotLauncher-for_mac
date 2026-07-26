import Cocoa

@MainActor
class AppToggler {
    static let shared = AppToggler()

    private let configStore = ConfigStore.shared

    func toggle(slotID: Int) {
        guard let slot = configStore.slots.first(where: { $0.id == slotID }) else { return }

        if slot.bundleIdentifier.isEmpty || NSWorkspace.shared.urlForApplication(withBundleIdentifier: slot.bundleIdentifier) == nil {
            Task { @MainActor in
                NSApplication.shared.activate(ignoringOtherApps: true)
                pickApp(for: slotID)
            }
            return
        }

        let bundleID = slot.bundleIdentifier
        Task { @MainActor in
            toggle(bundleIdentifier: bundleID)
        }
    }

    private func pickApp(for slotID: Int) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseDirectories = false
        panel.message = "Choose an application for Slot \(slotID)"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let bundleID = bundleIdentifierForApp(at: url)
        let name = appDisplayName(at: url)
        let updatedSlot = SlotConfig(id: slotID, bundleIdentifier: bundleID, displayName: name)
        configStore.updateSlot(updatedSlot)

        toggle(bundleIdentifier: bundleID)
    }

    func toggle(bundleIdentifier: String) {
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)

        guard let app = running.first else {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
                print("No app found for bundle ID: \(bundleIdentifier)")
                return
            }
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
            return
        }

        if app.isActive {
            app.hide()
        } else {
            app.unhide()
            app.activate(options: [.activateAllWindows])
        }
    }
}
