import AppKit
import RealityKit

@MainActor final class PolarChamberScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let louvers: [ModelEntity]
  private init(_ r: Entity, _ c: PerspectiveCamera, _ l: [ModelEntity]) {
    root = r
    camera = c
    louvers = l
  }
  static func load(imageURL: URL) async throws -> PolarChamberScene {
    let r = try await NewSceneSupport.entity("PolarChamber")
    let x = try NewSceneSupport.child("LouverRoot", in: r)
    let p = try NewSceneSupport.child("ProductRoot", in: r)
    let c = try NewSceneSupport.child("CameraRig", in: r)
    let l = try NewSceneSupport.child("LightRoot", in: r)
    var ceramic = PhysicallyBasedMaterial()
    ceramic.baseColor = .init(tint: NSColor(white: 0.82, alpha: 1))
    ceramic.roughness = 0.14
    var a: [ModelEntity] = []
    for i in 0..<11 {
      let e = ModelEntity(
        mesh: .generateBox(width: 0.52, height: 6.8, depth: 0.12, cornerRadius: 0.04),
        materials: [ceramic])
      e.position = [-2.6 + Float(i) * 0.52, -0.1, 0]
      x.addChild(e)
      a.append(e)
    }
    let pr = try await NewSceneSupport.product(
      imageURL: imageURL, height: 1.7, name: "PolarProduct")
    pr.position = [0.5, -0.5, -0.3]
    p.addChild(pr)
    let ib = try await NewSceneSupport.imageLight(id: "courtyard", exponent: 0.65, parent: l)
    NewSceneSupport.receiveIBL(a, light: ib)
    let cam = NewSceneSupport.camera(focalLength: 70, name: "PolarCamera")
    c.addChild(cam)
    let s = PolarChamberScene(r, cam, a)
    s.apply(frameIndex: 359)
    return s
  }
  func apply(frameIndex: Int) {
    let f = min(max(frameIndex, 0), 359)
    let ripple = NewSceneSupport.smooth(f, 0, 176)
    let clear = NewSceneSupport.smooth(f, 180, 260)
    let h = NewSceneSupport.smooth(f, 270, 359)
    for i in louvers.indices {
      let delay = NewSceneSupport.smooth(f, i * 5, 120 + i * 4)
      louvers[i].orientation = simd_quatf(
        angle: delay * sin(Float(i) * 0.85) * 1.2 + clear * Float.pi / 2, axis: [0, 1, 0])
      louvers[i].position.z = sin(Float(i) + ripple * 5) * 0.3 * (1 - clear)
    }
    camera.look(
      at: [0, -0.2, 0],
      from: [
        NewSceneSupport.mix(-1.3, 0.55, clear) + h * 0.1, 0.1, NewSceneSupport.mix(8, 12, clear),
      ], relativeTo: root)
  }
}
