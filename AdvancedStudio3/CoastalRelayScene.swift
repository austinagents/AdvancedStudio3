import AppKit
import RealityKit

@MainActor
final class CoastalRelayScene {
  let root: Entity
  let camera: PerspectiveCamera

  private let product: ModelEntity
  private let shadow: ModelEntity
  private let water: ModelEntity
  private let waveRibbons: [Entity]
  private let horizonMist: ModelEntity
  private let key: SpotLight
  private let rim: SpotLight

  private init(
    root: Entity,
    camera: PerspectiveCamera,
    product: ModelEntity,
    shadow: ModelEntity,
    water: ModelEntity,
    waveRibbons: [Entity],
    horizonMist: ModelEntity,
    key: SpotLight,
    rim: SpotLight
  ) {
    self.root = root
    self.camera = camera
    self.product = product
    self.shadow = shadow
    self.water = water
    self.waveRibbons = waveRibbons
    self.horizonMist = horizonMist
    self.key = key
    self.rim = rim
  }

  static func load(imageURL: URL) async throws -> CoastalRelayScene {
    let root = Entity()
    root.name = "CoastalRelay"

    var skyMaterial = UnlitMaterial(
      color: NSColor(red: 0.035, green: 0.10, blue: 0.17, alpha: 1))
    skyMaterial.faceCulling = .none
    let sky = ModelEntity(
      mesh: .generatePlane(width: 18, height: 14),
      materials: [skyMaterial])
    sky.name = "DeepNavySky"
    sky.position = [0, 1.9, -10.2]
    root.addChild(sky)

    var lowerFieldMaterial = UnlitMaterial(
      color: NSColor(red: 0.035, green: 0.23, blue: 0.27, alpha: 1))
    lowerFieldMaterial.faceCulling = .none
    let lowerField = ModelEntity(
      mesh: .generatePlane(width: 18, height: 5.2),
      materials: [lowerFieldMaterial])
    lowerField.name = "TealLowerField"
    lowerField.position = [0, -1.65, -10.1]
    root.addChild(lowerField)

    var waterMaterial = PhysicallyBasedMaterial()
    waterMaterial.baseColor = .init(
      tint: NSColor(red: 0.025, green: 0.22, blue: 0.27, alpha: 1))
    waterMaterial.roughness = .init(floatLiteral: 0.08)
    waterMaterial.metallic = .init(floatLiteral: 0.12)
    waterMaterial.clearcoat = .init(floatLiteral: 1.0)
    let water = ModelEntity(
      mesh: .generateBox(width: 14.0, height: 0.10, depth: 18.0, cornerRadius: 0.04),
      materials: [waterMaterial])
    water.name = "ReflectiveTidalPlane"
    water.position = [0, -2.84, -2.0]
    root.addChild(water)

    var horizonMistMaterial = UnlitMaterial(
      color: NSColor(red: 0.45, green: 0.83, blue: 0.80, alpha: 0.12))
    horizonMistMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.12))
    horizonMistMaterial.faceCulling = .none
    let horizonMist = ModelEntity(
      mesh: .generatePlane(width: 10.8, height: 0.68, cornerRadius: 0.30),
      materials: [horizonMistMaterial])
    horizonMist.name = "TidalHorizonMist"
    horizonMist.position = [0, -0.52, -8.9]
    root.addChild(horizonMist)

    let ribbonColors: [NSColor] = [
      NSColor(red: 0.08, green: 0.42, blue: 0.47, alpha: 0.40),
      NSColor(red: 0.12, green: 0.58, blue: 0.59, alpha: 0.30),
      NSColor(red: 0.31, green: 0.78, blue: 0.74, alpha: 0.22),
      NSColor(red: 0.63, green: 0.91, blue: 0.84, alpha: 0.14),
    ]
    var waveRibbons: [Entity] = []
    for index in 0..<4 {
      var material = UnlitMaterial(color: ribbonColors[index])
      material.blending = .transparent(
        opacity: .init(floatLiteral: Float(ribbonColors[index].alphaComponent)))
      material.faceCulling = .none

      var points: [SIMD3<Float>] = []
      for point in 0..<82 {
        let t = Float(point) / 81
        let x = -4.8 + t * 9.6
        let amplitude = 0.22 + Float(index) * 0.075
        let y = sin(t * .pi * 2 + Float(index) * 0.72) * amplitude
          + sin(t * .pi * 4 + Float(index) * 0.38) * 0.055
        points.append([x, y, 0])
      }
      let wave = ModelEntity(
        mesh: try Batch2SceneSupport.ribbonMesh(
          points: points,
          width: 0.24 + Float(index) * 0.055),
        materials: [material])
      wave.name = "BroadTidalRibbon\(index)"
      let waveRoot = Entity()
      waveRoot.name = "TidalWaveRoot\(index)"
      waveRoot.position = [
        index.isMultiple(of: 2) ? -0.42 : 0.36,
        -1.30 + Float(index) * 0.46,
        -1.85 - Float(index) * 1.18,
      ]
      waveRoot.addChild(wave)
      root.addChild(waveRoot)
      waveRibbons.append(waveRoot)
    }

    let product = try await Batch2SceneSupport.product(imageURL, height: 2.62)
    product.name = "CoastalHeroProduct"
    product.position = [0, -1.41, 0.72]
    root.addChild(product)
    let shadow = Batch2SceneSupport.addContactShadow(to: root, width: 2.18)
    shadow.position = [0, -2.77, 0.42]

    addCopy(to: root)

    let lighting = try await Batch2SceneSupport.light(
      root: root,
      ibl: "blue_grotto",
      exponent: 0.78,
      keyColor: NSColor(red: 0.74, green: 0.92, blue: 1.0, alpha: 1),
      rimColor: NSColor(red: 0.46, green: 1.0, blue: 0.87, alpha: 1),
      keyIntensity: 27_000,
      rimIntensity: 15_000)
    let camera = Batch2SceneSupport.camera(root: root, focalLength: 46)
    let scene = CoastalRelayScene(
      root: root,
      camera: camera,
      product: product,
      shadow: shadow,
      water: water,
      waveRibbons: waveRibbons,
      horizonMist: horizonMist,
      key: lighting.key,
      rim: lighting.rim)
    scene.apply(frameIndex: 0)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 449)
    let settle = NewSceneSupport.smooth(frame, 0, 84)
    let pass = NewSceneSupport.smooth(frame, 0, 449)
    let brighten = NewSceneSupport.smooth(frame, 88, 292)

    product.isEnabled = true
    product.position = NewSceneSupport.mix(
      [0, -1.48, 0.52], [0, -1.41, 0.72], settle)
    let productScale = NewSceneSupport.mix(0.97, 1.0, settle)
    product.scale = [productScale, productScale, productScale]
    product.orientation = simd_quatf(
      angle: NewSceneSupport.mix(-0.018, 0, settle), axis: [0, 1, 0])

    shadow.isEnabled = true
    shadow.position = [0, -2.77, 0.42]
    let shadowScale = NewSceneSupport.mix(0.90, 1.0, settle)
    shadow.scale = [shadowScale, 1, shadowScale]
    shadow.components.set(
      OpacityComponent(opacity: NewSceneSupport.mix(0.15, 0.27, settle)))

    water.position.y = -2.84 + sin(Float(frame) * 0.015) * 0.006
    for (index, wave) in waveRibbons.enumerated() {
      let direction: Float = index.isMultiple(of: 2) ? 1 : -1
      let phase = Float(index) * 0.78
      let baseY = -1.30 + Float(index) * 0.46
      let baseZ = -1.85 - Float(index) * 1.18
      wave.position = [
        direction * NewSceneSupport.mix(-0.80, 0.92, pass)
          + sin(Float(frame) * 0.012 + phase) * 0.10,
        baseY + sin(Float(frame) * 0.018 + phase) * 0.12,
        baseZ + NewSceneSupport.mix(0.28, -0.22, pass),
      ]
      wave.scale.x = 0.92 + sin(Float(frame) * 0.014 + phase) * 0.10
    }

    horizonMist.scale.x = NewSceneSupport.mix(0.72, 1.06, brighten)
    horizonMist.components.set(
      OpacityComponent(opacity: NewSceneSupport.mix(0.08, 0.16, brighten)))
    key.light.intensity = 24_000 + settle * 4_000 + brighten * 1_500
    rim.light.intensity = 12_000 + brighten * 6_000

    camera.look(
      at: NewSceneSupport.mix([0, -0.68, -0.34], [0, -0.62, 0.08], settle),
      from: [
        NewSceneSupport.mix(-0.30, 0.26, pass),
        NewSceneSupport.mix(0.20, 0.10, settle),
        NewSceneSupport.mix(12.60, 12.06, settle),
      ],
      relativeTo: root)
  }

  private static func addCopy(to root: Entity) {
    let title = NewSceneSupport.text(
      "GOOD STARTS WITHIN.",
      fontName: "HelveticaNeue-Medium",
      size: 0.146,
      color: .white,
      depth: 0.004)
    title.name = "CoastalCampaignHook"
    title.position = [-1.08, 1.54, 2.62]
    root.addChild(title)
    let kicker = NewSceneSupport.text(
      "DAILY PREBIOTIC FIBER",
      fontName: "SFMono-Medium",
      size: 0.058,
      color: NSColor(red: 0.64, green: 0.90, blue: 0.86, alpha: 0.86),
      depth: 0.003)
    kicker.position = [-1.07, 1.30, 2.62]
    root.addChild(kicker)
  }
}
