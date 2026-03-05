import Foundation

enum ClipSortOption: String, CaseIterable, Identifiable {
    case dateDesc
    case dateAsc
    case nameAsc
    case durationDesc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dateDesc:
            return "Date (Newest)"
        case .dateAsc:
            return "Date (Oldest)"
        case .nameAsc:
            return "Name (A-Z)"
        case .durationDesc:
            return "Duration (Longest)"
        }
    }

    func sort(_ clips: [ClipItem]) -> [ClipItem] {
        switch self {
        case .dateDesc:
            return clips.sorted { (lhs, rhs) in
                switch (lhs.date, rhs.date) {
                case let (l?, r?):
                    return l > r
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.name < rhs.name
                }
            }
        case .dateAsc:
            return clips.sorted { (lhs, rhs) in
                switch (lhs.date, rhs.date) {
                case let (l?, r?):
                    return l < r
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.name < rhs.name
                }
            }
        case .nameAsc:
            return clips.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .durationDesc:
            return clips.sorted { $0.duration > $1.duration }
        }
    }
}
