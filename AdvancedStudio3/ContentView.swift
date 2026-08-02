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
            case .exporting: "Rendering frames"
            case .complete: "Export validated"
            case .failed: "Needs attention"
            }
        }
    }

    var state: State = .empty
    var selectedTemplate: StudioTemplate = .opticalMesh
    var job: RenderJob?
    var processedImageURL: URL?
    var scene: StudioScene?
    var sceneRevision = 0
    var frameIndex = 0
    var isPlaying = false
    var exportProgress = 0.0
    var validation: VideoValidationResult?
    private var playbackTask: Task<Void, Never>?
    private var playbackGeneration = 0
    private var sceneLoadGeneration = 0

    var specification: AdSpecification {
        selectedTemplate.specification
    }

    var currentTime: Double {
        specification.seconds(for: frameIndex)
    }

    var durationLabel: String {
        String(format: "%.1f", specification.duration)
    }

    var stateLabel: String {
        state == .exporting
            ? "Rendering \(specification.frameCount) frames"
            : state.label
    }

    func importProduct(url: URL) async {
        stop()
        sceneLoadGeneration += 1
        let loadGeneration = sceneLoadGeneration
        state = .processing
        scene = nil
        validation = nil
        exportProgress = 0
        do {
            let job = try RenderJob.create(for: url, template: selectedTemplate)
            self.job = job
            let processed = try await Task.detached {
                try ForegroundProcessor().process(imageURL: url, job: job)
            }.value
            processedImageURL = processed
            state = .loading
            let loadedScene = try await StudioScene.load(
                template: selectedTemplate,
                imageURL: processed
            )
            guard loadGeneration == sceneLoadGeneration else { return }
            scene = loadedScene
            sceneRevision += 1
            frameIndex = selectedTemplate.heroFrame
            state = .ready
        } catch {
            guard loadGeneration == sceneLoadGeneration else { return }
            scene = nil
            state = .failed(error.localizedDescription)
        }
    }

    func selectTemplate(_ template: StudioTemplate) async {
        guard template != selectedTemplate,
              state != .processing,
              state != .exporting else {
            return
        }
        stop()
        sceneLoadGeneration += 1
        let loadGeneration = sceneLoadGeneration
        selectedTemplate = template
        validation = nil
        job = job?.retarget(to: template)
        scene = nil
        frameIndex = 0
        guard let processedImageURL else {
            state = .empty
            return
        }
        state = .loading
        do {
            let loadedScene = try await StudioScene.load(
                template: template,
                imageURL: processedImageURL
            )
            guard loadGeneration == sceneLoadGeneration,
                  selectedTemplate == template else {
                return
            }
            scene = loadedScene
            sceneRevision += 1
            frameIndex = template.heroFrame
            state = .ready
        } catch {
            guard loadGeneration == sceneLoadGeneration,
                  selectedTemplate == template else {
                return
            }
            scene = nil
            state = .failed(error.localizedDescription)
        }
    }

    func togglePlayback() {
        isPlaying ? stop() : play()
    }

    func play() {
        guard scene != nil, !isPlaying else { return }
        if frameIndex >= specification.finalFrameIndex {
            frameIndex = 0
        }
        playbackGeneration += 1
        let generation = playbackGeneration
        isPlaying = true
        playbackTask = Task { [weak self] in
            while let self,
                  !Task.isCancelled,
                  self.isPlaying,
                  generation == self.playbackGeneration {
                do {
                    try await Task.sleep(for: self.specification.frameDuration)
                } catch {
                    return
                }
                guard generation == self.playbackGeneration else { return }
                if self.frameIndex >= self.specification.finalFrameIndex {
                    self.isPlaying = false
                    self.playbackTask = nil
                    return
                } else {
                    self.frameIndex += 1
                }
            }
        }
    }

    func stop() {
        playbackGeneration += 1
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
        frameIndex = specification.frameIndex(at: value)
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
                job: job,
                template: selectedTemplate
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
                templateIdentifier: job.templateIdentifier,
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
    @State private var isBatch1Expanded = true
    @State private var isBatch2Expanded = true

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.08))
            HStack(spacing: 0) {
                templateLibrary
                    .frame(width: 250)
                Divider().overlay(Color.white.opacity(0.08))
                preview
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .top
                    )
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
        .task {
            await SceneAuditRenderer.runIfRequested()
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
                Label("Export \(session.durationLabel)s MOV", systemImage: "arrow.up.forward")
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
            Text(session.stateLabel)
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
            ScrollView(.vertical) {
                VStack(spacing: 14) {
                    DisclosureGroup(isExpanded: $isBatch1Expanded) {
                        LazyVStack(spacing: 14) {
                            ForEach(StudioTemplate.batch1Cases) { template in
                                templateCard(template)
                            }
                        }
                        .padding(.top, 12)
                    } label: {
                        librarySectionLabel("BATCH 1", count: StudioTemplate.batch1Cases.count)
                    }

                    Text("Premium 07–10 are valid refinement candidates, not production-ready.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    DisclosureGroup(isExpanded: $isBatch2Expanded) {
                        LazyVStack(spacing: 14) {
                            ForEach(StudioTemplate.batch2Cases) { template in
                                templateCard(template)
                            }
                        }
                        .padding(.top, 12)
                    } label: {
                        librarySectionLabel("BATCH 2", count: StudioTemplate.batch2Cases.count)
                    }
                }
                .tint(.secondary)
            }
            .scrollIndicators(.visible)
        }
        .padding(20)
    }

    private func librarySectionLabel(_ title: String, count: Int) -> some View {
        HStack {
            Label(title, systemImage: "square.stack.3d.up.fill")
                .font(.caption.weight(.bold))
                .tracking(1.1)
            Spacer()
            Text("\(count)")
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
    }

    private func templateCard(_ template: StudioTemplate) -> some View {
        let selected = session.selectedTemplate == template
        return Button {
            Task { await session.selectTemplate(template) }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: templateCardColors(template),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    if template == .opticalMesh {
                        Circle()
                            .fill(.blue.opacity(0.28))
                            .blur(radius: 16)
                            .frame(width: 90, height: 90)
                            .offset(x: 64, y: -18)
                    } else {
                        Capsule()
                            .fill(Color.orange.opacity(0.26))
                            .blur(radius: 12)
                            .frame(width: 150, height: 42)
                            .rotationEffect(.degrees(-18))
                            .offset(x: 54, y: -22)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(template.libraryIndex)
                                .font(.caption2.weight(.bold))
                                .tracking(1.2)
                            Spacer()
                            Text(template.validity.rawValue)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(0.8)
                                .foregroundStyle(
                                    template.validity == .valid
                                        ? Color.green
                                        : Color.orange
                                )
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(.black.opacity(0.55), in: Capsule())
                        }
                        Text(template.name)
                            .font(.headline)
                    }
                    .padding(12)
                }
                .frame(height: 112)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selected ? Color.blue : .white.opacity(0.1), lineWidth: selected ? 2 : 1)
                )
                HStack {
                    Label(
                        selected ? "Selected" : "Select",
                        systemImage: selected ? "checkmark.circle.fill" : "circle"
                    )
                    .foregroundStyle(selected ? .blue : .secondary)
                    Spacer()
                    Text(String(format: "%.1fs", template.specification.duration))
                        .foregroundStyle(.secondary)
                }
                .font(.caption.weight(.medium))
            }
        }
        .buttonStyle(.plain)
        .disabled(session.state == .processing || session.state == .exporting)
    }

    private func templateCardColors(_ template: StudioTemplate) -> [Color] {
        switch template {
        case .coastalRelay: [.cyan.opacity(0.72), Color(red: 0.62, green: 0.39, blue: 0.24), .black]
        case .glasshouseRise: [.green.opacity(0.68), Color(red: 0.46, green: 0.33, blue: 0.15), .black]
        case .alpineWake: [Color(red: 0.68, green: 0.80, blue: 0.90), Color(red: 0.16, green: 0.26, blue: 0.36), .black]
        case .kineticFacade: [.orange, .blue.opacity(0.65), .black]
        case .rainlightPavilion: [Color(red: 0.18, green: 0.48, blue: 0.62), Color(red: 0.25, green: 0.14, blue: 0.09), .black]
        case .observatoryTransit: [.indigo.opacity(0.82), .orange.opacity(0.72), .black]
        case .aerodynamicTrace: [.white, .red.opacity(0.78), .black]
        case .chromaticElevator: [.pink.opacity(0.80), .cyan.opacity(0.72), .black]
        case .terracedDawn: [.orange.opacity(0.90), Color(red: 0.42, green: 0.16, blue: 0.07), .black]
        case .haloStage: [.purple.opacity(0.76), .orange.opacity(0.82), .black]
        case .opticalMesh: [.blue.opacity(0.72), .indigo.opacity(0.25), .black]
        default: [Color(red: 0.58, green: 0.27, blue: 0.08), Color(red: 0.18, green: 0.10, blue: 0.07), .black]
        }
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
                        .id(session.sceneRevision)
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
                Text("\(time(session.currentTime))  /  \(session.durationLabel)")
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
            panelTitle(
                "PRODUCT / SCENE",
                subtitle: session.selectedTemplate.sceneSubtitle
            )
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

            detailRow("Template", session.selectedTemplate.name)
            detailRow("Duration", "\(session.durationLabel) seconds")
            detailRow("Output", "1080 × 1920")
            detailRow("Renderer", "RealityKit + Metal")

            if session.state == .exporting {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Rendering")
                        Spacer()
                        Text(
                            "\(Int(session.exportProgress * Double(session.specification.frameCount)))"
                                + " / \(session.specification.frameCount)"
                        )
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
                    in: 0...session.specification.duration
                )
                Text(session.durationLabel)
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
            }

            GeometryReader { geometry in
                let available = geometry.size.width
                HStack(spacing: 3) {
                    let colors: [Color] = [.cyan, .blue, .indigo, .purple]
                    ForEach(
                        Array(session.selectedTemplate.timelinePhases.enumerated()),
                        id: \.element.id
                    ) { index, item in
                        phase(item.title, item.range, color: colors[index])
                            .frame(
                                width: available * item.width
                                    / session.specification.duration - 2
                            )
                    }
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
