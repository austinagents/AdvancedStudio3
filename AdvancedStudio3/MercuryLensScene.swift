import AppKit
import RealityKit

@MainActor
final class MercuryLensScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let lenses: [ModelEntity]
  private let product: ModelEntity
  private init(_ r: Entity, _ c: PerspectiveCamera, _ l: [ModelEntity], _ p: ModelEntity) {
    root = r
    camera = c
    lenses = l
    product = p
  }
  static func load(imageURL: URL) async throws -> MercuryLensScene {
    let root = try await NewSceneSupport.entity("MercuryLens")
    let world = try NewSceneSupport.child("WorldRoot", in: root)
    let cr = try NewSceneSupport.child("LensRoot", in: root)
    let pr = try NewSceneSupport.child("ProductRoot", in: root)
    let cam = try NewSceneSupport.child("CameraRig", in: root)
    let lights = try NewSceneSupport.child("LightRoot", in: root)
    var chrome = PhysicallyBasedMaterial()
    chrome.baseColor = .init(tint: NSColor(white: 0.55, alpha: 1))
    chrome.metallic = .init(floatLiteral: 1)
    chrome.roughness = 0.035
    var matte = PhysicallyBasedMaterial()
    matte.baseColor = .init(tint: NSColor(red: 0.02, green: 0.03, blue: 0.045, alpha: 1))
    matte.roughness = 0.42
    let wall = ModelEntity(
      mesh: .generateBox(width: 13, height: 15, depth: 0.3, cornerRadius: 0.1), materials: [matte])
    wall.position = [0, 1, -3.5]
    world.addChild(wall)
    var lenses: [ModelEntity] = []
    for i in 0..<7 {
      let s = ModelEntity(
        mesh: .generateSphere(radius: 0.35 + Float(i % 3) * 0.11), materials: [chrome])
      let a = Float(i) / 7 * 2 * Float.pi
      s.position = [cos(a) * 3.5, sin(a) * 3.2, -0.2]
      cr.addChild(s)
      lenses.append(s)
    }
    let product = try await NewSceneSupport.product(
      imageURL: imageURL, height: 1.7, name: "MercuryProduct")
    product.position = [0.45, -0.45, -0.5]
    pr.addChild(product)
    let ibl = try await NewSceneSupport.imageLight(id: "blue_grotto", exponent: 0.8, parent: lights)
    NewSceneSupport.receiveIBL([wall] + lenses, light: ibl)
    let camera = NewSceneSupport.camera(focalLength: 64, name: "MercuryCamera")
    cam.addChild(camera)
    let scene = MercuryLensScene(root, camera, lenses, product)
    scene.apply(frameIndex: 359)
    return scene
  }
  func apply(frameIndex: Int) {
    let f = min(max(frameIndex, 0), 359)
    let merge = NewSceneSupport.smooth(f, 0, 176)
    let drain = NewSceneSupport.smooth(f, 180, 260)
    let hero = NewSceneSupport.smooth(f, 270, 359)
    for i in lenses.indices {
      let a = Float(i) / Float(lenses.count) * 2 * Float.pi
      let start = SIMD3<Float>(cos(a) * 3.5, sin(a) * 3.2, -0.2)
      let lens = SIMD3<Float>(0.1 + cos(a) * 0.75, -0.15 + sin(a) * 0.75, 0.15)
      let down = SIMD3<Float>(cos(a) * 1.3, -3.0, sin(a) * 1.3)
      lenses[i].position = NewSceneSupport.mix(NewSceneSupport.mix(start, lens, merge), down, drain)
      lenses[i].scale = SIMD3<Float>(repeating: NewSceneSupport.mix(1, 0.28, drain))
    }
    product.position.z = NewSceneSupport.mix(-0.5, 0.12, drain)
    let cp = SIMD3<Float>(
      NewSceneSupport.mix(-1.2, 0.65, drain) + hero * 0.08, 0.15,
      NewSceneSupport.mix(8.5, 11.8, drain))
    camera.look(at: [0, -0.2, 0], from: cp, relativeTo: root)
  }
}
