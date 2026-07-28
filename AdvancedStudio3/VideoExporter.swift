@preconcurrency import AVFoundation
import CoreImage
import Foundation

nonisolated struct VideoExporter {
    private let width = 1080
    private let height = 1920
    private let framesPerSecond: Int32 = 30
    private let frameCount = 150

    func export(processedImageURL: URL) async throws -> URL {
        try await Task.detached {
            try exportSynchronously(processedImageURL: processedImageURL)
        }.value
    }

    private func exportSynchronously(processedImageURL: URL) throws -> URL {
        let outputURL = try PrototypeFiles.videoURL()
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 8_000_000,
                AVVideoExpectedSourceFrameRateKey: framesPerSecond,
                AVVideoMaxKeyFrameIntervalKey: framesPerSecond
            ]
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: attributes
        )

        guard writer.canAdd(input) else {
            throw VideoExportError.cannotAddInput
        }
        writer.add(input)
        guard writer.startWriting() else {
            throw writer.error ?? VideoExportError.writerFailed
        }
        writer.startSession(atSourceTime: .zero)

        guard let sourceImage = CIImage(contentsOf: processedImageURL) else {
            throw PrototypeError.unreadableImage
        }
        let frameImage = makeFrame(from: sourceImage)
        let context = CIContext(options: [.cacheIntermediates: false])
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

        for frameIndex in 0..<frameCount {
            while !input.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.002)
            }
            guard let pool = adaptor.pixelBufferPool else {
                throw VideoExportError.missingPixelBufferPool
            }
            var optionalBuffer: CVPixelBuffer?
            guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &optionalBuffer) == kCVReturnSuccess,
                  let pixelBuffer = optionalBuffer else {
                throw VideoExportError.pixelBufferAllocationFailed
            }

            context.render(
                frameImage,
                to: pixelBuffer,
                bounds: CGRect(x: 0, y: 0, width: width, height: height),
                colorSpace: colorSpace
            )
            let time = CMTime(value: CMTimeValue(frameIndex), timescale: framesPerSecond)
            guard adaptor.append(pixelBuffer, withPresentationTime: time) else {
                throw writer.error ?? VideoExportError.writerFailed
            }
        }

        input.markAsFinished()
        writer.endSession(atSourceTime: CMTime(seconds: 5, preferredTimescale: 600))
        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            semaphore.signal()
        }
        semaphore.wait()

        guard writer.status == .completed else {
            throw writer.error ?? VideoExportError.writerFailed
        }
        return outputURL
    }

    private func makeFrame(from image: CIImage) -> CIImage {
        let canvas = CGRect(x: 0, y: 0, width: width, height: height)
        let scale = min(
            CGFloat(width) * 0.82 / image.extent.width,
            CGFloat(height) * 0.72 / image.extent.height
        )
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let translated = scaled.transformed(
            by: CGAffineTransform(
                translationX: canvas.midX - scaled.extent.midX,
                y: canvas.midY - scaled.extent.midY
            )
        )
        let background = CIImage(
            color: CIColor(red: 0.055, green: 0.06, blue: 0.075, alpha: 1)
        ).cropped(to: canvas)
        return translated.composited(over: background).cropped(to: canvas)
    }
}

nonisolated enum VideoExportError: LocalizedError {
    case cannotAddInput
    case missingPixelBufferPool
    case pixelBufferAllocationFailed
    case writerFailed

    var errorDescription: String? {
        switch self {
        case .cannotAddInput: "AVFoundation rejected the H.264 video input."
        case .missingPixelBufferPool: "AVFoundation did not create a pixel buffer pool."
        case .pixelBufferAllocationFailed: "A video frame buffer could not be allocated."
        case .writerFailed: "AVFoundation could not finish the video."
        }
    }
}
