import Foundation
import AVFoundation

struct ClipIndexer {
    static func indexClips(streamURL: URL) async throws -> [ClipItem] {
        let clips = try collectClips(streamURL: streamURL)
        var items: [ClipItem] = []
        items.reserveCapacity(clips.count)

        for clip in clips {
            let duration = await loadDuration(url: clip.url)
            let item = ClipItem(
                name: clip.name,
                url: clip.url,
                duration: duration,
                date: clip.date
            )
            items.append(item)
        }

        return items.sorted { (lhs, rhs) in
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
    }

    private struct ClipRecord {
        let url: URL
        let name: String
        let date: Date?
    }

    private static func collectClips(streamURL: URL) throws -> [ClipRecord] {
        let keys: Set<URLResourceKey> = [.creationDateKey, .contentModificationDateKey]
        let files = try FileManager.default.contentsOfDirectory(at: streamURL, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles])

        return files.compactMap { url -> ClipRecord? in
            guard url.pathExtension.lowercased() == "mts" else { return nil }
            let values = try? url.resourceValues(forKeys: keys)
            let date = values?.creationDate ?? values?.contentModificationDate
            let name = url.deletingPathExtension().lastPathComponent
            return ClipRecord(url: url, name: name, date: date)
        }
    }

    private static func loadDuration(url: URL) async -> TimeInterval {
        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            return seconds.isFinite ? seconds : 0
        } catch {
            return 0
        }
    }

}
