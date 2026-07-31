import AppKit
import RealityKit

@MainActor
final class SixAxisCeremonyScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let arms: [Entity]
  private let panels: [ModelEntity]
  private let joints: [[Entity]]
  private let inspectionLights: [PointLight]
  private let product: ModelEntity
  private let brand: ModelEntity

  private init(
    root: Entity, camera: PerspectiveCamera, arms: [Entity], panels: [ModelEntity],
    joints: [[Entity]], inspectionLights: [PointLight], product: ModelEntity, brand: ModelEntity
  ) {
    self.root = root
    self.camera = camera
    self.arms = arms
    self.panels = panels
    self.joints = joints
    self.inspectionLights = inspectionLights
    self.product = product
    self.brand = brand
  }

  static func load(imageURL: URL) async throws -> SixAxisCeremonyScene {
    let root = try await NewSceneSupport.entity("SixAxisCeremony")
    let lab = try NewSceneSupport.child("AssemblyLab", in: root)
    let robotRoot = try NewSceneSupport.child("RobotRoot", in: root)
    let productCell = try NewSceneSupport.child("ProductCell", in: root)
    let brandRoot = try NewSceneSupport.child("BrandRoot", in: root)
    let cameraRig = try NewSceneSupport.child("SymmetryCameraRig", in: root)
    let lightRig = try NewSceneSupport.child("InspectionLightRig", in: root)
    let white = try await NewSceneSupport.surfaceMaterial(
      id: "white_plaster_02",
      tint: NSColor(red: 0.88, green: 0.9, blue: 0.88, alpha: 1))
    let aluminum = try await NewSceneSupport.surfaceMaterial(
      id: "metal_plate_02",
      tint: NSColor(red: 0.48, green: 0.53, blue: 0.55, alpha: 1), metallic: true)
    let orange = try await NewSceneSupport.surfaceMaterial(
      id: "rust_coarse_01",
      tint: NSColor(red: 1, green: 0.22, blue: 0.015, alpha: 1))
    var glass = PhysicallyBasedMaterial()
    glass.baseColor = .init(tint: NSColor(red: 0.2, green: 0.72, blue: 0.86, alpha: 0.72))
    glass.roughness = 0.1
    glass.blending = .transparent(opacity: .init(floatLiteral: 0.72))
    glass.faceCulling = .none
    let wall = ModelEntity(
      mesh: .generateBox(width: 18, height: 17, depth: 0.6, cornerRadius: 0.16), materials: [white])
    wall.position = [0, 1, -5]
    lab.addChild(wall)
    let floor = ModelEntity(
      mesh: .generateBox(width: 18, height: 0.42, depth: 18, cornerRadius: 0.1), materials: [white])
    floor.position = [0, -4.3, 1]
    lab.addChild(floor)
    for index in -4...4 {
      let floorDatum = ModelEntity(
        mesh: .generateBox(width: 0.025, height: 0.018, depth: 16, cornerRadius: 0.004),
        materials: [aluminum])
      floorDatum.position = [Float(index) * 1.65, -4.08, 1]
      lab.addChild(floorDatum)
    }
    for index in -3...3 {
      let ceilingBlade = ModelEntity(
        mesh: .generateBox(width: 0.11, height: 0.18, depth: 13.5, cornerRadius: 0.025),
        materials: [aluminum])
      ceilingBlade.position = [Float(index) * 2.05, 6.2, 0.1]
      lab.addChild(ceilingBlade)
    }
    for index in 0..<5 {
      let rail = ModelEntity(
        mesh: .generateBox(width: 15, height: 0.045, depth: 0.06, cornerRadius: 0.015),
        materials: [aluminum])
      rail.position = [0, -3.98, -2 + Float(index) * 1.5]
      lab.addChild(rail)
    }
    let starts: [SIMD3<Float>] = [
      [-6.4, -2.8, 0], [6.4, -2.8, 0], [-6.4, 2.6, 0], [6.4, 2.6, 0], [-2.2, 5.7, 0],
      [2.2, 5.7, 0],
    ]
    let panelHomes: [SIMD3<Float>] = [
      [-1.15, -0.75, 0.65], [1.15, -0.75, 0.65], [-1.15, 1.45, 0.65], [1.15, 1.45, 0.65],
      [0, 0.35, 1.15], [0, 0.35, 0.15],
    ]
    var arms: [Entity] = []
    var panels: [ModelEntity] = []
    var jointSets: [[Entity]] = []
    var movingLights: [PointLight] = []
    for index in 0..<6 {
      let base = Entity()
      base.name = "RobotArm\(index)"
      base.position = starts[index]
      robotRoot.addChild(base)
      arms.append(base)
      let shoulder = Entity()
      let elbow = Entity()
      let wrist = Entity()
      base.addChild(shoulder)
      shoulder.addChild(elbow)
      elbow.addChild(wrist)
      jointSets.append([shoulder, elbow, wrist])
      let upper = ModelEntity(
        mesh: .generateBox(width: 2.7, height: 0.34, depth: 0.42, cornerRadius: 0.16),
        materials: [index.isMultiple(of: 2) ? orange : aluminum])
      upper.position.x = 1.35
      shoulder.addChild(upper)
      elbow.position.x = 2.7
      let forearm = ModelEntity(
        mesh: .generateBox(width: 2.2, height: 0.28, depth: 0.36, cornerRadius: 0.14),
        materials: [index.isMultiple(of: 2) ? aluminum : orange])
      forearm.position.x = 1.1
      elbow.addChild(forearm)
      wrist.position.x = 2.2
      for joint in [shoulder, elbow, wrist] {
        let cap = ModelEntity(
          mesh: .generateCylinder(height: 0.5, radius: 0.28), materials: [aluminum])
        cap.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        joint.addChild(cap)
      }
      let panel = ModelEntity(
        mesh: .generateBox(width: 2.2, height: 2.15, depth: 0.12, cornerRadius: 0.12),
        materials: [index == 4 ? glass : (index.isMultiple(of: 2) ? orange : aluminum)])
      panel.position = panelHomes[index]
      robotRoot.addChild(panel)
      panels.append(panel)
      let inspect = PointLight()
      inspect.light = .init(
        color: index.isMultiple(of: 2)
          ? NSColor(red: 1, green: 0.22, blue: 0.04, alpha: 1)
          : NSColor(red: 0.1, green: 0.72, blue: 1, alpha: 1), intensity: 13_000,
        attenuationRadius: 5)
      lightRig.addChild(inspect)
      movingLights.append(inspect)
    }
    let product = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.35, name: "SixAxisProduct", roughness: 0.18)
    product.position = [0, -2.15, 0.55]
    productCell.addChild(product)
    let stage = ModelEntity(mesh: .generateCylinder(height: 0.32, radius: 1.9), materials: [orange])
    stage.position = [0, -3.68, 0.15]
    productCell.addChild(stage)
    let stageReveal = ModelEntity(
      mesh: .generateCylinder(height: 0.07, radius: 1.96), materials: [aluminum])
    stageReveal.position = [0, -3.95, 0.15]
    productCell.addChild(stageReveal)
    let brand = NewSceneSupport.text(
      "ASSEMBLED AROUND YOU", fontName: "HelveticaNeue-Medium", size: 0.17,
      color: NSColor(white: 0.1, alpha: 1))
    brand.position = [-0.9, -3.2, 0.8]
    brandRoot.addChild(brand)
    let ibl = try await NewSceneSupport.imageLight(
      id: "cloudy_netted_nursery", exponent: 1.45, parent: lightRig)
    NewSceneSupport.receiveIBL([wall, floor, product, stage] + panels, light: ibl)
    NewSceneSupport.receiveIBL(in: root, light: ibl)
    let overhead = DirectionalLight()
    overhead.light = .init(color: .white, intensity: 8_500)
    overhead.look(at: [0, -1, 0], from: [-2, 7, 4], relativeTo: root)
    lightRig.addChild(overhead)
    let camera = NewSceneSupport.camera(focalLength: 50, name: "SymmetryCellCamera")
    cameraRig.addChild(camera)
    let scene = SixAxisCeremonyScene(
      root: root, camera: camera, arms: arms, panels: panels, joints: jointSets,
      inspectionLights: movingLights, product: product, brand: brand)
    scene.apply(frameIndex: 359)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 359)
    let assemble = NewSceneSupport.smooth(frame, 0, 176)
    let handoff = NewSceneSupport.smooth(frame, 180, 270)
    let hero = NewSceneSupport.smooth(frame, 270, 359)
    for index in arms.indices {
      let side: Float = index.isMultiple(of: 2) ? 1 : -1
      joints[index][0].orientation = simd_quatf(
        angle: NewSceneSupport.mix(side * 1.2, side * 0.25, assemble) + handoff * side * 0.55,
        axis: [0, 0, 1])
      joints[index][1].orientation = simd_quatf(
        angle: NewSceneSupport.mix(-side * 1.55, -side * 0.8, assemble) - handoff * side * 0.65,
        axis: [0, 0, 1])
      joints[index][2].orientation = simd_quatf(
        angle: assemble * side * 0.4 + handoff * side * 0.8, axis: [0, 0, 1])
      let angle = Float(index) / 6 * 2 * Float.pi
      let sealed = SIMD3<Float>(cos(angle) * 1.15, -0.15 + sin(angle) * 1.25, 0.75)
      let halo = SIMD3<Float>(cos(angle) * 4.3, -0.25 + sin(angle) * 3.1, -0.1)
      panels[index].position = NewSceneSupport.mix(sealed, halo, handoff)
      panels[index].orientation = simd_quatf(angle: handoff * angle, axis: [0, 1, 0])
      inspectionLights[index].position = panels[index].position + [0, 0.4, 1.2]
    }
    product.isEnabled = frame >= 180
    product.scale = .init(repeating: NewSceneSupport.mix(0.75, 1, handoff))
    product.position.y = NewSceneSupport.mix(-3.15, -2.15, handoff)
    brand.isEnabled = false
    brand.components.set(OpacityComponent(opacity: NewSceneSupport.smooth(frame, 294, 332)))
    camera.look(
      at: [0, NewSceneSupport.mix(0.15, -1.95, handoff), 0.4],
      from: NewSceneSupport.mix([0, 0.2, 11], [0.75 + hero * 0.06, 0.05, 13.5], handoff),
      relativeTo: root)
  }
}
