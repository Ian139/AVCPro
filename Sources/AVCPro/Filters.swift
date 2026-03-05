import Foundation

enum DateFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case last7Days
    case last30Days

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Dates"
        case .today:
            return "Today"
        case .last7Days:
            return "Last 7 Days"
        case .last30Days:
            return "Last 30 Days"
        }
    }

    func includes(_ date: Date?) -> Bool {
        guard let date else { return self == .all }
        switch self {
        case .all:
            return true
        case .today:
            return Calendar.current.isDateInToday(date)
        case .last7Days:
            return date >= Date().addingTimeInterval(-7 * 24 * 60 * 60)
        case .last30Days:
            return date >= Date().addingTimeInterval(-30 * 24 * 60 * 60)
        }
    }
}

enum DurationFilter: String, CaseIterable, Identifiable {
    case all
    case under1Min
    case oneToFive
    case fiveToFifteen
    case overFifteen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Durations"
        case .under1Min:
            return "Under 1 min"
        case .oneToFive:
            return "1-5 min"
        case .fiveToFifteen:
            return "5-15 min"
        case .overFifteen:
            return "15+ min"
        }
    }

    func includes(_ duration: TimeInterval) -> Bool {
        switch self {
        case .all:
            return true
        case .under1Min:
            return duration < 60
        case .oneToFive:
            return duration >= 60 && duration < 5 * 60
        case .fiveToFifteen:
            return duration >= 5 * 60 && duration < 15 * 60
        case .overFifteen:
            return duration >= 15 * 60
        }
    }
}
