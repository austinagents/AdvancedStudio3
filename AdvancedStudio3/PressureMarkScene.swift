import AppKit
import RealityKit

@MainActor
final class PressureMarkScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let press: Entity
  private let impressionRings: [ModelEntity]
  private let product: ModelEntity
  private let inkBed: ModelEntity
  private let label: ModelEntity
  private let cyanKey: SpotLight

  private init(
    root: Entity, camera: PerspectiveCamera, press: Entity, impressionRings: [ModelEntity],
    product: ModelEntity, inkBed: ModelEntity, label: ModelEntity, cyanKey: SpotLight
  ) {
    self.root = root
    self.camera = camera
    self.press = press
    self.impressionRings = impressionRings
    self.product = product
    self.inkBed = inkBed
    self.label = label
    self.cyanKey = cyanKey
  }

  static func load(imageURL: URL) async throws -> PressureMarkScene {
    let root = try await NewSceneSupport.entity("PressureMark")
    let lab = try NewSceneSupport.child("InkLabRoot", in: root)
    let press = try NewSceneSupport.child("DiePressRoot", in: root)
    let impressions = try NewSceneSupport.child("ImpressionRoot", in: root)
    let productRoot = try NewSceneSupport.child("ProductRoot", in: root)
    let labelRoot = try NewSceneSupport.child("LabelRoot", in: root)
    let cameraRig = try NewSceneSupport.child("UnderDieCamera", in: root)
    let lights = try NewSceneSupport.child("IndustrialLightRig", in: root)
    let concrete = try await NewSceneSupport.surfaceMaterial(
      id: "dark_rock_02",
      tint: NSColor(red: 0.16, green: 0.19, blue: 0.2, alpha: 1))
    let steel = try await NewSceneSupport.surfaceMaterial(
      id: "metal_plate_02",
      tint: NSColor(red: 0.25, green: 0.31, blue: 0.33, alpha: 1), metallic: true)
    let ink = try await NewSceneSupport.surfaceMaterial(
      id: "rust_coarse_01",
      tint: NSColor(red: 0.92, green: 1, blue: 0.02, alpha: 1))
    let wall = ModelEntity(
      mesh: .generateBox(width: 17, height: 16, depth: 0.55, cornerRadius: 0.15),
      materials: [concrete])
    wall.position = [0, 1, -4.5]
    lab.addChild(wall)
    let floor = ModelEntity(
      mesh: .generateBox(width: 17, height: 0.4, depth: 17, cornerRadius: 0.1),
      materials: [concrete])
    floor.position = [0, -4.25, 1]
    lab.addChild(floor)
    for index in -3...3 {
      let channel = ModelEntity(
        mesh: .generateBox(width: 0.09, height: 0.025, depth: 14.8, cornerRadius: 0.025),
        materials: [steel])
      channel.position = [Float(index) * 1.72, -4.025, 1]
      lab.addChild(channel)
    }
    let inkBed = ModelEntity(mesh: .generateCylinder(height: 0.12, radius: 4.35), materials: [ink])
    inkBed.position = [0.6, -3.98, 0.4]
    lab.addChild(inkBed)
    let die = ModelEntity(
      mesh: .generateBox(width: 5.9, height: 1.1, depth: 5.1, cornerRadius: 0.55),
      materials: [steel])
    die.position = [0.6, 0, 0.4]
    press.addChild(die)
    for x: Float in [-1, 1] {
      for z: Float in [-1, 1] {
        let bolt = ModelEntity(
          mesh: .generateCylinder(height: 0.12, radius: 0.16), materials: [steel])
        bolt.position = [0.6 + x * 2.45, -3.38, 0.4 + z * 2.0]
        press.addChild(bolt)
      }
    }
    let ram = ModelEntity(mesh: .generateCylinder(height: 7.5, radius: 0.72), materials: [steel])
    ram.position = [0.6, 4.1, 0.4]
    press.addChild(ram)
    for side: Float in [-1, 1] {
      let guide = ModelEntity(mesh: .generateCylinder(height: 9, radius: 0.18), materials: [steel])
      guide.position = [0.6 + side * 3.4, 1, 0.4]
      lab.addChild(guide)
    }
    var rings: [ModelEntity] = []
    for index in 0..<8 {
      let radius = 1.1 + Float(index) * 0.48
      let ring = ModelEntity(
        mesh: try annulusMesh(outerRadius: radius, width: 0.055),
        materials: [index.isMultiple(of: 2) ? steel : ink])
      ring.position = [0.6, -3.88 + Float(index) * 0.006, 0.4]
      ring.scale = [1, 1, 1]
      impressions.addChild(ring)
      rings.append(ring)
    }
    let product = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.35, name: "PressureMarkProduct", roughness: 0.16)
    product.position = [0.6, -2.25, 0.9]
    productRoot.addChild(product)
    let label = NewSceneSupport.text(
      "MAKE AN IMPRESSION", fontName: "HelveticaNeue-Bold", size: 0.19,
      color: NSColor(red: 0.9, green: 1, blue: 0.02, alpha: 1))
    label.position = [-0.9, -3.25, 1.15]
    labelRoot.addChild(label)
    let ibl = try await NewSceneSupport.imageLight(
      id: "blue_grotto", exponent: 1.25, parent: lights)
    NewSceneSupport.receiveIBL([wall, floor, inkBed, die, ram, product] + rings, light: ibl)
    NewSceneSupport.receiveIBL(in: root, light: ibl)
    let cyan = SpotLight()
    cyan.light = .init(
      color: NSColor(red: 0.05, green: 0.82, blue: 1, alpha: 1), intensity: 62_000,
      innerAngleInDegrees: 20, outerAngleInDegrees: 58, attenuationRadius: 20)
    lights.addChild(cyan)
    let acid = PointLight()
    acid.light = .init(
      color: NSColor(red: 0.88, green: 1, blue: 0.06, alpha: 1), intensity: 28_000,
      attenuationRadius: 10)
    acid.position = [4, -1, 3]
    lights.addChild(acid)
    let camera = NewSceneSupport.camera(focalLength: 66, name: "UnderDieTrackingCamera")
    cameraRig.addChild(camera)
    let scene = PressureMarkScene(
      root: root, camera: camera, press: press, impressionRings: rings, product: product,
      inkBed: inkBed, label: label, cyanKey: cyan)
    scene.apply(frameIndex: 359)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 359)
    let strike = NewSceneSupport.smooth(frame, 0, 158)
    let impact = NewSceneSupport.smooth(frame, 154, 190)
    let lift = NewSceneSupport.smooth(frame, 190, 270)
    let hero = NewSceneSupport.smooth(frame, 270, 359)
    let strikeEase = strike * strike * strike
    press.position.y = NewSceneSupport.mix(5.6, -3.28, strikeEase) + lift * 10.5
    inkBed.scale.y = NewSceneSupport.mix(1, 0.42, impact) + lift * 0.35
    for (index, ring) in impressionRings.enumerated() {
      let local = NewSceneSupport.smooth(frame, 158 + index * 5, 194 + index * 6)
      ring.scale = [NewSceneSupport.mix(0.18, 1, local), 1, NewSceneSupport.mix(0.18, 1, local)]
      ring.components.set(OpacityComponent(opacity: NewSceneSupport.mix(0, 1, local)))
    }
    product.isEnabled = frame >= 190
    product.scale = .init(repeating: NewSceneSupport.mix(0.72, 1, lift))
    product.position.y = NewSceneSupport.mix(-3.1, -2.25, lift)
    label.isEnabled = false
    label.components.set(OpacityComponent(opacity: NewSceneSupport.smooth(frame, 292, 330)))
    let macroTarget = SIMD3<Float>(0.6, -3.1, 0.4)
    let heroTarget = SIMD3<Float>(0.2, -1.95, 0.4)
    camera.look(
      at: NewSceneSupport.mix(macroTarget, heroTarget, lift),
      from: NewSceneSupport.mix([-4.6, -2.8, 3.2], [2.8 + hero * 0.1, -0.15, 12.7], lift),
      relativeTo: root)
    cyanKey.look(
      at: [0.6, -2, 0.4], from: NewSceneSupport.mix([-5, 1, 4], [3.5, 6, 5], lift), relativeTo: root
    )
  }

  private static func annulusMesh(outerRadius: Float, width: Float) throws -> MeshResource {
    let segments = 72
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    for segment in 0...segments {
      let angle = Float(segment) / Float(segments) * 2 * Float.pi
      for radius in [outerRadius - width, outerRadius] {
        positions.append([cos(angle) * radius, 0, sin(angle) * radius])
        normals.append([0, 1, 0])
      }
    }
    for segment in 0..<segments {
      let a = UInt32(segment * 2)
      let b = a + 1
      let c = a + 2
      let d = a + 3
      indices += [a, c, b, b, c, d]
    }
    var descriptor = MeshDescriptor(name: "InkImpression")
    descriptor.positions = .init(positions)
    descriptor.normals = .init(normals)
    descriptor.primitives = .triangles(indices)
    return try MeshResource.generate(from: [descriptor])
  }
}
