import Cocoa
import Combine
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

    private var fileObserver: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    private var udCancellable: AnyCancellable?

    private var configURL: URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("SlotIt")
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
        syncShortcutsToConfig()
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
        slots.removeAll { $0.id == id }
        needsConfiguration.remove(id)
        save()
    }

    func registerHotkey(for slotID: Int) {
        let name = shortcutName(for: slotID)
        KeyboardShortcuts.onKeyUp(for: name) { AppToggler.shared.toggle(slotID: slotID) }
    }

    func registerAllHotkeys() {
        for slot in slots {
            registerHotkey(for: slot.id)
        }
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
                self?.registerAllHotkeys()
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
        udCancellable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncShortcutsToConfig()
                self?.save()
            }
    }
}
