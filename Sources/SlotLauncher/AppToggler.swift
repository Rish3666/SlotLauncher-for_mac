import Cocoa

@MainActor
class AppToggler {
    static let shared = AppToggler()

    private let configStore = ConfigStore.shared

    func toggle(slotID: Int) {
        guard let slot = configStore.slots.first(where: { $0.id == slotID }) else { return }
        toggle(bundleIdentifier: slot.bundleIdentifier)
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
