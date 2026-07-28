import CoreImage
import Foundation
import Vision

enum PrototypeError: LocalizedError {
    case unreadableImage
    case noForeground
    case pngEncodingFailed

    var errorDescription: String? {
        switch self {
        case .unreadableImage: "The selected file is not a readable image."
        case .noForeground: "Vision could not find a foreground product."
        case .pngEncodingFailed: "The transparent PNG could not be encoded."
        }
    }
}

nonisolated struct ForegroundProcessor {
    private let context = CIContext()

    func process(imageURL: URL) throws -> URL {
        let hasAccess = imageURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                imageURL.stopAccessingSecurityScopedResource()
            }
        }

        guard let input = CIImage(contentsOf: imageURL, options: [.applyOrientationProperty: true]) else {
            throw PrototypeError.unreadableImage
        }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: input)
        try handler.perform([request])

        guard let observation = request.results?.first else {
            throw PrototypeError.noForeground
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
            throw PrototypeError.pngEncodingFailed
        }

        let outputURL = try PrototypeFiles.processedImageURL()
        try pngData.write(to: outputURL, options: .atomic)
        return outputURL
    }
}

nonisolated enum PrototypeFiles {
    static func archiveDirectory() throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = root
            .appendingPathComponent("AdvancedStudio3", isDirectory: true)
            .appendingPathComponent("Archive", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    static func processedImageURL() throws -> URL {
        try archiveDirectory().appendingPathComponent("product-cutout.png")
    }

    static func videoURL() throws -> URL {
        try archiveDirectory().appendingPathComponent("product-video.mov")
    }
}
