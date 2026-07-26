import Cocoa
import Combine
import KeyboardShortcuts

@MainActor
class ConfigStore: ObservableObject {
    static let shared = ConfigStore()

    @Published var slots: [SlotConfig] = []
    @Published var needsConfiguration: Set<Int> = []

    private var fileObserver: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    private var udDebounceWorkItem: DispatchWorkItem?
    private var udObserver: NSObjectProtocol?

    private var configURL: URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("SlotLauncher")
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        return supportDir.appendingPathComponent("config.json")
    }

    private init() {
        load()
        startWatching()
        startObservingShortcutChanges()
        validateSlots()
    }

    func load() {
        let url = configURL
        if !FileManager.default.fileExists(atPath: url.path) {
            writeDefaultConfig()
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([SlotConfig].self, from: data)
            slots = decoded
        } catch {
            print("Failed to load config: \(error)")
            writeDefaultConfig()
        }
    }

    private func writeDefaultConfig() {
        let defaults = [
            SlotConfig(id: 1, bundleIdentifier: "com.mitchellh.ghostty", displayName: "Ghostty"),
            SlotConfig(id: 2, bundleIdentifier: "", displayName: "Helium"),
            SlotConfig(id: 3, bundleIdentifier: "net.whatsapp.WhatsApp", displayName: "WhatsApp"),
            SlotConfig(id: 4, bundleIdentifier: "", displayName: "Feishin"),
            SlotConfig(id: 5, bundleIdentifier: "md.obsidian", displayName: "Obsidian"),
        ]
        slots = defaults
        save()
    }

    func save() {
        syncShortcutsToConfig()
        let url = configURL
        do {
            let data = try JSONEncoder().encode(slots)
            let tempURL = url.appendingPathExtension("tmp")
            try data.write(to: tempURL, options: .atomic)
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tempURL)
        } catch {
            print("Failed to save config: \(error)")
        }
    }

    func updateSlot(_ slot: SlotConfig) {
        guard let index = slots.firstIndex(where: { $0.id == slot.id }) else { return }
        slots[index] = slot
        needsConfiguration.remove(slot.id)
        save()
    }

    func applyShortcutsFromConfig() {
        for slot in slots {
            guard let json = slot.shortcutJSON, let data = json.data(using: .utf8),
                  let shortcut = try? JSONDecoder().decode(KeyboardShortcuts.Shortcut.self, from: data) else {
                continue
            }
            KeyboardShortcuts.setShortcut(shortcut, for: shortcutName(for: slot.id))
        }
    }

    private func syncShortcutsToConfig() {
        for i in slots.indices {
            guard let shortcut = KeyboardShortcuts.getShortcut(for: shortcutName(for: slots[i].id)) else {
                if slots[i].shortcutJSON != nil {
                    slots[i].shortcutJSON = nil
                }
                continue
            }
            let json = encodeShortcut(shortcut)
            if slots[i].shortcutJSON != json {
                slots[i].shortcutJSON = json
            }
        }
    }

    private func encodeShortcut(_ shortcut: KeyboardShortcuts.Shortcut) -> String? {
        guard let data = try? JSONEncoder().encode(shortcut),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    private func validateSlots() {
        for slot in slots {
            if slot.bundleIdentifier.isEmpty {
                needsConfiguration.insert(slot.id)
                continue
            }
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: slot.bundleIdentifier)
            if url == nil {
                needsConfiguration.insert(slot.id)
            }
        }
    }

    private func startWatching() {
        let url = configURL
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .delete, .rename],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            self?.debounceWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.load()
                self?.applyShortcutsFromConfig()
                self?.validateSlots()
            }
            self?.debounceWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        fileObserver = source
    }

    private func startObservingShortcutChanges() {
        udObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.udDebounceWorkItem?.cancel()
            let item = DispatchWorkItem { [weak self] in
                self?.syncShortcutsToConfig()
                self?.save()
            }
            self?.udDebounceWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: item)
        }
    }
}
