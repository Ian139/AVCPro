import Foundation

struct AvchdScanner {
    static func findStreamDirectory(root: URL) -> URL? {
        if isStreamDirectory(root) { return root }

        let candidates: [[String]] = [
            ["PRIVATE", "AVCHD", "BDMV", "STREAM"],
            ["AVCHD", "BDMV", "STREAM"],
            ["BDMV", "STREAM"],
            ["STREAM"]
        ]

        for components in candidates {
            if let resolved = resolveCaseInsensitivePath(root: root, components: components), isStreamDirectory(resolved) {
                return resolved
            }
        }

        return nil
    }

    private static func isStreamDirectory(_ url: URL) -> Bool {
        let contents = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        return contents.contains { $0.pathExtension.lowercased() == "mts" }
    }

    private static func resolveCaseInsensitivePath(root: URL, components: [String]) -> URL? {
        var current = root
        for component in components {
            let entries = (try? FileManager.default.contentsOfDirectory(at: current, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
            guard let match = entries.first(where: { $0.lastPathComponent.compare(component, options: [.caseInsensitive]) == .orderedSame }) else {
                return nil
            }
            current = match
        }
        return current
    }
}
