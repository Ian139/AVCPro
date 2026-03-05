import Foundation
import AVFoundation
import AppKit
import CryptoKit

actor ThumbnailService {
    static let shared = ThumbnailService()
    private var cache: [URL: NSImage] = [:]
    private let cacheDirectory: URL

    init() {
        let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let directory = (root ?? FileManager.default.temporaryDirectory).appendingPathComponent("AVCProThumbnails", isDirectory: true)
        cacheDirectory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }

    func thumbnail(for url: URL?) async -> NSImage? {
        guard let url else { return nil }

        if let cached = cache[url] {
            return cached
        }

        if let diskImage = loadFromDisk(for: url) {
            cache[url] = diskImage
            return diskImage
        }

        let image = await generateThumbnail(url: url)
        if let image {
            cache[url] = image
            saveToDisk(image: image, for: url)
        }
        return image
    }

    private func generateThumbnail(url: URL) async -> NSImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 270)
        let time = CMTime(seconds: 0, preferredTimescale: 600)

        return await withCheckedContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, _ in
                if let cgImage {
                    let image = NSImage(cgImage: cgImage, size: .zero)
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadFromDisk(for url: URL) -> NSImage? {
        let fileURL = cacheURL(for: url)
        return NSImage(contentsOf: fileURL)
    }

    private func saveToDisk(image: NSImage, for url: URL) {
        let fileURL = cacheURL(for: url)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) else {
            return
        }

        try? data.write(to: fileURL, options: .atomic)
    }

    private func cacheURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.path.utf8))
        let name = hash.map { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent(name).appendingPathExtension("jpg")
    }
}
