import AppKit
import RealityKit

@MainActor
final class RainlightPavilionScene {
  private struct RainDrop {
    let entity: ModelEntity
    let basePosition: SIMD3<Float>
    let speed: Float
    let side: Float
  }

  let root = Entity()
  let camera: PerspectiveCamera

  private let product: ModelEntity
  private let shadow: ModelEntity
  private let rain: [RainDrop]
  private let canopyRibs: [ModelEntity]
  private let lightVeil: [ModelEntity]
  private let practicals: [PointLight]
  private let skyLight: PointLight
  private let key: SpotLight
  private let rim: SpotLight

  private init(
    camera: PerspectiveCamera,
    product: ModelEntity,
    shadow: ModelEntity,
    rain: [RainDrop],
    canopyRibs: [ModelEntity],
    lightVeil: [ModelEntity],
    practicals: [PointLight],
    skyLight: PointLight,
    key: SpotLight,
    rim: SpotLight
  ) {
    self.camera = camera
    self.product = product
    self.shadow = shadow
    self.rain = rain
    self.canopyRibs = canopyRibs
    self.lightVeil = lightVeil
    self.practicals = practicals
    self.skyLight = skyLight
    self.key = key
    self.rim = rim
  }

  static func load(imageURL: URL) async throws -> RainlightPavilionScene {
    let set = Entity()
    set.name = "RainlightPavilionLuminousVeil"
    Batch2SceneSupport.addHook(
      to: set,
      title: "CLEAR. TASTE-FREE.",
      kicker: "Dissolves into your routine.",
      color: NSColor(white: 0.96, alpha: 1),
      x: -1.0
    )

    let floorPlaster = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.18, green: 0.25, blue: 0.25, alpha: 1)
    )
    let wallPlaster = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.08, green: 0.18, blue: 0.19, alpha: 1)
    )
    let palePlaster = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.15, green: 0.22, blue: 0.22, alpha: 1)
    )
    var silver = PhysicallyBasedMaterial()
    silver.baseColor = .init(
      tint: NSColor(red: 0.68, green: 0.73, blue: 0.73, alpha: 1)
    )
    silver.roughness = .init(floatLiteral: 0.30)
    silver.metallic = .init(floatLiteral: 0.45)
    silver.clearcoat = .init(floatLiteral: 0.30)
    var warmMetal = PhysicallyBasedMaterial()
    warmMetal.baseColor = .init(
      tint: NSColor(red: 0.70, green: 0.55, blue: 0.38, alpha: 1)
    )
    warmMetal.roughness = .init(floatLiteral: 0.31)
    warmMetal.metallic = .init(floatLiteral: 0.44)
    warmMetal.clearcoat = .init(floatLiteral: 0.28)

    let floor = ModelEntity(
      mesh: .generateBox(width: 11.5, height: 0.16, depth: 14, cornerRadius: 0.07),
      materials: [floorPlaster]
    )
    floor.name = "MatteRainCourt"
    floor.position = [0, -2.24, -2.8]
    set.addChild(floor)

    let wall = ModelEntity(
      mesh: .generateBox(width: 10.6, height: 7.2, depth: 0.28, cornerRadius: 0.08),
      materials: [wallPlaster]
    )
    wall.name = "BlueGreyPavilionWall"
    wall.position = [0, 0.70, -7.0]
    set.addChild(wall)

    for side: Float in [-1, 1] {
      let returnWall = ModelEntity(
        mesh: .generateBox(width: 2.25, height: 6.20, depth: 0.18, cornerRadius: 0.08),
        materials: [palePlaster]
      )
      returnWall.name = "PavilionReturn"
      returnWall.position = [side * 3.70, 0.34, -4.90]
      returnWall.orientation = simd_quatf(angle: side * 0.16, axis: [0, 1, 0])
      set.addChild(returnWall)
    }

    let recessedBay = ModelEntity(
      mesh: .generateBox(width: 4.45, height: 5.38, depth: 0.16, cornerRadius: 0.22),
      materials: [wallPlaster]
    )
    recessedBay.name = "RainlightRecess"
    recessedBay.position = [0, 0.04, -5.94]
    set.addChild(recessedBay)

    var veilMaterials: [PhysicallyBasedMaterial] = []
    for index in 0..<1 {
      var frost = PhysicallyBasedMaterial()
      frost.baseColor = .init(
        tint: NSColor(
          red: 0.69,
          green: 0.82,
          blue: 0.83,
          alpha: 0.68
        )
      )
      frost.roughness = .init(floatLiteral: 0.23)
      frost.metallic = .init(floatLiteral: 0.02)
      frost.clearcoat = .init(floatLiteral: 0.34)
      frost.emissiveColor = .init(
        color: NSColor(red: 0.012, green: 0.035, blue: 0.038, alpha: 1)
      )
      frost.emissiveIntensity = 0.08
      frost.blending = .transparent(opacity: .init(floatLiteral: 0.68))
      veilMaterials.append(frost)
    }

    // One continuous rippled glass curtain turns weather into a room-sized material surface.
    var lightVeil: [ModelEntity] = []
    for index in 0..<1 {
      let fin = ModelEntity(
        mesh: try rainGlassMesh(
          width: 3.34,
          height: 4.42,
          phase: 0.38
        ),
        materials: [veilMaterials[index]]
      )
      fin.name = "FrostedRainFin\(index)"
      fin.position = [0, 0.02, -5.56]
      fin.orientation = simd_quatf(angle: -0.025, axis: [0, 1, 0])
      set.addChild(fin)
      lightVeil.append(fin)
    }

    // Angled plaster wings make the illuminated veil part of a room-sized bay.
    for side: Float in [-1, 1] {
      let wing = ModelEntity(
        mesh: .generateBox(width: 1.18, height: 5.02, depth: 0.18, cornerRadius: 0.055),
        materials: [palePlaster]
      )
      wing.name = "RainlightWing"
      wing.position = [side * 2.06, 0.03, -5.55]
      wing.orientation = simd_quatf(angle: side * -0.18, axis: [0, 1, 0])
      set.addChild(wing)
    }

    for side: Float in [-1, 1] {
      let upright = ModelEntity(
        mesh: .generateBox(width: 0.12, height: 4.94, depth: 0.30, cornerRadius: 0.042),
        materials: [silver]
      )
      upright.name = "RainlightReveal"
      upright.position = [side * 1.54, 0.02, -5.35]
      set.addChild(upright)
    }

    var canopyRibs: [ModelEntity] = []
    for index in 0..<3 {
      let rib = ModelEntity(
        mesh: .generateBox(width: 1.38, height: 0.11, depth: 6.55, cornerRadius: 0.045),
        materials: [index.isMultiple(of: 2) ? silver : warmMetal]
      )
      rib.name = "CanopyFacet\(index)"
      rib.position = [-1.52 + Float(index) * 1.52, 2.76, -3.10]
      set.addChild(rib)
      canopyRibs.append(rib)
    }

    var integratedLightMaterial = PhysicallyBasedMaterial()
    integratedLightMaterial.baseColor = .init(
      tint: NSColor(red: 0.77, green: 0.91, blue: 0.91, alpha: 1)
    )
    integratedLightMaterial.roughness = .init(floatLiteral: 0.26)
    integratedLightMaterial.emissiveColor = .init(
      color: NSColor(red: 0.025, green: 0.14, blue: 0.15, alpha: 1)
    )
    integratedLightMaterial.emissiveIntensity = 0.54
    for side: Float in [-1, 1] {
      let ceilingLight = ModelEntity(
        mesh: .generateBox(width: 0.035, height: 0.025, depth: 5.72, cornerRadius: 0.012),
        materials: [integratedLightMaterial]
      )
      ceilingLight.name = "IntegratedRainlight"
      ceilingLight.position = [side * 1.34, 2.66, -2.82]
      set.addChild(ceilingLight)

    }

    var practicalMaterial = PhysicallyBasedMaterial()
    practicalMaterial.baseColor = .init(
      tint: NSColor(red: 1.0, green: 0.76, blue: 0.50, alpha: 1)
    )
    practicalMaterial.roughness = .init(floatLiteral: 0.24)
    practicalMaterial.emissiveColor = .init(
      color: NSColor(red: 0.28, green: 0.09, blue: 0.018, alpha: 1)
    )
    practicalMaterial.emissiveIntensity = 0.72

    var practicals: [PointLight] = []
    for bay in 0..<3 {
      for side: Float in [-1, 1] {
        let fixture = ModelEntity(
          mesh: .generateCylinder(height: 0.045, radius: 0.068),
          materials: [practicalMaterial]
        )
        fixture.position = [side * 1.58, 2.68, -1.25 - Float(bay) * 1.55]
        set.addChild(fixture)

        let practical = PointLight()
        practical.name = "PavilionPractical\(practicals.count)"
        practical.light = .init(
          color: NSColor(red: 1.0, green: 0.72, blue: 0.46, alpha: 1),
          intensity: 0,
          attenuationRadius: 4.5
        )
        practical.position = [fixture.position.x, 2.52, fixture.position.z]
        set.addChild(practical)
        practicals.append(practical)
      }
    }

    var rainMaterial = PhysicallyBasedMaterial()
    rainMaterial.baseColor = .init(
      tint: NSColor(red: 0.66, green: 0.86, blue: 0.89, alpha: 0.44)
    )
    rainMaterial.roughness = .init(floatLiteral: 0.12)
    rainMaterial.clearcoat = .init(floatLiteral: 0.72)
    rainMaterial.emissiveColor = .init(
      color: NSColor(red: 0.01, green: 0.055, blue: 0.065, alpha: 1)
    )
    rainMaterial.emissiveIntensity = 0.20
    rainMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.44))

    var rain: [RainDrop] = []
    for index in 0..<52 {
      let side: Float = index.isMultiple(of: 2) ? -1 : 1
      let column = index % 5
      let depth = (index / 5) % 6
      let phase = Float((index * 31) % 61) / 10
      let base = SIMD3<Float>(
        side * (1.92 + Float(column) * 0.27),
        phase,
        0.10 - Float(depth) * 1.02
      )
      let drop = ModelEntity(
        mesh: .generateCylinder(
          height: 0.26 + Float(index % 4) * 0.06,
          radius: 0.008 + Float(index % 3) * 0.0015
        ),
        materials: [rainMaterial]
      )
      drop.name = "ArchitecturalRain\(index)"
      drop.position = base
      drop.orientation = simd_quatf(angle: side * 0.035, axis: [0, 0, 1])
      set.addChild(drop)
      rain.append(
        RainDrop(
          entity: drop,
          basePosition: base,
          speed: 0.074 + Float(index % 6) * 0.006,
          side: side
        )
      )
    }

    var waterMaterial = PhysicallyBasedMaterial()
    waterMaterial.baseColor = .init(
      tint: NSColor(red: 0.42, green: 0.61, blue: 0.63, alpha: 0.72)
    )
    waterMaterial.roughness = .init(floatLiteral: 0.12)
    waterMaterial.metallic = .init(floatLiteral: 0.03)
    waterMaterial.clearcoat = .init(floatLiteral: 0.84)
    waterMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.72))
    let reflectingPool = ModelEntity(
      mesh: .generateCylinder(height: 0.026, radius: 1.90),
      materials: [waterMaterial]
    )
    reflectingPool.name = "RainlightReflectingPool"
    reflectingPool.position = [0, -2.13, 0.18]
    set.addChild(reflectingPool)

    let plinth = ModelEntity(
      mesh: .generateCylinder(height: 0.15, radius: 1.16),
      materials: [palePlaster]
    )
    plinth.name = "DryZonePlinth"
    plinth.position = [0, -2.03, 0.36]
    set.addChild(plinth)

    let product = try await Batch2SceneSupport.product(imageURL, height: 2.62)
    product.position = [0, -0.64, 0.74]
    set.addChild(product)

    let shadow = Batch2SceneSupport.addContactShadow(to: set, width: 2.10)
    shadow.position = [0, -1.94, 0.50]

    let lighting = try await Batch2SceneSupport.light(
      root: set,
      ibl: "cloudy_netted_nursery",
      exponent: 0.72,
      keyColor: NSColor(red: 0.76, green: 0.91, blue: 0.94, alpha: 1),
      rimColor: NSColor(red: 1.0, green: 0.72, blue: 0.48, alpha: 1),
      keyIntensity: 18_000,
      rimIntensity: 10_500
    )

    let skyLight = PointLight()
    skyLight.name = "VeilSkyLight"
    skyLight.light = .init(
      color: NSColor(red: 0.57, green: 0.83, blue: 0.86, alpha: 1),
      intensity: 2_250,
      attenuationRadius: 7.2
    )
    skyLight.position = [0, -0.10, -3.45]
    set.addChild(skyLight)

    let camera = Batch2SceneSupport.camera(root: set, focalLength: 46)
    let scene = RainlightPavilionScene(
      camera: camera,
      product: product,
      shadow: shadow,
      rain: rain,
      canopyRibs: canopyRibs,
      lightVeil: lightVeil,
      practicals: practicals,
      skyLight: skyLight,
      key: lighting.key,
      rim: lighting.rim
    )
    scene.root.addChild(set)
    camera.removeFromParent()
    scene.root.addChild(camera)
    scene.apply(frameIndex: 0)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 449)
    let hero = NewSceneSupport.smooth(frame, 0, 118)
    let shelter = NewSceneSupport.smooth(frame, 16, 190)
    let clear = NewSceneSupport.smooth(frame, 120, 312)
    let settle = NewSceneSupport.smooth(frame, 318, 449)

    for (index, fin) in lightVeil.enumerated() {
      let local = NewSceneSupport.smooth(frame, 10 + index * 11, 112 + index * 14)
      fin.position = [
        0,
        NewSceneSupport.mix(-0.13, 0.02, local),
        -5.56 + sin(Float(frame) * 0.012) * 0.018 * shelter * (1 - settle),
      ]
      fin.scale = [1, NewSceneSupport.mix(0.91, 1.0, local), 1]
      fin.orientation = simd_quatf(
        angle: NewSceneSupport.mix(-0.035, 0.018, local),
        axis: [0, 1, 0]
      )
    }

    for (index, rib) in canopyRibs.enumerated() {
      let side = Float(index - 1)
      let local = NewSceneSupport.smooth(frame, 18 + abs(index - 1) * 11, 122 + abs(index - 1) * 14)
      rib.position = [
        -1.52 + Float(index) * 1.52 + side * local * 0.09,
        2.76,
        -3.10,
      ]
      rib.orientation = simd_quatf(angle: side * local * 0.10, axis: [0, 1, 0])
    }

    for drop in rain {
      let travel = fmod(drop.basePosition.y + Float(frame) * drop.speed, 6.25)
      drop.entity.position = [
        drop.basePosition.x + drop.side * clear * 0.30,
        3.56 - travel,
        drop.basePosition.z,
      ]
      drop.entity.scale = [
        1,
        0.86 + 0.14 * sin(Float(frame) * 0.045 + drop.basePosition.y),
        1,
      ]
      drop.entity.isEnabled = true
    }

    for (index, practical) in practicals.enumerated() {
      let local = NewSceneSupport.smooth(frame, 35 + index * 14, 128 + index * 15)
      practical.light.intensity = local * (1_500 + shelter * 1_250 + settle * 450)
    }

    product.isEnabled = true
    product.position = NewSceneSupport.mix(
      SIMD3<Float>(0, -0.67, 0.72),
      SIMD3<Float>(0, -0.64, 0.76),
      hero
    )
    product.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.92, 1.0, hero))
    product.orientation = simd_quatf(
      angle: NewSceneSupport.mix(-0.055, 0, hero),
      axis: [0, 1, 0]
    )

    shadow.isEnabled = true
    shadow.position = [0, -1.94, 0.50]
    shadow.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.86, 1.0, hero))

    skyLight.light.intensity = 2_100 + shelter * 1_050 + clear * 500
    skyLight.position = [
      NewSceneSupport.mix(-1.25, 1.25, clear) * (1 - settle),
      -0.10,
      -3.45,
    ]
    key.light.intensity = 14_000 + hero * 3_500 + clear * 1_000
    rim.light.intensity = 7_800 + shelter * 1_700 + settle * 800

    let cameraProgress = NewSceneSupport.smooth(frame, 0, 400)
    camera.look(
      at: [0, -0.15, -0.55],
      from: NewSceneSupport.mix(
        SIMD3<Float>(-0.26, 0.20, 13.60),
        SIMD3<Float>(0.12, 0.06, 13.08),
        cameraProgress
      ),
      relativeTo: root
    )
  }

  private static func rainGlassMesh(
    width: Float,
    height: Float,
    phase: Float
  ) throws -> MeshResource {
    let columns = 18
    let rows = 28
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var indices: [UInt32] = []

    for row in 0...rows {
      let v = Float(row) / Float(rows)
      for column in 0...columns {
        let u = Float(column) / Float(columns)
        let x = (u - 0.5) * width
        let y = (v - 0.5) * height
        let wave = u * .pi * 1.35 + phase
        let verticalWave = v * .pi * 2.0 + phase * 0.45
        let z = sin(wave) * 0.16 + sin(verticalWave) * 0.026
        let dzdu = cos(wave) * .pi * 1.35 * 0.16
        let dzdv = cos(verticalWave) * .pi * 2.0 * 0.026
        let tangentU = SIMD3<Float>(width, 0, dzdu)
        let tangentV = SIMD3<Float>(0, height, dzdv)
        positions.append([x, y, z])
        normals.append(simd_normalize(simd_cross(tangentU, tangentV)))
      }
    }

    let stride = columns + 1
    for row in 0..<rows {
      for column in 0..<columns {
        let a = UInt32(row * stride + column)
        let b = a + 1
        let c = a + UInt32(stride)
        let d = c + 1
        indices += [a, b, c, b, d, c]
      }
    }

    var descriptor = MeshDescriptor(name: "RainlightRippledGlass")
    descriptor.positions = .init(positions)
    descriptor.normals = .init(normals)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }
}
