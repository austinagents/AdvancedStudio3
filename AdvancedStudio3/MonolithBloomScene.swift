import AppKit
import RealityKit

@MainActor final class MonolithBloomScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let petals: [ModelEntity]
  private init(_ r: Entity, _ c: PerspectiveCamera, _ p: [ModelEntity]) {
    root = r
    camera = c
    petals = p
  }
  static func load(imageURL: URL) async throws -> MonolithBloomScene {
    let r = try await NewSceneSupport.entity("MonolithBloom")
    let x = try NewSceneSupport.child("PetalRoot", in: r)
    let p = try NewSceneSupport.child("ProductRoot", in: r)
    let c = try NewSceneSupport.child("CameraRig", in: r)
    let l = try NewSceneSupport.child("LightRoot", in: r)
    var carbon = PhysicallyBasedMaterial()
    carbon.baseColor = .init(tint: NSColor(white: 0.025, alpha: 1))
    carbon.metallic = 0.7
    carbon.roughness = 0.2
    var a: [ModelEntity] = []
    for i in 0..<10 {
      let e = ModelEntity(
        mesh: .generateBox(width: 1.1, height: 3.8, depth: 0.18, cornerRadius: 0.5),
        materials: [carbon])
      let q = Float(i) / 10 * 2 * Float.pi
      e.position = [cos(q) * 0.55, sin(q) * 0.55, 0]
      e.orientation = simd_quatf(angle: q, axis: [0, 0, 1])
      x.addChild(e)
      a.append(e)
    }
    let pr = try await NewSceneSupport.product(
      imageURL: imageURL, height: 1.64, name: "BloomProduct")
    pr.position = [0.5, -0.5, -0.3]
    p.addChild(pr)
    let ib = try await NewSceneSupport.imageLight(id: "clarens_night_01", exponent: 0.9, parent: l)
    NewSceneSupport.receiveIBL(a, light: ib)
    let cam = NewSceneSupport.camera(focalLength: 80, name: "BloomCamera")
    c.addChild(cam)
    let s = MonolithBloomScene(r, cam, a)
    s.apply(frameIndex: 359)
    return s
  }
  func apply(frameIndex: Int) {
    let f = min(max(frameIndex, 0), 359)
    let pulse = NewSceneSupport.smooth(f, 0, 176)
    let bloom = NewSceneSupport.smooth(f, 180, 258)
    let h = NewSceneSupport.smooth(f, 270, 359)
    for i in petals.indices {
      let a = Float(i) / 10 * 2 * Float.pi
      let radius = NewSceneSupport.mix(0.55, 3.8, bloom)
      petals[i].position = [cos(a) * radius, sin(a) * radius - bloom * 1.1, -bloom * 0.2]
      petals[i].orientation = simd_quatf(
        angle: a + sin(pulse * Float.pi * 3 + Float(i)) * 0.08 + bloom * 0.7, axis: [0, 0, 1])
    }
    camera.look(
      at: [0, -0.25, 0],
      from: [
        NewSceneSupport.mix(-0.7, 0.45, bloom) + h * 0.08, 0.1, NewSceneSupport.mix(8.5, 12, bloom),
      ], relativeTo: root)
  }
}
