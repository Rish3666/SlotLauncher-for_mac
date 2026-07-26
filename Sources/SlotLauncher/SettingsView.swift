import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @EnvironmentObject var configStore: ConfigStore
    @State private var resolvingIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Slots")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

            List(configStore.slots) { slot in
                SlotRowView(
                    slot: slot,
                    shortcutName: shortcutName(for: slot.id),
                    needsConfiguration: configStore.needsConfiguration.contains(slot.id),
                    onPickApp: { pickApp(for: slot.id) }
                )
            }
            .listStyle(.plain)

            HStack {
                Spacer()
                Text("Shortcuts are global — they work even when SlotLauncher isn't focused.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.trailing)
                    .padding(.bottom, 8)
            }
        }
        .frame(minWidth: 520, minHeight: 400)
        .onAppear {
            DispatchQueue.main.async {
                resolvePendingSlots()
            }
        }
    }

    private func resolvePendingSlots() {
        let badSlots = configStore.needsConfiguration.sorted()
        guard resolvingIndex < badSlots.count else { return }
        let slotID = badSlots[resolvingIndex]
        resolvingIndex += 1
        pickApp(for: slotID)
        if resolvingIndex < badSlots.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                resolvePendingSlots()
            }
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
}
