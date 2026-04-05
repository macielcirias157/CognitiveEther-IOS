import Foundation

struct AIModel: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let size: String
    let type: String // e.g., "Vision", "Coding", "Lightweight"
    var isDownloaded: Bool = false
    var downloadProgress: Double = 0.0
}
