import Foundation

enum ExportMode: String, CaseIterable, Identifiable {
    case original
    case mp4

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original:
            return "Original (.MTS)"
        case .mp4:
            return "MP4 (ffmpeg)"
        }
    }

    var fileExtension: String {
        switch self {
        case .original:
            return "mts"
        case .mp4:
            return "mp4"
        }
    }
}
