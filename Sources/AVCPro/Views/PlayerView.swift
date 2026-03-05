import SwiftUI
import AVKit

struct PlayerView: NSViewRepresentable {
    let player: AVPlayer
    let onViewReady: (AVPlayerView) -> Void

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .floating
        view.videoGravity = .resizeAspect
        view.allowsPictureInPicturePlayback = true
        view.showsFullScreenToggleButton = true
        view.player = player
        onViewReady(view)
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
        onViewReady(nsView)
    }
}
