import AppKit
import RealityKit

@MainActor
final class AxisHouseScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let gimbals: [Entity]
  private let frames: [ModelEntity]
  private let product: ModelEntity
  private let inscription: ModelEntity
  private let amberPractical: PointLight

  private init(
    root: Entity, camera: PerspectiveCamera, gimbals: [Entity], frames: [ModelEntity],
    product: ModelEntity, inscription: ModelEntity, amberPractical: PointLight
  ) {
    self.root = root
    self.camera = camera
    self.gimbals = gimbals
    self.frames = frames
    self.product = product
    self.inscription = inscription
    self.amberPractical = amberPractical
  }

  static func load(imageURL: URL) async throws -> AxisHouseScene {
    let root = try await NewSceneSupport.entity("AxisHouse")
    let gallery = try NewSceneSupport.child("WalnutGallery", in: root)
    let gimbalRoot = try NewSceneSupport.child("GimbalRoot", in: root)
    let sanctum = try NewSceneSupport.child("ProductSanctum", in: root)
    let inscriptionRoot = try NewSceneSupport.child("InscriptionRoot", in: root)
    let cameraRig = try NewSceneSupport.child("SpiralCameraRig", in: root)
    let lights = try NewSceneSupport.child("PracticalLightRig", in: root)

    let plaster = try await NewSceneSupport.surfaceMaterial(
      id: "decrepit_wallpaper",
      tint: NSColor(red: 0.34, green: 0.28, blue: 0.22, alpha: 1))
    let walnut = try await NewSceneSupport.surfaceMaterial(
      id: "dark_wood",
      tint: NSColor(red: 0.19, green: 0.065, blue: 0.025, alpha: 1))
    let pearl = try await NewSceneSupport.surfaceMaterial(
      id: "metal_plate_02",
      tint: NSColor(red: 0.9, green: 0.79, blue: 0.58, alpha: 1), metallic: true)
    let wall = ModelEntity(
      mesh: .generateBox(width: 17, height: 16, depth: 0.6, cornerRadius: 0.22),
      materials: [plaster])
    wall.position = [0, 1, -4.6]
    gallery.addChild(wall)
    let floor = ModelEntity(
      mesh: .generateBox(width: 17, height: 0.42, depth: 17, cornerRadius: 0.14),
      materials: [walnut])
    floor.position = [0, -4.15, 1.2]
    gallery.addChild(floor)
    var shadowGap = PhysicallyBasedMaterial()
    shadowGap.baseColor = .init(tint: NSColor(white: 0.018, alpha: 1))
    shadowGap.roughness = 0.7
    for column in -2...2 {
      for row in 0..<3 {
        let panel = ModelEntity(
          mesh: .generateBox(width: 2.56, height: 2.5, depth: 0.08, cornerRadius: 0.025),
          materials: [plaster])
        panel.position = [Float(column) * 2.72, -1.85 + Float(row) * 2.67, -4.25]
        gallery.addChild(panel)
      }
    }
    let floorReveal = ModelEntity(
      mesh: .generateBox(width: 15.8, height: 0.035, depth: 0.18, cornerRadius: 0.012),
      materials: [shadowGap])
    floorReveal.position = [0, -3.92, -3.75]
    gallery.addChild(floorReveal)
    for index in 0..<7 {
      let inlay = ModelEntity(
        mesh: .generateBox(width: 0.035, height: 0.015, depth: 15, cornerRadius: 0.008),
        materials: [pearl])
      inlay.position = [-4.5 + Float(index) * 1.5, -3.92, 1.1]
      gallery.addChild(inlay)
    }

    var gimbals: [Entity] = []
    var frames: [ModelEntity] = []
    for index in 0..<5 {
      let pivot = Entity()
      pivot.name = "IndependentAxis\(index)"
      gimbalRoot.addChild(pivot)
      gimbals.append(pivot)
      let width = 7.1 - Float(index) * 0.95
      let height = 7.8 - Float(index) * 0.9
      let frame = try frameEntity(
        width: width, height: height, thickness: 0.25,
        material: index.isMultiple(of: 2) ? walnut : pearl)
      frame.position = [0, -0.05, Float(index) * 0.22]
      pivot.addChild(frame)
      frames.append(frame)
    }
    let product = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.35, name: "AxisHouseProduct", roughness: 0.18)
    product.position = [0.65, -2.2, 1.1]
    sanctum.addChild(product)
    let rearHalo = ModelEntity(
      mesh: .generateCylinder(height: 0.14, radius: 2.3), materials: [pearl])
    rearHalo.position = [0.65, -0.85, -0.2]
    rearHalo.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
    sanctum.addChild(rearHalo)
    let inscription = NewSceneSupport.text(
      "BUILT AROUND THE ESSENTIAL", fontName: "AvenirNext-Regular", size: 0.16,
      color: NSColor(red: 0.93, green: 0.8, blue: 0.58, alpha: 1))
    inscription.position = [-3.35, -3.25, 1.25]
    inscriptionRoot.addChild(inscription)
    let ibl = try await NewSceneSupport.imageLight(
      id: "ferndale_studio_02", exponent: 0.95, parent: lights)
    NewSceneSupport.receiveIBL([wall, floor, product, rearHalo] + frames, light: ibl)
    NewSceneSupport.receiveIBL(in: root, light: ibl)
    let amber = PointLight()
    amber.light = .init(
      color: NSColor(red: 1, green: 0.48, blue: 0.13, alpha: 1), intensity: 34_000,
      attenuationRadius: 13)
    lights.addChild(amber)
    let moon = SpotLight()
    moon.light = .init(
      color: NSColor(red: 0.44, green: 0.58, blue: 1, alpha: 1), intensity: 24_000,
      innerAngleInDegrees: 24, outerAngleInDegrees: 64, attenuationRadius: 18)
    moon.look(at: [0, -1, 0], from: [-5, 6, 4], relativeTo: root)
    lights.addChild(moon)
    let camera = NewSceneSupport.camera(focalLength: 48, name: "AxisSpiralCamera")
    cameraRig.addChild(camera)
    let scene = AxisHouseScene(
      root: root, camera: camera, gimbals: gimbals, frames: frames, product: product,
      inscription: inscription, amberPractical: amber)
    scene.apply(frameIndex: 359)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 359)
    let lock = NewSceneSupport.smooth(frame, 0, 176)
    let fold = NewSceneSupport.smooth(frame, 180, 270)
    let hero = NewSceneSupport.smooth(frame, 270, 359)
    for index in gimbals.indices {
      let phase = Float(index) * 0.82
      let start = simd_quatf(
        angle: sin(phase + 0.7) * 1.2,
        axis: simd_normalize(SIMD3<Float>(0.25 + Float(index) * 0.1, 0.8, 0.35)))
      gimbals[index].orientation = simd_slerp(start, simd_quatf(), lock)
      let localFold = NewSceneSupport.smooth(frame, 184 + index * 10, 234 + index * 9)
      gimbals[index].orientation *= simd_quatf(angle: localFold * .pi / 2, axis: [1, 0, 0])
      gimbals[index].position = [
        0, -localFold * (3.45 - Float(index) * 0.13), localFold * (0.8 + Float(index) * 0.28),
      ]
      frames[index].scale = [1, NewSceneSupport.mix(1, 0.16, localFold), 1]
    }
    product.isEnabled = frame >= 180
    product.position.y = NewSceneSupport.mix(-3.25, -2.2, fold)
    product.scale = .init(repeating: NewSceneSupport.mix(0.76, 1, fold))
    inscription.isEnabled = false
    inscription.components.set(OpacityComponent(opacity: NewSceneSupport.smooth(frame, 294, 334)))
    let angle = NewSceneSupport.mix(-0.95, 0.2, lock)
    let startCamera = SIMD3<Float>(cos(angle) * 10, 6.3, sin(angle) * 5 + 7)
    camera.look(
      at: NewSceneSupport.mix([0, 0.2, 0], [0.25, -1.95, 0.45], fold),
      from: NewSceneSupport.mix(startCamera, [2.4 + hero * 0.08, -0.2, 12.8], fold),
      relativeTo: root)
    amberPractical.position = NewSceneSupport.mix([-4.8, 1.8, 2.8], [4.2, 3.8, 3.4], lock)
  }

  private static func frameEntity(
    width: Float, height: Float, thickness: Float, material: PhysicallyBasedMaterial
  ) throws -> ModelEntity {
    let parent = ModelEntity()
    let horizontal = MeshResource.generateBox(
      width: width, height: thickness, depth: thickness, cornerRadius: thickness * 0.35)
    let vertical = MeshResource.generateBox(
      width: thickness, height: height, depth: thickness, cornerRadius: thickness * 0.35)
    for y: Float in [-1, 1] {
      let rail = ModelEntity(mesh: horizontal, materials: [material])
      rail.position.y = y * height * 0.5
      parent.addChild(rail)
    }
    for x: Float in [-1, 1] {
      let rail = ModelEntity(mesh: vertical, materials: [material])
      rail.position.x = x * width * 0.5
      parent.addChild(rail)
    }
    return parent
  }
}
