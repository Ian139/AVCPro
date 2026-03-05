import Foundation

struct ClipItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let duration: TimeInterval
    let date: Date?
}
