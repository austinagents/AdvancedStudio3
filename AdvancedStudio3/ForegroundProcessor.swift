import CoreImage
import Foundation
import Vision

enum StudioError: LocalizedError {
    case unreadableImage
    case noForeground
    case pngEncodingFailed
    case missingSceneEntity(String)
    case metalUnavailable
    case exportFailed(String)
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .unreadableImage: "The selected file is not a readable image."
        case .noForeground: "Vision could not find a foreground product."
        case .pngEncodingFailed: "The transparent PNG could not be encoded."
        case .missingSceneEntity(let name): "The premium scene is missing \(name)."
        case .metalUnavailable: "This Mac does not provide the required Metal rendering resources."
        case .exportFailed(let message): "Export failed: \(message)"
        case .validationFailed(let message): "Validation failed: \(message)"
        }
    }
}

nonisolated struct ForegroundProcessor {
    private let context = CIContext()

    func process(imageURL: URL, job: RenderJob) throws -> URL {
        let hasAccess = imageURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                imageURL.stopAccessingSecurityScopedResource()
            }
        }

        guard let input = CIImage(
            contentsOf: imageURL,
            options: [.applyOrientationProperty: true]
        ) else {
            throw StudioError.unreadableImage
        }

        try FileManager.default.copyItem(at: imageURL, to: job.originalImageURL)

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: input)
        try handler.perform([request])

        guard let observation = request.results?.first else {
            throw StudioError.noForeground
        }

        let maskBuffer = try observation.generateScaledMaskForImage(
            forInstances: observation.allInstances,
            from: handler
        )
        let mask = CIImage(cvPixelBuffer: maskBuffer)
        let transparent = CIImage(color: .clear).cropped(to: input.extent)
        let cutout = input.applyingFilter(
            "CIBlendWithMask",
            parameters: [
                kCIInputBackgroundImageKey: transparent,
                kCIInputMaskImageKey: mask
            ]
        )

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let pngData = context.pngRepresentation(
            of: cutout,
            format: .RGBA8,
            colorSpace: colorSpace
        ) else {
            throw StudioError.pngEncodingFailed
        }

        try pngData.write(to: job.processedImageURL, options: .atomic)
        return job.processedImageURL
    }
}

nonisolated struct RenderJob: Sendable {
    static let templateIdentifier = "optical-mesh-195"

    let id: UUID
    let createdAt: Date
    let directory: URL
    let originalImageURL: URL
    let processedImageURL: URL
    let videoURL: URL
    let metadataURL: URL

    static func create(for sourceURL: URL) throws -> RenderJob {
        let id = UUID()
        let createdAt = Date()
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = root
            .appendingPathComponent("AdvancedStudio3", isDirectory: true)
            .appendingPathComponent("Renders", isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let sourceExtension = sourceURL.pathExtension.isEmpty ? "image" : sourceURL.pathExtension
        return RenderJob(
            id: id,
            createdAt: createdAt,
            directory: directory,
            originalImageURL: directory.appendingPathComponent("original.\(sourceExtension)"),
            processedImageURL: directory.appendingPathComponent("product-cutout.png"),
            videoURL: directory.appendingPathComponent("optical-mesh-195.mov"),
            metadataURL: directory.appendingPathComponent("metadata.json")
        )
    }
}
