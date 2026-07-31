import AppKit
import RealityKit

@MainActor final class VelvetSingularityScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let ribbons: [ModelEntity]
  private let product: ModelEntity
  private init(_ r: Entity, _ c: PerspectiveCamera, _ a: [ModelEntity], _ p: ModelEntity) {
    root = r
    camera = c
    ribbons = a
    product = p
  }
  static func load(imageURL: URL) async throws -> VelvetSingularityScene {
    let r = try await NewSceneSupport.entity("VelvetSingularity")
    let w = try NewSceneSupport.child("WorldRoot", in: r)
    let x = try NewSceneSupport.child("RibbonRoot", in: r)
    let p = try NewSceneSupport.child("ProductRoot", in: r)
    let c = try NewSceneSupport.child("CameraRig", in: r)
    let l = try NewSceneSupport.child("LightRoot", in: r)
    let satin = try await NewSceneSupport.surfaceMaterial(
      id: "crepe_satin", tint: NSColor(red: 0.22, green: 0.015, blue: 0.04, alpha: 1))
    var a: [ModelEntity] = []
    for i in 0..<14 {
      let e = ModelEntity(
        mesh: .generateBox(width: 7.5, height: 0.42, depth: 0.08, cornerRadius: 0.19),
        materials: [satin])
      e.position = [0, -2.75 + Float(i) * 0.42, 0]
      x.addChild(e)
      a.append(e)
    }
    let pr = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.72, name: "VelvetProduct", roughness: 0.3)
    pr.position = [0.55, -0.5, -0.25]
    p.addChild(pr)
    let ib = try await NewSceneSupport.imageLight(
      id: "ferndale_studio_05", exponent: 0.7, parent: l)
    NewSceneSupport.receiveIBL(a + [pr], light: ib)
    let cam = NewSceneSupport.camera(focalLength: 76, name: "VelvetCamera")
    c.addChild(cam)
    let s = VelvetSingularityScene(r, cam, a, pr)
    s.apply(frameIndex: 359)
    return s
  }
  func apply(frameIndex: Int) {
    let f = min(max(frameIndex, 0), 359)
    let pull = NewSceneSupport.smooth(f, 0, 178)
    let tear = NewSceneSupport.smooth(f, 180, 258)
    let h = NewSceneSupport.smooth(f, 270, 359)
    for i in ribbons.indices {
      let y = -2.75 + Float(i) * 0.42
      let phase = sin(Float(i) * 1.3 + pull * 4)
      ribbons[i].position = [
        phase * pull * 0.32 + (i % 2 == 0 ? -1 : 1) * tear * 4, y, tear * 0.15,
      ]
      ribbons[i].orientation = simd_quatf(angle: phase * pull * 0.08, axis: [0, 0, 1])
    }
    let cp = SIMD3<Float>(
      NewSceneSupport.mix(-0.7, 0.45, tear) + h * 0.08, 0.1, NewSceneSupport.mix(8.4, 12, tear))
    camera.look(at: [0, -0.25, 0], from: cp, relativeTo: root)
  }
}
