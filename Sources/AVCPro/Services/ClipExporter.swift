import Foundation

struct ClipExportResult {
    let fileCount: Int
}

struct ClipExporter {
    static func export(
        clips: [ClipItem],
        to destination: URL,
        mode: ExportMode,
        onProgress: ((ClipItem, Int, Int) -> Void)? = nil
    ) throws -> ClipExportResult {
        var fileCount = 0
        let manager = FileManager.default
        let total = clips.count

        for (index, clip) in clips.enumerated() {
            onProgress?(clip, index + 1, total)
            switch mode {
            case .original:
                let target = uniqueURL(for: clip.url.lastPathComponent, in: destination)
                try copyItem(at: clip.url, to: target, manager: manager)
                fileCount += 1
            case .mp4:
                let baseName = clip.name.isEmpty ? "Clip" : clip.name
                let fileName = "\(baseName).mp4"
                let target = uniqueURL(for: fileName, in: destination)
                try FFMpeg.convertToMP4(clip: clip, outputURL: target)
                fileCount += 1
            }
        }

        return ClipExportResult(fileCount: fileCount)
    }

    private static func copyItem(
        at source: URL,
        to destination: URL,
        manager: FileManager
    ) throws {
        if manager.fileExists(atPath: destination.path) {
            try manager.removeItem(at: destination)
        }
        try manager.copyItem(at: source, to: destination)
    }

    private static func uniqueURL(for name: String, in directory: URL, isDirectory: Bool = false) -> URL {
        let baseURL = directory.appendingPathComponent(name, isDirectory: isDirectory)
        if !FileManager.default.fileExists(atPath: baseURL.path) {
            return baseURL
        }

        let ext = baseURL.pathExtension
        let baseName = baseURL.deletingPathExtension().lastPathComponent
        var counter = 1

        while true {
            let candidateName = "\(baseName)-\(counter)"
            let candidate = directory
                .appendingPathComponent(candidateName, isDirectory: isDirectory)
                .appendingPathExtension(ext)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            counter += 1
        }
    }
}
