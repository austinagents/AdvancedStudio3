import AppKit
import RealityKit

@MainActor
final class KineticFacadeScene {
  private struct Shutter {
    let entity: ModelEntity
    let closed: SIMD3<Float>
    let opened: SIMD3<Float>
    let closedAngle: Float
    let openedAngle: Float
    let axis: SIMD3<Float>
  }

  let root = Entity()
  let camera: PerspectiveCamera

  private let product: ModelEntity
  private let shadow: ModelEntity
  private let shutters: [Shutter]
  private let aperture: ModelEntity
  private let apertureLight: PointLight
  private let sweep: SpotLight
  private let key: SpotLight
  private let rim: SpotLight

  private init(
    camera: PerspectiveCamera,
    product: ModelEntity,
    shadow: ModelEntity,
    shutters: [Shutter],
    aperture: ModelEntity,
    apertureLight: PointLight,
    sweep: SpotLight,
    key: SpotLight,
    rim: SpotLight
  ) {
    self.camera = camera
    self.product = product
    self.shadow = shadow
    self.shutters = shutters
    self.aperture = aperture
    self.apertureLight = apertureLight
    self.sweep = sweep
    self.key = key
    self.rim = rim
  }

  static func load(imageURL: URL) async throws -> KineticFacadeScene {
    let set = Entity()
    set.name = "BenefiberDailyGallery"
    Batch2SceneSupport.addHook(
      to: set,
      title: "FITS YOUR DAY.",
      kicker: "Daily fiber, without the fuss.",
      color: NSColor(red: 0.18, green: 0.17, blue: 0.15, alpha: 1),
      x: -1.02
    )

    let floorPlaster = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.92, green: 0.89, blue: 0.82, alpha: 1)
    )
    let wallPlaster = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.98, green: 0.95, blue: 0.89, alpha: 1)
    )

    var bronze = PhysicallyBasedMaterial()
    bronze.baseColor = .init(tint: NSColor(red: 0.66, green: 0.47, blue: 0.28, alpha: 1))
    bronze.roughness = .init(floatLiteral: 0.29)
    bronze.metallic = .init(floatLiteral: 0.72)
    bronze.clearcoat = .init(floatLiteral: 0.30)

    var titanium = PhysicallyBasedMaterial()
    titanium.baseColor = .init(tint: NSColor(red: 0.67, green: 0.69, blue: 0.67, alpha: 1))
    titanium.roughness = .init(floatLiteral: 0.26)
    titanium.metallic = .init(floatLiteral: 0.76)
    titanium.clearcoat = .init(floatLiteral: 0.34)

    var coveMaterial = PhysicallyBasedMaterial()
    coveMaterial.baseColor = .init(tint: NSColor(red: 0.88, green: 0.80, blue: 0.64, alpha: 1))
    coveMaterial.roughness = .init(floatLiteral: 0.42)
    coveMaterial.emissiveColor = .init(color: NSColor(red: 0.08, green: 0.045, blue: 0.016, alpha: 1))
    coveMaterial.emissiveIntensity = 0.18

    let floor = ModelEntity(
      mesh: .generateBox(width: 12, height: 0.18, depth: 14, cornerRadius: 0.08),
      materials: [floorPlaster]
    )
    floor.position = [0, -2.24, -2.7]
    set.addChild(floor)

    let wall = ModelEntity(
      mesh: .generateBox(width: 11, height: 7.4, depth: 0.28, cornerRadius: 0.08),
      materials: [wallPlaster]
    )
    wall.position = [0, 0.72, -7.2]
    set.addChild(wall)

    // Broad angled room planes establish real perspective without framing the product.
    for side: Float in [-1, 1] {
      let returnWall = ModelEntity(
        mesh: .generateBox(width: 1.45, height: 5.9, depth: 6.8, cornerRadius: 0.06),
        materials: [wallPlaster]
      )
      returnWall.position = [side * 3.38, 0.18, -3.30]
      returnWall.orientation = simd_quatf(angle: side * -0.18, axis: [0, 1, 0])
      set.addChild(returnWall)

      let ceilingPlane = ModelEntity(
        mesh: .generateBox(width: 1.75, height: 0.11, depth: 6.3, cornerRadius: 0.035),
        materials: [side < 0 ? bronze : titanium]
      )
      ceilingPlane.position = [side * 2.12, 2.74, -2.65]
      ceilingPlane.orientation = simd_quatf(angle: side * -0.14, axis: [0, 1, 0])
      set.addChild(ceilingPlane)
    }

    let aperture = ModelEntity(mesh: .generateSphere(radius: 2.38), materials: [coveMaterial])
    aperture.name = "SculptedDailyLightCove"
    aperture.position = [0, 0.02, -6.02]
    aperture.scale = [0.82, 1.02, 0.13]
    set.addChild(aperture)

    // Four room-scale facets read as two substantial shutter wings. Their overlap
    // creates a continuous bronze/titanium surface instead of a row of thin slats.
    let closed: [SIMD3<Float>] = [
      [-2.02, -0.03, -4.02], [-0.88, 0.04, -3.82],
      [0.88, 0.04, -3.82], [2.02, -0.03, -4.02],
    ]
    let opened: [SIMD3<Float>] = [
      [-2.96, 0.06, -3.08], [-2.02, 0.38, -3.62],
      [2.02, 0.38, -3.62], [2.96, 0.06, -3.08],
    ]
    let closedAngles: [Float] = [-0.18, -0.07, 0.07, 0.18]
    let openedAngles: [Float] = [-0.58, -0.34, 0.34, 0.58]
    let widths: [Float] = [1.52, 1.42, 1.42, 1.52]
    let heights: [Float] = [4.72, 4.46, 4.46, 4.72]
    var shutters: [Shutter] = []
    for index in 0..<4 {
      let shutter = ModelEntity(
        mesh: .generateBox(
          width: widths[index], height: heights[index], depth: 0.24,
          cornerRadius: 0.055
        ),
        materials: [index == 0 || index == 3 ? bronze : titanium]
      )
      shutter.name = index < 2 ? "LeftShutterWingFacet\(index)" : "RightShutterWingFacet\(index - 2)"
      shutter.position = closed[index]
      set.addChild(shutter)
      shutters.append(
        Shutter(
          entity: shutter,
          closed: closed[index],
          opened: opened[index],
          closedAngle: closedAngles[index],
          openedAngle: openedAngles[index],
          axis: [0, 1, 0]
        )
      )
    }

    let plinth = ModelEntity(
      mesh: .generateCylinder(height: 0.16, radius: 1.12),
      materials: [floorPlaster]
    )
    plinth.position = [0, -2.03, 0.34]
    set.addChild(plinth)

    let product = try await Batch2SceneSupport.product(imageURL, height: 2.62)
    product.position = [0, -0.64, 0.76]
    set.addChild(product)

    let shadow = Batch2SceneSupport.addContactShadow(to: set, width: 2.0)
    shadow.position = [0, -1.94, 0.50]

    let lighting = try await Batch2SceneSupport.light(
      root: set,
      ibl: "courtyard",
      exponent: 0.88,
      keyColor: NSColor(red: 1.0, green: 0.92, blue: 0.80, alpha: 1),
      rimColor: NSColor(red: 0.80, green: 0.88, blue: 1.0, alpha: 1),
      keyIntensity: 19_000,
      rimIntensity: 10_000
    )

    let apertureLight = PointLight()
    apertureLight.light = .init(
      color: NSColor(red: 1.0, green: 0.79, blue: 0.55, alpha: 1),
      intensity: 2_200,
      attenuationRadius: 8
    )
    apertureLight.position = [0, -0.1, -3.85]
    set.addChild(apertureLight)

    let sweep = SpotLight()
    sweep.light = .init(
      color: NSColor(red: 1.0, green: 0.88, blue: 0.70, alpha: 1),
      intensity: 0,
      innerAngleInDegrees: 9,
      outerAngleInDegrees: 27,
      attenuationRadius: 18
    )
    set.addChild(sweep)

    let camera = Batch2SceneSupport.camera(root: set, focalLength: 44)
    let scene = KineticFacadeScene(
      camera: camera,
      product: product,
      shadow: shadow,
      shutters: shutters,
      aperture: aperture,
      apertureLight: apertureLight,
      sweep: sweep,
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
    let reveal = NewSceneSupport.smooth(frame, 0, 155)
    let focus = NewSceneSupport.smooth(frame, 85, 270)
    let settle = NewSceneSupport.smooth(frame, 300, 449)

    for (index, shutter) in shutters.enumerated() {
      let stagger = NewSceneSupport.smooth(frame, index * 7, 118 + index * 8)
      let progress = max(reveal * 0.70, stagger)
      let breath = sin(Float(frame) * 0.018 + Float(index)) * 0.018 * focus * (1 - settle)
      shutter.entity.position = NewSceneSupport.mix(shutter.closed, shutter.opened, progress)
      shutter.entity.orientation = simd_quatf(
        angle: NewSceneSupport.mix(shutter.closedAngle, shutter.openedAngle, progress) + breath,
        axis: shutter.axis
      )
    }

    aperture.scale = [
      NewSceneSupport.mix(0.72, 0.92, reveal),
      NewSceneSupport.mix(0.88, 1.06, reveal),
      0.13,
    ]
    aperture.position = [0, NewSceneSupport.mix(-0.08, 0.10, reveal), -6.02]

    product.isEnabled = true
    product.position = NewSceneSupport.mix(
      SIMD3<Float>(0, -0.68, 0.74),
      SIMD3<Float>(0, -0.64, 0.78),
      NewSceneSupport.smooth(frame, 0, 92)
    )
    product.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.94, 1.0, reveal))
    product.orientation = simd_quatf(
      angle: NewSceneSupport.mix(0.045, 0, reveal),
      axis: [0, 1, 0]
    )

    shadow.position = [0, -1.94, 0.50]
    shadow.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.88, 1.0, reveal))

    let sweepTarget = NewSceneSupport.mix(-2.3, 2.3, NewSceneSupport.smooth(frame, 24, 228))
    sweep.look(at: [sweepTarget, -0.1, -3.4], from: [-3.4 + sweepTarget, 3.0, 2.2], relativeTo: root)
    sweep.light.intensity = 700 + focus * 4_500 - settle * 2_000
    apertureLight.position = [NewSceneSupport.mix(-0.9, 0.9, focus), -0.1, -3.85]
    apertureLight.light.intensity = 2_000 + reveal * 1_700 + focus * 500
    key.light.intensity = 16_000 + reveal * 3_000 + focus * 900
    rim.light.intensity = 7_500 + reveal * 2_500 + settle * 700

    let cameraProgress = NewSceneSupport.smooth(frame, 0, 380)
    camera.look(
      at: [0, -0.16, -0.65],
      from: NewSceneSupport.mix(
        SIMD3<Float>(0.48, 0.26, 13.45),
        SIMD3<Float>(-0.18, 0.07, 12.82),
        cameraProgress
      ),
      relativeTo: root
    )
  }
}
