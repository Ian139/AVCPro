import Foundation

enum ClipLayoutMode: String, CaseIterable, Identifiable {
    case grid
    case list

    var id: String { rawValue }

    var toggleIcon: String {
        switch self {
        case .grid:
            return "list.bullet"
        case .list:
            return "square.grid.2x2"
        }
    }

    mutating func toggle() {
        self = (self == .grid) ? .list : .grid
    }
}
