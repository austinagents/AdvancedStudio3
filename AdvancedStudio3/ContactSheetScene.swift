import AppKit
import RealityKit

@MainActor
final class ContactSheetScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let upperStrip: Entity
  private let lowerStrip: Entity
  private let frames: [ModelEntity]
  private let leftRoller: Entity
  private let rightRoller: Entity
  private let product: ModelEntity
  private let caption: ModelEntity
  private let projector: SpotLight

  private init(
    root: Entity, camera: PerspectiveCamera, upperStrip: Entity, lowerStrip: Entity,
    frames: [ModelEntity], leftRoller: Entity, rightRoller: Entity, product: ModelEntity,
    caption: ModelEntity, projector: SpotLight
  ) {
    self.root = root
    self.camera = camera
    self.upperStrip = upperStrip
    self.lowerStrip = lowerStrip
    self.frames = frames
    self.leftRoller = leftRoller
    self.rightRoller = rightRoller
    self.product = product
    self.caption = caption
    self.projector = projector
  }

  static func load(imageURL: URL) async throws -> ContactSheetScene {
    let root = try await NewSceneSupport.entity("ContactSheet")
    let stage = try NewSceneSupport.child("PhotoStageRoot", in: root)
    let transport = try NewSceneSupport.child("FilmTransportRoot", in: root)
    let takeUp = try NewSceneSupport.child("TakeUpRoot", in: root)
    let productRoot = try NewSceneSupport.child("ProductRoot", in: root)
    let captionRoot = try NewSceneSupport.child("CaptionRoot", in: root)
    let cameraRig = try NewSceneSupport.child("TrackingCameraRig", in: root)
    let lights = try NewSceneSupport.child("ProjectorLightRig", in: root)
    let cream = try await NewSceneSupport.surfaceMaterial(
      id: "decrepit_wallpaper",
      tint: NSColor(red: 0.84, green: 0.73, blue: 0.58, alpha: 1))
    var film = PhysicallyBasedMaterial()
    film.baseColor = .init(tint: NSColor(red: 0.12, green: 0.075, blue: 0.045, alpha: 0.88))
    film.roughness = 0.16
    film.blending = .transparent(opacity: .init(floatLiteral: 0.88))
    film.faceCulling = .none
    var amber = PhysicallyBasedMaterial()
    amber.baseColor = .init(tint: NSColor(red: 0.93, green: 0.39, blue: 0.06, alpha: 0.82))
    amber.roughness = 0.18
    amber.blending = .transparent(opacity: .init(floatLiteral: 0.82))
    amber.faceCulling = .none
    let black = try await NewSceneSupport.surfaceMaterial(
      id: "metal_plate_02", tint: NSColor(white: 0.025, alpha: 1), metallic: true)
    let wall = ModelEntity(
      mesh: .generateBox(width: 17, height: 16, depth: 0.55, cornerRadius: 0.2), materials: [cream])
    wall.position = [0, 1, -4.5]
    stage.addChild(wall)
    let floor = ModelEntity(
      mesh: .generateBox(width: 17, height: 0.4, depth: 17, cornerRadius: 0.14), materials: [cream])
    floor.position = [0, -4.2, 1]
    stage.addChild(floor)
    for index in -2...2 {
      let lightSlot = ModelEntity(
        mesh: .generateBox(width: 1.35, height: 0.055, depth: 0.04, cornerRadius: 0.02),
        materials: [amber])
      lightSlot.position = [Float(index) * 2.15, 4.85, -4.18]
      stage.addChild(lightSlot)
    }
    for side: Float in [-1, 1] {
      let rail = ModelEntity(
        mesh: .generateBox(width: 0.12, height: 10.7, depth: 0.16, cornerRadius: 0.035),
        materials: [black])
      rail.position = [side * 6.25, 0.15, -4.12]
      stage.addChild(rail)
    }
    let upper = Entity()
    upper.name = "UpperFilmTransport"
    transport.addChild(upper)
    let lower = Entity()
    lower.name = "LowerFilmTransport"
    transport.addChild(lower)
    var frames: [ModelEntity] = []
    for index in 0..<12 {
      let panel = ModelEntity(
        mesh: .generateBox(width: 2.0, height: 2.55, depth: 0.075, cornerRadius: 0.035),
        materials: [index.isMultiple(of: 3) ? amber : film])
      panel.position = [-11 + Float(index) * 2.15, 1.42, 0.75]
      upper.addChild(panel)
      frames.append(panel)
      let panel2 = ModelEntity(
        mesh: .generateBox(width: 2.0, height: 2.55, depth: 0.075, cornerRadius: 0.035),
        materials: [index.isMultiple(of: 4) ? amber : film])
      panel2.position = [11 - Float(index) * 2.15, -1.28, 0.76]
      lower.addChild(panel2)
      frames.append(panel2)
      for y: Float in [-1, 1] {
        let perforation = ModelEntity(
          mesh: .generateBox(width: 0.18, height: 0.11, depth: 0.09, cornerRadius: 0.018),
          materials: [cream])
        perforation.position = [-11 + Float(index) * 2.15, 1.42 + y * 1.08, 0.82]
        upper.addChild(perforation)
        let perforation2 = ModelEntity(
          mesh: .generateBox(width: 0.18, height: 0.11, depth: 0.09, cornerRadius: 0.018),
          materials: [cream])
        perforation2.position = [11 - Float(index) * 2.15, -1.28 + y * 1.08, 0.83]
        lower.addChild(perforation2)
      }
    }
    let leftRoller = Entity()
    let rightRoller = Entity()
    takeUp.addChild(leftRoller)
    takeUp.addChild(rightRoller)
    for (roller, x) in [(leftRoller, Float(-5.8)), (rightRoller, Float(5.8))] {
      let core = ModelEntity(mesh: .generateCylinder(height: 4.7, radius: 0.46), materials: [black])
      core.position = [x, 0, 0.35]
      roller.addChild(core)
      for y: Float in [-1, 1] {
        let flange = ModelEntity(
          mesh: .generateCylinder(height: 0.12, radius: 0.72), materials: [black])
        flange.position = [x, y * 2.35, 0.35]
        roller.addChild(flange)
      }
      for y: Float in [-1, 1] {
        let bearing = ModelEntity(
          mesh: .generateCylinder(height: 0.16, radius: 0.92), materials: [black])
        bearing.position = [x, y * 2.48, 0.35]
        roller.addChild(bearing)
      }
    }
    let product = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.35, name: "ContactSheetProduct", roughness: 0.24)
    product.position = [0.85, -2.15, 0.55]
    productRoot.addChild(product)
    let caption = NewSceneSupport.text(
      "THE FRAME WORTH KEEPING", fontName: "HelveticaNeue-Medium", size: 0.17,
      color: NSColor(red: 0.18, green: 0.08, blue: 0.035, alpha: 1))
    caption.position = [-0.95, -3.2, 0.95]
    captionRoot.addChild(caption)
    let ibl = try await NewSceneSupport.imageLight(
      id: "ferndale_studio_02", exponent: 1.2, parent: lights)
    NewSceneSupport.receiveIBL([wall, floor, product] + frames, light: ibl)
    NewSceneSupport.receiveIBL(in: root, light: ibl)
    let projector = SpotLight()
    projector.light = .init(
      color: NSColor(red: 1, green: 0.83, blue: 0.59, alpha: 1), intensity: 58_000,
      innerAngleInDegrees: 18, outerAngleInDegrees: 48, attenuationRadius: 20)
    lights.addChild(projector)
    let safe = PointLight()
    safe.light = .init(
      color: NSColor(red: 0.92, green: 0.025, blue: 0.01, alpha: 1), intensity: 18_000,
      attenuationRadius: 10)
    safe.position = [-5, 1, 3]
    lights.addChild(safe)
    let camera = NewSceneSupport.camera(focalLength: 85, name: "FilmTrackingCamera")
    cameraRig.addChild(camera)
    let scene = ContactSheetScene(
      root: root, camera: camera, upperStrip: upper, lowerStrip: lower, frames: frames,
      leftRoller: leftRoller, rightRoller: rightRoller, product: product, caption: caption,
      projector: projector)
    scene.apply(frameIndex: 359)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 359)
    let transport = NewSceneSupport.smooth(frame, 0, 176)
    let wind = NewSceneSupport.smooth(frame, 180, 270)
    let hero = NewSceneSupport.smooth(frame, 270, 359)
    upperStrip.position.x = -transport * 6.45 - wind * 12
    lowerStrip.position.x = transport * 6.45 + wind * 12
    upperStrip.position.y = wind * 4.8
    lowerStrip.position.y = -wind * 4.8
    leftRoller.orientation = simd_quatf(angle: wind * 8 * .pi, axis: [0, 1, 0])
    rightRoller.orientation = simd_quatf(angle: -wind * 8 * .pi, axis: [0, 1, 0])
    for (index, panel) in frames.enumerated() {
      panel.components.set(
        OpacityComponent(
          opacity: 0.58 + 0.34 * abs(sin(transport * .pi * 10 + Float(index) * 0.63))))
    }
    product.isEnabled = frame >= 180
    product.scale = .init(repeating: NewSceneSupport.mix(0.8, 1, wind))
    product.position.y = NewSceneSupport.mix(-3.1, -2.15, wind)
    caption.isEnabled = false
    caption.components.set(OpacityComponent(opacity: NewSceneSupport.smooth(frame, 294, 332)))
    camera.look(
      at: NewSceneSupport.mix([-1.6, 0.2, 0.7], [0.2, -1.95, 0.3], wind),
      from: NewSceneSupport.mix(
        [-5.8 + transport * 2.1, 0.35, 6.1], [2.6 + hero * 0.08, 0.05, 13.2], wind),
      relativeTo: root)
    projector.look(
      at: [0.4, -1, 0], from: NewSceneSupport.mix([5, 2, 5], [-3.5, 6.5, 5], wind), relativeTo: root
    )
  }
}
