import Cocoa
import KeyboardShortcuts

struct ConfigFile: Codable {
    var nextID: Int = 1
    var slots: [SlotConfig] = []
}

func shortcutName(for slotID: Int) -> KeyboardShortcuts.Name {
    KeyboardShortcuts.Name("slot_\(slotID)")
}

@MainActor
class ConfigStore: ObservableObject {
    static let shared = ConfigStore()

    @Published var slots: [SlotConfig] = []
    @Published var needsConfiguration: Set<Int> = []
    @Published var nextID: Int = 1

    var iconCache: [String: NSImage] = [:]

    private var fileObserver: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    private var registeredSlotIDs: Set<Int> = []

    private var configURL: URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("SlotIt")
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        return supportDir.appendingPathComponent("config.json")
    }

    private init() {
        load()
        startWatching()
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
            let decoded = try JSONDecoder().decode(ConfigFile.self, from: data)
            slots = decoded.slots
            nextID = decoded.nextID
        } catch {
            print("Failed to load config: \(error)")
            writeDefaultConfig()
        }
    }

    private func writeDefaultConfig() {
        slots = []
        nextID = 1
        save()
    }

    func save() {
        let url = configURL
        do {
            let configFile = ConfigFile(nextID: nextID, slots: slots)
            let data = try JSONEncoder().encode(configFile)
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
        iconCache.removeValue(forKey: slot.bundleIdentifier)
        save()
    }

    func addSlot() -> SlotConfig {
        let slot = SlotConfig(id: nextID, bundleIdentifier: "", displayName: "Shortcut \(nextID)")
        nextID += 1
        slots.append(slot)
        save()
        registerHotkey(for: slot.id)
        return slot
    }

    func removeSlot(_ id: Int) {
        let name = shortcutName(for: id)
        KeyboardShortcuts.removeHandler(for: name)
        KeyboardShortcuts.setShortcut(nil, for: name)
        slots.removeAll { $0.id == id }
        needsConfiguration.remove(id)
        registeredSlotIDs.remove(id)
        save()
    }

    func registerHotkey(for slotID: Int) {
        guard registeredSlotIDs.insert(slotID).inserted else { return }
        let name = shortcutName(for: slotID)
        KeyboardShortcuts.onKeyUp(for: name) { AppToggler.shared.toggle(slotID: slotID) }
    }

    func registerAllHotkeys() {
        KeyboardShortcuts.removeAllHandlers()
        registeredSlotIDs = []
        for slot in slots {
            registerHotkey(for: slot.id)
        }
    }

    func onShortcutChanged(slotID: Int, shortcutJSON: String?) {
        guard let index = slots.firstIndex(where: { $0.id == slotID }) else { return }
        slots[index].shortcutJSON = shortcutJSON
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

    func cachedIcon(for bundleID: String) -> NSImage? {
        if let icon = iconCache[bundleID] { return icon }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        iconCache[bundleID] = icon
        return icon
    }

    private func validateSlots() {
        needsConfiguration.removeAll()
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
}
