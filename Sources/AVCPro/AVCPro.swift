import SwiftUI

@main
struct AVCProApp: App {
    @StateObject private var library = ClipLibrary()
    @StateObject private var playerService = PlayerService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .environmentObject(playerService)
        }
        .commands {
            CommandMenu("Playback") {
                Button("Play/Pause") {
                    playerService.togglePlayPause()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("Stop") {
                    playerService.stop()
                }
                .keyboardShortcut(".", modifiers: [.command])

                Divider()

                Button("Back 10 Seconds") {
                    playerService.seek(by: -10)
                }
                .keyboardShortcut("[", modifiers: [.command])

                Button("Forward 10 Seconds") {
                    playerService.seek(by: 10)
                }
                .keyboardShortcut("]", modifiers: [.command])

                Divider()

                Button("Toggle Fullscreen") {
                    playerService.toggleFullscreen()
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
        }
    }
}
