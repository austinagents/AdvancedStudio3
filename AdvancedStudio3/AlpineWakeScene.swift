import AppKit
import RealityKit

@MainActor
final class AlpineWakeScene {
  let root: Entity
  let camera: PerspectiveCamera

  private let product: ModelEntity
  private let shadow: ModelEntity
  private let mountainBands: [ModelEntity]
  private let cloudRibbons: [Entity]
  private let sunDisc: ModelEntity
  private let key: SpotLight
  private let rim: SpotLight

  private init(
    root: Entity,
    camera: PerspectiveCamera,
    product: ModelEntity,
    shadow: ModelEntity,
    mountainBands: [ModelEntity],
    cloudRibbons: [Entity],
    sunDisc: ModelEntity,
    key: SpotLight,
    rim: SpotLight
  ) {
    self.root = root
    self.camera = camera
    self.product = product
    self.shadow = shadow
    self.mountainBands = mountainBands
    self.cloudRibbons = cloudRibbons
    self.sunDisc = sunDisc
    self.key = key
    self.rim = rim
  }

  static func load(imageURL: URL) async throws -> AlpineWakeScene {
    let root = Entity()
    root.name = "AlpineWake"

    let snow = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.90, green: 0.92, blue: 0.92, alpha: 1))

    var skyMaterial = UnlitMaterial(
      color: NSColor(red: 0.60, green: 0.74, blue: 0.88, alpha: 1))
    skyMaterial.faceCulling = .none
    let sky = ModelEntity(
      mesh: .generatePlane(width: 18, height: 14),
      materials: [skyMaterial])
    sky.name = "PowderBlueSky"
    sky.position = [0, 1.9, -10.2]
    root.addChild(sky)

    var sunMaterial = UnlitMaterial(
      color: NSColor(red: 1.0, green: 0.68, blue: 0.43, alpha: 0.92))
    sunMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.92))
    sunMaterial.faceCulling = .none
    let sunDisc = ModelEntity(
      mesh: .generatePlane(width: 1.42, height: 1.42, cornerRadius: 0.71),
      materials: [sunMaterial])
    sunDisc.name = "WarmAlpineSunrise"
    sunDisc.position = [1.62, -0.82, -8.25]
    root.addChild(sunDisc)

    let bandColors: [NSColor] = [
      NSColor(red: 0.36, green: 0.52, blue: 0.70, alpha: 1),
      NSColor(red: 0.63, green: 0.76, blue: 0.87, alpha: 1),
      NSColor(red: 0.87, green: 0.91, blue: 0.94, alpha: 1),
    ]
    let bandZ: [Float] = [-6.40, -4.50, -2.65]
    let bases: [Float] = [-1.42, -1.72, -2.03]
    let lifts: [Float] = [1.62, 1.23, 0.88]
    var mountainBands: [ModelEntity] = []
    for index in 0..<3 {
      var material = PhysicallyBasedMaterial()
      material.baseColor = .init(tint: bandColors[index])
      material.roughness = .init(floatLiteral: 0.88)
      material.metallic = .init(floatLiteral: 0.0)
      material.faceCulling = .none
      let mesh = try mountainBandMesh(
        width: 12.0,
        bottom: -3.30,
        segments: 88
      ) { x in
        let left = exp(-pow((x + 2.42) / 1.02, 2)) * lifts[index]
        let right = exp(-pow((x - 2.28) / 1.10, 2)) * lifts[index] * 0.92
        let contour = sin(x * 0.88 + Float(index) * 0.72) * (0.08 - Float(index) * 0.012)
        return bases[index] + left + right + contour
      }
      let band = ModelEntity(mesh: mesh, materials: [material])
      band.name = "SculptedMountainBand\(index)"
      band.position = [0, 0, bandZ[index]]
      root.addChild(band)
      mountainBands.append(band)
    }

    var cloudRibbons: [Entity] = []
    for index in 0..<3 {
      var cloudMaterial = UnlitMaterial(
        color: NSColor(white: 1.0, alpha: 0.10 - CGFloat(index) * 0.018))
      cloudMaterial.blending = .transparent(
        opacity: .init(floatLiteral: 0.10 - Float(index) * 0.018))
      cloudMaterial.faceCulling = .none
      var points: [SIMD3<Float>] = []
      for point in 0..<72 {
        let t = Float(point) / 71
        let x = -3.7 + t * 7.4
        let y = sin(t * .pi * 2 + Float(index) * 0.84) * 0.07
          + sin(t * .pi * 4) * 0.025
        points.append([x, y, 0])
      }
      let cloud = ModelEntity(
        mesh: try Batch2SceneSupport.ribbonMesh(
          points: points,
          width: 0.12 + Float(index) * 0.035),
        materials: [cloudMaterial])
      let cloudRoot = Entity()
      cloudRoot.name = "AtmosphericCloud\(index)"
      cloudRoot.position = [
        index.isMultiple(of: 2) ? -1.0 : 1.1,
        0.40 + Float(index) * 0.36,
        -8.65 - Float(index) * 0.18,
      ]
      cloudRoot.addChild(cloud)
      root.addChild(cloudRoot)
      cloudRibbons.append(cloudRoot)
    }

    let ground = ModelEntity(
      mesh: .generateBox(width: 15, height: 0.20, depth: 18, cornerRadius: 0.10),
      materials: [snow])
    ground.name = "ContinuousSnowField"
    ground.position = [0, -2.94, -2.0]
    root.addChild(ground)

    let product = try await Batch2SceneSupport.product(imageURL, height: 2.62)
    product.name = "AlpineHeroProduct"
    product.position = [0.04, -1.41, 0.74]
    root.addChild(product)
    let shadow = Batch2SceneSupport.addContactShadow(to: root, width: 2.18)
    shadow.position = [0.04, -2.77, 0.42]

    addCopy(to: root)

    let lighting = try await Batch2SceneSupport.light(
      root: root,
      ibl: "goegap",
      exponent: 0.70,
      keyColor: NSColor(red: 0.84, green: 0.92, blue: 1.0, alpha: 1),
      rimColor: NSColor(red: 1.0, green: 0.70, blue: 0.48, alpha: 1),
      keyIntensity: 25_000,
      rimIntensity: 15_000)
    let camera = Batch2SceneSupport.camera(root: root, focalLength: 46)
    let scene = AlpineWakeScene(
      root: root,
      camera: camera,
      product: product,
      shadow: shadow,
      mountainBands: mountainBands,
      cloudRibbons: cloudRibbons,
      sunDisc: sunDisc,
      key: lighting.key,
      rim: lighting.rim)
    scene.apply(frameIndex: 0)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 449)
    let settle = NewSceneSupport.smooth(frame, 0, 84)
    let rise = NewSceneSupport.smooth(frame, 0, 330)
    let travel = NewSceneSupport.smooth(frame, 0, 449)

    product.isEnabled = true
    product.position = NewSceneSupport.mix(
      [0.04, -1.48, 0.52], [0.04, -1.41, 0.74], settle)
    let productScale = NewSceneSupport.mix(0.97, 1.0, settle)
    product.scale = [productScale, productScale, productScale]
    product.orientation = simd_quatf(
      angle: NewSceneSupport.mix(-0.016, 0, settle), axis: [1, 0, 0])

    shadow.isEnabled = true
    shadow.position = [0.04, -2.77, 0.42]
    let shadowScale = NewSceneSupport.mix(0.90, 1.0, settle)
    shadow.scale = [shadowScale, 1, shadowScale]
    shadow.components.set(
      OpacityComponent(opacity: NewSceneSupport.mix(0.13, 0.24, settle)))

    sunDisc.position = [
      NewSceneSupport.mix(1.76, 1.46, rise),
      NewSceneSupport.mix(-0.82, 0.28, rise),
      -8.25,
    ]
    let sunScale = NewSceneSupport.mix(0.84, 1.0, rise)
    sunDisc.scale = [sunScale, sunScale, sunScale]

    for (index, band) in mountainBands.enumerated() {
      let direction: Float = index.isMultiple(of: 2) ? -1 : 1
      band.position.x = direction * NewSceneSupport.mix(0.18, -0.20, travel)
      band.position.z = [-6.40, -4.50, -2.65][index]
        + NewSceneSupport.mix(0.18, -0.12, travel) * Float(index + 1) * 0.35
    }

    for (index, cloud) in cloudRibbons.enumerated() {
      let direction: Float = index.isMultiple(of: 2) ? 1 : -1
      cloud.position.x = direction * NewSceneSupport.mix(-1.35, 1.55, travel)
        + sin(Float(frame) * 0.008 + Float(index)) * 0.08
      cloud.position.y = 0.40 + Float(index) * 0.36
        + sin(Float(frame) * 0.010 + Float(index)) * 0.035
    }

    key.light.intensity = 22_000 + settle * 4_000 + rise * 1_000
    rim.light.intensity = 11_000 + rise * 8_000
    camera.look(
      at: NewSceneSupport.mix([0, -0.68, -0.34], [0.04, -0.61, 0.10], settle),
      from: [
        NewSceneSupport.mix(-0.30, 0.24, travel),
        NewSceneSupport.mix(0.20, 0.10, settle),
        NewSceneSupport.mix(12.62, 12.04, settle),
      ],
      relativeTo: root)
  }

  private static func addCopy(to root: Entity) {
    let title = NewSceneSupport.text(
      "FEEL GOOD. GO FURTHER.",
      fontName: "HelveticaNeue-Medium",
      size: 0.140,
      color: NSColor(red: 0.08, green: 0.14, blue: 0.22, alpha: 1),
      depth: 0.004)
    title.name = "AlpineCampaignHook"
    title.position = [-1.10, 1.54, 2.62]
    root.addChild(title)
    let kicker = NewSceneSupport.text(
      "DAILY FIBER FOR WHAT'S NEXT",
      fontName: "SFMono-Medium",
      size: 0.056,
      color: NSColor(red: 0.16, green: 0.29, blue: 0.44, alpha: 0.82),
      depth: 0.003)
    kicker.position = [-1.09, 1.30, 2.62]
    root.addChild(kicker)
  }

  private static func mountainBandMesh(
    width: Float,
    bottom: Float,
    segments: Int,
    top: (Float) -> Float
  ) throws -> MeshResource {
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var textureCoordinates: [SIMD2<Float>] = []
    var indices: [UInt32] = []
    for segment in 0...segments {
      let t = Float(segment) / Float(segments)
      let x = (t - 0.5) * width
      positions += [[x, bottom, 0], [x, top(x), 0]]
      normals += [[0, 0, 1], [0, 0, 1]]
      textureCoordinates += [[t, 0], [t, 1]]
    }
    for segment in 0..<segments {
      let a = UInt32(segment * 2)
      indices += [a, a + 1, a + 2, a + 1, a + 3, a + 2]
    }
    var descriptor = MeshDescriptor(name: "AlpineMountainBand")
    descriptor.positions = .init(positions)
    descriptor.normals = .init(normals)
    descriptor.textureCoordinates = .init(textureCoordinates)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }
}
