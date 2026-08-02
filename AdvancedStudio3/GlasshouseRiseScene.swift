import AppKit
import RealityKit

@MainActor
final class GlasshouseRiseScene {
  let root: Entity
  let camera: PerspectiveCamera

  private let product: ModelEntity
  private let shadow: ModelEntity
  private let glassPanels: [ModelEntity]
  private let canopyLeaves: [Entity]
  private let bronzeSweep: Entity
  private let sunSweep: ModelEntity
  private let key: SpotLight
  private let rim: SpotLight

  private init(
    root: Entity,
    camera: PerspectiveCamera,
    product: ModelEntity,
    shadow: ModelEntity,
    glassPanels: [ModelEntity],
    canopyLeaves: [Entity],
    bronzeSweep: Entity,
    sunSweep: ModelEntity,
    key: SpotLight,
    rim: SpotLight
  ) {
    self.root = root
    self.camera = camera
    self.product = product
    self.shadow = shadow
    self.glassPanels = glassPanels
    self.canopyLeaves = canopyLeaves
    self.bronzeSweep = bronzeSweep
    self.sunSweep = sunSweep
    self.key = key
    self.rim = rim
  }

  static func load(imageURL: URL) async throws -> GlasshouseRiseScene {
    let root = Entity()
    root.name = "GlasshouseRise"

    let plaster = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.88, green: 0.86, blue: 0.76, alpha: 1))
    var bronze = PhysicallyBasedMaterial()
    bronze.baseColor = .init(
      tint: NSColor(red: 0.58, green: 0.39, blue: 0.20, alpha: 1))
    bronze.roughness = .init(floatLiteral: 0.34)
    bronze.metallic = .init(floatLiteral: 0.58)
    bronze.clearcoat = .init(floatLiteral: 0.20)

    var ivoryMaterial = UnlitMaterial(
      color: NSColor(red: 0.83, green: 0.82, blue: 0.72, alpha: 1))
    ivoryMaterial.faceCulling = .none
    let ivoryField = ModelEntity(
      mesh: .generatePlane(width: 18, height: 14),
      materials: [ivoryMaterial])
    ivoryField.name = "WarmIvoryDaylight"
    ivoryField.position = [0, 1.9, -10.2]
    root.addChild(ivoryField)

    var sageMaterial = UnlitMaterial(
      color: NSColor(red: 0.48, green: 0.57, blue: 0.47, alpha: 1))
    sageMaterial.faceCulling = .none
    let sageField = ModelEntity(
      mesh: .generatePlane(width: 18, height: 5.2),
      materials: [sageMaterial])
    sageField.name = "SageGardenField"
    sageField.position = [0, -1.70, -10.1]
    root.addChild(sageField)

    let floor = ModelEntity(
      mesh: .generateBox(width: 15, height: 0.20, depth: 18, cornerRadius: 0.10),
      materials: [plaster])
    floor.name = "ContinuousConservatoryFloor"
    floor.position = [0, -2.92, -2.0]
    root.addChild(floor)

    var glass = PhysicallyBasedMaterial()
    glass.baseColor = .init(
      tint: NSColor(red: 0.72, green: 0.92, blue: 0.80, alpha: 0.10))
    glass.roughness = .init(floatLiteral: 0.08)
    glass.metallic = .init(floatLiteral: 0.02)
    glass.clearcoat = .init(floatLiteral: 0.90)
    glass.blending = .transparent(opacity: .init(floatLiteral: 0.10))
    glass.faceCulling = .none

    let rearGlass = ModelEntity(
      mesh: .generatePlane(width: 7.2, height: 5.6, cornerRadius: 0.16),
      materials: [glass])
    rearGlass.name = "ContinuousRearGlazing"
    rearGlass.position = [0, -0.25, -8.35]
    root.addChild(rearGlass)

    var glassPanels: [ModelEntity] = []
    for side: Float in [-1, 1] {
      let panel = ModelEntity(
        mesh: .generateBox(width: 3.35, height: 0.055, depth: 8.6, cornerRadius: 0.035),
        materials: [glass])
      panel.name = "OpeningGlassRoof\(side < 0 ? "Left" : "Right")"
      panel.position = [side * 1.58, 1.06, -4.35]
      panel.orientation = simd_quatf(angle: -side * 0.28, axis: [0, 0, 1])
      root.addChild(panel)
      glassPanels.append(panel)
    }

    // One continuous bronze vault is the entire structural language.
    let bronzeSweep = Entity()
    bronzeSweep.name = "SingleBronzeVault"
    bronzeSweep.position = [0, -2.76, -3.05]
    let vault = ModelEntity(
      mesh: try vaultBandMesh(
        halfWidth: 2.78,
        height: 4.18,
        thickness: 0.13,
        depth: 0.20),
      materials: [bronze])
    bronzeSweep.addChild(vault)
    root.addChild(bronzeSweep)

    var nearFoliage = PhysicallyBasedMaterial()
    nearFoliage.baseColor = .init(
      tint: NSColor(red: 0.12, green: 0.31, blue: 0.16, alpha: 1))
    nearFoliage.roughness = .init(floatLiteral: 0.82)
    nearFoliage.faceCulling = .none
    var middleFoliage = PhysicallyBasedMaterial()
    middleFoliage.baseColor = .init(
      tint: NSColor(red: 0.20, green: 0.43, blue: 0.23, alpha: 1))
    middleFoliage.roughness = .init(floatLiteral: 0.78)
    middleFoliage.faceCulling = .none
    var farFoliage = PhysicallyBasedMaterial()
    farFoliage.baseColor = .init(
      tint: NSColor(red: 0.35, green: 0.54, blue: 0.33, alpha: 1))
    farFoliage.roughness = .init(floatLiteral: 0.76)
    farFoliage.faceCulling = .none
    let foliageMaterials = [nearFoliage, middleFoliage, farFoliage]

    let leafMeshes = try [
      leafMesh(length: 1.48, width: 0.34, curl: 0.08),
      leafMesh(length: 1.30, width: 0.30, curl: 0.12),
      leafMesh(length: 1.62, width: 0.38, curl: 0.06),
    ]
    var canopyLeaves: [Entity] = []
    for side: Float in [-1, 1] {
      for layer in 0..<3 {
        let leafRoot = Entity()
        leafRoot.name = "SculpturalLeaf\(side < 0 ? "L" : "R")\(layer)"
        leafRoot.position = [
          side * (2.05 + Float(layer) * 0.12),
          -2.48 + Float(layer) * 0.92,
          -1.20 - Float(layer) * 1.92,
        ]
        let leaf = ModelEntity(
          mesh: leafMeshes[layer],
          materials: [foliageMaterials[layer]])
        leaf.orientation =
          simd_quatf(angle: -side * (0.50 - Float(layer) * 0.11), axis: [0, 0, 1])
          * simd_quatf(angle: side * (0.12 + Float(layer) * 0.06), axis: [0, 1, 0])
        leafRoot.addChild(leaf)
        root.addChild(leafRoot)
        canopyLeaves.append(leafRoot)
      }
    }

    var sunMaterial = UnlitMaterial(
      color: NSColor(red: 1.0, green: 0.93, blue: 0.70, alpha: 0.10))
    sunMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.10))
    sunMaterial.faceCulling = .none
    let sunSweep = ModelEntity(
      mesh: .generatePlane(width: 1.55, height: 5.8, cornerRadius: 0.70),
      materials: [sunMaterial])
    sunSweep.name = "TravelingConservatoryLight"
    sunSweep.position = [-2.2, -0.30, -7.55]
    sunSweep.orientation = simd_quatf(angle: -0.12, axis: [0, 1, 0])
    root.addChild(sunSweep)

    let product = try await Batch2SceneSupport.product(imageURL, height: 2.62)
    product.name = "GlasshouseHeroProduct"
    product.position = [0, -1.41, 0.74]
    root.addChild(product)
    let shadow = Batch2SceneSupport.addContactShadow(to: root, width: 2.18)
    shadow.position = [0, -2.77, 0.42]

    addCopy(to: root)

    let lighting = try await Batch2SceneSupport.light(
      root: root,
      ibl: "courtyard",
      exponent: 0.72,
      keyColor: NSColor(red: 1.0, green: 0.97, blue: 0.84, alpha: 1),
      rimColor: NSColor(red: 0.72, green: 0.96, blue: 0.69, alpha: 1),
      keyIntensity: 26_000,
      rimIntensity: 14_000)
    let camera = Batch2SceneSupport.camera(root: root, focalLength: 46)
    let scene = GlasshouseRiseScene(
      root: root,
      camera: camera,
      product: product,
      shadow: shadow,
      glassPanels: glassPanels,
      canopyLeaves: canopyLeaves,
      bronzeSweep: bronzeSweep,
      sunSweep: sunSweep,
      key: lighting.key,
      rim: lighting.rim)
    scene.apply(frameIndex: 0)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 449)
    let settle = NewSceneSupport.smooth(frame, 0, 84)
    let open = NewSceneSupport.smooth(frame, 38, 260)
    let travel = NewSceneSupport.smooth(frame, 0, 449)
    let grow = NewSceneSupport.smooth(frame, 70, 320)

    product.isEnabled = true
    product.position = NewSceneSupport.mix(
      [0, -1.48, 0.52], [0, -1.41, 0.74], settle)
    let productScale = NewSceneSupport.mix(0.97, 1.0, settle)
    product.scale = [productScale, productScale, productScale]
    product.orientation = simd_quatf(
      angle: NewSceneSupport.mix(0.018, 0, settle), axis: [0, 1, 0])

    shadow.isEnabled = true
    shadow.position = [0, -2.77, 0.42]
    let shadowScale = NewSceneSupport.mix(0.90, 1.0, settle)
    shadow.scale = [shadowScale, 1, shadowScale]
    shadow.components.set(
      OpacityComponent(opacity: NewSceneSupport.mix(0.14, 0.25, settle)))

    for (index, panel) in glassPanels.enumerated() {
      let side: Float = index == 0 ? -1 : 1
      panel.orientation = simd_quatf(
        angle: -side * NewSceneSupport.mix(0.24, 0.39, open), axis: [0, 0, 1])
      panel.position.y = NewSceneSupport.mix(1.01, 1.14, open)
    }

    bronzeSweep.scale = [1, NewSceneSupport.mix(0.96, 1.0, settle), 1]
    bronzeSweep.position.y = NewSceneSupport.mix(-2.86, -2.76, settle)

    for (index, leaf) in canopyLeaves.enumerated() {
      let side: Float = index < 3 ? -1 : 1
      let layer = index % 3
      let local = NewSceneSupport.smooth(frame, 54 + layer * 26, 188 + layer * 26)
      leaf.orientation =
        simd_quatf(
          angle: side * NewSceneSupport.mix(0.10, -0.06, local), axis: [0, 0, 1])
        * simd_quatf(
          angle: side * sin(Float(frame) * 0.011 + Float(index)) * 0.035 * grow,
          axis: [0, 1, 0])
      let scale = NewSceneSupport.mix(0.90, 1.0, local)
      leaf.scale = [scale, scale, scale]
    }

    sunSweep.position.x = NewSceneSupport.mix(-2.30, 2.20, travel)
    sunSweep.components.set(
      OpacityComponent(opacity: 0.07 + sin(Float(frame) * 0.008) * 0.025))
    key.light.intensity = 23_000 + open * 5_000
    rim.light.intensity = 11_000 + grow * 6_000

    camera.look(
      at: NewSceneSupport.mix([0, -0.68, -0.34], [0, -0.61, 0.10], settle),
      from: [
        NewSceneSupport.mix(0.30, -0.25, travel),
        NewSceneSupport.mix(0.22, 0.10, settle),
        NewSceneSupport.mix(12.62, 12.04, settle),
      ],
      relativeTo: root)
  }

  private static func addCopy(to root: Entity) {
    let title = NewSceneSupport.text(
      "PLANT POWER. MADE SIMPLE.",
      fontName: "HelveticaNeue-Medium",
      size: 0.128,
      color: NSColor(red: 0.08, green: 0.16, blue: 0.10, alpha: 1),
      depth: 0.004)
    title.name = "GlasshouseCampaignHook"
    title.position = [-1.14, 1.54, 2.62]
    root.addChild(title)
    let kicker = NewSceneSupport.text(
      "PREBIOTIC FIBER, SIMPLIFIED",
      fontName: "SFMono-Medium",
      size: 0.056,
      color: NSColor(red: 0.12, green: 0.28, blue: 0.17, alpha: 0.84),
      depth: 0.003)
    kicker.position = [-1.13, 1.30, 2.62]
    root.addChild(kicker)
  }

  private static func vaultBandMesh(
    halfWidth: Float,
    height: Float,
    thickness: Float,
    depth: Float
  ) throws -> MeshResource {
    let segments = 64
    var positions: [SIMD3<Float>] = []
    var textureCoordinates: [SIMD2<Float>] = []
    var indices: [UInt32] = []
    for segment in 0...segments {
      let t = Float(segment) / Float(segments)
      let angle = t * .pi
      let direction = SIMD2<Float>(cos(angle), sin(angle))
      let center = SIMD2<Float>(halfWidth * cos(angle), height * sin(angle))
      let inner = center - direction * thickness
      let outer = center + direction * thickness
      positions += [
        [inner.x, inner.y, -depth / 2],
        [inner.x, inner.y, depth / 2],
        [outer.x, outer.y, -depth / 2],
        [outer.x, outer.y, depth / 2],
      ]
      textureCoordinates += [[t * 4, 0], [t * 4, 0.3], [t * 4, 0.7], [t * 4, 1]]
    }
    for segment in 0..<segments {
      let a = UInt32(segment * 4)
      let b = a + 4
      indices += [
        a, b, a + 2, b, b + 2, a + 2,
        a + 1, a + 3, b + 1, b + 1, a + 3, b + 3,
        a, a + 1, b, b, a + 1, b + 1,
        a + 2, b + 2, a + 3, b + 2, b + 3, a + 3,
      ]
    }
    var descriptor = MeshDescriptor(name: "GlasshouseBronzeVault")
    descriptor.positions = .init(positions)
    descriptor.textureCoordinates = .init(textureCoordinates)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }

  private static func leafMesh(
    length: Float,
    width: Float,
    curl: Float
  ) throws -> MeshResource {
    let segments = 24
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var textureCoordinates: [SIMD2<Float>] = []
    var indices: [UInt32] = []
    for segment in 0...segments {
      let t = Float(segment) / Float(segments)
      let y = t * length
      let halfWidth = sin(t * .pi) * width
      let depth = sin(t * .pi) * curl
      positions += [
        [-halfWidth, y, 0],
        [0, y, depth],
        [halfWidth, y, 0],
      ]
      normals += Array(repeating: SIMD3<Float>(0, 0, 1), count: 3)
      textureCoordinates += [[0, t], [0.5, t], [1, t]]
    }
    for segment in 0..<segments {
      let a = UInt32(segment * 3)
      let b = a + 3
      indices += [
        a, b, a + 1,
        a + 1, b, b + 1,
        a + 1, b + 1, a + 2,
        a + 2, b + 1, b + 2,
      ]
    }
    var descriptor = MeshDescriptor(name: "GlasshouseSculpturalLeaf")
    descriptor.positions = .init(positions)
    descriptor.normals = .init(normals)
    descriptor.textureCoordinates = .init(textureCoordinates)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }
}
