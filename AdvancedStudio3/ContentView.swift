import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@main
struct AdvancedStudio3App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1440, height: 920)
        .modelContainer(for: ArchiveRecord.self)
    }
}

@MainActor
@Observable
final class StudioSession {
    enum State: Equatable {
        case empty
        case processing
        case loading
        case ready
        case exporting
        case complete
        case failed(String)

        var label: String {
            switch self {
            case .empty: "Awaiting product"
            case .processing: "Isolating product"
            case .loading: "Building RealityKit scene"
            case .ready: "Ready to preview"
            case .exporting: "Rendering 240 frames"
            case .complete: "Export validated"
            case .failed: "Needs attention"
            }
        }
    }

    var state: State = .empty
    var job: RenderJob?
    var processedImageURL: URL?
    var scene: PremiumAdScene?
    var frameIndex = 0
    var isPlaying = false
    var exportProgress = 0.0
    var validation: VideoValidationResult?
    private var playbackTask: Task<Void, Never>?

    var currentTime: Double {
        Double(frameIndex) / Double(PremiumAdScene.frameRate)
    }

    func importProduct(url: URL) async {
        stop()
        state = .processing
        validation = nil
        exportProgress = 0
        do {
            let job = try RenderJob.create(for: url)
            self.job = job
            let processed = try await Task.detached {
                try ForegroundProcessor().process(imageURL: url, job: job)
            }.value
            processedImageURL = processed
            state = .loading
            scene = try await PremiumAdScene.load(imageURL: processed)
            frameIndex = PremiumAdScene.heroFrame
            state = .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func togglePlayback() {
        isPlaying ? stop() : play()
    }

    func play() {
        guard scene != nil, !isPlaying else { return }
        if frameIndex >= PremiumAdScene.frameCount - 1 {
            frameIndex = 0
        }
        isPlaying = true
        playbackTask = Task { [weak self] in
            while let self, !Task.isCancelled, self.isPlaying {
                try? await Task.sleep(for: .milliseconds(33))
                if self.frameIndex >= PremiumAdScene.frameCount - 1 {
                    self.stop()
                } else {
                    self.frameIndex += 1
                }
            }
        }
    }

    func stop() {
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
    }

    func restart() {
        stop()
        frameIndex = 0
        scene?.apply(frameIndex: 0)
    }

    func scrub(to value: Double) {
        stop()
        frameIndex = min(
            PremiumAdScene.frameCount - 1,
            max(0, Int((value * Double(PremiumAdScene.frameRate)).rounded()))
        )
        scene?.apply(frameIndex: frameIndex)
    }

    func export(modelContext: ModelContext) async {
        guard let job, let processedImageURL else { return }
        stop()
        state = .exporting
        exportProgress = 0
        do {
            let result = try await RealityKitVideoExporter().export(
                processedImageURL: processedImageURL,
                job: job
            ) { [weak self] progress in
                self?.exportProgress = progress
            }
            validation = result
            let record = ArchiveRecord(
                id: job.id,
                createdAt: job.createdAt,
                originalImageURL: job.originalImageURL,
                processedImageURL: job.processedImageURL,
                videoURL: job.videoURL,
                templateIdentifier: RenderJob.templateIdentifier,
                validation: result
            )
            modelContext.insert(record)
            try modelContext.save()
            state = .complete
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func openExport() {
        guard let videoURL = job?.videoURL,
              FileManager.default.fileExists(atPath: videoURL.path) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([videoURL])
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var session = StudioSession()
    @State private var isImporting = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.08))
            HStack(spacing: 0) {
                templateLibrary
                    .frame(width: 250)
                Divider().overlay(Color.white.opacity(0.08))
                preview
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Divider().overlay(Color.white.opacity(0.08))
                controls
                    .frame(width: 290)
            }
            .frame(maxHeight: .infinity)
            Divider().overlay(Color.white.opacity(0.08))
            timeline
                .frame(height: 150)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.025, green: 0.032, blue: 0.055),
                    Color(red: 0.012, green: 0.016, blue: 0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundStyle(.white)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            Task { await session.importProduct(url: url) }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.blue.gradient)
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text("ADVANCED STUDIO 3")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .tracking(1.5)
                Text("Apple-native product motion")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            statusPill
            Button {
                Task { await session.export(modelContext: modelContext) }
            } label: {
                Label("Export 8s MOV", systemImage: "arrow.up.forward")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(session.scene == nil || session.state == .exporting)
        }
        .padding(.horizontal, 22)
        .frame(height: 68)
    }

    private var statusPill: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            Text(session.state.label)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.white.opacity(0.055), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.08)))
    }

    private var templateLibrary: some View {
        VStack(alignment: .leading, spacing: 16) {
            panelTitle("TEMPLATE LIBRARY", subtitle: "Curated motion systems")
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.7), .indigo.opacity(0.25), .black],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Circle()
                        .fill(.blue.opacity(0.28))
                        .blur(radius: 18)
                        .frame(width: 110, height: 110)
                        .offset(x: 68, y: -25)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PREMIUM 01")
                            .font(.caption2.weight(.bold))
                            .tracking(1.2)
                        Text("Optical Mesh")
                            .font(.headline)
                    }
                    .padding(14)
                }
                .frame(height: 170)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue, lineWidth: 2)
                )
                HStack {
                    Label("Selected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                    Spacer()
                    Text("8.0s")
                        .foregroundStyle(.secondary)
                }
                .font(.caption.weight(.medium))
            }
            Spacer()
            Text("One finished template. Additional templates will appear here without changing the studio workflow.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
    }

    private var preview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("AD PREVIEW")
                    .font(.caption.weight(.bold))
                    .tracking(1.3)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("1080 × 1920  •  9:16")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(.black.opacity(0.5))
                    .shadow(color: .blue.opacity(0.16), radius: 40)

                if let scene = session.scene {
                    ProductSceneView(scene: scene, frameIndex: session.frameIndex)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    emptyPreview
                }

                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.12))
                    .allowsHitTesting(false)
            }
            .aspectRatio(9 / 16, contentMode: .fit)
            .frame(maxHeight: 620)
            .padding(.horizontal, 34)

            HStack(spacing: 18) {
                Button(action: session.restart) {
                    Image(systemName: "backward.end.fill")
                }
                Button(action: session.togglePlayback) {
                    Image(systemName: session.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 22)
                }
                .buttonStyle(.borderedProminent)
                Text("\(time(session.currentTime))  /  8.0")
                    .font(.system(.callout, design: .monospaced).weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .disabled(session.scene == nil)
        }
        .padding(.vertical, 20)
    }

    private var emptyPreview: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(.blue)
            Text("Your finished ad appears here")
                .font(.headline)
            Text("Import a product to isolate it with Vision and build the premium RealityKit scene.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 220)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 22) {
            panelTitle("PRODUCT / SCENE", subtitle: "Template 195 · Optical Mesh")
            GroupBox {
                VStack(alignment: .leading, spacing: 13) {
                    if let url = session.processedImageURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.black.opacity(0.22))
                            .frame(height: 150)
                            .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                    }

                    Button {
                        isImporting = true
                    } label: {
                        Label(
                            session.processedImageURL == nil ? "Import Product" : "Replace Product",
                            systemImage: "photo.badge.plus"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(session.state == .processing || session.state == .exporting)
                }
                .padding(5)
            }

            detailRow("Template", "Optical Mesh")
            detailRow("Duration", "8.0 seconds")
            detailRow("Output", "1080 × 1920")
            detailRow("Renderer", "RealityKit + Metal")

            if session.state == .exporting {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Rendering")
                        Spacer()
                        Text("\(Int(session.exportProgress * 360)) / 360")
                            .monospacedDigit()
                    }
                    .font(.caption.weight(.medium))
                    ProgressView(value: session.exportProgress)
                        .tint(.blue)
                }
            }

            if let validation = session.validation {
                validationView(validation)
            }

            if case .failed(let message) = session.state {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: session.openExport) {
                Label("Open Export", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .disabled(session.validation == nil)
        }
        .padding(20)
    }

    private var timeline: some View {
        VStack(spacing: 11) {
            HStack(spacing: 14) {
                Button(action: session.togglePlayback) {
                    Image(systemName: session.isPlaying ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)
                Button(action: session.restart) {
                    Image(systemName: "arrow.counterclockwise")
                }
                Text(time(session.currentTime))
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                    .frame(width: 45)
                Slider(
                    value: Binding(
                        get: { session.currentTime },
                        set: session.scrub(to:)
                    ),
                    in: 0...12
                )
                Text("8.0")
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
            }

            GeometryReader { geometry in
                let available = geometry.size.width
                HStack(spacing: 3) {
                    phase("CAMERA PUSH", "0–6.3s", color: .cyan)
                        .frame(width: available * 2 / 12 - 2)
                    phase("LATTICE FORM", "0.7–4.8s", color: .blue)
                        .frame(width: available * 4 / 12 - 2)
                    phase("PRODUCT REVEAL", "4.1–5.5s", color: .indigo)
                        .frame(width: available * 4 / 12 - 2)
                    phase("COPY / HOLD", "6.2–8s", color: .purple)
                        .frame(width: available * 2 / 12 - 2)
                }
            }
            .frame(height: 48)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 15)
        .disabled(session.scene == nil)
    }

    private func phase(_ title: String, _ range: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
                Text(range)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(color.opacity(0.34)))
    }

    private func panelTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.callout.weight(.medium))
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.caption)
    }

    private func validationView(_ result: VideoValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("Export validated", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .font(.caption.weight(.semibold))
            Text(result.summary)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.green.opacity(0.2)))
    }

    private var statusColor: Color {
        switch session.state {
        case .empty: .secondary
        case .processing, .loading, .exporting: .orange
        case .ready: .blue
        case .complete: .green
        case .failed: .red
        }
    }

    private func time(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}

#Preview {
    ContentView()
        .frame(width: 1440, height: 920)
}
