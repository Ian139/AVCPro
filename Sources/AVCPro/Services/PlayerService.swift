import Foundation
import AVFoundation
import AVKit

@MainActor
final class PlayerService: ObservableObject {
    @Published var player = AVPlayer()
    @Published var currentClip: ClipItem?
    @Published var isPlaying = false
    weak var playerView: AVPlayerView?

    func play(clip: ClipItem) {
        currentClip = clip
        let item = AVPlayerItem(url: clip.url)
        player.replaceCurrentItem(with: item)
        player.play()
        isPlaying = true
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        currentClip = nil
        isPlaying = false
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func seek(by seconds: Double) {
        let current = player.currentTime()
        let newTime = CMTimeGetSeconds(current) + seconds
        let clamped = max(newTime, 0)
        let time = CMTime(seconds: clamped, preferredTimescale: 600)
        player.seek(to: time)
    }

    func attach(playerView: AVPlayerView) {
        self.playerView = playerView
    }

    func toggleFullscreen() {
        guard let window = playerView?.window else { return }
        window.toggleFullScreen(nil)
    }
}
