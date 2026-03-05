import Foundation
import AppKit

@MainActor
final class ClipLibrary: ObservableObject {
    @Published var clips: [ClipItem] = []
    @Published var isScanning = false
    @Published var errorMessage: String?
    @Published var sourceName: String = "No source selected"
    @Published var lastSourceURL: URL?

    func scan(url: URL, sourceName: String? = nil) {
        isScanning = true
        errorMessage = nil
        clips = []
        self.sourceName = sourceName ?? url.lastPathComponent
        self.lastSourceURL = url

        Task.detached(priority: .userInitiated) {
            guard let streamURL = AvchdScanner.findStreamDirectory(root: url) else {
                await MainActor.run {
                    self.errorMessage = "No AVCHD structure found."
                    self.isScanning = false
                }
                return
            }

            do {
                let items = try await ClipIndexer.indexClips(streamURL: streamURL)
                await MainActor.run {
                    self.clips = items
                    self.isScanning = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to read clips."
                    self.isScanning = false
                }
            }
        }
    }

    func refreshCurrent() {
        guard let lastSourceURL else { return }
        scan(url: lastSourceURL, sourceName: sourceName)
    }
}
