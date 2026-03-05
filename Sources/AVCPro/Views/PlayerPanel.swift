import SwiftUI

struct PlayerPanel: View {
    @EnvironmentObject private var playerService: PlayerService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(playerService.currentClip?.name ?? "No clip selected")
                    .font(.headline)
                Spacer()
                playbackButtons
            }

            if let clip = playerService.currentClip {
                Text(Formatters.dateString(clip.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            PlayerView(player: playerService.player) { view in
                playerService.attach(playerView: view)
            }
                .frame(minHeight: 220)
                .background(Color.black)
                .cornerRadius(10)
        }
        .padding()
    }

    private var playbackButtons: some View {
        HStack(spacing: 10) {
            Button {
                playerService.seek(by: -10)
            } label: {
                Image(systemName: "gobackward.10")
            }
            .help("Back 10s")

            Button {
                playerService.togglePlayPause()
            } label: {
                Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
            }
            .help("Play/Pause")

            Button {
                playerService.seek(by: 10)
            } label: {
                Image(systemName: "goforward.10")
            }
            .help("Forward 10s")

            Button {
                playerService.stop()
            } label: {
                Image(systemName: "stop.fill")
            }
            .help("Stop")

            Button {
                playerService.toggleFullscreen()
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
            }
            .help("Fullscreen")
        }
        .buttonStyle(.borderless)
    }

}
