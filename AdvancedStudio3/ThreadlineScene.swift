import AppKit
import RealityKit

@MainActor
final class ThreadlineScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let shell: Entity
  private let threadSegments: [ModelEntity]
  private let sleevePanels: [ModelEntity]
  private let innerCap: ModelEntity
  private let product: ModelEntity
  private let copy: ModelEntity
  private let graze: SpotLight

  private init(
    root: Entity, camera: PerspectiveCamera, shell: Entity, threadSegments: [ModelEntity],
    sleevePanels: [ModelEntity], innerCap: ModelEntity, product: ModelEntity, copy: ModelEntity,
    graze: SpotLight
  ) {
    self.root = root
    self.camera = camera
    self.shell = shell
    self.threadSegments = threadSegments
    self.sleevePanels = sleevePanels
    self.innerCap = innerCap
    self.product = product
    self.copy = copy
    self.graze = graze
  }

  static func load(imageURL: URL) async throws -> ThreadlineScene {
    let root = try await NewSceneSupport.entity("Threadline")
    let stage = try NewSceneSupport.child("MachinedStage", in: root)
    let shell = try NewSceneSupport.child("ThreadedShellRoot", in: root)
    let capRoot = try NewSceneSupport.child("InnerCapRoot", in: root)
    let productRoot = try NewSceneSupport.child("ProductRoot", in: root)
    let copyRoot = try NewSceneSupport.child("CopyRoot", in: root)
    let cameraRig = try NewSceneSupport.child("ThreadFollowerCamera", in: root)
    let lights = try NewSceneSupport.child("GrazingLightRig", in: root)
    let silver = try await NewSceneSupport.surfaceMaterial(
      id: "metal_plate_02",
      tint: NSColor(red: 0.62, green: 0.65, blue: 0.66, alpha: 1), metallic: true)
    let cobalt = try await NewSceneSupport.surfaceMaterial(
      id: "rust_coarse_01",
      tint: NSColor(red: 0.025, green: 0.09, blue: 0.58, alpha: 1))
    let frost = try await NewSceneSupport.surfaceMaterial(
      id: "long_white_tiles",
      tint: NSColor(red: 0.82, green: 0.87, blue: 0.9, alpha: 1))
    let wall = ModelEntity(
      mesh: .generateBox(width: 18, height: 17, depth: 0.6, cornerRadius: 0.2), materials: [frost])
    wall.position = [0, 1, -5]
    stage.addChild(wall)
    let floor = ModelEntity(
      mesh: .generateBox(width: 18, height: 0.42, depth: 18, cornerRadius: 0.12), materials: [frost]
    )
    floor.position = [0, -4.25, 1]
    stage.addChild(floor)
    for radius: Float in [3.85, 4.45, 5.05, 5.65] {
      let groove = ModelEntity(
        mesh: .generateCylinder(height: 0.025, radius: radius), materials: [cobalt])
      let inset = ModelEntity(
        mesh: .generateCylinder(height: 0.03, radius: radius - 0.055), materials: [frost])
      groove.position = [0.4, -4.02, 0.25]
      inset.position = [0.4, -4, 0.25]
      stage.addChild(groove)
      stage.addChild(inset)
    }
    let base = ModelEntity(mesh: .generateCylinder(height: 0.55, radius: 3.5), materials: [silver])
    base.position = [0.4, -3.82, 0.25]
    stage.addChild(base)
    for index in 0..<18 {
      let angle = Float(index) / 18 * 2 * Float.pi
      let knurl = ModelEntity(
        mesh: .generateBox(width: 0.12, height: 0.18, depth: 0.5, cornerRadius: 0.035),
        materials: [silver])
      knurl.position = [0.4 + cos(angle) * 3.43, -3.82, 0.25 + sin(angle) * 3.43]
      knurl.orientation = simd_quatf(angle: -angle, axis: [0, 1, 0])
      stage.addChild(knurl)
    }
    let innerCap = ModelEntity(
      mesh: .generateCylinder(height: 0.38, radius: 2.15), materials: [cobalt])
    innerCap.position = [0.4, -3.42, 0.25]
    capRoot.addChild(innerCap)
    var threadSegments: [ModelEntity] = []
    var sleevePanels: [ModelEntity] = []
    let segments = 64
    for index in 0..<segments {
      let angle = Float(index) / Float(segments) * 2 * Float.pi
      let radius: Float = 3.12
      let thread = ModelEntity(
        mesh: .generateBox(width: 0.42, height: 0.24, depth: 0.34, cornerRadius: 0.07),
        materials: [cobalt])
      thread.position = [
        0.4 + cos(angle) * radius, -2.95 + Float(index) / Float(segments) * 1.25,
        0.25 + sin(angle) * radius,
      ]
      thread.orientation =
        simd_quatf(angle: -angle, axis: [0, 1, 0]) * simd_quatf(angle: 0.12, axis: [0, 0, 1])
      shell.addChild(thread)
      threadSegments.append(thread)
    }
    for index in 0..<28 {
      let angle = Float(index) / 28 * 2 * Float.pi
      let panel = ModelEntity(
        mesh: .generateBox(width: 0.72, height: 7.4, depth: 0.3, cornerRadius: 0.1),
        materials: [silver])
      panel.position = [0.4 + cos(angle) * 3.3, 0.35, 0.25 + sin(angle) * 3.3]
      panel.orientation = simd_quatf(angle: -angle, axis: [0, 1, 0])
      shell.addChild(panel)
      sleevePanels.append(panel)
    }
    for index in 0..<9 {
      let groove = ModelEntity(
        mesh: .generateCylinder(height: 0.04, radius: 3.55 + Float(index % 2) * 0.05),
        materials: [cobalt])
      groove.position = [0.4, -3.52 + Float(index) * 0.045, 0.25]
      stage.addChild(groove)
    }
    let product = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.35, name: "ThreadlineProduct", roughness: 0.15)
    product.position = [0.4, -2.05, 0.8]
    productRoot.addChild(product)
    let copy = NewSceneSupport.text(
      "ENGINEERED TO OPEN", fontName: "HelveticaNeue-Medium", size: 0.17,
      color: NSColor(red: 0.025, green: 0.07, blue: 0.35, alpha: 1))
    copy.position = [-0.9, -3.15, 0.95]
    copyRoot.addChild(copy)
    let ibl = try await NewSceneSupport.imageLight(
      id: "ferndale_studio_02", exponent: 1.55, parent: lights)
    NewSceneSupport.receiveIBL(
      [wall, floor, base, innerCap, product] + threadSegments + sleevePanels, light: ibl)
    NewSceneSupport.receiveIBL(in: root, light: ibl)
    let graze = SpotLight()
    graze.light = .init(
      color: NSColor(red: 0.42, green: 0.64, blue: 1, alpha: 1), intensity: 74_000,
      innerAngleInDegrees: 10, outerAngleInDegrees: 34, attenuationRadius: 21)
    lights.addChild(graze)
    let warm = DirectionalLight()
    warm.light = .init(color: NSColor(red: 1, green: 0.64, blue: 0.32, alpha: 1), intensity: 7_000)
    warm.look(at: [0, -1, 0], from: [-5, 7, 4], relativeTo: root)
    lights.addChild(warm)
    let camera = NewSceneSupport.camera(focalLength: 70, name: "ThreadFollowerCamera")
    cameraRig.addChild(camera)
    let scene = ThreadlineScene(
      root: root, camera: camera, shell: shell, threadSegments: threadSegments,
      sleevePanels: sleevePanels, innerCap: innerCap, product: product, copy: copy, graze: graze)
    scene.apply(frameIndex: 359)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 359)
    let wind = NewSceneSupport.smooth(frame, 0, 176)
    let unscrew = NewSceneSupport.smooth(frame, 180, 270)
    let hero = NewSceneSupport.smooth(frame, 270, 359)
    let rotation = wind * 2.2 * .pi + unscrew * 3.4 * .pi
    shell.orientation = simd_quatf(angle: rotation, axis: [0, 1, 0])
    shell.position.y = unscrew * 10.5
    for (index, segment) in threadSegments.enumerated() {
      segment.scale.x = 0.9 + 0.1 * sin(wind * .pi * 8 + Float(index) * 0.24)
    }
    for (index, panel) in sleevePanels.enumerated() {
      panel.components.set(
        OpacityComponent(opacity: 0.8 + 0.2 * abs(cos(rotation + Float(index) * 0.31))))
    }
    product.isEnabled = frame >= 180
    product.scale = .init(repeating: NewSceneSupport.mix(0.76, 1, unscrew))
    product.position.y = NewSceneSupport.mix(-3.05, -2.05, unscrew)
    innerCap.scale.y = NewSceneSupport.mix(0.25, 1, unscrew)
    copy.isEnabled = false
    copy.components.set(OpacityComponent(opacity: NewSceneSupport.smooth(frame, 294, 332)))
    let followAngle = NewSceneSupport.mix(-1.25, 0.22, unscrew) - wind * 0.35
    let macro = SIMD3<Float>(
      0.4 + cos(followAngle) * 4.25, -2.1 + wind * 0.7, 0.25 + sin(followAngle) * 4.25)
    camera.look(
      at: NewSceneSupport.mix([0.4, -2.45, 0.25], [0.1, -1.95, 0.45], unscrew),
      from: NewSceneSupport.mix(macro, [2.6 + hero * 0.07, 0.05, 13.3], unscrew), relativeTo: root)
    graze.look(
      at: [0.4, -1.4, 0.25], from: [cos(rotation) * 5.5, 4.5, sin(rotation) * 5.5 + 2.5],
      relativeTo: root)
  }
}
