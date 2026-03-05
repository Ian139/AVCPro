import SwiftUI
import AppKit

struct ExportView: View {
    @EnvironmentObject private var library: ClipLibrary
    @EnvironmentObject private var playerService: PlayerService

    let onPlay: (ClipItem) -> Void
    let onReveal: (ClipItem) -> Void
    let onCopyPaths: (ClipItem) -> Void

    @State private var selection: Set<UUID> = []
    @State private var isExporting = false
    @State private var statusMessage: String?
    @State private var exportMode: ExportMode = .original
    @State private var searchText = ""
    @State private var sortOption: ClipSortOption = .dateDesc
    @State private var layoutMode: ClipLayoutMode = .grid
    @State private var dateFilter: DateFilter = .all
    @State private var durationFilter: DurationFilter = .all

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            contentBody
            Divider()
            PlayerPanel()
                .frame(minHeight: 180, idealHeight: 200)
        }
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(library.sourceName)
                    .font(.headline)
                Spacer()
                if isExporting {
                    ProgressView("Exporting...")
                }
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

                Picker("Format", selection: $exportMode) {
                    ForEach(ExportMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .frame(minWidth: 280)
                if exportMode == .mp4 && !ffmpegAvailable {
                    Text("ffmpeg not found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Select All") {
                    selection = Set(filteredClips.map { $0.id })
                }
                Button("Clear") {
                    selection.removeAll()
                }
                Button(exportButtonTitle) {
                    exportSelected()
                }
                .disabled(selection.isEmpty || isExporting || (exportMode == .mp4 && !ffmpegAvailable))
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                    Text("No clips to export")
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if layoutMode == .grid {
                    ExportClipGrid(
                        clips: filteredClips,
                        selection: selection,
                        onToggleSelect: toggleSelection,
                        onPlay: onPlay,
                        onReveal: onReveal,
                        onCopyPaths: onCopyPaths
                    )
                } else {
                    ExportClipList(
                        clips: filteredClips,
                        selection: selection,
                        onToggleSelect: toggleSelection,
                        onPlay: onPlay,
                        onReveal: onReveal,
                        onCopyPaths: onCopyPaths
                    )
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func toggleSelection(_ clip: ClipItem) {
        if selection.contains(clip.id) {
            selection.remove(clip.id)
        } else {
            selection.insert(clip.id)
        }
    }

    private func exportSelected() {
        let clips = library.clips.filter { selection.contains($0.id) }
        guard !clips.isEmpty else { return }

        if exportMode == .mp4 && !ffmpegAvailable {
            statusMessage = "ffmpeg not found. Install ffmpeg to export MP4."
            return
        }

        let panel = NSOpenPanel()
        panel.title = "Choose Export Folder"
        panel.prompt = "Export"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let destination = panel.url {
            isExporting = true
            statusMessage = exportMode == .mp4
                ? "Exporting \(clips.count) clip(s) as MP4..."
                : "Exporting \(clips.count) clip(s)..."
            let mode = exportMode

            Task.detached(priority: .userInitiated) {
                do {
                    let result = try ClipExporter.export(
                        clips: clips,
                        to: destination,
                        mode: mode,
                        onProgress: { clip, index, total in
                            let name = clip.name.isEmpty ? "Clip" : clip.name
                            Task { @MainActor in
                                statusMessage = "Exporting \(index)/\(total): \(name)"
                            }
                        }
                    )
                    await MainActor.run {
                        isExporting = false
                        statusMessage = "Exported \(result.fileCount) files to \(destination.lastPathComponent)."
                    }
                } catch let error as FFMpegError {
                    await MainActor.run {
                        isExporting = false
                        switch error {
                        case .notInstalled:
                            statusMessage = "ffmpeg not found. Install ffmpeg to export MP4."
                        case .failed(let message):
                            statusMessage = "MP4 export failed: \(message)"
                        }
                    }
                } catch {
                    await MainActor.run {
                        isExporting = false
                        statusMessage = "Export failed."
                    }
                }
            }
        }
    }

    private var exportButtonTitle: String {
        exportMode == .mp4 ? "Export MP4..." : "Export Selected..."
    }

    private var ffmpegAvailable: Bool {
        FFMpeg.isAvailable()
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

struct ExportClipGrid: View {
    let clips: [ClipItem]
    let selection: Set<UUID>
    let onToggleSelect: (ClipItem) -> Void
    let onPlay: (ClipItem) -> Void
    let onReveal: (ClipItem) -> Void
    let onCopyPaths: (ClipItem) -> Void

    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 18)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(clips) { clip in
                    ExportClipCell(
                        clip: clip,
                        isSelected: selection.contains(clip.id),
                        onToggleSelect: { onToggleSelect(clip) },
                        onPlay: { onPlay(clip) },
                        onReveal: { onReveal(clip) },
                        onCopyPaths: { onCopyPaths(clip) }
                    )
                }
            }
            .padding()
        }
    }
}

struct ExportClipList: View {
    let clips: [ClipItem]
    let selection: Set<UUID>
    let onToggleSelect: (ClipItem) -> Void
    let onPlay: (ClipItem) -> Void
    let onReveal: (ClipItem) -> Void
    let onCopyPaths: (ClipItem) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(clips) { clip in
                    ExportClipRow(
                        clip: clip,
                        isSelected: selection.contains(clip.id),
                        onToggleSelect: { onToggleSelect(clip) },
                        onPlay: { onPlay(clip) },
                        onReveal: { onReveal(clip) },
                        onCopyPaths: { onCopyPaths(clip) }
                    )
                }
            }
            .padding()
        }
    }
}

struct ExportClipRow: View {
    let clip: ClipItem
    let isSelected: Bool
    let onToggleSelect: () -> Void
    let onPlay: () -> Void
    let onReveal: () -> Void
    let onCopyPaths: () -> Void

    @State private var thumbnail: NSImage?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)

            thumbnailView

            VStack(alignment: .leading, spacing: 4) {
                Text(clip.name)
                    .font(.headline)
                Text(Formatters.dateString(clip.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onPlay()
            } label: {
                Image(systemName: "play.fill")
            }
            .buttonStyle(.borderless)

            Text(Formatters.durationString(clip.duration))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(rowBackground)
        .overlay(rowBorder)
        .contextMenu {
            Button("Play") {
                onPlay()
            }
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
            .stroke(isSelected ? Color.accentColor.opacity(0.9) : Color.clear, lineWidth: 2)
    }
}

struct ExportClipCell: View {
    let clip: ClipItem
    let isSelected: Bool
    let onToggleSelect: () -> Void
    let onPlay: () -> Void
    let onReveal: () -> Void
    let onCopyPaths: () -> Void

    @State private var thumbnail: NSImage?

    var body: some View {
        Button(action: onToggleSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    thumbnailView
                    durationBadge
                    selectionBadge
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
            Button("Play") {
                onPlay()
            }
            Button("Reveal in Finder") {
                onReveal()
            }
            Button("Copy Path") {
                onCopyPaths()
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                onPlay()
            } label: {
                Image(systemName: "play.fill")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .padding(8)
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

    private var selectionBadge: some View {
        Group {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .padding(6)
            }
        }
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
            .stroke(isSelected ? Color.accentColor.opacity(0.9) : Color.clear, lineWidth: 2)
    }
}
