import SwiftUI
import KeyboardShortcuts

struct SlotRowView: View {
    let slot: SlotConfig
    let shortcutName: KeyboardShortcuts.Name
    let needsConfiguration: Bool
    let onPickApp: () -> Void
    let onRemove: () -> Void
    let onShortcutChanged: (String?) -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let icon = appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "app")
                            .foregroundColor(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.displayName)
                    .font(.body)
                if needsConfiguration {
                    Text("App not found — click Change App to set")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            Button("Change App...") {
                onPickApp()
            }
            .buttonStyle(.bordered)

            Button {
                onRemove()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.bordered)
            .help("Remove shortcut")

            KeyboardShortcuts.Recorder("", name: shortcutName, onChange: { shortcut in
                if let s = shortcut,
                   let data = try? JSONEncoder().encode(s),
                   let json = String(data: data, encoding: .utf8) {
                    onShortcutChanged(json)
                } else {
                    onShortcutChanged(nil)
                }
            })
            .fixedSize()
            .id("recorder-\(slot.id)")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }

    private var appIcon: NSImage? {
        guard !slot.bundleIdentifier.isEmpty else { return nil }
        return ConfigStore.shared.cachedIcon(for: slot.bundleIdentifier)
    }
}
