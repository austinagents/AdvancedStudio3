import AppKit
import CoreImage
import CoreVideo
import Metal
import RealityKit

@MainActor
enum SceneAuditRenderer {
  static func runIfRequested() async {
    let environment = ProcessInfo.processInfo.environment
    guard environment["AS3_RENDER_AUDIT"] == "1",
      let productPath = environment["AS3_PRODUCT_CUTOUT"],
      let outputPath = environment["AS3_AUDIT_OUTPUT"]
    else {
      return
    }
    let productURL = URL(fileURLWithPath: productPath)
    let outputURL = URL(fileURLWithPath: outputPath, isDirectory: true)
    do {
      try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
      for template in StudioTemplate.candidateCases {
        let templateDirectory = outputURL.appendingPathComponent(
          template.rawValue, isDirectory: true)
        try FileManager.default.createDirectory(
          at: templateDirectory, withIntermediateDirectories: true)
        let frames = validationFrames(for: template)
        let scene = try await StudioScene.load(template: template, imageURL: productURL)
        for frame in frames {
          let destination = templateDirectory.appendingPathComponent(
            String(format: "%03d.png", frame))
          try await render(scene: scene, frameIndex: frame, to: destination)
        }
      }
      try "complete\n".write(
        to: outputURL.appendingPathComponent("AUDIT_COMPLETE"), atomically: true, encoding: .utf8)
    } catch {
      try? error.localizedDescription.write(
        to: outputURL.appendingPathComponent("AUDIT_FAILED"), atomically: true, encoding: .utf8)
    }
    NSApplication.shared.terminate(nil)
  }

  private static func validationFrames(for template: StudioTemplate) -> [Int] {
    switch template {
    case .opticalMesh: [0, 120, 210, 239]
    case .opticalCorridor: [0, 180, 251, 276, 320, 359]
    case .paperAperture: [0, 180, 251, 276, 320, 359]
    case .ceramicImpact: [0, 180, 251, 276, 320, 359]
    case .basaltTide: [0, 180, 251, 276, 320, 359]
    case .satinCurrent: [0, 180, 251, 276, 320, 359]
    case .canyonExposure: [0, 180, 251, 276, 320, 359]
    case .timberVault: [0, 180, 251, 276, 320, 359]
    case .bluegumHelix: [0, 180, 251, 276, 320, 359]
    case .magneticConvergence: [0, 180, 251, 276, 320, 359]
    case .oxideLightCut: [0, 180, 251, 276, 320, 359]
    case .photonGuillotine, .mercuryLens, .velvetSingularity, .polarChamber,
      .chronoSand, .thermalAlloy, .porcelainEcho, .gravityScript,
      .crystalTension, .monolithBloom, .vacuumCast, .anamorphicCourt,
      .moireEngine, .axisHouse, .pressureMark, .contactSheet,
      .seamRelease, .escapementZero, .sixAxisCeremony, .threadline:
      [0, 60, 180, 225, 270, 315, 359]
    }
  }

  private static func render(scene: StudioScene, frameIndex: Int, to url: URL) async throws {
    guard let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue(),
      let texture = device.makeTexture(descriptor: textureDescriptor())
    else {
      throw StudioError.metalUnavailable
    }
    scene.apply(frameIndex: frameIndex)
    let renderer = try RealityRenderer()
    renderer.entities.append(scene.root)
    renderer.activeCamera = scene.camera
    renderer.cameraSettings.colorBackground = .color(
      CGColor(red: 0.008, green: 0.009, blue: 0.012, alpha: 1))
    renderer.cameraSettings.isToneMappingEnabled = true
    renderer.cameraSettings.antialiasing = .multisample4X
    let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: texture))
    guard let commandBuffer = commandQueue.makeCommandBuffer(),
      let event = device.makeEvent()
    else {
      throw StudioError.metalUnavailable
    }
    commandBuffer.encodeSignalEvent(event, value: 1)
    commandBuffer.commit()
    try await withCheckedThrowingContinuation { continuation in
      do {
        try renderer.updateAndRender(
          deltaTime: 1.0 / 30.0,
          cameraOutput: output,
          onComplete: { _ in continuation.resume() },
          actionsBeforeRender: [.wait(for: event, value: 1)]
        )
      } catch {
        continuation.resume(throwing: error)
      }
    }
    let image = CIImage(
      mtlTexture: texture, options: [.colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])!
      .oriented(.downMirrored)
    let context = CIContext(mtlDevice: device)
    try context.writePNGRepresentation(
      of: image,
      to: url,
      format: .BGRA8,
      colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
    )
  }

  private static func textureDescriptor() -> MTLTextureDescriptor {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .bgra8Unorm,
      width: 540,
      height: 960,
      mipmapped: false
    )
    descriptor.usage = [.renderTarget, .shaderRead]
    descriptor.storageMode = .private
    return descriptor
  }
}
