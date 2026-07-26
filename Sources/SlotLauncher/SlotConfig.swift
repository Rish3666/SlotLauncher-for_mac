import Foundation

struct SlotConfig: Identifiable, Codable, Equatable {
    var id: Int
    var bundleIdentifier: String
    var displayName: String
    var shortcutJSON: String?
}
