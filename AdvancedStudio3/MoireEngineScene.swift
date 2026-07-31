import AppKit
import RealityKit

@MainActor
final class MoireEngineScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let horizontalScreen: Entity
  private let verticalScreen: Entity
  private let horizontalBars: [ModelEntity]
  private let verticalBars: [ModelEntity]
  private let product: ModelEntity
  private let lift: ModelEntity
  private let copy: ModelEntity
  private let softbox: SpotLight

  private init(
    root: Entity, camera: PerspectiveCamera, horizontalScreen: Entity, verticalScreen: Entity,
    horizontalBars: [ModelEntity], verticalBars: [ModelEntity], product: ModelEntity,
    lift: ModelEntity, copy: ModelEntity, softbox: SpotLight
  ) {
    self.root = root
    self.camera = camera
    self.horizontalScreen = horizontalScreen
    self.verticalScreen = verticalScreen
    self.horizontalBars = horizontalBars
    self.verticalBars = verticalBars
    self.product = product
    self.lift = lift
    self.copy = copy
    self.softbox = softbox
  }

  static func load(imageURL: URL) async throws -> MoireEngineScene {
    let root = try await NewSceneSupport.entity("MoireEngine")
    let stage = try NewSceneSupport.child("WhiteStage", in: root)
    let horizontalScreen = try NewSceneSupport.child("HorizontalScreen", in: root)
    let verticalScreen = try NewSceneSupport.child("VerticalScreen", in: root)
    let productLift = try NewSceneSupport.child("ProductLift", in: root)
    let copyRoot = try NewSceneSupport.child("CopyRoot", in: root)
    let crane = try NewSceneSupport.child("CraneCamera", in: root)
    let lights = try NewSceneSupport.child("SoftboxRig", in: root)
    let white = try await NewSceneSupport.surfaceMaterial(
      id: "long_white_tiles", tint: NSColor(white: 0.94, alpha: 1))
    let red = try await NewSceneSupport.surfaceMaterial(
      id: "metal_plate_02",
      tint: NSColor(red: 0.94, green: 0.045, blue: 0.03, alpha: 1), metallic: true)
    let graphite = try await NewSceneSupport.surfaceMaterial(
      id: "dark_rock_02", tint: NSColor(white: 0.055, alpha: 1))
    let wall = ModelEntity(
      mesh: .generateBox(width: 16, height: 16, depth: 0.5, cornerRadius: 0.22), materials: [white])
    wall.position = [0, 1, -4.4]
    stage.addChild(wall)
    let floor = ModelEntity(
      mesh: .generateBox(width: 16, height: 0.35, depth: 16, cornerRadius: 0.14), materials: [white]
    )
    floor.position = [0, -4.2, 1]
    stage.addChild(floor)
    for side: Float in [-1, 1] {
      let portal = ModelEntity(
        mesh: .generateBox(width: 0.14, height: 10.8, depth: 0.32, cornerRadius: 0.045),
        materials: [graphite])
      portal.position = [side * 5.85, 0.2, -3.9]
      stage.addChild(portal)
    }
    let header = ModelEntity(
      mesh: .generateBox(width: 11.84, height: 0.14, depth: 0.32, cornerRadius: 0.045),
      materials: [graphite])
    header.position = [0, 5.55, -3.9]
    stage.addChild(header)
    for index in -3...3 {
      let datum = ModelEntity(
        mesh: .generateBox(width: 0.012, height: 0.012, depth: 11.8, cornerRadius: 0.003),
        materials: [red])
      datum.position = [Float(index) * 1.55, -4.01, 1.1]
      stage.addChild(datum)
    }
    let redWall = ModelEntity(
      mesh: .generateBox(width: 5.2, height: 10.5, depth: 0.22, cornerRadius: 0.08),
      materials: [red])
    redWall.position = [4.7, 0.2, -3.9]
    stage.addChild(redWall)
    var horizontal: [ModelEntity] = []
    var vertical: [ModelEntity] = []
    for index in 0..<39 {
      let bar = ModelEntity(
        mesh: .generateBox(width: 11.4, height: 0.105, depth: 0.11, cornerRadius: 0.025),
        materials: [graphite])
      bar.position = [0, -4 + Float(index) * 0.21, 0.55]
      horizontalScreen.addChild(bar)
      horizontal.append(bar)
    }
    for index in 0..<53 {
      let bar = ModelEntity(
        mesh: .generateBox(width: 0.075, height: 9.2, depth: 0.10, cornerRadius: 0.022),
        materials: [red])
      bar.position = [-5.4 + Float(index) * 0.205, 0, 0.72]
      verticalScreen.addChild(bar)
      vertical.append(bar)
    }
    let lift = ModelEntity(
      mesh: .generateCylinder(height: 0.42, radius: 1.85), materials: [graphite])
    lift.position = [-0.75, -3.85, 0.3]
    productLift.addChild(lift)
    let product = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.35, name: "MoireProduct", roughness: 0.2)
    product.position = [-0.75, -2.25, 0.85]
    productLift.addChild(product)
    let copy = NewSceneSupport.text(
      "PRECISION, RESOLVED.", fontName: "HelveticaNeue-Medium", size: 0.18,
      color: NSColor(white: 0.08, alpha: 1))
    copy.position = [-0.75, -3.25, 0.7]
    copyRoot.addChild(copy)
    let ibl = try await NewSceneSupport.imageLight(
      id: "ferndale_studio_02", exponent: 1.5, parent: lights)
    NewSceneSupport.receiveIBL(
      [wall, floor, redWall, lift, product] + horizontal + vertical, light: ibl)
    NewSceneSupport.receiveIBL(in: root, light: ibl)
    let softbox = SpotLight()
    softbox.light = .init(
      color: .white, intensity: 54_000, innerAngleInDegrees: 30, outerAngleInDegrees: 78,
      attenuationRadius: 22)
    lights.addChild(softbox)
    let redBounce = PointLight()
    redBounce.light = .init(
      color: NSColor(red: 1, green: 0.14, blue: 0.08, alpha: 1), intensity: 16_000,
      attenuationRadius: 9)
    redBounce.position = [5, 0, 2]
    lights.addChild(redBounce)
    let camera = NewSceneSupport.camera(focalLength: 86, name: "MoireCraneCamera")
    crane.addChild(camera)
    let scene = MoireEngineScene(
      root: root, camera: camera, horizontalScreen: horizontalScreen,
      verticalScreen: verticalScreen, horizontalBars: horizontal, verticalBars: vertical,
      product: product, lift: lift, copy: copy, softbox: softbox)
    scene.apply(frameIndex: 359)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 359)
    let interference = NewSceneSupport.smooth(frame, 0, 176)
    let decouple = NewSceneSupport.smooth(frame, 180, 268)
    let hero = NewSceneSupport.smooth(frame, 270, 359)
    horizontalScreen.position.x = sin(interference * .pi * 8) * 0.24
    horizontalScreen.position.y = decouple * 10.5
    verticalScreen.position.y = cos(interference * .pi * 7) * 0.16
    verticalScreen.position.x = decouple * 13
    for (index, bar) in horizontalBars.enumerated() {
      bar.scale.x = 0.86 + sin(interference * .pi * 5 + Float(index) * 0.31) * 0.14 * (1 - decouple)
    }
    for (index, bar) in verticalBars.enumerated() {
      bar.scale.y = 0.84 + cos(interference * .pi * 4 + Float(index) * 0.25) * 0.16 * (1 - decouple)
    }
    product.isEnabled = frame >= 178
    product.scale = .init(repeating: NewSceneSupport.mix(0.78, 1, decouple))
    lift.position.y = NewSceneSupport.mix(-4.7, -3.85, decouple)
    copy.isEnabled = false
    copy.components.set(OpacityComponent(opacity: NewSceneSupport.smooth(frame, 294, 330)))
    camera.look(
      at: NewSceneSupport.mix([0, 0.1, 0.5], [-0.1, -1.95, 0.3], decouple),
      from: NewSceneSupport.mix([0.4, 0.2, 6.2], [2.4, 0.65 + hero * 0.06, 13.5], decouple),
      relativeTo: root)
    softbox.look(
      at: [-0.5, -1.4, 0], from: NewSceneSupport.mix([-4, 6, 4], [3.5, 7, 5], decouple),
      relativeTo: root)
  }
}
