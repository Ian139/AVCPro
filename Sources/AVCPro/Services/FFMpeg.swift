import Foundation

enum FFMpegError: Error {
    case notInstalled
    case failed(String)
}

struct FFMpeg {
    static func isAvailable() -> Bool {
        return ffmpegPath() != nil
    }

    static func convertToMP4(clip: ClipItem, outputURL: URL) throws {
        guard let path = ffmpegPath() else {
            throw FFMpegError.notInstalled
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        let command = "\(shellEscape(path)) -y -i \(shellEscape(clip.url.path)) -c:v copy -c:a aac -b:a 192k -movflags +faststart \(shellEscape(outputURL.path))"
        let arguments: [String] = ["-lc", command]

        process.standardError = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice


        do {
            process.arguments = arguments
            try process.run()
            process.waitUntilExit()
        } catch {
            throw FFMpegError.failed("Failed to start ffmpeg.")
        }

        if process.terminationStatus != 0 {
            throw FFMpegError.failed("ffmpeg failed.")
        }

    }

    private static func ffmpegPath() -> String? {
        let candidates = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg"
        ]

        return fallbackPath(candidates)
    }

    private static func fallbackPath(_ candidates: [String]) -> String? {
        for candidate in candidates {
            if FileManager.default.fileExists(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    private static func shellEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

}
