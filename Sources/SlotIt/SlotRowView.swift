import SwiftUI
import KeyboardShortcuts

struct SlotRowView: View {
    let slot: SlotConfig
    let shortcutName: KeyboardShortcuts.Name
    let needsConfiguration: Bool
    let onPickApp: () -> Void

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

            KeyboardShortcuts.Recorder("", name: shortcutName)
                .fixedSize()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }

    private var appIcon: NSImage? {
        guard !slot.bundleIdentifier.isEmpty,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: slot.bundleIdentifier) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
