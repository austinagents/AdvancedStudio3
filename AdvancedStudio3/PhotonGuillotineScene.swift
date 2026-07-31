import AppKit
import RealityKit

@MainActor
final class PhotonGuillotineScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let doors: [ModelEntity]
  private let beam: ModelEntity
  private let product: ModelEntity
  private init(
    _ root: Entity, _ camera: PerspectiveCamera, _ doors: [ModelEntity], _ beam: ModelEntity,
    _ product: ModelEntity
  ) {
    self.root = root
    self.camera = camera
    self.doors = doors
    self.beam = beam
    self.product = product
  }
  static func load(imageURL: URL) async throws -> PhotonGuillotineScene {
    let root = try await NewSceneSupport.entity("PhotonGuillotine")
    let world = try NewSceneSupport.child("WorldRoot", in: root)
    let creative = try NewSceneSupport.child("BladeRoot", in: root)
    let productRoot = try NewSceneSupport.child("ProductRoot", in: root)
    let cameraRig = try NewSceneSupport.child("CameraRig", in: root)
    let lights = try NewSceneSupport.child("LightRoot", in: root)
    let plaster = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02", tint: NSColor(white: 0.72, alpha: 1))
    var black = PhysicallyBasedMaterial()
    black.baseColor = .init(tint: NSColor(white: 0.008, alpha: 1))
    black.roughness = 0.2
    black.metallic = 0.65
    let wall = ModelEntity(
      mesh: .generateBox(width: 13, height: 15, depth: 0.35, cornerRadius: 0.1),
      materials: [plaster])
    wall.position = [0, 1, -3.4]
    world.addChild(wall)
    let floor = ModelEntity(
      mesh: .generateBox(width: 13, height: 0.24, depth: 12, cornerRadius: 0.08),
      materials: [plaster])
    floor.position = [0, -3.5, 0.5]
    world.addChild(floor)
    var doors: [ModelEntity] = []
    for side: Float in [-1, 1] {
      let d = ModelEntity(
        mesh: .generateBox(width: 3.15, height: 6.8, depth: 0.32, cornerRadius: 0.04),
        materials: [black])
      d.position = [side * 1.58, -0.1, 0]
      creative.addChild(d)
      doors.append(d)
    }
    let beam = ModelEntity(
      mesh: .generateBox(width: 0.035, height: 7.2, depth: 0.035, cornerRadius: 0.015),
      materials: [UnlitMaterial(color: NSColor(red: 1, green: 0.45, blue: 0.12, alpha: 1))])
    beam.position = [0, -0.1, 0.2]
    creative.addChild(beam)
    let product = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.75, name: "PhotonProduct", roughness: 0.2)
    product.position = [0.62, -0.55, -0.28]
    productRoot.addChild(product)
    let ibl = try await NewSceneSupport.imageLight(
      id: "ferndale_studio_02", exponent: 0.75, parent: lights)
    NewSceneSupport.receiveIBL([wall, floor, product] + doors, light: ibl)
    let key = SpotLight()
    key.light = .init(
      color: NSColor(white: 0.95, alpha: 1), intensity: 12000, innerAngleInDegrees: 22,
      outerAngleInDegrees: 52, attenuationRadius: 14)
    key.look(at: [0, -0.4, 0], from: [3.5, 3.5, 5.5], relativeTo: root)
    lights.addChild(key)
    let camera = NewSceneSupport.camera(focalLength: 72, name: "PhotonCamera")
    cameraRig.addChild(camera)
    let scene = PhotonGuillotineScene(root, camera, doors, beam, product)
    scene.apply(frameIndex: 359)
    return scene
  }
  func apply(frameIndex: Int) {
    let f = min(max(frameIndex, 0), 359)
    let scan = NewSceneSupport.smooth(f, 0, 170)
    let open = NewSceneSupport.smooth(f, 180, 258)
    let hero = NewSceneSupport.smooth(f, 270, 359)
    beam.position.x = NewSceneSupport.mix(-2.7, 2.7, scan)
    for i in doors.indices {
      let s: Float = i == 0 ? -1 : 1
      doors[i].position.x = s * NewSceneSupport.mix(1.58, 4.2, open)
      doors[i].orientation = simd_quatf(angle: s * open * 0.12, axis: [0, 1, 0])
    }
    beam.isEnabled = f < 260
    product.position.z = NewSceneSupport.mix(-0.28, 0.12, open)
    let cp = NewSceneSupport.mix([-1.1, 0.2, 8.2], [0.55 + hero * 0.1, 0.15, 12.2], open)
    camera.look(at: [0.15, -0.25, 0], from: cp, relativeTo: root)
    product.orientation = simd_quatf(
      angle: atan2(cp.x - product.position.x, cp.z - product.position.z), axis: [0, 1, 0])
  }
}
