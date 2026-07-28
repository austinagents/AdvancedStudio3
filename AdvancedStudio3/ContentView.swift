import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct AdvancedStudio3App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .modelContainer(for: ArchiveRecord.self)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isImporting = false
    @State private var importedImageURL: URL?
    @State private var processedImageURL: URL?
    @State private var isProcessing = false
    @State private var status = "Import one image to begin."

    var body: some View {
        VStack(spacing: 20) {
            Group {
                if let processedImageURL {
                    ProductSceneView(imageURL: processedImageURL)
                } else if let importedImageURL {
                    AsyncImage(url: importedImageURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    ContentUnavailableView(
                        "No Product Image",
                        systemImage: "photo",
                        description: Text(status)
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button("Import Product Image") {
                isImporting = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)

            if isProcessing {
                ProgressView("Extracting foreground…")
            } else {
                Text(status)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 520)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result else { return }
            guard let url = urls.first else { return }
            importedImageURL = url
            processedImageURL = nil
            isProcessing = true
            status = "Processing product…"

            Task {
                do {
                    let outputURL = try await Task.detached {
                        try ForegroundProcessor().process(imageURL: url)
                    }.value
                    processedImageURL = outputURL
                    status = "Loading PrototypeTemplate…"
                    _ = try await PrototypeTemplateScene.load(
                        imageURL: outputURL
                    )
                    status = "Rendering 150 template frames…"
                    let videoURL = try await VideoExporter().export(
                        processedImageURL: outputURL
                    )
                    let record = ArchiveRecord(
                        imageURL: outputURL,
                        videoURL: videoURL
                    )
                    modelContext.insert(record)
                    try modelContext.save()
                    status = "PrototypeTemplate archive saved: \(videoURL.lastPathComponent)"
                } catch {
                    status = error.localizedDescription
                }
                isProcessing = false
            }
        }
    }
}

#Preview {
    ContentView()
}
