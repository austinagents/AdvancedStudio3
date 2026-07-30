@preconcurrency import AVFoundation
import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation
import Metal
import RealityKit
import VideoToolbox

struct VideoValidationResult: Codable, Sendable {
    let fileExists: Bool
    let codec: String
    let width: Int
    let height: Int
    let nominalFrameRate: Double
    let durationSeconds: Double
    let videoTrackCount: Int
    let firstFrameReadable: Bool
    let finalFrameReadable: Bool
    let frameContentChanges: Bool
    let expectedWidth: Int
    let expectedHeight: Int
    let expectedFrameRate: Double
    let expectedDurationSeconds: Double

    var isValid: Bool {
        fileExists
            && codec == "H.264"
            && width == expectedWidth
            && height == expectedHeight
            && abs(nominalFrameRate - expectedFrameRate) < 0.01
            && abs(durationSeconds - expectedDurationSeconds) < (1.0 / 600.0)
            && videoTrackCount == 1
            && firstFrameReadable
            && finalFrameReadable
            && frameContentChanges
    }

    var summary: String {
        "\(width)×\(height) • \(String(format: "%.2f", nominalFrameRate)) fps • "
            + "\(String(format: "%.3f", durationSeconds)) s • \(codec) • "
            + (frameContentChanges ? "motion verified" : "static-frame failure")
    }
}

@MainActor
final class RealityKitVideoExporter {
    func export(
        processedImageURL: URL,
        job: RenderJob,
        template: StudioTemplate,
        progress: @escaping @MainActor (Double) -> Void
    ) async throws -> VideoValidationResult {
        let specification = template.specification
        let scene = try await StudioScene.load(
            template: template,
            imageURL: processedImageURL
        )
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            throw StudioError.metalUnavailable
        }

        let renderer = try RealityRenderer()
        renderer.entities.append(contentsOf: [scene.root])
        renderer.activeCamera = scene.camera
        renderer.cameraSettings.colorBackground = .color(
            CGColor(red: 0.012, green: 0.018, blue: 0.05, alpha: 1)
        )
        renderer.cameraSettings.isToneMappingEnabled = true
        renderer.cameraSettings.antialiasing = .multisample4X

        let writer = try AVAssetWriter(outputURL: job.videoURL, fileType: .mov)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: specification.width,
            AVVideoHeightKey: specification.height,
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
            ],
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 12_000_000,
                AVVideoExpectedSourceFrameRateKey: specification.frameRate,
                AVVideoMaxKeyFrameIntervalKey: specification.frameRate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: specification.width,
            kCVPixelBufferHeightKey as String: specification.height,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: attributes
        )

        guard writer.canAdd(input) else {
            throw StudioError.exportFailed("AVFoundation rejected the H.264 input.")
        }
        writer.add(input)
        guard writer.startWriting() else {
            throw writer.error ?? StudioError.exportFailed("The writer could not start.")
        }
        writer.startSession(atSourceTime: .zero)

        guard let pool = adaptor.pixelBufferPool else {
            throw StudioError.exportFailed("AVFoundation did not create a pixel-buffer pool.")
        }
        var textureCache: CVMetalTextureCache?
        guard CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache) == kCVReturnSuccess,
              let textureCache else {
            throw StudioError.metalUnavailable
        }

        for frameIndex in 0..<specification.frameCount {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(2))
            }

            var optionalBuffer: CVPixelBuffer?
            guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &optionalBuffer) == kCVReturnSuccess,
                  let pixelBuffer = optionalBuffer else {
                throw StudioError.exportFailed("A frame buffer could not be allocated.")
            }

            var optionalMetalTexture: CVMetalTexture?
            let textureStatus = CVMetalTextureCacheCreateTextureFromImage(
                nil,
                textureCache,
                pixelBuffer,
                nil,
                .bgra8Unorm,
                specification.width,
                specification.height,
                0,
                &optionalMetalTexture
            )
            guard textureStatus == kCVReturnSuccess,
                  let metalTextureRef = optionalMetalTexture,
                  let texture = CVMetalTextureGetTexture(metalTextureRef) else {
                throw StudioError.exportFailed("Core Video could not expose the Metal texture.")
            }

            scene.apply(frameIndex: frameIndex)
            let output = try RealityRenderer.CameraOutput(
                .singleProjection(colorTexture: texture)
            )
            try await render(
                renderer: renderer,
                output: output,
                commandQueue: commandQueue,
                frameRate: specification.frameRate
            )

            let presentationTime = CMTime(
                value: CMTimeValue(frameIndex),
                timescale: specification.frameRate
            )
            guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                throw writer.error ?? StudioError.exportFailed("Frame \(frameIndex) was rejected.")
            }
            progress(Double(frameIndex + 1) / Double(specification.frameCount))
        }

        input.markAsFinished()
        writer.endSession(
            atSourceTime: CMTime(
                value: CMTimeValue(specification.frameCount),
                timescale: specification.frameRate
            )
        )
        await writer.finishWriting()
        guard writer.status == .completed else {
            throw writer.error ?? StudioError.exportFailed("The writer did not complete.")
        }

        let validation = try await VideoValidator().validate(
            url: job.videoURL,
            expected: specification
        )
        let metadata = try JSONEncoder.studio.encode(validation)
        try metadata.write(to: job.metadataURL, options: .atomic)
        guard validation.isValid else {
            throw StudioError.validationFailed(validation.summary)
        }
        return validation
    }

    private func render(
        renderer: RealityRenderer,
        output: RealityRenderer.CameraOutput,
        commandQueue: MTLCommandQueue,
        frameRate: Int32
    ) async throws {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw StudioError.metalUnavailable
        }
        let event = commandBuffer.device.makeEvent()!
        let signalValue: UInt64 = 1
        commandBuffer.encodeSignalEvent(event, value: signalValue)
        commandBuffer.commit()

        try await withCheckedThrowingContinuation { continuation in
            do {
                try renderer.updateAndRender(
                    deltaTime: 1.0 / Double(frameRate),
                    cameraOutput: output,
                    onComplete: { _ in continuation.resume() },
                    actionsBeforeRender: [.wait(for: event, value: signalValue)]
                )
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

nonisolated struct VideoValidator {
    func validate(
        url: URL,
        expected: AdSpecification
    ) async throws -> VideoValidationResult {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = tracks.first else {
            throw StudioError.validationFailed("The MOV contains no video track.")
        }

        let size = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        let transformedSize = size.applying(transform)
        let rate = try await track.load(.nominalFrameRate)
        let descriptions = try await track.load(.formatDescriptions)
        let codec = descriptions.first.map { description -> String in
            let subtype = CMFormatDescriptionGetMediaSubType(description)
            return subtype == kCMVideoCodecType_H264 ? "H.264" : fourCC(subtype)
        } ?? "Unknown"

        let first = try await frameSignature(asset: asset, time: .zero)
        let finalTime = CMTime(
            value: CMTimeValue(expected.finalFrameIndex),
            timescale: expected.frameRate
        )
        let final = try await frameSignature(asset: asset, time: finalTime)
        let middle = try await frameSignature(
            asset: asset,
            time: CMTime(
                value: CMTimeValue(expected.frameCount / 2),
                timescale: expected.frameRate
            )
        )

        return VideoValidationResult(
            fileExists: FileManager.default.fileExists(atPath: url.path),
            codec: codec,
            width: Int(abs(transformedSize.width)),
            height: Int(abs(transformedSize.height)),
            nominalFrameRate: Double(rate),
            durationSeconds: CMTimeGetSeconds(duration),
            videoTrackCount: tracks.count,
            firstFrameReadable: first != nil,
            finalFrameReadable: final != nil,
            frameContentChanges: first != middle || middle != final,
            expectedWidth: expected.width,
            expectedHeight: expected.height,
            expectedFrameRate: Double(expected.frameRate),
            expectedDurationSeconds: expected.duration
        )
    }

    private func frameSignature(asset: AVAsset, time: CMTime) async throws -> UInt64? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let image = try await generator.image(at: time).image
        guard let data = image.dataProvider?.data as Data? else { return nil }
        var hash: UInt64 = 14_695_981_039_346_656_037
        let stride = max(1, data.count / 4096)
        for index in Swift.stride(from: 0, to: data.count, by: stride) {
            hash ^= UInt64(data[index])
            hash &*= 1_099_511_628_211
        }
        return hash
    }

    private func fourCC(_ code: FourCharCode) -> String {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xff),
            UInt8((code >> 16) & 0xff),
            UInt8((code >> 8) & 0xff),
            UInt8(code & 0xff)
        ]
        return String(bytes: bytes, encoding: .macOSRoman) ?? "Unknown"
    }
}

private extension JSONEncoder {
    static var studio: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
