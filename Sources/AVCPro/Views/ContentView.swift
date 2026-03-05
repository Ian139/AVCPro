import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var library: ClipLibrary
    @EnvironmentObject private var playerService: PlayerService

    var body: some View {
        TabView {
            BrowseView(
                onPlay: { clip in
                    playerService.play(clip: clip)
                },
                onReveal: revealClip,
                onCopyPaths: copyClipPaths
            )
            .tabItem {
                Label("Browse", systemImage: "film")
            }

            ExportView(
                onPlay: { clip in
                    playerService.play(clip: clip)
                },
                onReveal: revealClip,
                onCopyPaths: copyClipPaths
            )
            .tabItem {
                Label("Export", systemImage: "square.and.arrow.up")
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    chooseFolder()
                } label: {
                    Label("Import", systemImage: "tray.and.arrow.down")
                }

                Button {
                    library.refreshCurrent()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(library.lastSourceURL == nil)
            }
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose AVCHD Folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            library.scan(url: url, sourceName: url.lastPathComponent)
        }
    }

    private func revealClip(_ clip: ClipItem) {
        NSWorkspace.shared.activateFileViewerSelecting([clip.url])
    }

    private func copyClipPaths(_ clip: ClipItem) {
        let paths = clip.url.path
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(paths, forType: .string)
    }

}

struct BrowseView: View {
    @EnvironmentObject private var library: ClipLibrary
    @EnvironmentObject private var playerService: PlayerService

    let onPlay: (ClipItem) -> Void
    let onReveal: (ClipItem) -> Void
    let onCopyPaths: (ClipItem) -> Void

    @State private var searchText = ""
    @State private var sortOption: ClipSortOption = .dateDesc
    @State private var layoutMode: ClipLayoutMode = .grid
    @State private var dateFilter: DateFilter = .all
    @State private var durationFilter: DurationFilter = .all

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            VSplitView {
                contentBody
                    .frame(minHeight: 240, idealHeight: 420)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                PlayerPanel()
                    .frame(minHeight: 260, idealHeight: 340)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(library.sourceName)
                    .font(.headline)
                Spacer()
                if library.isScanning {
                    ProgressView("Scanning...")
                }
            }

            HStack {
                TextField("Search clips", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                Picker("Sort", selection: $sortOption) {
                    ForEach(ClipSortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.menu)
                Picker("Date", selection: $dateFilter) {
                    ForEach(DateFilter.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.menu)
                Picker("Duration", selection: $durationFilter) {
                    ForEach(DurationFilter.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.menu)
                Button {
                    layoutMode.toggle()
                } label: {
                    Image(systemName: layoutMode.toggleIcon)
                }
                .help(layoutMode == .grid ? "List view" : "Grid view")
                Spacer()
            }
        }
        .padding()
    }

    private var contentBody: some View {
        Group {
            if let errorMessage = library.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text(errorMessage)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if library.clips.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "film")
                        .font(.largeTitle)
                    Text("No clips to display")
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if layoutMode == .grid {
                    ClipGrid(
                        clips: filteredClips,
                        selectedClip: playerService.currentClip,
                        onSelect: onPlay,
                        onReveal: onReveal,
                        onCopyPaths: onCopyPaths
                    )
                } else {
                    ClipList(
                        clips: filteredClips,
                        selectedClip: playerService.currentClip,
                        onSelect: onPlay,
                        onReveal: onReveal,
                        onCopyPaths: onCopyPaths
                    )
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var filteredClips: [ClipItem] {
        var clips = library.clips
        if !searchText.isEmpty {
            clips = clips.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        clips = clips.filter { dateFilter.includes($0.date) }
        clips = clips.filter { durationFilter.includes($0.duration) }
        return sortOption.sort(clips)
    }
}

struct ClipGrid: View {
    let clips: [ClipItem]
    let selectedClip: ClipItem?
    let onSelect: (ClipItem) -> Void
    let onReveal: (ClipItem) -> Void
    let onCopyPaths: (ClipItem) -> Void

    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 18)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(clips) { clip in
                    ClipCell(
                        clip: clip,
                        isSelected: clip.id == selectedClip?.id,
                        onPlay: { onSelect(clip) },
                        onReveal: { onReveal(clip) },
                        onCopyPaths: { onCopyPaths(clip) }
                    )
                }
            }
            .padding()
        }
    }
}


struct ClipCell: View {
    let clip: ClipItem
    let isSelected: Bool
    let onPlay: () -> Void
    let onReveal: () -> Void
    let onCopyPaths: () -> Void
    @State private var thumbnail: NSImage?

    var body: some View {
        Button(action: onPlay) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    thumbnailView
                    durationBadge
                }
                Text(clip.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(metadataText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(cellBackground)
            .overlay(cellBorder)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Reveal in Finder") {
                onReveal()
            }
            Button("Copy Path") {
                onCopyPaths()
            }
        }
        .task(id: clip.url) {
            if thumbnail == nil {
                thumbnail = await ThumbnailService.shared.thumbnail(for: clip.url)
            }
        }
    }

    private var thumbnailView: some View {
        ZStack {
            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(colors: [Color.gray.opacity(0.35), Color.gray.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "film")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 140)
        .clipped()
        .cornerRadius(8)
    }

    private var durationBadge: some View {
        Text(Formatters.durationString(clip.duration))
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.6))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(6)
    }

    private var metadataText: String {
        return Formatters.dateString(clip.date)
    }

    private var cellBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(nsColor: .controlBackgroundColor))
    }

    private var cellBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(isSelected ? Color.accentColor.opacity(0.8) : Color.clear, lineWidth: 2)
    }
}

struct ClipList: View {
    let clips: [ClipItem]
    let selectedClip: ClipItem?
    let onSelect: (ClipItem) -> Void
    let onReveal: (ClipItem) -> Void
    let onCopyPaths: (ClipItem) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(clips) { clip in
                    ClipRow(
                        clip: clip,
                        isSelected: clip.id == selectedClip?.id,
                        onPlay: { onSelect(clip) },
                        onReveal: { onReveal(clip) },
                        onCopyPaths: { onCopyPaths(clip) }
                    )
                }
            }
            .padding()
        }
    }
}

struct ClipRow: View {
    let clip: ClipItem
    let isSelected: Bool
    let onPlay: () -> Void
    let onReveal: () -> Void
    let onCopyPaths: () -> Void

    @State private var thumbnail: NSImage?

    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 12) {
                thumbnailView
                VStack(alignment: .leading, spacing: 4) {
                    Text(clip.name)
                        .font(.headline)
                    Text(Formatters.dateString(clip.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(Formatters.durationString(clip.duration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(rowBackground)
            .overlay(rowBorder)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Reveal in Finder") {
                onReveal()
            }
            Button("Copy Path") {
                onCopyPaths()
            }
        }
        .task(id: clip.url) {
            if thumbnail == nil {
                thumbnail = await ThumbnailService.shared.thumbnail(for: clip.url)
            }
        }
    }

    private var thumbnailView: some View {
        ZStack {
            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(colors: [Color.gray.opacity(0.35), Color.gray.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "film")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 120, height: 68)
        .clipped()
        .cornerRadius(6)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(nsColor: .controlBackgroundColor))
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(isSelected ? Color.accentColor.opacity(0.8) : Color.clear, lineWidth: 2)
    }
}
