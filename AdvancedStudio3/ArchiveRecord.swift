import Foundation
import SwiftData

@Model
final class ArchiveRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var originalImageFilename: String = ""
    var processedImageFilename: String = ""
    var videoFilename: String = ""
    var templateIdentifier: String = "optical-mesh-195"
    var durationSeconds: Double = 8
    var pixelWidth: Int = 1080
    var pixelHeight: Int = 1920
    var frameRate: Double = 30
    var validationSummary: String = ""

    init(
        id: UUID,
        createdAt: Date,
        originalImageURL: URL,
        processedImageURL: URL,
        videoURL: URL,
        templateIdentifier: String,
        validation: VideoValidationResult
    ) {
        self.id = id
        self.createdAt = createdAt
        originalImageFilename = originalImageURL.lastPathComponent
        processedImageFilename = processedImageURL.lastPathComponent
        videoFilename = videoURL.lastPathComponent
        self.templateIdentifier = templateIdentifier
        durationSeconds = validation.durationSeconds
        pixelWidth = validation.width
        pixelHeight = validation.height
        frameRate = validation.nominalFrameRate
        validationSummary = validation.summary
    }
}
