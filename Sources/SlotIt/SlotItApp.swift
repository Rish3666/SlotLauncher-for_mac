import SwiftUI
import KeyboardShortcuts

@main
struct SlotItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var configStore = ConfigStore.shared

    var body: some Scene {
        WindowGroup {
            SettingsView()
                .environmentObject(configStore)
                .frame(minWidth: 520, minHeight: 400)
        }
        .windowResizability(.contentMinSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        ConfigStore.shared.registerAllHotkeys()
        ConfigStore.shared.applyShortcutsFromConfig()
        addMenuItem()
    }

    @objc private func showSettingsWindow() {
        NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
    }

    private func addMenuItem() {
        guard let mainMenu = NSApplication.shared.mainMenu,
              let appMenuItem = mainMenu.items.first,
              let appMenu = appMenuItem.submenu else { return }
        let item = NSMenuItem(title: "Show SlotIt", action: #selector(showSettingsWindow), keyEquivalent: "")
        item.target = self
        appMenu.addItem(item)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
        }
        return true
    }
}
