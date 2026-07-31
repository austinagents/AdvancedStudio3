import AppKit
import RealityKit

@MainActor final class ChronoSandScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let grains: [ModelEntity]
  private init(_ r: Entity, _ c: PerspectiveCamera, _ g: [ModelEntity]) {
    root = r
    camera = c
    grains = g
  }
  static func load(imageURL: URL) async throws -> ChronoSandScene {
    let r = try await NewSceneSupport.entity("ChronoSand")
    let x = try NewSceneSupport.child("GrainRoot", in: r)
    let p = try NewSceneSupport.child("ProductRoot", in: r)
    let c = try NewSceneSupport.child("CameraRig", in: r)
    let l = try NewSceneSupport.child("LightRoot", in: r)
    var sand = PhysicallyBasedMaterial()
    sand.baseColor = .init(tint: NSColor(red: 0.48, green: 0.26, blue: 0.08, alpha: 1))
    sand.roughness = 0.78
    var g: [ModelEntity] = []
    for i in 0..<72 {
      let e = ModelEntity(
        mesh: .generateSphere(radius: 0.055 + Float(i % 4) * 0.012), materials: [sand])
      x.addChild(e)
      g.append(e)
    }
    let pr = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.65, name: "ChronoProduct")
    pr.position = [0.45, -0.52, -0.2]
    p.addChild(pr)
    let ib = try await NewSceneSupport.imageLight(id: "goegap", exponent: 0.7, parent: l)
    NewSceneSupport.receiveIBL(g + [pr], light: ib)
    let cam = NewSceneSupport.camera(focalLength: 82, name: "ChronoCamera")
    c.addChild(cam)
    let s = ChronoSandScene(r, cam, g)
    s.apply(frameIndex: 359)
    return s
  }
  func apply(frameIndex: Int) {
    let f = min(max(frameIndex, 0), 359)
    let reverse = NewSceneSupport.smooth(f, 0, 176)
    let fall = NewSceneSupport.smooth(f, 180, 258)
    let h = NewSceneSupport.smooth(f, 270, 359)
    for i in grains.indices {
      let a = Float(i) * 2.399963
      let start = SIMD3<Float>(cos(a) * Float(i % 9) * 0.18, -3 + Float(i % 5) * 0.06, sin(a) * 0.3)
      let hour = SIMD3<Float>(
        cos(a) * (1.9 - abs(Float(i % 18) - 9) * 0.12), -2.5 + Float(i / 9) * 0.7, sin(a) * 0.15)
      let end = SIMD3<Float>(cos(a) * 2.7, -3.1, sin(a) * 1.2)
      grains[i].position = NewSceneSupport.mix(NewSceneSupport.mix(start, hour, reverse), end, fall)
    }
    camera.look(at: [0, -0.4, 0], from: [0.4 + h * 0.1, 0.2, 11.8], relativeTo: root)
  }
}
