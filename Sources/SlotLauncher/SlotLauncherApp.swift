import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let slot1 = Self("slot1", default: .init(.one, modifiers: [.command]))
    static let slot2 = Self("slot2", default: .init(.two, modifiers: [.command]))
    static let slot3 = Self("slot3", default: .init(.three, modifiers: [.command]))
    static let slot4 = Self("slot4", default: .init(.four, modifiers: [.command]))
    static let slot5 = Self("slot5", default: .init(.five, modifiers: [.command]))
}

func shortcutName(for slotID: Int) -> KeyboardShortcuts.Name {
    switch slotID {
    case 1: return .slot1
    case 2: return .slot2
    case 3: return .slot3
    case 4: return .slot4
    case 5: return .slot5
    default: fatalError("Invalid slot ID")
    }
}

@main
struct SlotLauncherApp: App {
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
        KeyboardShortcuts.onKeyUp(for: .slot1) { AppToggler.shared.toggle(slotID: 1) }
        KeyboardShortcuts.onKeyUp(for: .slot2) { AppToggler.shared.toggle(slotID: 2) }
        KeyboardShortcuts.onKeyUp(for: .slot3) { AppToggler.shared.toggle(slotID: 3) }
        KeyboardShortcuts.onKeyUp(for: .slot4) { AppToggler.shared.toggle(slotID: 4) }
        KeyboardShortcuts.onKeyUp(for: .slot5) { AppToggler.shared.toggle(slotID: 5) }

        ConfigStore.shared.applyShortcutsFromConfig()

        addShowSlotLauncherMenuItem()
    }

    @objc private func showSettingsWindow() {
        NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
    }

    private func addShowSlotLauncherMenuItem() {
        guard let mainMenu = NSApplication.shared.mainMenu,
              let appMenuItem = mainMenu.items.first,
              let appMenu = appMenuItem.submenu else { return }
        let item = NSMenuItem(title: "Show SlotLauncher", action: #selector(showSettingsWindow), keyEquivalent: "")
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
