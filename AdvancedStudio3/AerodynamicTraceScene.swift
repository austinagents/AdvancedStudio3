import AppKit
import RealityKit

@MainActor
final class AerodynamicTraceScene {
  let root: Entity
  let camera: PerspectiveCamera

  private let product: ModelEntity
  private let shadow: ModelEntity
  private let platform: ModelEntity
  private let airflow: [ModelEntity]
  private let ribs: [ModelEntity]
  private let shells: [ModelEntity]
  private let keyLight: SpotLight

  private init(
    root: Entity, camera: PerspectiveCamera, product: ModelEntity, shadow: ModelEntity,
    platform: ModelEntity, airflow: [ModelEntity], ribs: [ModelEntity],
    shells: [ModelEntity], keyLight: SpotLight
  ) {
    self.root = root
    self.camera = camera
    self.product = product
    self.shadow = shadow
    self.platform = platform
    self.airflow = airflow
    self.ribs = ribs
    self.shells = shells
    self.keyLight = keyLight
  }

  static func load(imageURL: URL) async throws -> AerodynamicTraceScene {
    let root = Entity()
    root.name = "AerodynamicTracePearlWindLab"
    addCampaignHook(
      to: root, title: "DAILY FIBER. MADE EASY.", kicker: "LIGHT BY DESIGN.",
      color: NSColor(red: 0.075, green: 0.105, blue: 0.10, alpha: 1))

    let pearlWall = material(
      NSColor(red: 0.89, green: 0.91, blue: 0.89, alpha: 1), roughness: 0.82)
    let pearlFloor = material(
      NSColor(red: 0.67, green: 0.70, blue: 0.68, alpha: 1), roughness: 0.68)
    let satinPearl = material(
      NSColor(red: 0.76, green: 0.82, blue: 0.80, alpha: 1),
      roughness: 0.30, metallic: 0.54)
    let coolAlloy = material(
      NSColor(red: 0.43, green: 0.58, blue: 0.57, alpha: 1),
      roughness: 0.26, metallic: 0.72)
    Batch2SceneSupport.texturedCyclorama(root: root, floor: pearlFloor, wall: pearlWall)

    var shells: [ModelEntity] = []
    for side: Float in [-1, 1] {
      let shell = ModelEntity(
        mesh: try windShellMesh(side: side), materials: [pearlWall])
      shell.name = side < 0 ? "LeftPearlWindShell" : "RightPearlWindShell"
      shell.position = [0, -0.05, -4.25]
      root.addChild(shell)
      shells.append(shell)
    }

    var ribs: [ModelEntity] = []
    for depthIndex in 0..<3 {
      for side: Float in [-1, 1] {
        let rib = ModelEntity(
          mesh: try curvedSideRibMesh(
            side: side, thickness: 0.055 + Float(depthIndex) * 0.008,
            depth: 0.18 + Float(depthIndex) * 0.035),
          materials: [depthIndex.isMultiple(of: 2) ? satinPearl : coolAlloy])
        rib.name = side < 0
          ? "LeftWindRib\(depthIndex)" : "RightWindRib\(depthIndex)"
        rib.position = [0, -0.42, -1.72 - Float(depthIndex) * 0.78]
        root.addChild(rib)
        ribs.append(rib)
      }
    }

    let airflowColors = [
      NSColor(red: 0.12, green: 0.63, blue: 0.59, alpha: 1),
      NSColor(red: 0.20, green: 0.72, blue: 0.48, alpha: 1),
      NSColor(red: 0.23, green: 0.60, blue: 0.75, alpha: 1),
      NSColor(red: 0.52, green: 0.76, blue: 0.61, alpha: 1),
      NSColor(red: 0.29, green: 0.70, blue: 0.76, alpha: 1),
      NSColor(red: 0.13, green: 0.54, blue: 0.43, alpha: 1),
    ]
    var airflow: [ModelEntity] = []
    for index in 0..<6 {
      var ribbonMaterial = UnlitMaterial(color: airflowColors[index])
      ribbonMaterial.blending = .transparent(
        opacity: .init(floatLiteral: index.isMultiple(of: 2) ? 0.52 : 0.36))
      ribbonMaterial.faceCulling = .none
      let ribbon = ModelEntity(
        mesh: try airflowRibbonMesh(index: index), materials: [ribbonMaterial])
      ribbon.name = "SculptedAirflowRibbon\(index)"
      ribbon.position = [0, 0, -1.02 - Float(index % 3) * 0.18]
      root.addChild(ribbon)
      airflow.append(ribbon)
    }

    let platform = ModelEntity(
      mesh: .generateCylinder(height: 0.20, radius: 0.98), materials: [satinPearl])
    platform.name = "PearlWindPedestal"
    platform.position = [0, -2.19, 0.02]
    root.addChild(platform)
    let platformCap = ModelEntity(
      mesh: .generateCylinder(height: 0.035, radius: 0.83), materials: [pearlFloor])
    platformCap.position = [0, 0.118, 0]
    platform.addChild(platformCap)

    let product = try await Batch2SceneSupport.product(imageURL, height: 2.62)
    product.position = [0, -0.69, 0.72]
    root.addChild(product)
    let shadow = Batch2SceneSupport.addContactShadow(to: root, width: 2.02)
    shadow.position = [0, -2.06, 0.61]

    let lights = try await Batch2SceneSupport.light(
      root: root, ibl: "cloudy_netted_nursery", exponent: 1.03,
      keyColor: NSColor(red: 0.94, green: 0.99, blue: 1, alpha: 1),
      rimColor: NSColor(red: 0.27, green: 0.72, blue: 0.66, alpha: 1),
      keyIntensity: 34_000, rimIntensity: 15_000)
    let camera = Batch2SceneSupport.camera(root: root, focalLength: 46)
    let scene = AerodynamicTraceScene(
      root: root, camera: camera, product: product, shadow: shadow, platform: platform,
      airflow: airflow, ribs: ribs, shells: shells, keyLight: lights.key)
    scene.apply(frameIndex: 0)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 449)
    let establish = NewSceneSupport.smooth(frame, 0, 104)
    let hero = NewSceneSupport.smooth(frame, 12, 112)
    let settle = NewSceneSupport.smooth(frame, 112, 236)

    for (index, shell) in shells.enumerated() {
      let side: Float = index == 0 ? -1 : 1
      let local = NewSceneSupport.smooth(frame, index * 8, 92 + index * 8)
      shell.position.x = side * NewSceneSupport.mix(0.56, 0, local)
      shell.orientation = simd_quatf(
        angle: side * NewSceneSupport.mix(0.11, 0.018, local), axis: [0, 1, 0])
    }
    for (index, rib) in ribs.enumerated() {
      let depthIndex = index / 2
      let side: Float = index.isMultiple(of: 2) ? -1 : 1
      let local = NewSceneSupport.smooth(frame, 4 + depthIndex * 11, 74 + depthIndex * 13)
      rib.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.84, 1, local))
      rib.orientation = simd_quatf(
        angle: side * (NewSceneSupport.mix(0.38, 0.045, local)
          + sin(Float(frame) * 0.008 + Float(depthIndex)) * 0.012 * settle),
        axis: [0, 1, 0])
    }
    for (index, ribbon) in airflow.enumerated() {
      let local = NewSceneSupport.smooth(frame, 6 + index * 7, 76 + index * 9)
      ribbon.scale = [NewSceneSupport.mix(0.70, 1, local), 1, 1]
      ribbon.position.x = NewSceneSupport.mix(-3.65 - Float(index % 2) * 0.25, 0, local)
        + sin(Float(frame) * 0.014 + Float(index) * 0.82) * 0.065 * establish
      ribbon.position.y = cos(Float(frame) * 0.010 + Float(index) * 0.71) * 0.026 * settle
    }

    product.isEnabled = true
    product.position = NewSceneSupport.mix([0, -1.08, 0.72], [0, -0.69, 0.72], hero)
    product.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.90, 1, hero))
    product.orientation = simd_quatf(
      angle: NewSceneSupport.mix(-0.075, 0.010, settle), axis: [0, 1, 0])
    platform.position.y = NewSceneSupport.mix(-2.46, -2.19, hero)
    shadow.isEnabled = true
    shadow.position.y = platform.position.y + 0.13
    shadow.scale = SIMD3<Float>(repeating: NewSceneSupport.mix(0.80, 1, hero))

    camera.look(
      at: [0, -0.34, -0.82],
      from: NewSceneSupport.mix([-0.34, 0.28, 12.82], [0.15, 0.10, 12.22], settle),
      relativeTo: root)
    keyLight.look(
      at: [0, -0.42, 0],
      from: NewSceneSupport.mix([-4.7, 5.9, 7.7], [-4.0, 5.5, 8.1], settle),
      relativeTo: root)
  }

  private static func addCampaignHook(
    to root: Entity, title: String, kicker: String, color: NSColor
  ) {
    let titleEntity = NewSceneSupport.text(
      title, fontName: "AvenirNext-DemiBold", size: 0.101, color: color, depth: 0.005)
    titleEntity.position = [-1.12, 1.67, 3.0]
    root.addChild(titleEntity)
    let kickerEntity = NewSceneSupport.text(
      kicker, fontName: "SFMono-Medium", size: 0.066,
      color: color.withAlphaComponent(0.70), depth: 0.003)
    kickerEntity.position = [-1.11, 1.45, 3.0]
    root.addChild(kickerEntity)
  }

  private static func material(
    _ color: NSColor, roughness: Float, metallic: Float = 0
  ) -> PhysicallyBasedMaterial {
    var material = PhysicallyBasedMaterial()
    material.baseColor = .init(tint: color)
    material.roughness = .init(floatLiteral: roughness)
    material.metallic = .init(floatLiteral: metallic)
    return material
  }

  private static func windShellMesh(side: Float) throws -> MeshResource {
    let rows = 28
    let columns = 9
    var positions: [SIMD3<Float>] = []
    var textureCoordinates: [SIMD2<Float>] = []
    var indices: [UInt32] = []
    for row in 0...rows {
      let v = Float(row) / Float(rows)
      let y = NewSceneSupport.mix(-2.88, 3.70, v)
      let vertical = v * 2 - 1
      let inner = 1.72 + 0.46 * vertical * vertical
      for column in 0...columns {
        let u = Float(column) / Float(columns)
        let x = side * NewSceneSupport.mix(inner, 4.55, u)
        let z = -0.30 - pow(u, 0.72) * 1.15 + sin(v * .pi) * 0.10
        positions.append([x, y, z])
        textureCoordinates.append([u * 2.2, v * 2.4])
      }
    }
    for row in 0..<rows {
      for column in 0..<columns {
        let a = UInt32(row * (columns + 1) + column)
        let b = a + 1
        let c = a + UInt32(columns + 1)
        let d = c + 1
        if side < 0 {
          indices += [a, c, b, b, c, d]
        } else {
          indices += [a, b, c, b, d, c]
        }
      }
    }
    var descriptor = MeshDescriptor(name: "CurvedPearlWindShell")
    descriptor.positions = .init(positions)
    descriptor.textureCoordinates = .init(textureCoordinates)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }

  private static func curvedSideRibMesh(
    side: Float, thickness: Float, depth: Float
  ) throws -> MeshResource {
    let segments = 44
    var centerline: [SIMD3<Float>] = []
    for segment in 0...segments {
      let t = Float(segment) / Float(segments)
      let vertical = t * 2 - 1
      let x = side * (2.28 - 0.70 * (1 - vertical * vertical))
      let y = NewSceneSupport.mix(-2.45, 2.75, t)
      centerline.append([x, y, 0])
    }
    var positions: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    for segment in 0...segments {
      let previous = centerline[max(0, segment - 1)]
      let next = centerline[min(segments, segment + 1)]
      let tangent = simd_normalize(next - previous)
      let normal = simd_normalize(SIMD3<Float>(-tangent.y, tangent.x, 0))
      for z: Float in [-depth / 2, depth / 2] {
        positions += [
          centerline[segment] - normal * thickness + [0, 0, z],
          centerline[segment] + normal * thickness + [0, 0, z],
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
    var descriptor = MeshDescriptor(name: "OpenCurvedWindRib")
    descriptor.positions = .init(positions)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }

  private static func airflowRibbonMesh(index: Int) throws -> MeshResource {
    let segments = 72
    let bases: [Float] = [-1.38, -0.92, -0.48, -0.02, 0.44, 0.90]
    var points: [SIMD3<Float>] = []
    for segment in 0...segments {
      let t = Float(segment) / Float(segments)
      let x = NewSceneSupport.mix(-3.35, 3.35, t)
      let envelope = sin(t * .pi)
      let direction: Float = bases[index] < -0.20 ? -1 : 1
      let deflection = direction * envelope * (0.16 + Float(index % 3) * 0.045)
      let y = bases[index] + deflection
        + sin(t * .pi * 2 + Float(index) * 0.64) * 0.070 * envelope
      let z = sin(t * .pi + Float(index) * 0.38) * 0.13
      points.append([x, y, z])
    }
    let width: Float = index.isMultiple(of: 2) ? 0.025 : 0.017
    var positions: [SIMD3<Float>] = []
    var textureCoordinates: [SIMD2<Float>] = []
    var indices: [UInt32] = []
    for segment in 0...segments {
      let previous = points[max(0, segment - 1)]
      let next = points[min(segments, segment + 1)]
      let tangent = simd_normalize(next - previous)
      let normal = simd_normalize(SIMD3<Float>(-tangent.y, tangent.x, 0))
      positions += [points[segment] - normal * width, points[segment] + normal * width]
      let u = Float(segment) / Float(segments)
      textureCoordinates += [[u, 0], [u, 1]]
    }
    for segment in 0..<segments {
      let a = UInt32(segment * 2)
      indices += [a, a + 1, a + 2, a + 1, a + 3, a + 2]
    }
    var descriptor = MeshDescriptor(name: "SculptedAirflowRibbon")
    descriptor.positions = .init(positions)
    descriptor.textureCoordinates = .init(textureCoordinates)
    descriptor.primitives = .triangles(indices)
    return try .generate(from: [descriptor])
  }
}
