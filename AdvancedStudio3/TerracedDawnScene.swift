import AppKit
import RealityKit

@MainActor
final class TerracedDawnScene {
  let root: Entity
  let camera: PerspectiveCamera

  private let product: ModelEntity
  private let shadow: ModelEntity
  private let platform: ModelEntity
  private let terraces: [ModelEntity]
  private let markers: [ModelEntity]
  private let keyLight: SpotLight
  private let dawnLight: SpotLight

  private init(
    root: Entity, camera: PerspectiveCamera, product: ModelEntity, shadow: ModelEntity,
    platform: ModelEntity, terraces: [ModelEntity], markers: [ModelEntity], keyLight: SpotLight,
    dawnLight: SpotLight
  ) {
    self.root = root
    self.camera = camera
    self.product = product
    self.shadow = shadow
    self.platform = platform
    self.terraces = terraces
    self.markers = markers
    self.keyLight = keyLight
    self.dawnLight = dawnLight
  }

  static func load(imageURL: URL) async throws -> TerracedDawnScene {
    let root = Entity()
    root.name = "TerracedDawnSculptedAmphitheater"
    let copyColor = NSColor(red: 0.92, green: 0.84, blue: 0.74, alpha: 1)
    addCampaignHook(
      to: root, title: "38 SERVINGS. ONE SIMPLE RITUAL.",
      kicker: "FEEL GOOD, DAILY.", color: copyColor)

    let warmStone = matteMaterial(
      NSColor(red: 0.56, green: 0.35, blue: 0.25, alpha: 1), roughness: 0.94)
    let dawnWall = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.94, green: 0.68, blue: 0.54, alpha: 1))
    Batch2SceneSupport.texturedCyclorama(root: root, floor: warmStone, wall: dawnWall)

    let terracotta = matteMaterial(
      NSColor(red: 0.48, green: 0.215, blue: 0.125, alpha: 1), roughness: 0.92)
    let deepClay = matteMaterial(
      NSColor(red: 0.31, green: 0.13, blue: 0.095, alpha: 1), roughness: 0.95)
    let sandstone = matteMaterial(
      NSColor(red: 0.53, green: 0.38, blue: 0.27, alpha: 1), roughness: 0.88)
    let paleClay = matteMaterial(
      NSColor(red: 0.62, green: 0.33, blue: 0.19, alpha: 1), roughness: 0.90)

    var terraces: [ModelEntity] = []
    let terraceMaterials: [PhysicallyBasedMaterial] = [
      sandstone, terracotta, deepClay, paleClay, terracotta, sandstone,
    ]
    for level in 0..<4 {
      let innerRadius = 1.18 + Float(level) * 0.58
      let terrace = ModelEntity(
        mesh: try curvedTerraceMesh(
          innerRadius: innerRadius, outerRadius: innerRadius + 0.44,
          height: 0.28 + Float(level) * 0.025),
        materials: [terraceMaterials[level]])
      terrace.name = "ContinuousCurvedTerrace\(level)"
      terrace.position = [0, -2.78 + Float(level) * 0.31, -0.34]
      root.addChild(terrace)
      terraces.append(terrace)
    }

    var markers: [ModelEntity] = []
    for index in 0..<38 {
      let band = index % 2
      let ordinal = index / 2
      let t = Float(ordinal) / 18
      let angle = NewSceneSupport.mix(-1.18, 1.18, t)
      let radius = 2.46 + Float(band) * 0.58
      let marker = ModelEntity(
        mesh: .generateBox(
          width: 0.064, height: 0.022, depth: 0.14, cornerRadius: 0.010),
        materials: [markerMaterial(glow: 0.12)])
      marker.name = "InsetServingMarker\(index + 1)"
      marker.position = [
        sin(angle) * radius, -2.14 + Float(band) * 0.31,
        -0.34 - cos(angle) * radius,
      ]
      marker.orientation = simd_quatf(angle: -angle, axis: [0, 1, 0])
      root.addChild(marker)
      markers.append(marker)
    }

    let platform = ModelEntity(
      mesh: .generateCylinder(height: 0.28, radius: 1.00), materials: [sandstone])
    platform.name = "CarvedStoneAltar"
    platform.position = [0, -2.18, 0.04]
    root.addChild(platform)
    let cap = ModelEntity(
      mesh: .generateCylinder(height: 0.040, radius: 0.84), materials: [paleClay])
    cap.position = [0, 0.16, 0]
    platform.addChild(cap)

    let product = try await Batch2SceneSupport.product(imageURL, height: 2.62)
    product.position = [0, -0.69, 0.72]
    root.addChild(product)
    let shadow = Batch2SceneSupport.addContactShadow(to: root, width: 2.10)
    shadow.position = [0, -2.005, 0.61]

    let lights = try await Batch2SceneSupport.light(
      root: root, ibl: "goegap", exponent: 0.84,
      keyColor: NSColor(red: 1, green: 0.71, blue: 0.49, alpha: 1),
      rimColor: NSColor(red: 0.49, green: 0.58, blue: 0.74, alpha: 1),
      keyIntensity: 28_000, rimIntensity: 11_000)
    let dawnLight = SpotLight()
    dawnLight.name = "ArchitecturalDawnWash"
    dawnLight.light = .init(
      color: NSColor(red: 1, green: 0.45, blue: 0.26, alpha: 1), intensity: 24_000,
      innerAngleInDegrees: 50, outerAngleInDegrees: 104, attenuationRadius: 28)
    dawnLight.look(at: [0, -0.10, -8.70], from: [-1.4, 1.6, 4.8], relativeTo: root)
    root.addChild(dawnLight)

    let camera = Batch2SceneSupport.camera(root: root, focalLength: 47)
    let scene = TerracedDawnScene(
      root: root, camera: camera, product: product, shadow: shadow, platform: platform,
      terraces: terraces, markers: markers, keyLight: lights.key, dawnLight: dawnLight)
    scene.apply(frameIndex: 0)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 449)
    let landscape = NewSceneSupport.smooth(frame, 0, 112)
    let hero = NewSceneSupport.smooth(frame, 18, 116)
    let settle = NewSceneSupport.smooth(frame, 116, 246)
    let dawn = NewSceneSupport.smooth(frame, 0, 360)
    let lateLightDrift = sin(Float(frame) * 0.009) * 0.14 * settle

    for (index, terrace) in terraces.enumerated() {
      let local = NewSceneSupport.smooth(frame, 3 + index * 12, 78 + index * 13)
      let finalY = -2.78 + Float(index) * 0.31
      terrace.position = [0, NewSceneSupport.mix(finalY - 0.30, finalY, local), -0.34]
      terrace.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.86, 1, local))
      terrace.orientation = simd_quatf(
        angle: sin(Float(frame) * 0.006 + Float(index)) * 0.006 * settle,
        axis: [0, 1, 0])
    }
    let sweep = NewSceneSupport.mix(-4, 42, Float(frame) / 449)
    for (index, marker) in markers.enumerated() {
      let distance = Float(index) - sweep
      let glow = 0.12 + 0.88 * exp(-(distance * distance) / 18)
      marker.model?.materials = [Self.markerMaterial(glow: glow)]
      marker.scale = SIMD3<Float>(repeating: 0.82 + glow * 0.34)
    }

    product.isEnabled = true
    product.position = NewSceneSupport.mix([0, -1.14, 0.72], [0, -0.69, 0.72], hero)
    product.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.86, 1, hero))
    product.orientation = simd_quatf(
      angle: NewSceneSupport.mix(0.10, -0.014, settle), axis: [0, 1, 0])
    platform.position.y = NewSceneSupport.mix(-2.50, -2.18, hero)
    shadow.isEnabled = true
    shadow.position.y = platform.position.y + 0.175
    shadow.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.76, 1, hero))

    camera.look(
      at: [0, -0.34, -0.90],
      from: NewSceneSupport.mix([0.34, 0.46, 12.98], [0.12, 0.18, 12.34], settle),
      relativeTo: root)
    keyLight.look(
      at: [0, -0.48, 0],
      from: NewSceneSupport.mix([4.9, 3.2, 7.0], [4.2, 5.0, 7.5], landscape),
      relativeTo: root)
    dawnLight.look(
      at: [0, NewSceneSupport.mix(-0.70, 0.30, dawn) + lateLightDrift * 0.18, -8.70],
      from: [NewSceneSupport.mix(-1.8, 1.0, dawn) + lateLightDrift, 1.8, 4.8],
      relativeTo: root)
  }

  private static func matteMaterial(
    _ color: NSColor, roughness: Float
  ) -> PhysicallyBasedMaterial {
    var material = PhysicallyBasedMaterial()
    material.baseColor = .init(tint: color)
    material.roughness = .init(floatLiteral: roughness)
    material.metallic = .init(floatLiteral: 0)
    return material
  }

  private static func curvedTerraceMesh(
    innerRadius: Float, outerRadius: Float, height: Float
  ) throws -> MeshResource {
    let segments = 64
    var positions: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    for segment in 0...segments {
      let t = Float(segment) / Float(segments)
      let angle = NewSceneSupport.mix(-1.26, 1.26, t)
      let direction = SIMD2<Float>(sin(angle), -cos(angle))
      positions += [
        [direction.x * outerRadius, 0, direction.y * outerRadius],
        [direction.x * innerRadius, 0, direction.y * innerRadius],
        [direction.x * outerRadius, -height, direction.y * outerRadius],
        [direction.x * innerRadius, -height, direction.y * innerRadius],
      ]
    }
    for segment in 0..<segments {
      let a = UInt32(segment * 4)
      let b = a + 4
      indices += [a, b, a + 1, a + 1, b, b + 1]
      indices += [a, a + 2, b, a + 2, b + 2, b]
      indices += [a + 1, b + 1, a + 3, a + 3, b + 1, b + 3]
    }
    var descriptor = MeshDescriptor(name: "ContinuousCurvedAmphitheaterTier")
    descriptor.positions = .init(positions)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }

  private static func markerMaterial(glow: Float) -> UnlitMaterial {
    let value = min(max(glow, 0), 1)
    return UnlitMaterial(color: NSColor(
      red: CGFloat(0.34 + value * 0.66), green: CGFloat(0.15 + value * 0.47),
      blue: CGFloat(0.07 + value * 0.17), alpha: 1))
  }

  private static func addCampaignHook(
    to root: Entity, title: String, kicker: String, color: NSColor
  ) {
    let titleEntity = NewSceneSupport.text(
      title, fontName: "AvenirNext-DemiBold", size: 0.078, color: color, depth: 0.005)
    titleEntity.position = [-1.16, 1.67, 3.0]
    root.addChild(titleEntity)
    let kickerEntity = NewSceneSupport.text(
      kicker, fontName: "SFMono-Medium", size: 0.064,
      color: color.withAlphaComponent(0.72), depth: 0.003)
    kickerEntity.position = [-1.15, 1.45, 3.0]
    root.addChild(kickerEntity)
  }
}
