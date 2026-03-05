import Foundation

enum Formatters {
    static let duration: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()

    static let shortDuration: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()

    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static func durationString(_ duration: TimeInterval) -> String {
        guard duration > 0 else { return "--:--" }
        if duration < 3600 {
            return Formatters.shortDuration.string(from: duration) ?? "--:--"
        }
        return Formatters.duration.string(from: duration) ?? "--:--"
    }

    static func dateString(_ date: Date?) -> String {
        guard let date else { return "Unknown date" }
        return Formatters.date.string(from: date)
    }
}
