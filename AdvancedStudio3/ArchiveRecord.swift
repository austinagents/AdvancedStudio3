import Foundation
import SwiftData

@Model
final class ArchiveRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var imageFilename: String
    var videoFilename: String
    var durationSeconds: Double
    var pixelWidth: Int
    var pixelHeight: Int

    init(imageURL: URL, videoURL: URL) {
        id = UUID()
        createdAt = Date()
        imageFilename = imageURL.lastPathComponent
        videoFilename = videoURL.lastPathComponent
        durationSeconds = 5
        pixelWidth = 1080
        pixelHeight = 1920
    }
}
