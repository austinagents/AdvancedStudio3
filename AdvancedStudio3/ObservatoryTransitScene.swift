import AppKit
import RealityKit

@MainActor
final class ObservatoryTransitScene {
  let root = Entity()
  let camera: PerspectiveCamera

  private let product: ModelEntity
  private let shadow: ModelEntity
  private let moon: ModelEntity
  private let meridians: [ModelEntity]
  private let stars: [ModelEntity]
  private let transitMarkers: [ModelEntity]
  private let moonLight: PointLight
  private let key: SpotLight
  private let rim: SpotLight

  private init(
    camera: PerspectiveCamera,
    product: ModelEntity,
    shadow: ModelEntity,
    moon: ModelEntity,
    meridians: [ModelEntity],
    stars: [ModelEntity],
    transitMarkers: [ModelEntity],
    moonLight: PointLight,
    key: SpotLight,
    rim: SpotLight
  ) {
    self.camera = camera
    self.product = product
    self.shadow = shadow
    self.moon = moon
    self.meridians = meridians
    self.stars = stars
    self.transitMarkers = transitMarkers
    self.moonLight = moonLight
    self.key = key
    self.rim = rim
  }

  static func load(imageURL: URL) async throws -> ObservatoryTransitScene {
    let set = Entity()
    set.name = "BenefiberMicrobiomeConstellation"
    Batch2SceneSupport.addHook(
      to: set,
      title: "NOURISH THE GOOD.",
      kicker: "Prebiotic fiber for good bacteria.",
      color: NSColor(red: 0.95, green: 0.96, blue: 1.0, alpha: 1),
      x: -1.0
    )

    let floorPlaster = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1)
    )
    let wallPlaster = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.045, green: 0.07, blue: 0.17, alpha: 1)
    )
    let returnPlaster = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.08, green: 0.09, blue: 0.16, alpha: 1)
    )
    let moonPlaster = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.78, green: 0.75, blue: 0.68, alpha: 1)
    )
    var silver = PhysicallyBasedMaterial()
    silver.baseColor = .init(
      tint: NSColor(red: 0.51, green: 0.58, blue: 0.68, alpha: 1)
    )
    silver.roughness = .init(floatLiteral: 0.28)
    silver.metallic = .init(floatLiteral: 0.64)
    silver.clearcoat = .init(floatLiteral: 0.32)
    var brass = PhysicallyBasedMaterial()
    brass.baseColor = .init(
      tint: NSColor(red: 0.67, green: 0.48, blue: 0.27, alpha: 1)
    )
    brass.roughness = .init(floatLiteral: 0.30)
    brass.metallic = .init(floatLiteral: 0.62)
    brass.clearcoat = .init(floatLiteral: 0.30)
    var portalStone = PhysicallyBasedMaterial()
    portalStone.baseColor = .init(
      tint: NSColor(red: 0.63, green: 0.69, blue: 0.73, alpha: 1)
    )
    portalStone.roughness = .init(floatLiteral: 0.44)
    portalStone.metallic = .init(floatLiteral: 0.03)
    portalStone.clearcoat = .init(floatLiteral: 0.10)

    let floor = ModelEntity(
      mesh: .generateBox(width: 11.5, height: 0.16, depth: 14, cornerRadius: 0.07),
      materials: [floorPlaster]
    )
    floor.name = "ObservatoryGalleryFloor"
    floor.position = [0, -2.24, -2.8]
    set.addChild(floor)

    let wall = ModelEntity(
      mesh: .generateBox(width: 10.6, height: 7.2, depth: 0.28, cornerRadius: 0.08),
      materials: [wallPlaster]
    )
    wall.name = "ObservatoryBlueWall"
    wall.position = [0, 0.70, -7.0]
    set.addChild(wall)

    for side: Float in [-1, 1] {
      let returnWall = ModelEntity(
        mesh: .generateBox(width: 2.30, height: 6.25, depth: 0.19, cornerRadius: 0.08),
        materials: [returnPlaster]
      )
      returnWall.name = "ObservatoryReturn"
      returnWall.position = [side * 3.72, 0.35, -4.95]
      returnWall.orientation = simd_quatf(angle: side * 0.15, axis: [0, 1, 0])
      set.addChild(returnWall)
    }

    var fieldMaterial = moonPlaster
    fieldMaterial.baseColor = .init(tint: NSColor(red: 0.22, green: 0.31, blue: 0.58, alpha: 1))
    fieldMaterial.emissiveColor = .init(color: NSColor(red: 0.025, green: 0.055, blue: 0.18, alpha: 1))
    fieldMaterial.emissiveIntensity = 0.72

    let moon = ModelEntity(
      mesh: .generateSphere(radius: 2.36),
      materials: [fieldMaterial]
    )
    moon.name = "RecessedMicrobiomeField"
    moon.position = [0, 0.02, -5.78]
    moon.scale = [0.94, 0.82, 0.12]
    set.addChild(moon)

    var meridians: [ModelEntity] = []
    let radii: [Float] = [2.18, 2.68]
    for index in 0..<radii.count {
      let ring = ModelEntity(
        mesh: try arcMesh(
          radius: radii[index],
          thickness: index == 0 ? 0.022 : 0.030,
          startAngle: 0.12,
          endAngle: .pi - 0.10,
          depth: 0.055
        ),
        materials: [brass]
      )
      ring.name = "MeridianArc\(index)"
      ring.position = [index == 0 ? -0.18 : 0.18, -1.52, -3.72 - Float(index) * 0.95]
      set.addChild(ring)
      meridians.append(ring)
    }

    // Sparse calibrated points give scale without turning the wall into visual noise.
    var stars: [ModelEntity] = []
    for index in 0..<24 {
      let palette: [NSColor] = [
        NSColor(red: 0.25, green: 0.80, blue: 0.82, alpha: 0.82),
        NSColor(red: 0.46, green: 0.58, blue: 1.0, alpha: 0.78),
        NSColor(red: 0.96, green: 0.60, blue: 0.28, alpha: 0.82),
        NSColor(red: 0.74, green: 0.46, blue: 0.94, alpha: 0.76),
      ]
      let color = palette[index % palette.count]
      var starMaterial = PhysicallyBasedMaterial()
      starMaterial.baseColor = .init(tint: color)
      starMaterial.roughness = .init(floatLiteral: 0.14)
      starMaterial.clearcoat = .init(floatLiteral: 0.72)
      starMaterial.emissiveColor = .init(color: color)
      starMaterial.emissiveIntensity = 0.34
      starMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.78))
      let radius = 1.85 + Float((index * 23) % 100) / 100 * 1.18
      let angle = Float((index * 53) % 360) * .pi / 180
      let star = ModelEntity(
        mesh: .generateSphere(radius: 0.045 + Float(index % 5) * 0.020),
        materials: [starMaterial]
      )
      star.name = "ObservatoryPoint\(index)"
      star.position = [
        cos(angle) * radius,
        -0.18 + sin(angle) * radius * 0.86,
        -4.95 + Float(index % 4) * 0.34,
      ]
      set.addChild(star)
      stars.append(star)
    }

    var markerMaterial = PhysicallyBasedMaterial()
    markerMaterial.baseColor = .init(
      tint: NSColor(red: 0.94, green: 0.55, blue: 0.23, alpha: 1)
    )
    markerMaterial.roughness = .init(floatLiteral: 0.22)
    markerMaterial.metallic = .init(floatLiteral: 0.36)
    markerMaterial.emissiveColor = .init(
      color: NSColor(red: 0.22, green: 0.055, blue: 0.012, alpha: 1)
    )
    markerMaterial.emissiveIntensity = 0.52
    var transitMarkers: [ModelEntity] = []
    for index in 0..<2 {
      let marker = ModelEntity(
        mesh: .generateSphere(radius: 0.055 - Float(index) * 0.008),
        materials: [markerMaterial]
      )
      marker.name = "TransitMarker\(index)"
      marker.position = [0, radii[index], -4.94]
      set.addChild(marker)
      transitMarkers.append(marker)
    }

    let plinth = ModelEntity(
      mesh: .generateCylinder(height: 0.16, radius: 1.18),
      materials: [floorPlaster]
    )
    plinth.name = "ObservatoryHeroPlinth"
    plinth.position = [0, -2.03, 0.36]
    set.addChild(plinth)

    let plinthBand = ModelEntity(
      mesh: .generateCylinder(height: 0.035, radius: 1.19),
      materials: [silver]
    )
    plinthBand.name = "ObservatoryPlinthBand"
    plinthBand.position = [0, -2.12, 0.36]
    set.addChild(plinthBand)

    let product = try await Batch2SceneSupport.product(imageURL, height: 2.72)
    product.position = [0, -0.55, 0.76]
    set.addChild(product)

    let shadow = Batch2SceneSupport.addContactShadow(to: set, width: 2.10)
    shadow.position = [0, -1.94, 0.51]

    let lighting = try await Batch2SceneSupport.light(
      root: set,
      ibl: "church_museum",
      exponent: 0.66,
      keyColor: NSColor(red: 0.74, green: 0.83, blue: 1.0, alpha: 1),
      rimColor: NSColor(red: 1.0, green: 0.70, blue: 0.44, alpha: 1),
      keyIntensity: 17_500,
      rimIntensity: 9_500
    )

    let moonLight = PointLight()
    moonLight.name = "MoonSculptLight"
    moonLight.light = .init(
      color: NSColor(red: 1.0, green: 0.79, blue: 0.58, alpha: 1),
      intensity: 4_600,
      attenuationRadius: 8.2
    )
    moonLight.position = [-1.72, 1.26, -3.72]
    set.addChild(moonLight)

    let camera = Batch2SceneSupport.camera(root: set, focalLength: 48)
    let scene = ObservatoryTransitScene(
      camera: camera,
      product: product,
      shadow: shadow,
      moon: moon,
      meridians: meridians,
      stars: stars,
      transitMarkers: transitMarkers,
      moonLight: moonLight,
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
    let rise = NewSceneSupport.smooth(frame, 12, 190)
    let transit = NewSceneSupport.smooth(frame, 115, 338)
    let settle = NewSceneSupport.smooth(frame, 330, 449)

    moon.position = [
      NewSceneSupport.mix(0.24, 0.0, rise),
      NewSceneSupport.mix(-0.18, 0.02, rise),
      -5.48,
    ]
    moon.scale = [
      NewSceneSupport.mix(0.94, 1.0, rise),
      NewSceneSupport.mix(0.80, 0.88, rise),
      0.12,
    ]
    moon.orientation = simd_quatf(angle: rise * 0.10, axis: [0, 1, 0])

    let radii: [Float] = [2.86, 2.46]
    for (index, ring) in meridians.enumerated() {
      let direction: Float = index == 0 ? 0 : -1
      let startX: Float = index == 0 ? -0.04 : 0.12
      let quietPrecession = sin(Float(frame) * 0.010 + Float(index) * 1.3)
        * 0.022 * rise * (1 - settle)
      ring.position = [
        NewSceneSupport.mix(startX, 0, rise),
        NewSceneSupport.mix(-1.94, -1.90, rise),
        -5.03 - Float(index) * 0.08,
      ]
      ring.scale = [1, 1, 1]
      ring.orientation = simd_quatf(
        angle: direction * NewSceneSupport.mix(0.075, 0.012, rise) + quietPrecession,
        axis: [0, 1, 0]
      )
    }

    for (index, marker) in transitMarkers.enumerated() {
      let startAngle: Float = index == 0 ? 0.08 : .pi - 0.08
      let resolvedAngle = .pi / 2 + (Float(index) - 0.5) * 0.14
      let angle = NewSceneSupport.mix(startAngle, resolvedAngle, transit)
      marker.position = [
        cos(angle) * radii[index],
        -1.90 + sin(angle) * radii[index],
        -4.92 + Float(index) * 0.03,
      ]
    }

    for (index, star) in stars.enumerated() {
      let twinkle = 0.82 + 0.18 * sin(Float(frame) * 0.028 + Float(index) * 1.67)
      star.scale = SIMD3<Float>(repeating: twinkle)
      star.position.x += sin(Float(frame) * 0.006 + Float(index)) * 0.0018
      star.position.y += cos(Float(frame) * 0.007 + Float(index) * 0.7) * 0.0014
    }

    product.isEnabled = true
    product.position = NewSceneSupport.mix(
      SIMD3<Float>(0, -0.62, 0.74),
      SIMD3<Float>(0, -0.59, 0.78),
      hero
    )
    product.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.92, 1.0, hero))
    product.orientation = simd_quatf(
      angle: NewSceneSupport.mix(0.055, 0, hero),
      axis: [0, 1, 0]
    )

    shadow.isEnabled = true
    shadow.position = [0, -1.94, 0.51]
    shadow.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.86, 1.0, hero))

    moonLight.light.intensity = 4_000 + rise * 1_800 + transit * 600
    key.light.intensity = 14_000 + hero * 3_200 + transit * 800
    rim.light.intensity = 7_200 + rise * 1_500 + settle * 800

    let cameraProgress = NewSceneSupport.smooth(frame, 0, 405)
    camera.look(
      at: [0, -0.14, -0.56],
      from: NewSceneSupport.mix(
        SIMD3<Float>(-0.30, 0.19, 13.62),
        SIMD3<Float>(0.16, 0.06, 13.08),
        cameraProgress
      ),
      relativeTo: root
    )
  }

  private static func arcMesh(
    radius: Float,
    thickness: Float,
    startAngle: Float,
    endAngle: Float,
    depth: Float
  ) throws -> MeshResource {
    let segments = 64
    var positions: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    for segment in 0...segments {
      let progress = Float(segment) / Float(segments)
      let angle = NewSceneSupport.mix(startAngle, endAngle, progress)
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
    var descriptor = MeshDescriptor(name: "ObservatoryMeridianArc")
    descriptor.positions = .init(positions)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }
}
