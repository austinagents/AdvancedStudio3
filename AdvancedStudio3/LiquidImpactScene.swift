import AppKit
import RealityKit

@MainActor
final class LiquidImpactScene {
  let root: Entity
  let camera: PerspectiveCamera

  private let product: Entity
  private let floor: ModelEntity
  private let panels: [ModelEntity]
  private let panelHomes: [SIMD3<Float>]
  private let ripples: [ModelEntity]
  private let particles: [ModelEntity]
  private let key: DirectionalLight
  private let rim: PointLight

  private init(
    root: Entity,
    camera: PerspectiveCamera,
    product: Entity,
    floor: ModelEntity,
    panels: [ModelEntity],
    panelHomes: [SIMD3<Float>],
    ripples: [ModelEntity],
    particles: [ModelEntity],
    key: DirectionalLight,
    rim: PointLight
  ) {
    self.root = root
    self.camera = camera
    self.product = product
    self.floor = floor
    self.panels = panels
    self.panelHomes = panelHomes
    self.ripples = ripples
    self.particles = particles
    self.key = key
    self.rim = rim
  }

  static func load(imageURL: URL) async throws -> LiquidImpactScene {
    let root = Entity()
    root.name = "LiquidImpact"

    // MARK: - Materials

    var liquid = PhysicallyBasedMaterial()
    liquid.baseColor = .init(
      tint: NSColor(red: 0.018, green: 0.022, blue: 0.028, alpha: 1)
    )
    liquid.metallic = 0.98
    liquid.roughness = 0.10

    var architecture = PhysicallyBasedMaterial()
    architecture.baseColor = .init(
      tint: NSColor(red: 0.025, green: 0.030, blue: 0.040, alpha: 1)
    )
    architecture.metallic = 0.88
    architecture.roughness = 0.18

    var highlight = PhysicallyBasedMaterial()
    highlight.baseColor = .init(
      tint: NSColor(red: 0.22, green: 0.29, blue: 0.38, alpha: 1)
    )
    highlight.metallic = 1.0
    highlight.roughness = 0.07

    // MARK: - Living liquid floor

    let floor = ModelEntity(
      mesh: .generateBox(
        width: 18,
        height: 0.12,
        depth: 20,
        cornerRadius: 0.04
      ),
      materials: [liquid]
    )
    floor.name = "LiquidFloor"
    floor.position = [0, -3.25, 0]
    root.addChild(floor)

    // MARK: - Deep chamber

    let back = ModelEntity(
      mesh: .generateBox(
        width: 18,
        height: 13,
        depth: 0.35,
        cornerRadius: 0.12
      ),
      materials: [architecture]
    )
    back.position = [0, 1.2, -6.2]
    root.addChild(back)

    // MARK: - Moving architectural blades

    var panels: [ModelEntity] = []
    var panelHomes: [SIMD3<Float>] = []

    for index in 0..<10 {
      let side: Float = index.isMultiple(of: 2) ? -1 : 1
      let depthLayer = Float(index / 2)

      let panel = ModelEntity(
        mesh: .generateBox(
          width: 0.28 + depthLayer * 0.035,
          height: 7.5 - depthLayer * 0.35,
          depth: 1.4,
          cornerRadius: 0.08
        ),
        materials: [index.isMultiple(of: 3) ? highlight : architecture]
      )

      let home = SIMD3<Float>(
        side * (2.2 + depthLayer * 0.78),
        -0.15 + depthLayer * 0.08,
        -0.4 - depthLayer * 0.85
      )

      panel.position = home
      root.addChild(panel)

      panels.append(panel)
      panelHomes.append(home)
    }

    // MARK: - Concentric liquid response field

    var ripples: [ModelEntity] = []

    for index in 0..<11 {
      let ripple = ModelEntity(
        mesh: .generateCylinder(
          height: 0.014,
          radius: 0.42 + Float(index) * 0.31
        ),
        materials: [highlight]
      )

      ripple.name = "ImpactRipple\(index)"
      ripple.position = [
        0,
        -3.17 + Float(index) * 0.001,
        0.35
      ]

      ripple.scale = [0.001, 1, 0.001]

      root.addChild(ripple)
      ripples.append(ripple)
    }

    // MARK: - Suspended atmosphere
    // Deterministic geometry rather than random particles so preview/export match.

    var particles: [ModelEntity] = []

    for index in 0..<54 {
      let size = 0.018 + Float(index % 5) * 0.006

      let mote = ModelEntity(
        mesh: .generateSphere(radius: size),
        materials: [highlight]
      )

      let fi = Float(index)

      mote.position = [
        sin(fi * 2.37) * (2.3 + Float(index % 7) * 0.42),
        -1.8 + Float(index % 11) * 0.48,
        -3.8 + Float(index % 9) * 0.72
      ]

      root.addChild(mote)
      particles.append(mote)
    }

    // MARK: - Product

    let product = try await NewSceneSupport.spatialProduct(
      imageURL: imageURL,
      height: 1.65,
      name: "LiquidImpactProduct",
      depth: 0.14
    )

    product.position = [0, -3.55, 0.45]
    product.scale = .init(repeating: 0.82)
    root.addChild(product)

    // MARK: - Image based lighting

    let ibl = try await NewSceneSupport.imageLight(
      id: "ferndale_studio_02",
      exponent: 1.45,
      parent: root
    )

    NewSceneSupport.receiveIBL(
      [floor, back] + panels + ripples + particles,
      light: ibl
    )

    NewSceneSupport.receiveIBL(in: root, light: ibl)

    // MARK: - Hero lighting

    let key = DirectionalLight()
    key.light = .init(
      color: NSColor(
        red: 0.82,
        green: 0.90,
        blue: 1.0,
        alpha: 1
      ),
      intensity: 10_500
    )
    root.addChild(key)

    let rim = PointLight()
    rim.light = .init(
      color: NSColor(
        red: 0.32,
        green: 0.50,
        blue: 1.0,
        alpha: 1
      ),
      intensity: 17_000,
      attenuationRadius: 11
    )
    rim.position = [3.8, 1.5, 1.8]
    root.addChild(rim)

    // MARK: - Camera

    let camera = NewSceneSupport.camera(
      focalLength: 72,
      name: "LiquidImpactCamera"
    )
    root.addChild(camera)

    let scene = LiquidImpactScene(
      root: root,
      camera: camera,
      product: product,
      floor: floor,
      panels: panels,
      panelHomes: panelHomes,
      ripples: ripples,
      particles: particles,
      key: key,
      rim: rim
    )

    scene.apply(frameIndex: 359)
    return scene
  }

  func apply(frameIndex: Int) {
    let frame = min(max(frameIndex, 0), 359)

    // 0–45: immediate environmental hook
    let hook = NewSceneSupport.smooth(frame, 0, 45)

    // 45–120: chamber reveal
    let build = NewSceneSupport.smooth(frame, 45, 120)

    // 120–195: environment converges
    let converge = NewSceneSupport.smooth(frame, 120, 195)

    // 195–255: product reveal
    let reveal = NewSceneSupport.smooth(frame, 195, 255)

    // 255–300: payoff
    let payoff = NewSceneSupport.smooth(frame, 255, 300)

    // 300–359: living hero hold
    let hero = NewSceneSupport.smooth(frame, 300, 359)

    // MARK: Liquid surface pulse

    let f = Float(frame)

    let wave =
      sin(f * 0.19) * 0.55 +
      sin(f * 0.071 + 1.4) * 0.30 +
      sin(f * 0.033 + 2.2) * 0.15

    let earlyEnergy = 1.0 - build * 0.55
    let settleEnergy = 1.0 - hero * 0.72

    floor.scale = [
      1 + wave * 0.010 * earlyEnergy * settleEnergy,
      1,
      1 - wave * 0.008 * earlyEnergy * settleEnergy
    ]

    floor.orientation = simd_quatf(
      angle: wave * 0.0045 * settleEnergy,
      axis: [1, 0, 0]
    )

    // MARK: Architecture choreography

    for (index, panel) in panels.enumerated() {
      let home = panelHomes[index]
      let side: Float = index.isMultiple(of: 2) ? -1 : 1
      let fi = Float(index)

      let opening = build * (0.45 + fi * 0.035)
      let convergencePull = converge * 0.32
      let livingMotion =
        sin(f * 0.018 + fi * 0.72) *
        (1 - hero * 0.72)

      panel.position = home
      panel.position.x += side * opening
      panel.position.x -= side * convergencePull
      panel.position.y += livingMotion * 0.10
      panel.position.z += cos(f * 0.014 + fi) * 0.10

      panel.orientation = simd_quatf(
        angle:
          side *
          (
            -0.16 * build +
            0.11 * converge +
            livingMotion * 0.025
          ),
        axis: [0, 1, 0]
      )
    }

    // MARK: Convergence + impact wave

    for (index, ripple) in ripples.enumerated() {
      let delay = index * 4

      let inward = NewSceneSupport.smooth(
        frame,
        118 + delay,
        188 + delay
      )

      let impact = NewSceneSupport.smooth(
        frame,
        198 + delay,
        244 + delay
      )

      let settle = NewSceneSupport.smooth(
        frame,
        270 + delay / 2,
        340
      )

      let initial = 2.4 + Float(index) * 0.18
      let compressed: Float = 0.10
      let expanded = 0.8 + Float(index) * 0.33

      var scale = NewSceneSupport.mix(
        initial,
        compressed,
        inward
      )

      scale = NewSceneSupport.mix(
        scale,
        expanded,
        impact
      )

      scale +=
        sin(f * 0.055 + Float(index) * 0.8) *
        0.025 *
        (1 - settle)

      ripple.scale = [scale, 1, scale]

      ripple.position.y =
        -3.17 +
        sin(f * 0.08 + Float(index)) *
        0.012 *
        (1 - settle)
    }

    // MARK: Atmospheric field

    for (index, mote) in particles.enumerated() {
      let fi = Float(index)

      let driftX =
        sin(f * 0.011 + fi * 1.73) *
        (0.003 + Float(index % 4) * 0.0006)

      let driftY =
        cos(f * 0.009 + fi * 0.91) *
        (0.002 + Float(index % 3) * 0.0005)

      mote.position.x += driftX
      mote.position.y += driftY

      let convergence =
        NewSceneSupport.smooth(
          frame,
          125 + index % 18,
          205 + index % 18
        )

      mote.position.x *= 1 - convergence * 0.0018
      mote.position.z +=
        sin(f * 0.007 + fi) *
        0.0015
    }

    // MARK: Product reveal

    product.isEnabled = frame >= 190

    product.position.y = NewSceneSupport.mix(
      -3.55,
      -1.72,
      reveal
    )

    product.position.z = NewSceneSupport.mix(
      0.45,
      0.62,
      reveal
    )

    let productScale = NewSceneSupport.mix(
      0.82,
      1.0,
      reveal
    )

    product.scale = .init(repeating: productScale)

    product.orientation = simd_quatf(
      angle:
        NewSceneSupport.mix(
          -0.18,
          0.025 * sin(Float(frame - 255) * 0.018),
          payoff
        ),
      axis: [0, 1, 0]
    )

    // MARK: Lighting choreography

    key.look(
      at: [0, -1.4, 0.4],
      from: NewSceneSupport.mix(
        [-6.5, 8.5, -4.0],
        [5.5, 7.5, 2.5],
        converge
      ),
      relativeTo: root
    )

    rim.position = NewSceneSupport.mix(
      [4.8, 0.4, -1.8],
      [2.8, 2.1, 2.8],
      reveal
    )

    // MARK: Camera choreography

    let cameraFromA = SIMD3<Float>(
      -0.35,
      -2.78,
      2.15
    )

    let cameraFromB = SIMD3<Float>(
      -5.4,
      -0.15,
      9.6
    )

    let cameraFromC = SIMD3<Float>(
      2.5,
      -0.35,
      8.0
    )

    let cameraFromD = SIMD3<Float>(
      1.35,
      -0.65,
      7.15
    )

    let cameraTargetA = SIMD3<Float>(
      0,
      -3.12,
      -0.6
    )

    let cameraTargetB = SIMD3<Float>(
      0,
      -1.7,
      0.25
    )

    let cameraTargetC = SIMD3<Float>(
      0,
      -1.65,
      0.55
    )

    var cameraFrom = NewSceneSupport.mix(
      cameraFromA,
      cameraFromB,
      build
    )

    cameraFrom = NewSceneSupport.mix(
      cameraFrom,
      cameraFromC,
      reveal
    )

    cameraFrom = NewSceneSupport.mix(
      cameraFrom,
      cameraFromD,
      hero
    )

    var cameraTarget = NewSceneSupport.mix(
      cameraTargetA,
      cameraTargetB,
      build
    )

    cameraTarget = NewSceneSupport.mix(
      cameraTarget,
      cameraTargetC,
      reveal
    )

    camera.look(
      at: cameraTarget,
      from: cameraFrom,
      relativeTo: root
    )

    _ = hook
  }
}
