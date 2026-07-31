import AppKit
import RealityKit

@MainActor
final class SeamReleaseScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let leftPanel: Entity
  private let rightPanel: Entity
  private let leftTeeth: [ModelEntity]
  private let rightTeeth: [ModelEntity]
  private let slider: ModelEntity
  private let product: ModelEntity
  private let copy: ModelEntity
  private let chaseLight: PointLight

  private init(
    root: Entity, camera: PerspectiveCamera, leftPanel: Entity, rightPanel: Entity,
    leftTeeth: [ModelEntity], rightTeeth: [ModelEntity], slider: ModelEntity, product: ModelEntity,
    copy: ModelEntity, chaseLight: PointLight
  ) {
    self.root = root
    self.camera = camera
    self.leftPanel = leftPanel
    self.rightPanel = rightPanel
    self.leftTeeth = leftTeeth
    self.rightTeeth = rightTeeth
    self.slider = slider
    self.product = product
    self.copy = copy
    self.chaseLight = chaseLight
  }

  static func load(imageURL: URL) async throws -> SeamReleaseScene {
    let root = try await NewSceneSupport.entity("SeamRelease")
    let chamber = try NewSceneSupport.child("TechnicalChamber", in: root)
    let left = try NewSceneSupport.child("LeftPanelRoot", in: root)
    let right = try NewSceneSupport.child("RightPanelRoot", in: root)
    let zipper = try NewSceneSupport.child("ZipperRoot", in: root)
    let productRoot = try NewSceneSupport.child("ProductRoot", in: root)
    let copyRoot = try NewSceneSupport.child("CopyRoot", in: root)
    let cameraRig = try NewSceneSupport.child("SliderCameraRig", in: root)
    let lights = try NewSceneSupport.child("LinearLightRig", in: root)
    let chamberMaterial = try await NewSceneSupport.surfaceMaterial(
      id: "long_white_tiles",
      tint: NSColor(red: 0.68, green: 0.72, blue: 0.7, alpha: 1))
    let textile = try await NewSceneSupport.surfaceMaterial(
      id: "crepe_satin",
      tint: NSColor(red: 0.055, green: 0.085, blue: 0.075, alpha: 1))
    let lime = try await NewSceneSupport.surfaceMaterial(
      id: "metal_plate_02",
      tint: NSColor(red: 0.6, green: 1, blue: 0.04, alpha: 1), metallic: true)
    let titanium = try await NewSceneSupport.surfaceMaterial(
      id: "metal_plate_02",
      tint: NSColor(red: 0.46, green: 0.52, blue: 0.5, alpha: 1), metallic: true)
    let wall = ModelEntity(
      mesh: .generateBox(width: 17, height: 16, depth: 0.55, cornerRadius: 0.18),
      materials: [chamberMaterial])
    wall.position = [0, 1, -4.5]
    chamber.addChild(wall)
    let floor = ModelEntity(
      mesh: .generateBox(width: 17, height: 0.42, depth: 17, cornerRadius: 0.12),
      materials: [chamberMaterial])
    floor.position = [0, -4.2, 1]
    chamber.addChild(floor)
    for index in -3...3 {
      let serviceJoint = ModelEntity(
        mesh: .generateBox(width: 0.035, height: 0.02, depth: 14.5, cornerRadius: 0.006),
        materials: [titanium])
      serviceJoint.position = [Float(index) * 1.8, -3.98, 0.9]
      chamber.addChild(serviceJoint)
    }
    let leftSheet = ModelEntity(
      mesh: .generateBox(width: 5.6, height: 9.8, depth: 0.12, cornerRadius: 0.08),
      materials: [textile])
    leftSheet.position = [-2.8, 0, 0.42]
    left.addChild(leftSheet)
    let rightSheet = ModelEntity(
      mesh: .generateBox(width: 5.6, height: 9.8, depth: 0.12, cornerRadius: 0.08),
      materials: [textile])
    rightSheet.position = [2.8, 0, 0.42]
    right.addChild(rightSheet)
    for side: Float in [-1, 1] {
      for index in 0..<12 {
        let stitch = ModelEntity(
          mesh: .generateBox(width: 0.035, height: 0.16, depth: 0.025, cornerRadius: 0.012),
          materials: [lime])
        stitch.position = [side * 0.72, -3.25 + Float(index) * 0.58, 0.36]
        (side < 0 ? left : right).addChild(stitch)
      }
    }
    var leftTeeth: [ModelEntity] = []
    var rightTeeth: [ModelEntity] = []
    for index in 0..<30 {
      let y = -4.45 + Float(index) * 0.305
      let lt = ModelEntity(
        mesh: .generateBox(width: 0.48, height: 0.19, depth: 0.26, cornerRadius: 0.055),
        materials: [index.isMultiple(of: 5) ? lime : titanium])
      lt.position = [-0.22, y, 0.62]
      left.addChild(lt)
      leftTeeth.append(lt)
      let rt = ModelEntity(
        mesh: .generateBox(width: 0.48, height: 0.19, depth: 0.26, cornerRadius: 0.055),
        materials: [index.isMultiple(of: 5) ? lime : titanium])
      rt.position = [0.22, y + 0.15, 0.62]
      right.addChild(rt)
      rightTeeth.append(rt)
    }
    let slider = ModelEntity(
      mesh: .generateBox(width: 1.05, height: 0.9, depth: 0.48, cornerRadius: 0.2),
      materials: [lime])
    slider.position = [0, -4.3, 0.95]
    zipper.addChild(slider)
    let handle = ModelEntity(
      mesh: .generateBox(width: 0.32, height: 1.25, depth: 0.18, cornerRadius: 0.1),
      materials: [titanium])
    handle.position = [0, 0.85, 0]
    slider.addChild(handle)
    let product = try await NewSceneSupport.litProduct(
      imageURL: imageURL, height: 1.35, name: "SeamProduct", roughness: 0.2)
    product.position = [0.7, -2.15, 0.25]
    productRoot.addChild(product)
    let plinth = ModelEntity(
      mesh: .generateBox(width: 3.6, height: 0.32, depth: 2.4, cornerRadius: 0.16),
      materials: [lime])
    plinth.position = [0.7, -3.68, 0.1]
    productRoot.addChild(plinth)
    let copy = NewSceneSupport.text(
      "ENGINEERED TO RELEASE", fontName: "AvenirNext-DemiBold", size: 0.17,
      color: NSColor(red: 0.09, green: 0.12, blue: 0.1, alpha: 1))
    copy.position = [-0.95, -3.2, 0.72]
    copyRoot.addChild(copy)
    let ibl = try await NewSceneSupport.imageLight(
      id: "cloudy_netted_nursery", exponent: 1.35, parent: lights)
    NewSceneSupport.receiveIBL(
      [wall, floor, leftSheet, rightSheet, slider, handle, product, plinth] + leftTeeth
        + rightTeeth, light: ibl)
    NewSceneSupport.receiveIBL(in: root, light: ibl)
    let chase = PointLight()
    chase.light = .init(
      color: NSColor(red: 0.55, green: 1, blue: 0.03, alpha: 1), intensity: 32_000,
      attenuationRadius: 7)
    lights.addChild(chase)
    let overhead = SpotLight()
    overhead.light = .init(
      color: NSColor(red: 0.7, green: 0.86, blue: 1, alpha: 1), intensity: 45_000,
      innerAngleInDegrees: 28, outerAngleInDegrees: 72, attenuationRadius: 20)
    overhead.look(at: [0, -1, 0], from: [-4, 7, 5], relativeTo: root)
    lights.addChild(overhead)
    let camera = NewSceneSupport.camera(focalLength: 62, name: "SliderChaseCamera")
    cameraRig.addChild(camera)
    let scene = SeamReleaseScene(
      root: root, camera: camera, leftPanel: left, rightPanel: right, leftTeeth: leftTeeth,
      rightTeeth: rightTeeth, slider: slider, product: product, copy: copy, chaseLight: chase)
    scene.apply(frameIndex: 359)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 359)
    let seal = NewSceneSupport.smooth(frame, 0, 176)
    let release = NewSceneSupport.smooth(frame, 180, 270)
    let hero = NewSceneSupport.smooth(frame, 270, 359)
    slider.position.y = NewSceneSupport.mix(-4.3, 4.35, seal) - release * 8.65
    for index in leftTeeth.indices {
      let yOrder = Float(index) / Float(leftTeeth.count - 1)
      let localSeal = min(max(seal * 1.35 - yOrder * 0.35, 0), 1)
      let localRelease = min(max(release * 1.4 - (1 - yOrder) * 0.4, 0), 1)
      leftTeeth[index].position.x =
        NewSceneSupport.mix(-0.42, -0.22, localSeal) - localRelease * 0.95
      rightTeeth[index].position.x =
        NewSceneSupport.mix(0.42, 0.22, localSeal) + localRelease * 0.95
      leftTeeth[index].orientation = simd_quatf(angle: -localRelease * 0.7, axis: [0, 1, 0])
      rightTeeth[index].orientation = simd_quatf(angle: localRelease * 0.7, axis: [0, 1, 0])
    }
    leftPanel.position.x = -release * 6.2
    rightPanel.position.x = release * 6.2
    leftPanel.orientation = simd_quatf(angle: -release * 0.3, axis: [0, 1, 0])
    rightPanel.orientation = simd_quatf(angle: release * 0.3, axis: [0, 1, 0])
    product.isEnabled = frame >= 180
    product.scale = .init(repeating: NewSceneSupport.mix(0.78, 1, release))
    product.position.y = NewSceneSupport.mix(-3.05, -2.15, release)
    copy.isEnabled = false
    copy.components.set(OpacityComponent(opacity: NewSceneSupport.smooth(frame, 294, 332)))
    let chaseY = slider.position.y - 0.15
    camera.look(
      at: NewSceneSupport.mix([0, chaseY, 0.6], [0.2, -1.95, 0.2], release),
      from: NewSceneSupport.mix([1.3, chaseY - 0.15, 3.2], [2.8 + hero * 0.08, 0, 13], release),
      relativeTo: root)
    chaseLight.position = [0.4, chaseY, 2.2]
  }
}
