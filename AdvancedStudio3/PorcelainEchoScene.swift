import AppKit
import RealityKit

@MainActor final class PorcelainEchoScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let rings: [ModelEntity]
  private init(_ r: Entity, _ c: PerspectiveCamera, _ a: [ModelEntity]) {
    root = r
    camera = c
    rings = a
  }
  static func load(imageURL: URL) async throws -> PorcelainEchoScene {
    let r = try await NewSceneSupport.entity("PorcelainEcho")
    let x = try NewSceneSupport.child("EchoRoot", in: r)
    let p = try NewSceneSupport.child("ProductRoot", in: r)
    let c = try NewSceneSupport.child("CameraRig", in: r)
    let l = try NewSceneSupport.child("LightRoot", in: r)
    var m = PhysicallyBasedMaterial()
    m.baseColor = .init(tint: NSColor(white: 0.9, alpha: 1))
    m.roughness = 0.12
    var a: [ModelEntity] = []
    for i in 0..<7 {
      let e = ModelEntity(
        mesh: .generateCylinder(height: 0.12, radius: 0.7 + Float(i) * 0.42), materials: [m])
      e.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
      x.addChild(e)
      a.append(e)
    }
    let pr = try await NewSceneSupport.product(
      imageURL: imageURL, height: 1.62, name: "EchoProduct")
    pr.position = [0.5, -0.5, -0.3]
    p.addChild(pr)
    let ib = try await NewSceneSupport.imageLight(
      id: "cyclorama_hard_light", exponent: 0.6, parent: l)
    NewSceneSupport.receiveIBL(a, light: ib)
    let cam = NewSceneSupport.camera(focalLength: 78, name: "EchoCamera")
    c.addChild(cam)
    let s = PorcelainEchoScene(r, cam, a)
    s.apply(frameIndex: 359)
    return s
  }
  func apply(frameIndex: Int) {
    let f = min(max(frameIndex, 0), 359)
    let wave = NewSceneSupport.smooth(f, 0, 176)
    let stack = NewSceneSupport.smooth(f, 180, 258)
    let h = NewSceneSupport.smooth(f, 270, 359)
    for i in rings.indices {
      let pulse = sin(wave * 8 - Float(i) * 0.7) * 0.35 * (1 - stack)
      rings[i].position = [0, pulse, NewSceneSupport.mix(Float(i) * (-0.32), 0, stack)]
      rings[i].scale = SIMD3<Float>(
        repeating: NewSceneSupport.mix(1, 0.28 + Float(i) * 0.035, stack))
      rings[i].position.y += NewSceneSupport.mix(0, -2.8 + Float(i) * 0.04, stack)
    }
    camera.look(at: [0, -0.3, 0], from: [0.35 + h * 0.08, 0.15, 12], relativeTo: root)
  }
}
