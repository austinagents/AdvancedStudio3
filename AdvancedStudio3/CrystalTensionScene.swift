import AppKit
import RealityKit

@MainActor final class CrystalTensionScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let crystals: [ModelEntity]
  private init(_ r: Entity, _ c: PerspectiveCamera, _ a: [ModelEntity]) {
    root = r
    camera = c
    crystals = a
  }
  static func load(imageURL: URL) async throws -> CrystalTensionScene {
    let r = try await NewSceneSupport.entity("CrystalTension")
    let x = try NewSceneSupport.child("CrystalRoot", in: r)
    let p = try NewSceneSupport.child("ProductRoot", in: r)
    let c = try NewSceneSupport.child("CameraRig", in: r)
    let l = try NewSceneSupport.child("LightRoot", in: r)
    var glass = PhysicallyBasedMaterial()
    glass.baseColor = .init(tint: NSColor(red: 0.25, green: 0.55, blue: 0.9, alpha: 0.42))
    glass.roughness = 0.04
    glass.blending = .transparent(opacity: .init(floatLiteral: 0.42))
    var a: [ModelEntity] = []
    for i in 0..<6 {
      let e = ModelEntity(
        mesh: .generateBox(width: 0.24, height: 7, depth: 0.24, cornerRadius: 0.04),
        materials: [glass])
      let q = Float(i) / 6 * 2 * Float.pi
      e.position = [cos(q) * 2.2, sin(q) * 0.4, 0]
      e.orientation = simd_quatf(angle: q, axis: [0, 0, 1])
      x.addChild(e)
      a.append(e)
    }
    let pr = try await NewSceneSupport.product(
      imageURL: imageURL, height: 1.66, name: "CrystalProduct")
    pr.position = [0.5, -0.5, -0.3]
    p.addChild(pr)
    let ib = try await NewSceneSupport.imageLight(
      id: "cloudy_netted_nursery", exponent: 0.85, parent: l)
    NewSceneSupport.receiveIBL(a, light: ib)
    let cam = NewSceneSupport.camera(focalLength: 74, name: "CrystalCamera")
    c.addChild(cam)
    let s = CrystalTensionScene(r, cam, a)
    s.apply(frameIndex: 359)
    return s
  }
  func apply(frameIndex: Int) {
    let f = min(max(frameIndex, 0), 359)
    let tight = NewSceneSupport.smooth(f, 0, 176)
    let release = NewSceneSupport.smooth(f, 180, 258)
    let h = NewSceneSupport.smooth(f, 270, 359)
    for i in crystals.indices {
      let a = Float(i) / 6 * 2 * Float.pi
      crystals[i].position = [
        cos(a) * NewSceneSupport.mix(2.2, 0.65, tight) + cos(a) * release * 3.5,
        sin(a) * NewSceneSupport.mix(2.2, 0.65, tight) + sin(a) * release * 3.5, -release * 0.3,
      ]
      crystals[i].orientation = simd_quatf(angle: a + tight * 1.2 - release * 0.8, axis: [0, 0, 1])
    }
    camera.look(
      at: [0, -0.2, 0],
      from: [
        NewSceneSupport.mix(-0.9, 0.5, release) + h * 0.08, 0.1,
        NewSceneSupport.mix(8.2, 12, release),
      ], relativeTo: root)
  }
}
