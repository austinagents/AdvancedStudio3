import AppKit
import RealityKit

@MainActor
final class AnamorphicCourtScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let columns: [ModelEntity]
  private let columnHomes: [SIMD3<Float>]
  private let product: ModelEntity
  private let sun: DirectionalLight
  private let brand: ModelEntity

  private init(
    root: Entity, camera: PerspectiveCamera, columns: [ModelEntity], homes: [SIMD3<Float>],
    product: ModelEntity, sun: DirectionalLight, brand: ModelEntity
  ) {
    self.root = root
    self.camera = camera
    self.columns = columns
    self.columnHomes = homes
    self.product = product
    self.sun = sun
    self.brand = brand
  }

  static func load(imageURL: URL) async throws -> AnamorphicCourtScene {
    let root = try await NewSceneSupport.entity("AnamorphicCourt")
    let courtyard = try NewSceneSupport.child("CourtyardRoot", in: root)
    let field = try NewSceneSupport.child("ColumnFieldRoot", in: root)
    let productRoot = try NewSceneSupport.child("ProductRoot", in: root)
    let brandRoot = try NewSceneSupport.child("BrandRoot", in: root)
    let cameraRail = try NewSceneSupport.child("CameraRail", in: root)
    let sunRig = try NewSceneSupport.child("SunRig", in: root)

    let travertine = try await NewSceneSupport.surfaceMaterial(
      id: "cliff_side",
      tint: NSColor(red: 0.91, green: 0.72, blue: 0.48, alpha: 1))
    let vermilion = try await NewSceneSupport.surfaceMaterial(
      id: "rust_coarse_01",
      tint: NSColor(red: 0.82, green: 0.08, blue: 0.035, alpha: 1))
    let ultramarine = try await NewSceneSupport.surfaceMaterial(
      id: "metal_plate_02",
      tint: NSColor(red: 0.02, green: 0.12, blue: 0.62, alpha: 1), metallic: true)

    let back = ModelEntity(
      mesh: .generateBox(width: 20, height: 15, depth: 0.6, cornerRadius: 0.25),
      materials: [travertine])
    back.position = [0, 1.2, -5.2]
    courtyard.addChild(back)
    let floor = ModelEntity(
      mesh: .generateBox(width: 20, height: 0.45, depth: 18, cornerRadius: 0.12),
      materials: [travertine])
    floor.position = [0, -4.15, 1.5]
    courtyard.addChild(floor)
    var jointMaterial = PhysicallyBasedMaterial()
    jointMaterial.baseColor = .init(tint: NSColor(red: 0.18, green: 0.11, blue: 0.07, alpha: 1))
    jointMaterial.roughness = 0.86
    for index in -4...4 {
      let joint = ModelEntity(
        mesh: .generateBox(width: 0.026, height: 0.018, depth: 15.5, cornerRadius: 0.004),
        materials: [jointMaterial])
      joint.position = [Float(index) * 1.75, -3.91, 1.1]
      courtyard.addChild(joint)
    }
    for level in 0..<5 {
      let reveal = ModelEntity(
        mesh: .generateBox(width: 16.5, height: 0.025, depth: 0.022, cornerRadius: 0.004),
        materials: [jointMaterial])
      reveal.position = [0, -2.65 + Float(level) * 1.8, -4.88]
      courtyard.addChild(reveal)
    }
    for side: Float in [-1, 1] {
      let arcade = ModelEntity(
        mesh: .generateBox(width: 0.55, height: 11, depth: 15, cornerRadius: 0.15),
        materials: [travertine])
      arcade.position = [side * 8.4, 0, 1]
      courtyard.addChild(arcade)
    }

    let silhouette: [(Float, Float)] = [
      (-1.8, -2.4), (-1.8, -1.2), (-1.65, 0), (-1.25, 1.3), (-0.55, 2.25),
      (0.35, 2.45), (1.2, 1.8), (1.65, 0.75), (1.8, -0.55), (1.7, -1.8),
      (1.05, -2.5), (0.2, -2.75), (-0.75, -2.65),
    ]
    var columns: [ModelEntity] = []
    var homes: [SIMD3<Float>] = []
    for (index, point) in silhouette.enumerated() {
      for depthIndex in 0..<2 {
        let height = 5.4 + Float((index + depthIndex) % 4) * 0.7
        let column = ModelEntity(
          mesh: .generateBox(width: 0.52, height: height, depth: 0.72, cornerRadius: 0.12),
          materials: [(index + depthIndex).isMultiple(of: 3) ? ultramarine : vermilion])
        let home = SIMD3<Float>(
          point.0 + Float(depthIndex) * 0.24, point.1 - height * 0.5, Float(depthIndex) * 0.8)
        column.position = home
        field.addChild(column)
        columns.append(column)
        homes.append(home)
      }
    }
    let product = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.35, name: "AnamorphicProduct", roughness: 0.22)
    product.position = [0.45, -2.15, 1.25]
    productRoot.addChild(product)
    let plinth = ModelEntity(
      mesh: .generateBox(width: 3.8, height: 0.32, depth: 2.5, cornerRadius: 0.14),
      materials: [ultramarine])
    plinth.position = [0.45, -3.65, 0.8]
    productRoot.addChild(plinth)
    let plinthReveal = ModelEntity(
      mesh: .generateBox(width: 3.62, height: 0.055, depth: 2.32, cornerRadius: 0.08),
      materials: [jointMaterial])
    plinthReveal.position = [0.45, -3.84, 0.8]
    productRoot.addChild(plinthReveal)
    let brand = NewSceneSupport.text(
      "ONE OBJECT. EVERY ANGLE.", fontName: "AvenirNext-Medium", size: 0.17,
      color: NSColor(red: 0.08, green: 0.06, blue: 0.035, alpha: 1))
    brand.position = [-0.95, -3.15, 1.4]

    let ibl = try await NewSceneSupport.imageLight(
      id: "ferndale_studio_02", exponent: 1.35, parent: sunRig)
    NewSceneSupport.receiveIBL([back, floor, product, plinth, plinthReveal] + columns, light: ibl)
    NewSceneSupport.receiveIBL(in: root, light: ibl)
    let sun = DirectionalLight()
    sun.light = .init(color: NSColor(red: 1, green: 0.76, blue: 0.48, alpha: 1), intensity: 11_000)
    sunRig.addChild(sun)
    let bounce = PointLight()
    bounce.light = .init(
      color: NSColor(red: 0.32, green: 0.5, blue: 1, alpha: 1), intensity: 20_000,
      attenuationRadius: 12)
    bounce.position = [-5, 0, 3]
    sunRig.addChild(bounce)
    let camera = NewSceneSupport.camera(focalLength: 78, name: "AnamorphicRailCamera")
    cameraRail.addChild(camera)
    let scene = AnamorphicCourtScene(
      root: root, camera: camera, columns: columns, homes: homes, product: product, sun: sun,
      brand: brand)
    scene.apply(frameIndex: 359)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 359)
    let align = NewSceneSupport.smooth(frame, 0, 176)
    let clear = NewSceneSupport.smooth(frame, 180, 270)
    let hero = NewSceneSupport.smooth(frame, 270, 359)
    for (index, column) in columns.enumerated() {
      let home = columnHomes[index]
      let scrambled = SIMD3<Float>(
        home.x * 1.7 + sin(Float(index) * 2.1) * 2.4, home.y + cos(Float(index) * 1.3) * 1.25,
        home.z + sin(Float(index)) * 3.4)
      let radialDelay = abs(home.x) * 8 + abs(home.y + 1.2) * 4
      let localClear = NewSceneSupport.smooth(frame, 184 + Int(radialDelay), 234 + Int(radialDelay))
      column.position = NewSceneSupport.mix(scrambled, home, align)
      column.position.y -= localClear * 9.5
      column.orientation = simd_quatf(
        angle: (1 - align) * sin(Float(index) * 1.7) * 0.5, axis: [0, 1, 0])
    }
    product.isEnabled = frame >= 180
    product.position.y = NewSceneSupport.mix(-3.2, -2.15, clear)
    product.scale = .init(repeating: NewSceneSupport.mix(0.78, 1, clear))
    brand.isEnabled = frame >= 292
    brand.components.set(OpacityComponent(opacity: NewSceneSupport.smooth(frame, 292, 332)))
    let cameraFrom = NewSceneSupport.mix([-7.8, 0.4, 5.8], [2.7 + hero * 0.08, -0.1, 13.4], clear)
    let cameraTarget = NewSceneSupport.mix([-1.4, 0.2, 0], [0.05, -1.95, 0.5], clear)
    camera.look(at: cameraTarget, from: cameraFrom, relativeTo: root)
    sun.look(
      at: [0, -1, 0], from: NewSceneSupport.mix([-7, 8, -4], [6, 9, 2], align), relativeTo: root)
  }
}
