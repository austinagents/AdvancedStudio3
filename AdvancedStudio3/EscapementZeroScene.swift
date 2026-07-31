import AppKit
import RealityKit

@MainActor
final class EscapementZeroScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let gears: [Entity]
  private let gearHomes: [SIMD3<Float>]
  private let escapement: Entity
  private let pallet: ModelEntity
  private let product: ModelEntity
  private let mark: ModelEntity
  private let ruby: PointLight

  private init(
    root: Entity, camera: PerspectiveCamera, gears: [Entity], homes: [SIMD3<Float>],
    escapement: Entity, pallet: ModelEntity, product: ModelEntity, mark: ModelEntity,
    ruby: PointLight
  ) {
    self.root = root
    self.camera = camera
    self.gears = gears
    self.gearHomes = homes
    self.escapement = escapement
    self.pallet = pallet
    self.product = product
    self.mark = mark
    self.ruby = ruby
  }

  static func load(imageURL: URL) async throws -> EscapementZeroScene {
    let root = try await NewSceneSupport.entity("EscapementZero")
    let vault = try NewSceneSupport.child("HorologyVault", in: root)
    let train = try NewSceneSupport.child("GearTrainRoot", in: root)
    let escapement = try NewSceneSupport.child("EscapementRoot", in: root)
    let productRoot = try NewSceneSupport.child("ProductRoot", in: root)
    let markRoot = try NewSceneSupport.child("MarkRoot", in: root)
    let cameraRig = try NewSceneSupport.child("ProbeCameraRig", in: root)
    let lights = try NewSceneSupport.child("JewelLightRig", in: root)
    let vaultMaterial = try await NewSceneSupport.surfaceMaterial(
      id: "dark_rock_02",
      tint: NSColor(red: 0.22, green: 0.24, blue: 0.26, alpha: 1))
    let rhodium = try await NewSceneSupport.surfaceMaterial(
      id: "metal_plate_02",
      tint: NSColor(red: 0.68, green: 0.73, blue: 0.76, alpha: 1), metallic: true)
    let ceramic = try await NewSceneSupport.surfaceMaterial(
      id: "long_white_tiles",
      tint: NSColor(red: 0.025, green: 0.03, blue: 0.035, alpha: 1))
    let jewel = try await NewSceneSupport.surfaceMaterial(
      id: "rust_coarse_01",
      tint: NSColor(red: 0.74, green: 0.01, blue: 0.035, alpha: 1))
    let wall = ModelEntity(
      mesh: .generateBox(width: 17, height: 16, depth: 0.6, cornerRadius: 0.24),
      materials: [vaultMaterial])
    wall.position = [0, 1, -4.7]
    vault.addChild(wall)
    let floor = ModelEntity(
      mesh: .generateBox(width: 17, height: 0.42, depth: 17, cornerRadius: 0.14),
      materials: [vaultMaterial])
    floor.position = [0, -4.2, 1]
    vault.addChild(floor)
    for radius: Float in [2.8, 3.55, 4.3, 5.05] {
      let engraving = ModelEntity(
        mesh: .generateCylinder(height: 0.022, radius: radius), materials: [rhodium])
      let recess = ModelEntity(
        mesh: .generateCylinder(height: 0.028, radius: radius - 0.045), materials: [vaultMaterial])
      engraving.position = [0, -3.98, 0.4]
      recess.position = [0, -3.96, 0.4]
      vault.addChild(engraving)
      vault.addChild(recess)
    }
    let specs: [(SIMD3<Float>, Float, Int)] = [
      ([-2.35, 1.35, 0.1], 2.05, 26), ([1.35, 1.8, 0.35], 1.55, 22),
      ([-1.05, -1.65, 0.5], 1.8, 24), ([2.25, -1.15, 0.25], 1.45, 20),
      ([0.25, 0.05, 0.75], 0.9, 18),
    ]
    var gears: [Entity] = []
    var homes: [SIMD3<Float>] = []
    for (index, spec) in specs.enumerated() {
      let gear = try gearEntity(
        radius: spec.1, teeth: spec.2, metal: index.isMultiple(of: 2) ? rhodium : ceramic,
        jewel: jewel)
      gear.position = spec.0
      train.addChild(gear)
      gears.append(gear)
      homes.append(spec.0)
    }
    let pallet = ModelEntity(
      mesh: .generateBox(width: 2.1, height: 0.34, depth: 0.3, cornerRadius: 0.12),
      materials: [jewel])
    pallet.position = [0.1, 3.15, 0.95]
    escapement.addChild(pallet)
    let pivot = ModelEntity(
      mesh: .generateCylinder(height: 0.32, radius: 0.24), materials: [rhodium])
    pivot.position = [0.1, 3.15, 0.95]
    pivot.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
    escapement.addChild(pivot)
    for angleIndex in 0..<6 {
      let angle = Float(angleIndex) / 6 * 2 * Float.pi
      let jewelMount = ModelEntity(
        mesh: .generateCylinder(height: 0.12, radius: 0.15), materials: [jewel])
      jewelMount.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
      jewelMount.position = [cos(angle) * 2.55, sin(angle) * 2.15 - 0.2, 0.12]
      train.addChild(jewelMount)
    }
    let product = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.35, name: "EscapementProduct", roughness: 0.14)
    product.position = [0.4, -2.15, 1.05]
    productRoot.addChild(product)
    let dais = ModelEntity(
      mesh: .generateCylinder(height: 0.38, radius: 1.85), materials: [ceramic])
    dais.position = [0.4, -3.68, 0.45]
    productRoot.addChild(dais)
    let mark = NewSceneSupport.text(
      "TIME, RELEASED", fontName: "AvenirNext-Medium", size: 0.17,
      color: NSColor(red: 0.75, green: 0.78, blue: 0.8, alpha: 1))
    mark.position = [-0.85, -3.15, 1.15]
    markRoot.addChild(mark)
    let ibl = try await NewSceneSupport.imageLight(
      id: "blue_grotto", exponent: 1.25, parent: lights)
    NewSceneSupport.receiveIBL([wall, floor, pallet, pivot, product, dais], light: ibl)
    NewSceneSupport.receiveIBL(in: root, light: ibl)
    let ruby = PointLight()
    ruby.light = .init(
      color: NSColor(red: 1, green: 0.015, blue: 0.03, alpha: 1), intensity: 32_000,
      attenuationRadius: 7)
    ruby.position = [0.1, 3.2, 2.2]
    lights.addChild(ruby)
    let pin = SpotLight()
    pin.light = .init(
      color: NSColor(red: 0.62, green: 0.76, blue: 1, alpha: 1), intensity: 68_000,
      innerAngleInDegrees: 12, outerAngleInDegrees: 38, attenuationRadius: 19)
    pin.look(at: [0, -1, 0], from: [-3.5, 6, 5], relativeTo: root)
    lights.addChild(pin)
    let camera = NewSceneSupport.camera(focalLength: 92, name: "EscapementProbeCamera")
    cameraRig.addChild(camera)
    let scene = EscapementZeroScene(
      root: root, camera: camera, gears: gears, homes: homes, escapement: escapement,
      pallet: pallet, product: product, mark: mark, ruby: ruby)
    scene.apply(frameIndex: 359)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 359)
    let run = NewSceneSupport.smooth(frame, 0, 176)
    let release = NewSceneSupport.smooth(frame, 180, 270)
    let hero = NewSceneSupport.smooth(frame, 270, 359)
    pallet.orientation = simd_quatf(
      angle: sin(run * .pi * 14) * 0.18 * (1 - release), axis: [0, 0, 1])
    for index in gears.indices {
      let direction: Float = index.isMultiple(of: 2) ? 1 : -1
      gears[index].orientation = simd_quatf(
        angle: direction * run * .pi * (2.3 + Float(index) * 0.4), axis: [0, 0, 1])
      let home = gearHomes[index]
      let radial = simd_normalize(SIMD3<Float>(home.x + 0.2, home.y + 0.5, 0))
      let local = NewSceneSupport.smooth(frame, 184 + index * 8, 238 + index * 7)
      gears[index].position = home + radial * local * (5.8 + Float(index) * 0.35)
    }
    escapement.position.y = release * 5
    product.isEnabled = frame >= 180
    product.scale = .init(repeating: NewSceneSupport.mix(0.76, 1, release))
    product.position.y = NewSceneSupport.mix(-3.15, -2.15, release)
    mark.isEnabled = false
    mark.components.set(OpacityComponent(opacity: NewSceneSupport.smooth(frame, 294, 332)))
    camera.look(
      at: NewSceneSupport.mix([-1.15, 0.55, 0.4], [0.05, -1.95, 0.45], release),
      from: NewSceneSupport.mix(
        [-2.8 + run * 1.4, 0.4, 3.6], [2.55 + hero * 0.06, 0, 13.4], release), relativeTo: root)
    ruby.position = NewSceneSupport.mix([0.1, 3.2, 2.2], [3.7, 2.4, 3.1], release)
  }

  private static func gearEntity(
    radius: Float, teeth: Int, metal: PhysicallyBasedMaterial, jewel: PhysicallyBasedMaterial
  ) throws -> Entity {
    let gear = Entity()
    let disc = ModelEntity(
      mesh: .generateCylinder(height: 0.18, radius: radius * 0.72), materials: [metal])
    disc.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
    gear.addChild(disc)
    for index in 0..<teeth {
      let angle = Float(index) / Float(teeth) * 2 * Float.pi
      let tooth = ModelEntity(
        mesh: .generateBox(
          width: radius * 0.22, height: radius * 0.12, depth: 0.22, cornerRadius: 0.035),
        materials: [metal])
      tooth.position = [cos(angle) * radius * 0.91, sin(angle) * radius * 0.91, 0]
      tooth.orientation = simd_quatf(angle: angle, axis: [0, 0, 1])
      gear.addChild(tooth)
    }
    for angle: Float in [0, .pi / 2, .pi, .pi * 1.5] {
      let spoke = ModelEntity(
        mesh: .generateBox(
          width: radius * 1.05, height: radius * 0.11, depth: 0.2, cornerRadius: 0.04),
        materials: [metal])
      spoke.orientation = simd_quatf(angle: angle, axis: [0, 0, 1])
      gear.addChild(spoke)
    }
    let bearing = ModelEntity(
      mesh: .generateCylinder(height: 0.3, radius: radius * 0.16), materials: [jewel])
    bearing.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
    gear.addChild(bearing)
    return gear
  }
}
