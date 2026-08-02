import AppKit
import RealityKit

@MainActor
final class HaloStageScene {
  let root: Entity
  let camera: PerspectiveCamera

  private let product: ModelEntity
  private let shadow: ModelEntity
  private let platform: ModelEntity
  private let halos: [ModelEntity]
  private let curtains: [ModelEntity]
  private let keyLight: SpotLight
  private let backLight: SpotLight

  private init(
    root: Entity, camera: PerspectiveCamera, product: ModelEntity, shadow: ModelEntity,
    platform: ModelEntity, halos: [ModelEntity], curtains: [ModelEntity], keyLight: SpotLight,
    backLight: SpotLight
  ) {
    self.root = root
    self.camera = camera
    self.product = product
    self.shadow = shadow
    self.platform = platform
    self.halos = halos
    self.curtains = curtains
    self.keyLight = keyLight
    self.backLight = backLight
  }

  static func load(imageURL: URL) async throws -> HaloStageScene {
    let root = Entity()
    root.name = "HaloStageSatinTheater"
    let copyColor = NSColor(red: 0.92, green: 0.89, blue: 0.85, alpha: 1)
    addCampaignHook(
      to: root, title: "ONE SCOOP. EVERY DAY.", kicker: "GOOD STARTS WITHIN.",
      color: copyColor)

    let velvet = stageMaterial(
      NSColor(red: 0.36, green: 0.19, blue: 0.34, alpha: 1), roughness: 0.54)
    let graphite = stageMaterial(
      NSColor(red: 0.105, green: 0.095, blue: 0.115, alpha: 1), roughness: 0.90)
    let champagne = stageMaterial(
      NSColor(red: 0.62, green: 0.43, blue: 0.25, alpha: 1),
      roughness: 0.28, metallic: 0.88)
    let blackMetal = stageMaterial(
      NSColor(red: 0.18, green: 0.14, blue: 0.18, alpha: 1),
      roughness: 0.34, metallic: 0.70)
    Batch2SceneSupport.texturedCyclorama(root: root, floor: graphite, wall: velvet)

    var curtains: [ModelEntity] = []
    for side: Float in [-1, 1] {
      let curtain = ModelEntity(mesh: try curtainMesh(side: side), materials: [velvet])
      curtain.name = side < 0 ? "LeftSatinProscenium" : "RightSatinProscenium"
      curtain.position = [0, 0, -3.42]
      root.addChild(curtain)
      curtains.append(curtain)
    }

    var halos: [ModelEntity] = []
    let primaryHalo = ModelEntity(
      mesh: try Batch2SceneSupport.ringMesh(radius: 1.83, thickness: 0.105, depth: 0.29),
      materials: [champagne])
    primaryHalo.name = "PrimaryLuminousHalo"
    root.addChild(primaryHalo)
    var primaryGlow = UnlitMaterial(
      color: NSColor(red: 1, green: 0.75, blue: 0.43, alpha: 1))
    primaryGlow.blending = .transparent(opacity: .init(floatLiteral: 0.72))
    let glowTrim = ModelEntity(
      mesh: try Batch2SceneSupport.ringMesh(radius: 1.83, thickness: 0.022, depth: 0.032),
      materials: [primaryGlow])
    glowTrim.position.z = 0.17
    primaryHalo.addChild(glowTrim)
    halos.append(primaryHalo)

    let arcSpecs: [(Float, Float, Float)] = [(2.22, -2.78, 0.52), (1.55, 0.18, 3.72)]
    for (index, spec) in arcSpecs.enumerated() {
      let arc = ModelEntity(
        mesh: try haloArcMesh(
          radius: spec.0, startAngle: spec.1, endAngle: spec.2,
          thickness: index == 0 ? 0.030 : 0.024, depth: 0.075),
        materials: [index == 0 ? blackMetal : champagne])
      arc.name = "OffsetHaloArc\(index)"
      root.addChild(arc)
      halos.append(arc)
    }

    let platform = ModelEntity(
      mesh: .generateCylinder(height: 0.28, radius: 1.08), materials: [blackMetal])
    platform.name = "SatinHeroStage"
    platform.position = [0, -2.20, -0.02]
    root.addChild(platform)
    let platformCap = ModelEntity(
      mesh: .generateCylinder(height: 0.038, radius: 0.90), materials: [graphite])
    platformCap.position = [0, 0.16, 0]
    platform.addChild(platformCap)
    let brassReveal = ModelEntity(
      mesh: .generateCylinder(height: 0.018, radius: 1.09), materials: [champagne])
    brassReveal.position = [0, -0.15, 0]
    platform.addChild(brassReveal)

    let product = try await Batch2SceneSupport.product(imageURL, height: 2.62)
    product.position = [0, -0.69, 0.74]
    root.addChild(product)
    let shadow = Batch2SceneSupport.addContactShadow(to: root, width: 2.18)
    shadow.position = [0, -2.025, 0.62]

    let lights = try await Batch2SceneSupport.light(
      root: root, ibl: "clarens_night_01", exponent: 0.98,
      keyColor: NSColor(red: 1, green: 0.80, blue: 0.64, alpha: 1),
      rimColor: NSColor(red: 0.58, green: 0.65, blue: 0.78, alpha: 1),
      keyIntensity: 31_000, rimIntensity: 14_000)
    let backLight = SpotLight()
    backLight.name = "DiffusedSatinGlow"
    backLight.light = .init(
      color: NSColor(red: 0.88, green: 0.48, blue: 0.34, alpha: 1), intensity: 20_000,
      innerAngleInDegrees: 46, outerAngleInDegrees: 96, attenuationRadius: 25)
    backLight.look(at: [0, -0.30, -8.75], from: [0.8, 1.6, 4.8], relativeTo: root)
    root.addChild(backLight)

    let camera = Batch2SceneSupport.camera(root: root, focalLength: 48)
    let scene = HaloStageScene(
      root: root, camera: camera, product: product, shadow: shadow, platform: platform,
      halos: halos, curtains: curtains, keyLight: lights.key, backLight: backLight)
    scene.apply(frameIndex: 0)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 449)
    let aperture = NewSceneSupport.smooth(frame, 0, 98)
    let hero = NewSceneSupport.smooth(frame, 18, 116)
    let settle = NewSceneSupport.smooth(frame, 116, 238)
    let pulse = sin(Float(frame) * 0.016) * 0.012 * settle
    let haloDrift = sin(Float(frame) * 0.009) * 0.020 * settle

    for (index, halo) in halos.enumerated() {
      let local = NewSceneSupport.smooth(frame, index * 12, 78 + index * 14)
      if index == 0 {
        halo.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.82, 1, local) + pulse)
        halo.position = [0, NewSceneSupport.mix(-0.72, -0.43, local), -2.48]
        halo.orientation = simd_quatf(angle: haloDrift, axis: [0, 1, 0])
      } else {
        let side: Float = index == 1 ? -1 : 1
        halo.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.86, 1, local))
        halo.position = [
          NewSceneSupport.mix(side * 1.18, side * 0.26, local),
          NewSceneSupport.mix(index == 1 ? 0.20 : -0.90, index == 1 ? -0.18 : -0.58, local),
          index == 1 ? -2.92 : -2.18,
        ]
        halo.orientation = simd_quatf(
          angle: side * NewSceneSupport.mix(0.68, 0.10, local) + side * haloDrift,
          axis: [0, 1, 0])
      }
    }
    for (index, curtain) in curtains.enumerated() {
      let side: Float = index == 0 ? -1 : 1
      curtain.position.x = side
        * (NewSceneSupport.mix(0, 0.22, aperture)
          + sin(Float(frame) * 0.007) * 0.024 * settle)
    }

    product.isEnabled = true
    product.position = NewSceneSupport.mix([0, -1.14, 0.74], [0, -0.69, 0.74], hero)
    product.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.85, 1, hero))
    product.orientation = simd_quatf(
      angle: NewSceneSupport.mix(-0.11, 0.012, settle), axis: [0, 1, 0])
    platform.position.y = NewSceneSupport.mix(-2.56, -2.20, hero)
    shadow.isEnabled = true
    shadow.position.y = platform.position.y + 0.175
    shadow.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.74, 1, hero))

    camera.look(
      at: [0, -0.34, -0.78],
      from: NewSceneSupport.mix([-0.30, 0.30, 13.02], [0.10, 0.15, 12.46], settle),
      relativeTo: root)
    keyLight.look(
      at: [0, -0.44, 0],
      from: NewSceneSupport.mix([-4.8, 6.1, 7.6], [-4.0, 5.7, 8.0], aperture),
      relativeTo: root)
    backLight.look(
      at: [0, -0.30 + sin(Float(frame) * 0.006) * 0.18, -8.75],
      from: [NewSceneSupport.mix(0.8, -0.6, settle), 1.6, 4.8], relativeTo: root)
  }

  private static func curtainMesh(side: Float) throws -> MeshResource {
    let columns = 28
    let rows = 30
    let innerX: Float = side < 0 ? -1.46 : 1.46
    let outerX: Float = side < 0 ? -5.8 : 5.8
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var textureCoordinates: [SIMD2<Float>] = []
    var indices: [UInt32] = []
    for row in 0...rows {
      let v = Float(row) / Float(rows)
      let y = NewSceneSupport.mix(-3.2, 4.7, v)
      for column in 0...columns {
        let u = Float(column) / Float(columns)
        let x = NewSceneSupport.mix(innerX, outerX, u)
        let fold = sin(u * .pi * 13) * 0.15
          + sin(u * .pi * 4 + v * .pi) * 0.035
        positions.append([x, y, fold])
        normals.append([0, 0, 1])
        textureCoordinates.append([u * 3.5, v * 2.5])
      }
    }
    for row in 0..<rows {
      for column in 0..<columns {
        let a = UInt32(row * (columns + 1) + column)
        let b = a + 1
        let c = a + UInt32(columns + 1)
        let d = c + 1
        indices += [a, b, c, b, d, c]
      }
    }
    var descriptor = MeshDescriptor(name: "SatinTheaterCurtain")
    descriptor.positions = .init(positions)
    descriptor.normals = .init(normals)
    descriptor.textureCoordinates = .init(textureCoordinates)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }

  private static func stageMaterial(
    _ color: NSColor, roughness: Float, metallic: Float = 0
  ) -> PhysicallyBasedMaterial {
    var material = PhysicallyBasedMaterial()
    material.baseColor = .init(tint: color)
    material.roughness = .init(floatLiteral: roughness)
    material.metallic = .init(floatLiteral: metallic)
    return material
  }

  private static func haloArcMesh(
    radius: Float, startAngle: Float, endAngle: Float, thickness: Float, depth: Float
  ) throws -> MeshResource {
    let segments = 64
    var positions: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    for segment in 0...segments {
      let t = Float(segment) / Float(segments)
      let angle = NewSceneSupport.mix(startAngle, endAngle, t)
      let direction = SIMD2<Float>(cos(angle), sin(angle))
      for z: Float in [-depth / 2, depth / 2] {
        positions += [
          [direction.x * (radius - thickness), direction.y * (radius - thickness), z],
          [direction.x * (radius + thickness), direction.y * (radius + thickness), z],
        ]
      }
    }
    for segment in 0..<segments {
      let a = UInt32(segment * 4)
      let b = a + 4
      indices += [a, a + 1, b, a + 1, b + 1, b]
      indices += [a + 2, b + 2, a + 3, a + 3, b + 2, b + 3]
      indices += [a, b, a + 2, a + 2, b, b + 2]
      indices += [a + 1, a + 3, b + 1, a + 3, b + 3, b + 1]
    }
    var descriptor = MeshDescriptor(name: "OffsetDimensionalHaloArc")
    descriptor.positions = .init(positions)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }

  private static func addCampaignHook(
    to root: Entity, title: String, kicker: String, color: NSColor
  ) {
    let titleEntity = NewSceneSupport.text(
      title, fontName: "AvenirNext-DemiBold", size: 0.098, color: color, depth: 0.005)
    titleEntity.position = [-1.12, 1.67, 3.0]
    root.addChild(titleEntity)
    let kickerEntity = NewSceneSupport.text(
      kicker, fontName: "SFMono-Medium", size: 0.064,
      color: color.withAlphaComponent(0.72), depth: 0.003)
    kickerEntity.position = [-1.11, 1.45, 3.0]
    root.addChild(kickerEntity)
  }
}
