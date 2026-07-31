import AppKit
import RealityKit

@MainActor final class ThermalAlloyScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let fins: [ModelEntity]
  private init(_ r: Entity, _ c: PerspectiveCamera, _ f: [ModelEntity]) {
    root = r
    camera = c
    fins = f
  }
  static func load(imageURL: URL) async throws -> ThermalAlloyScene {
    let r = try await NewSceneSupport.entity("ThermalAlloy")
    let x = try NewSceneSupport.child("FinRoot", in: r)
    let p = try NewSceneSupport.child("ProductRoot", in: r)
    let c = try NewSceneSupport.child("CameraRig", in: r)
    let l = try NewSceneSupport.child("LightRoot", in: r)
    let metal = try await NewSceneSupport.surfaceMaterial(id: "metal_plate_02", metallic: true)
    var f: [ModelEntity] = []
    for i in 0..<10 {
      let e = ModelEntity(
        mesh: .generateBox(width: 0.58, height: 5.8, depth: 0.18, cornerRadius: 0.05),
        materials: [metal])
      e.position = [-2.61 + Float(i) * 0.58, -0.1, 0]
      x.addChild(e)
      f.append(e)
    }
    let pr = try await NewSceneSupport.product(
      imageURL: imageURL, height: 1.68, name: "ThermalProduct")
    pr.position = [0.5, -0.5, -0.25]
    p.addChild(pr)
    let ib = try await NewSceneSupport.imageLight(
      id: "aircraft_workshop_01", exponent: 0.8, parent: l)
    NewSceneSupport.receiveIBL(f, light: ib)
    let heat = PointLight()
    heat.light = .init(
      color: NSColor(red: 1, green: 0.12, blue: 0.02, alpha: 1), intensity: 16000,
      attenuationRadius: 8)
    heat.position = [0, -2, 2]
    l.addChild(heat)
    let cam = NewSceneSupport.camera(focalLength: 66, name: "ThermalCamera")
    c.addChild(cam)
    let s = ThermalAlloyScene(r, cam, f)
    s.apply(frameIndex: 359)
    return s
  }
  func apply(frameIndex: Int) {
    let f = min(max(frameIndex, 0), 359)
    let heat = NewSceneSupport.smooth(f, 0, 176)
    let curl = NewSceneSupport.smooth(f, 180, 258)
    let h = NewSceneSupport.smooth(f, 270, 359)
    for i in fins.indices {
      let side: Float = i < 5 ? -1 : 1
      let local = NewSceneSupport.smooth(f, 180 + abs(5 - i) * 5, 250)
      fins[i].position.x = (-2.61 + Float(i) * 0.58) + side * local * 3
      fins[i].orientation = simd_quatf(angle: side * (heat * 0.08 + curl * 0.7), axis: [0, 1, 0])
    }
    camera.look(
      at: [0, -0.25, 0],
      from: [
        NewSceneSupport.mix(-0.8, 0.5, curl) + h * 0.08, 0.15, NewSceneSupport.mix(8.5, 12, curl),
      ], relativeTo: root)
  }
}
