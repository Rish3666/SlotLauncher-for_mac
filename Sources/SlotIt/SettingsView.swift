import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @EnvironmentObject var configStore: ConfigStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Shortcuts")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(configStore.slots) { slot in
                        SlotRowView(
                            slot: slot,
                            shortcutName: shortcutName(for: slot.id),
                            needsConfiguration: configStore.needsConfiguration.contains(slot.id),
                            onPickApp: { pickApp(for: slot.id) },
                            onRemove: { configStore.removeSlot(slot.id) },
                            onShortcutChanged: { json in
                                configStore.onShortcutChanged(slotID: slot.id, shortcutJSON: json)
                            }
                        )

                        if slot.id != configStore.slots.last?.id {
                            Divider()
                                .padding(.leading)
                        }
                    }

                    Button("Add New Shortcut") {
                        _ = configStore.addSlot()
                    }
                    .buttonStyle(.bordered)
                    .padding(.vertical, 8)
                }
            }

            HStack {
                Spacer()
                Text("Shortcuts are global — they work even when SlotIt isn't focused.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.trailing)
                    .padding(.bottom, 8)
            }
        }
        .frame(minWidth: 520, minHeight: 400)
    }

    private func pickApp(for slotID: Int) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseDirectories = false
        panel.message = "Choose an application for Shortcut \(slotID)"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let bundleID = bundleIdentifierForApp(at: url)
        let name = appDisplayName(at: url)
        let updatedSlot = SlotConfig(id: slotID, bundleIdentifier: bundleID, displayName: name)
        configStore.updateSlot(updatedSlot)
    }
}
