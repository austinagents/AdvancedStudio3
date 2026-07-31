import AppKit
import RealityKit

@MainActor
final class VacuumCastScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let membrane: ModelEntity
  private let product: ModelEntity
  private let pedestal: ModelEntity
  private let edgeLight: SpotLight
  private let copy: ModelEntity

  private init(
    root: Entity, camera: PerspectiveCamera, membrane: ModelEntity, product: ModelEntity,
    pedestal: ModelEntity, edgeLight: SpotLight, copy: ModelEntity
  ) {
    self.root = root
    self.camera = camera
    self.membrane = membrane
    self.product = product
    self.pedestal = pedestal
    self.edgeLight = edgeLight
    self.copy = copy
  }

  static func load(imageURL: URL) async throws -> VacuumCastScene {
    let root = try await NewSceneSupport.entity("VacuumCast")
    let cyclorama = try NewSceneSupport.child("CycloramaRoot", in: root)
    let membraneRoot = try NewSceneSupport.child("MembraneRoot", in: root)
    let productRoot = try NewSceneSupport.child("ProductRoot", in: root)
    let typography = try NewSceneSupport.child("TypographyRoot", in: root)
    let cameraRig = try NewSceneSupport.child("CameraRig", in: root)
    let lights = try NewSceneSupport.child("LightRoot", in: root)

    let warmStone = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.86, green: 0.82, blue: 0.72, alpha: 1))
    let cobalt = try await NewSceneSupport.surfaceMaterial(
      id: "metal_plate_02",
      tint: NSColor(red: 0.035, green: 0.12, blue: 0.48, alpha: 1), metallic: true)
    var membraneMaterial = PhysicallyBasedMaterial()
    membraneMaterial.baseColor = .init(
      tint: NSColor(red: 0.95, green: 0.39, blue: 0.14, alpha: 0.93))
    membraneMaterial.roughness = 0.3
    membraneMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.93))
    membraneMaterial.faceCulling = .none

    let wall = ModelEntity(
      mesh: .generateBox(width: 15, height: 16, depth: 0.5, cornerRadius: 0.3),
      materials: [warmStone])
    wall.position = [0, 1, -4.2]
    cyclorama.addChild(wall)
    let floor = ModelEntity(
      mesh: .generateBox(width: 15, height: 0.38, depth: 14, cornerRadius: 0.18),
      materials: [warmStone])
    floor.position = [0, -4.1, 1]
    cyclorama.addChild(floor)
    var revealMaterial = PhysicallyBasedMaterial()
    revealMaterial.baseColor = .init(tint: NSColor(red: 0.055, green: 0.07, blue: 0.09, alpha: 1))
    revealMaterial.roughness = 0.42
    for index in -3...3 {
      let seam = ModelEntity(
        mesh: .generateBox(width: 0.022, height: 11.8, depth: 0.018, cornerRadius: 0.006),
        materials: [revealMaterial])
      seam.position = [Float(index) * 1.82, 0.75, -3.93]
      cyclorama.addChild(seam)
    }
    let pedestalCollar = ModelEntity(
      mesh: .generateCylinder(height: 0.07, radius: 2.13), materials: [revealMaterial])
    pedestalCollar.position = [0.9, -3.98, 0.35]
    productRoot.addChild(pedestalCollar)
    let pedestal = ModelEntity(
      mesh: .generateCylinder(height: 1.0, radius: 2.05), materials: [cobalt])
    pedestal.position = [0.9, -3.55, 0.35]
    productRoot.addChild(pedestal)

    let membrane = ModelEntity(
      mesh: try membraneMesh(form: 0, peel: 0), materials: [membraneMaterial])
    membrane.name = "ContinuousVacuumMembrane"
    membraneRoot.addChild(membrane)
    let product = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.35, name: "VacuumCastProduct", roughness: 0.19)
    product.position = [0.9, -2.3, 0.78]
    productRoot.addChild(product)
    let copy = NewSceneSupport.text(
      "FORM FOLLOWS DESIRE", fontName: "AvenirNext-DemiBold", size: 0.18,
      color: NSColor(red: 0.05, green: 0.09, blue: 0.22, alpha: 1))
    copy.position = [-0.95, -3.05, 0.5]
    typography.addChild(copy)

    let ibl = try await NewSceneSupport.imageLight(
      id: "cloudy_netted_nursery", exponent: 1.55, parent: lights)
    NewSceneSupport.receiveIBL(
      [wall, floor, pedestal, pedestalCollar, membrane, product], light: ibl)
    NewSceneSupport.receiveIBL(in: root, light: ibl)
    let edgeLight = SpotLight()
    edgeLight.light = .init(
      color: NSColor(red: 1, green: 0.42, blue: 0.12, alpha: 1), intensity: 48_000,
      innerAngleInDegrees: 18, outerAngleInDegrees: 55, attenuationRadius: 20)
    lights.addChild(edgeLight)
    let fill = DirectionalLight()
    fill.light = .init(color: NSColor(red: 0.55, green: 0.72, blue: 1, alpha: 1), intensity: 7_500)
    fill.look(at: [0, -1, 0], from: [-4, 6, 5], relativeTo: root)
    lights.addChild(fill)
    let camera = NewSceneSupport.camera(focalLength: 58, name: "VacuumMacroCamera")
    cameraRig.addChild(camera)
    let scene = VacuumCastScene(
      root: root, camera: camera, membrane: membrane, product: product, pedestal: pedestal,
      edgeLight: edgeLight, copy: copy)
    scene.apply(frameIndex: 359)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 359)
    let form = 0.28 + NewSceneSupport.smooth(frame, 0, 174) * 0.72
    let peel = NewSceneSupport.smooth(frame, 180, 270)
    let hero = NewSceneSupport.smooth(frame, 270, 359)
    membrane.model?.mesh = (try? Self.membraneMesh(form: form, peel: peel)) ?? membrane.model!.mesh
    membrane.isEnabled = peel < 0.995
    product.isEnabled = frame >= 176
    product.scale = .init(repeating: NewSceneSupport.mix(0.84, 1, peel))
    pedestal.scale.y = NewSceneSupport.mix(0.12, 1, peel)
    copy.isEnabled = false
    copy.components.set(OpacityComponent(opacity: NewSceneSupport.smooth(frame, 290, 330)))
    edgeLight.look(
      at: [0.7, -1.8, 0], from: NewSceneSupport.mix([-5, 4, 5], [4.8, 5.5, 4], peel),
      relativeTo: root)
    camera.look(
      at: NewSceneSupport.mix([-1.2, 0.4, 0], [0.35, -1.95, 0.2], peel),
      from: NewSceneSupport.mix([-4.7, 0.9, 6.8], [2.7 + hero * 0.12, -0.15, 12.8], peel),
      relativeTo: root)
  }

  private static func membraneMesh(form: Float, peel: Float) throws -> MeshResource {
    let columns = 34
    let rows = 44
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var uvs: [SIMD2<Float>] = []
    var indices: [UInt32] = []
    for row in 0...rows {
      let v = Float(row) / Float(rows)
      let y0 = NewSceneSupport.mix(-4.0, 4.9, v)
      for column in 0...columns {
        let u = Float(column) / Float(columns)
        let x0 = NewSceneSupport.mix(-5.5, 5.5, u)
        let dx = (x0 - 0.9) / 1.65
        let dy = (y0 + 1.65) / 2.15
        let cavity = exp(-(dx * dx + dy * dy) * 2.1) * form
        let tension = sin((x0 + y0) * 2.2 + form * 5) * 0.055 * form * (1 - cavity)
        let release = max(0, peel - v * 0.72) / max(0.28, 1 - v * 0.72)
        let liftedY = y0 + release * release * 9.5
        let curlZ = release * sin(v * .pi) * 2.7
        positions.append([x0, liftedY, 0.58 - cavity * 1.8 + tension + curlZ])
        normals.append([0, 0, 1])
        uvs.append([u, v])
      }
    }
    let stride = columns + 1
    for row in 0..<rows {
      for column in 0..<columns {
        let a = UInt32(row * stride + column)
        let b = a + 1
        let c = UInt32((row + 1) * stride + column)
        let d = c + 1
        indices += [a, c, b, b, c, d]
      }
    }
    var descriptor = MeshDescriptor(name: "VacuumMembrane")
    descriptor.positions = .init(positions)
    descriptor.normals = .init(normals)
    descriptor.textureCoordinates = .init(uvs)
    descriptor.primitives = .triangles(indices)
    return try MeshResource.generate(from: [descriptor])
  }
}
