import AppKit
import ImageIO
import RealityKit

@MainActor
enum Batch2ProductionScene {
  enum Style: Sendable {
    case coastalRelay, glasshouseRise, alpineWake, kineticFacade, rainlightPavilion
    case observatoryTransit, aerodynamicTrace, chromaticElevator, terracedDawn, haloStage
  }

  case coastalRelay(CoastalRelayScene)
  case glasshouseRise(GlasshouseRiseScene)
  case alpineWake(AlpineWakeScene)
  case kineticFacade(KineticFacadeScene)
  case rainlightPavilion(RainlightPavilionScene)
  case observatoryTransit(ObservatoryTransitScene)
  case aerodynamicTrace(AerodynamicTraceScene)
  case chromaticElevator(ChromaticElevatorScene)
  case terracedDawn(TerracedDawnScene)
  case haloStage(HaloStageScene)

  static func load(style: Style, imageURL: URL) async throws -> Batch2ProductionScene {
    switch style {
    case .coastalRelay: .coastalRelay(try await CoastalRelayScene.load(imageURL: imageURL))
    case .glasshouseRise: .glasshouseRise(try await GlasshouseRiseScene.load(imageURL: imageURL))
    case .alpineWake: .alpineWake(try await AlpineWakeScene.load(imageURL: imageURL))
    case .kineticFacade: .kineticFacade(try await KineticFacadeScene.load(imageURL: imageURL))
    case .rainlightPavilion: .rainlightPavilion(try await RainlightPavilionScene.load(imageURL: imageURL))
    case .observatoryTransit: .observatoryTransit(try await ObservatoryTransitScene.load(imageURL: imageURL))
    case .aerodynamicTrace: .aerodynamicTrace(try await AerodynamicTraceScene.load(imageURL: imageURL))
    case .chromaticElevator: .chromaticElevator(try await ChromaticElevatorScene.load(imageURL: imageURL))
    case .terracedDawn: .terracedDawn(try await TerracedDawnScene.load(imageURL: imageURL))
    case .haloStage: .haloStage(try await HaloStageScene.load(imageURL: imageURL))
    }
  }

  var root: Entity {
    switch self {
    case .coastalRelay(let scene): scene.root
    case .glasshouseRise(let scene): scene.root
    case .alpineWake(let scene): scene.root
    case .kineticFacade(let scene): scene.root
    case .rainlightPavilion(let scene): scene.root
    case .observatoryTransit(let scene): scene.root
    case .aerodynamicTrace(let scene): scene.root
    case .chromaticElevator(let scene): scene.root
    case .terracedDawn(let scene): scene.root
    case .haloStage(let scene): scene.root
    }
  }

  var camera: PerspectiveCamera {
    switch self {
    case .coastalRelay(let scene): scene.camera
    case .glasshouseRise(let scene): scene.camera
    case .alpineWake(let scene): scene.camera
    case .kineticFacade(let scene): scene.camera
    case .rainlightPavilion(let scene): scene.camera
    case .observatoryTransit(let scene): scene.camera
    case .aerodynamicTrace(let scene): scene.camera
    case .chromaticElevator(let scene): scene.camera
    case .terracedDawn(let scene): scene.camera
    case .haloStage(let scene): scene.camera
    }
  }

  func apply(frameIndex: Int) {
    switch self {
    case .coastalRelay(let scene): scene.apply(frameIndex: frameIndex)
    case .glasshouseRise(let scene): scene.apply(frameIndex: frameIndex)
    case .alpineWake(let scene): scene.apply(frameIndex: frameIndex)
    case .kineticFacade(let scene): scene.apply(frameIndex: frameIndex)
    case .rainlightPavilion(let scene): scene.apply(frameIndex: frameIndex)
    case .observatoryTransit(let scene): scene.apply(frameIndex: frameIndex)
    case .aerodynamicTrace(let scene): scene.apply(frameIndex: frameIndex)
    case .chromaticElevator(let scene): scene.apply(frameIndex: frameIndex)
    case .terracedDawn(let scene): scene.apply(frameIndex: frameIndex)
    case .haloStage(let scene): scene.apply(frameIndex: frameIndex)
    }
  }
}

@MainActor
enum Batch2SceneSupport {
  struct Lighting {
    let key: SpotLight
    let rim: SpotLight
    let fill: DirectionalLight
  }

  static func product(_ imageURL: URL, height: Float = 2.8) async throws -> ModelEntity {
    let aspect = imageAspectRatio(imageURL)
    let fittedHeight = min(height * 1.24, 3.80 / max(aspect, 0.01))
    let texture = try await TextureResource(contentsOf: imageURL)
    var material = PhysicallyBasedMaterial()
    material.baseColor = .init(tint: .white, texture: .init(texture))
    material.roughness = .init(floatLiteral: 0.24)
    material.metallic = .init(floatLiteral: 0.0)
    material.emissiveColor = .init(color: .white, texture: .init(texture))
    material.emissiveIntensity = 0.14
    material.blending = .transparent(opacity: .init(floatLiteral: 1))
    material.opacityThreshold = 0.01
    material.faceCulling = .none
    let product = ModelEntity(
      mesh: .generatePlane(width: fittedHeight * aspect, height: fittedHeight),
      materials: [material])
    product.name = "HeroProduct"
    return product
  }

  static func addHook(
    to root: Entity, title: String, kicker: String, color: NSColor = .white,
    x: Float = -1.0
  ) {
    let titleEntity = NewSceneSupport.text(
      title, fontName: "AvenirNext-DemiBold", size: 0.125, color: color, depth: 0.006)
    titleEntity.name = "CampaignHook"
    titleEntity.position = [x, 1.66, 3.0]
    root.addChild(titleEntity)
    let kickerEntity = NewSceneSupport.text(
      kicker.uppercased(), fontName: "SFMono-Medium", size: 0.074,
      color: color.withAlphaComponent(0.72), depth: 0.003)
    kickerEntity.name = "CampaignKicker"
    kickerEntity.position = [x + 0.01, 1.45, 3.0]
    root.addChild(kickerEntity)
  }

  private static func imageAspectRatio(_ url: URL) -> Float {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
      let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
      height.floatValue > 0
    else { return 0.72 }
    return width.floatValue / height.floatValue
  }

  static func addContactShadow(to root: Entity, width: Float = 2.7) -> ModelEntity {
    var material = UnlitMaterial(color: NSColor(white: 0, alpha: 0.38))
    material.blending = .transparent(opacity: .init(floatLiteral: 0.38))
    let shadow = ModelEntity(
      mesh: .generatePlane(width: width, depth: width * 0.36, cornerRadius: width * 0.16),
      materials: [material])
    shadow.name = "HeroContactShadow"
    root.addChild(shadow)
    return shadow
  }

  static func addHeroField(
    to root: Entity, color: NSColor, accent: NSColor,
    position: SIMD3<Float> = [0, -0.68, 0.06]
  ) {
    var fieldMaterial = UnlitMaterial(color: color)
    fieldMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.88))
    let field = ModelEntity(
      mesh: .generatePlane(width: 2.15, height: 3.45, cornerRadius: 0.54),
      materials: [fieldMaterial])
    field.name = "HeroContrastField"
    field.position = position
    root.addChild(field)

    var accentMaterial = UnlitMaterial(color: accent)
    accentMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.78))
    let accentLine = ModelEntity(
      mesh: .generateBox(width: 1.10, height: 0.028, depth: 0.025, cornerRadius: 0.014),
      materials: [accentMaterial])
    accentLine.name = "HeroAccentLine"
    accentLine.position = [position.x, position.y - 1.92, position.z + 0.02]
    root.addChild(accentLine)
  }

  static func light(
    root: Entity, ibl: String, exponent: Float,
    keyColor: NSColor, rimColor: NSColor,
    keyIntensity: Float = 30_000, rimIntensity: Float = 20_000
  ) async throws -> Lighting {
    let rig = Entity()
    rig.name = "ProductionLightRig"
    root.addChild(rig)
    let imageLight = try await NewSceneSupport.imageLight(id: ibl, exponent: exponent, parent: rig)
    NewSceneSupport.receiveIBL(in: root, light: imageLight)
    let key = SpotLight()
    key.light = .init(
      color: keyColor, intensity: keyIntensity, innerAngleInDegrees: 18,
      outerAngleInDegrees: 54, attenuationRadius: 25)
    key.look(at: [0, -0.6, 0], from: [-5.5, 6.2, 7.8], relativeTo: root)
    rig.addChild(key)
    let rim = SpotLight()
    rim.light = .init(
      color: rimColor, intensity: rimIntensity, innerAngleInDegrees: 22,
      outerAngleInDegrees: 60, attenuationRadius: 24)
    rim.look(at: [0, -0.4, 0], from: [5.5, 3.6, 5.8], relativeTo: root)
    rig.addChild(rim)
    let fill = DirectionalLight()
    fill.light = .init(color: keyColor, intensity: 3_200)
    fill.look(at: [0, 0, -1], from: [4, 7, 5], relativeTo: root)
    rig.addChild(fill)
    return Lighting(key: key, rim: rim, fill: fill)
  }

  static func camera(root: Entity, focalLength: Float = 48) -> PerspectiveCamera {
    let camera = NewSceneSupport.camera(focalLength: focalLength, name: "Batch2ProductionCamera")
    root.addChild(camera)
    return camera
  }

  static func texturedCyclorama(
    root: Entity, floor: PhysicallyBasedMaterial, wall: PhysicallyBasedMaterial,
    width: Float = 15, depth: Float = 18
  ) {
    let floorEntity = ModelEntity(
      mesh: .generateBox(width: width, height: 0.24, depth: depth, cornerRadius: 0.08),
      materials: [floor])
    floorEntity.position = [0, -3.18, -2.0]
    root.addChild(floorEntity)
    let wallEntity = ModelEntity(
      mesh: .generateBox(width: width, height: 12, depth: 0.28, cornerRadius: 0.08),
      materials: [wall])
    wallEntity.position = [0, 2.35, -9.0]
    root.addChild(wallEntity)
  }

  static func galleryCyclorama(root: Entity, color: NSColor, width: Float = 15, depth: Float = 18) {
    var floorMaterial = PhysicallyBasedMaterial()
    floorMaterial.baseColor = .init(tint: color)
    floorMaterial.roughness = 0.72
    let floor = ModelEntity(
      mesh: .generateBox(width: width, height: 0.24, depth: depth, cornerRadius: 0.08),
      materials: [floorMaterial])
    floor.position = [0, -3.18, -2]
    root.addChild(floor)

    var wallMaterial = PhysicallyBasedMaterial()
    wallMaterial.baseColor = .init(tint: color.blended(withFraction: 0.12, of: .white) ?? color)
    wallMaterial.roughness = 0.86
    let wall = ModelEntity(
      mesh: .generateBox(width: width, height: 12, depth: 0.28, cornerRadius: 0.08),
      materials: [wallMaterial])
    wall.position = [0, 2.35, -9]
    root.addChild(wall)
  }

  static func ringMesh(radius: Float, thickness: Float, depth: Float = 0.06) throws -> MeshResource {
    let segments = 72
    var positions: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    for segment in 0...segments {
      let angle = Float(segment) / Float(segments) * .pi * 2
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
    var descriptor = MeshDescriptor(name: "Batch2Ring")
    descriptor.positions = .init(positions)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }

  static func terrainMesh(
    width: Float, depth: Float, columns: Int = 36, rows: Int = 36,
    height: (Float, Float) -> Float
  ) throws -> MeshResource {
    var positions: [SIMD3<Float>] = []
    var textureCoordinates: [SIMD2<Float>] = []
    for row in 0...rows {
      for column in 0...columns {
        let u = Float(column) / Float(columns)
        let v = Float(row) / Float(rows)
        let x = (u - 0.5) * width
        let z = (v - 0.5) * depth
        positions.append([x, height(x, z), z])
        textureCoordinates.append([u * 4, v * 4])
      }
    }
    var indices: [UInt32] = []
    for row in 0..<rows {
      for column in 0..<columns {
        let a = UInt32(row * (columns + 1) + column)
        let b = a + 1
        let c = a + UInt32(columns + 1)
        let d = c + 1
        indices += [a, c, b, b, c, d]
      }
    }
    var descriptor = MeshDescriptor(name: "Batch2Terrain")
    descriptor.positions = .init(positions)
    descriptor.textureCoordinates = .init(textureCoordinates)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }

  static func ribbonMesh(points: [SIMD3<Float>], width: Float) throws -> MeshResource {
    var positions: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    for (index, point) in points.enumerated() {
      let previous = points[max(0, index - 1)]
      let next = points[min(points.count - 1, index + 1)]
      let tangent = simd_normalize(next - previous)
      let normal = simd_normalize(simd_cross(tangent, SIMD3<Float>(0, 0, 1)))
      positions += [point - normal * width, point + normal * width]
    }
    for index in 0..<(points.count - 1) {
      let a = UInt32(index * 2)
      indices += [a, a + 1, a + 2, a + 1, a + 3, a + 2]
    }
    var descriptor = MeshDescriptor(name: "Batch2Ribbon")
    descriptor.positions = .init(positions)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }
}
