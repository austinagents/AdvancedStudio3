import AppKit
import RealityKit

@MainActor
final class ChromaticElevatorScene {
  let root: Entity
  let camera: PerspectiveCamera

  private let product: ModelEntity
  private let shadow: ModelEntity
  private let platform: ModelEntity
  private let prismFins: [ModelEntity]
  private let lightColumns: [ModelEntity]
  private let portal: Entity
  private let keyLight: SpotLight

  private init(
    root: Entity, camera: PerspectiveCamera, product: ModelEntity, shadow: ModelEntity,
    platform: ModelEntity, prismFins: [ModelEntity], lightColumns: [ModelEntity],
    portal: Entity, keyLight: SpotLight
  ) {
    self.root = root
    self.camera = camera
    self.product = product
    self.shadow = shadow
    self.platform = platform
    self.prismFins = prismFins
    self.lightColumns = lightColumns
    self.portal = portal
    self.keyLight = keyLight
  }

  static func load(imageURL: URL) async throws -> ChromaticElevatorScene {
    let root = Entity()
    root.name = "ChromaticElevatorPrismaticAtrium"
    let ink = NSColor(red: 0.12, green: 0.115, blue: 0.13, alpha: 1)
    addCampaignHook(
      to: root, title: "A BRIGHTER ROUTINE.", kicker: "CLEAR. TASTE-FREE.", color: ink)

    let warmWhite = atriumMaterial(
      NSColor(red: 0.91, green: 0.91, blue: 0.88, alpha: 1), roughness: 0.88)
    let floorStone = atriumMaterial(
      NSColor(red: 0.64, green: 0.65, blue: 0.63, alpha: 1), roughness: 0.76)
    let champagne = atriumMaterial(
      NSColor(red: 0.74, green: 0.68, blue: 0.57, alpha: 1),
      roughness: 0.28, metallic: 0.82)
    Batch2SceneSupport.texturedCyclorama(root: root, floor: floorStone, wall: warmWhite)

    let portal = Entity()
    portal.name = "PrismaticAtriumArchitecture"
    root.addChild(portal)
    let palette = [
      NSColor(red: 0.93, green: 0.48, blue: 0.39, alpha: 1),
      NSColor(red: 0.31, green: 0.68, blue: 0.88, alpha: 1),
      NSColor(red: 0.73, green: 0.52, blue: 0.84, alpha: 1),
      NSColor(red: 0.93, green: 0.70, blue: 0.34, alpha: 1),
    ]
    var prismFins: [ModelEntity] = []
    for index in 0..<8 {
      let side: Float = index < 4 ? -1 : 1
      let lane = index % 4
      var glass = PhysicallyBasedMaterial()
      glass.baseColor = .init(tint: palette[lane].withAlphaComponent(0.28))
      glass.roughness = 0.08
      glass.metallic = 0.02
      glass.blending = .transparent(opacity: .init(floatLiteral: 0.34))
      let fin = ModelEntity(
        mesh: .generateBox(
          width: 0.44 + Float(lane) * 0.045, height: 4.72,
          depth: 0.18 + Float(lane) * 0.045, cornerRadius: 0.035),
        materials: [glass])
      fin.name = side < 0 ? "LeftGlassFin\(lane)" : "RightGlassFin\(lane)"
      fin.position = [
        side * (1.34 + Float(lane) * 0.43), -0.62,
        -1.92 - Float(lane) * 0.72,
      ]
      root.addChild(fin)
      prismFins.append(fin)
    }

    var lightColumns: [ModelEntity] = []
    let columnX: [Float] = [-1.28, -0.72, 0.16, 0.80, 1.30]
    for (index, x) in columnX.enumerated() {
      var glow = UnlitMaterial(color: palette[index % palette.count])
      glow.blending = .transparent(opacity: .init(floatLiteral: 0.25))
      let column = ModelEntity(
        mesh: .generateBox(
          width: 0.095 + Float(index % 2) * 0.045, height: 5.25,
          depth: 0.028, cornerRadius: 0.012),
        materials: [glow])
      column.name = "PrismaticLightColumn\(index)"
      column.position = [x, -0.58, -5.02 - Float(index % 2) * 0.18]
      column.orientation = simd_quatf(
        angle: (-0.15 + Float(index) * 0.075), axis: [0, 0, 1])
      root.addChild(column)
      lightColumns.append(column)
    }

    let platform = ModelEntity(
      mesh: .generateCylinder(height: 0.20, radius: 1.02), materials: [floorStone])
    platform.name = "FloatingStoneLift"
    platform.position = [0, -2.18, 0]
    root.addChild(platform)
    let brassReveal = ModelEntity(
      mesh: .generateCylinder(height: 0.040, radius: 1.045), materials: [champagne])
    brassReveal.position = [0, -0.10, 0]
    platform.addChild(brassReveal)

    let product = try await Batch2SceneSupport.product(imageURL, height: 2.62)
    product.position = [0, -0.69, 0.72]
    root.addChild(product)
    let shadow = Batch2SceneSupport.addContactShadow(to: root, width: 2.12)
    shadow.position = [0, -2.045, 0.62]

    let lights = try await Batch2SceneSupport.light(
      root: root, ibl: "cloudy_netted_nursery", exponent: 0.90,
      keyColor: NSColor(red: 0.98, green: 0.99, blue: 1, alpha: 1),
      rimColor: NSColor(red: 0.50, green: 0.69, blue: 0.96, alpha: 1),
      keyIntensity: 30_000, rimIntensity: 13_000)
    let camera = Batch2SceneSupport.camera(root: root, focalLength: 47)
    let scene = ChromaticElevatorScene(
      root: root, camera: camera, product: product, shadow: shadow, platform: platform,
      prismFins: prismFins, lightColumns: lightColumns, portal: portal,
      keyLight: lights.key)
    scene.apply(frameIndex: 0)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 449)
    let architecture = NewSceneSupport.smooth(frame, 0, 92)
    let lift = NewSceneSupport.smooth(frame, 16, 116)
    let settle = NewSceneSupport.smooth(frame, 116, 224)
    let atmosphere = NewSceneSupport.smooth(frame, 145, 320)
    let chromaDrift = sin(Float(frame) * 0.012) * 0.034 * atmosphere

    portal.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.84, 1, architecture))
    portal.position.y = NewSceneSupport.mix(-0.28, 0, architecture)
    for (index, fin) in prismFins.enumerated() {
      let side: Float = index < 4 ? -1 : 1
      let lane = index % 4
      let local = NewSceneSupport.smooth(frame, 3 + lane * 9, 76 + lane * 10)
      fin.scale.y = NewSceneSupport.mix(0.16, 1, local)
      fin.position.y = -3.045 + 2.425 * fin.scale.y
      fin.orientation = simd_quatf(
        angle: side * NewSceneSupport.mix(0.72, 0.16 + Float(lane) * 0.025, local)
          + side * chromaDrift * (1 + Float(lane) * 0.10),
        axis: [0, 1, 0])
    }
    let columnBases: [Float] = [-1.28, -0.72, 0.16, 0.80, 1.30]
    for (index, column) in lightColumns.enumerated() {
      let local = NewSceneSupport.smooth(frame, 8 + index * 8, 80 + index * 9)
      column.scale.y = NewSceneSupport.mix(0.04, 1, local)
      column.position.y = -3.05 + 2.45 * column.scale.y
      column.position.x = columnBases[index]
        + sin(Float(frame) * 0.013 + Float(index) * 0.86) * 0.024 * atmosphere
    }

    product.isEnabled = true
    product.position = NewSceneSupport.mix([0, -1.30, 0.72], [0, -0.69, 0.72], lift)
    product.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.90, 1, lift))
    product.orientation = simd_quatf(
      angle: NewSceneSupport.mix(-0.09, 0.014, settle), axis: [0, 1, 0])
    platform.position.y = NewSceneSupport.mix(-3.00, -2.18, lift)
    shadow.isEnabled = true
    shadow.position.y = platform.position.y + 0.135
    shadow.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.78, 1, lift))

    camera.look(
      at: [0, -0.33, -0.84],
      from: NewSceneSupport.mix([-0.26, 0.28, 12.94], [0.10, 0.10, 12.34], settle),
      relativeTo: root)
    keyLight.look(
      at: [0, -0.48, 0],
      from: NewSceneSupport.mix([-4.4, 6.1, 7.8], [-3.8, 5.7, 8.0], atmosphere),
      relativeTo: root)
  }

  private static func atriumMaterial(
    _ color: NSColor, roughness: Float, metallic: Float = 0
  ) -> PhysicallyBasedMaterial {
    var material = PhysicallyBasedMaterial()
    material.baseColor = .init(tint: color)
    material.roughness = .init(floatLiteral: roughness)
    material.metallic = .init(floatLiteral: metallic)
    return material
  }

  private static func addCampaignHook(
    to root: Entity, title: String, kicker: String, color: NSColor
  ) {
    let titleEntity = NewSceneSupport.text(
      title, fontName: "AvenirNext-DemiBold", size: 0.104, color: color, depth: 0.005)
    titleEntity.position = [-1.12, 1.67, 3.0]
    root.addChild(titleEntity)
    let kickerEntity = NewSceneSupport.text(
      kicker, fontName: "SFMono-Medium", size: 0.066,
      color: color.withAlphaComponent(0.70), depth: 0.003)
    kickerEntity.position = [-1.11, 1.45, 3.0]
    root.addChild(kickerEntity)
  }
}
