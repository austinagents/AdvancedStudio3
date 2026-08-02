import Foundation

nonisolated struct AdSpecification: Hashable, Sendable {
    let frameRate: Int32
    let frameCount: Int
    let width: Int
    let height: Int

    init(frameRate: Int32 = 30, frameCount: Int, width: Int = 1080, height: Int = 1920) {
        precondition(frameRate > 0)
        precondition(frameCount > 1)
        precondition(width > 0 && height > 0)
        self.frameRate = frameRate
        self.frameCount = frameCount
        self.width = width
        self.height = height
    }

    static let legacyEightSeconds = AdSpecification(frameCount: 240)
    static let premiumTwelveSeconds = AdSpecification(frameCount: 360)
    static let premiumFifteenSeconds = AdSpecification(frameCount: 450)

    var duration: TimeInterval {
        Double(frameCount) / Double(frameRate)
    }

    var finalFrameIndex: Int {
        frameCount - 1
    }

    var frameDuration: Duration {
        .seconds(1.0 / Double(frameRate))
    }

    func seconds(for frameIndex: Int) -> Double {
        Double(clamped(frameIndex)) / Double(frameRate)
    }

    func frameIndex(at seconds: Double) -> Int {
        clamped(Int((seconds * Double(frameRate)).rounded()))
    }

    func clamped(_ frameIndex: Int) -> Int {
        min(finalFrameIndex, max(0, frameIndex))
    }
}
