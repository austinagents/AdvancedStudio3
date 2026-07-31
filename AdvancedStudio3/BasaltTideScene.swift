import AppKit
import RealityKit

@MainActor
final class BasaltTideScene {
    let root: Entity
    let camera: PerspectiveCamera
    private let product: ModelEntity
    private let liquid: ModelEntity
    private let threads: [ModelEntity]
    private let stateOne: ModelEntity
    private let stateTwo: ModelEntity

    private init(root: Entity, camera: PerspectiveCamera, product: ModelEntity, liquid: ModelEntity, threads: [ModelEntity], stateOne: ModelEntity, stateTwo: ModelEntity) {
        self.root = root; self.camera = camera; self.product = product; self.liquid = liquid
        self.threads = threads; self.stateOne = stateOne; self.stateTwo = stateTwo
    }

    static func load(imageURL: URL) async throws -> BasaltTideScene {
        let root = try await NewSceneSupport.entity("BasaltTide")
        let basinRoot = try NewSceneSupport.child("BasaltBasin", in: root)
        let liquidRoot = try NewSceneSupport.child("LiquidSheet", in: root)
        let threadRoot = try NewSceneSupport.child("LiquidThreadRoot", in: root)
        let productRoot = try NewSceneSupport.child("SuspendedProductSlot", in: root)
        let dataRoot = try NewSceneSupport.child("CornerDataRoot", in: root)
        let cameraRig = try NewSceneSupport.child("MacroCameraRail", in: root)
        let lights = try NewSceneSupport.child("UnderwaterLightRig", in: root)

        let basalt = try await NewSceneSupport.surfaceMaterial(id: "dark_rock_02")
        let basin = ModelEntity(mesh: .generateCylinder(height: 0.72, radius: 3.6), materials: [basalt])
        basin.scale.z = 0.69; basin.position.y = -2.25; basinRoot.addChild(basin)

        var liquidMaterial = PhysicallyBasedMaterial()
        liquidMaterial.baseColor = .init(tint: NSColor(red: 0.005, green: 0.045, blue: 0.052, alpha: 0.84))
        liquidMaterial.roughness = 0.08
        liquidMaterial.metallic = 0.12
        liquidMaterial.clearcoat = .init(floatLiteral: 1)
        liquidMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.84))
        let liquid = ModelEntity(mesh: .generateBox(width: 6.6, height: 5.6, depth: 0.08, cornerRadius: 0.04), materials: [liquidMaterial])
        liquid.position = [0, -4.9, 0.35]; liquidRoot.addChild(liquid)

        var threads: [ModelEntity] = []
        for index in 0..<12 {
            let thread = ModelEntity(mesh: .generateCylinder(height: 4.8, radius: 0.045 + Float(index % 4) * 0.018), materials: [liquidMaterial])
            let angle = Float(index) / 12 * 2 * Float.pi
            thread.position = [cos(angle) * 2.45, -0.3, -0.55 - abs(sin(angle)) * 0.25]
            threadRoot.addChild(thread); threads.append(thread)
        }
        let product = try await NewSceneSupport.product(imageURL: imageURL, height: 2.05, name: "SuspendedProduct")
        product.position = [0, -0.25, 0]; productRoot.addChild(product)
        let stateOne = NewSceneSupport.text("STATE 01 / FLUX", fontName: "SFMono-Regular", size: 0.16, color: .cyan)
        let stateTwo = NewSceneSupport.text("STATE 02 / FORM", fontName: "SFMono-Regular", size: 0.16, color: .cyan)
        stateOne.position = [-2.8, 3.9, 0.5]; stateTwo.position = [-2.8, 3.9, 0.5]
        dataRoot.addChild(stateOne); dataRoot.addChild(stateTwo)

        let ibl = try await NewSceneSupport.imageLight(id: "blue_grotto", exponent: -0.15, parent: lights)
        NewSceneSupport.receiveIBL([basin, liquid] + threads, light: ibl)
        let cyan = PointLight(); cyan.light = .init(color: .cyan, intensity: 11_000, attenuationRadius: 8)
        cyan.position = [0, -1.4, 0]; lights.addChild(cyan)
        let camera = NewSceneSupport.camera(focalLength: 110, name: "BasaltMacroCamera"); cameraRig.addChild(camera)
        let scene = BasaltTideScene(root: root, camera: camera, product: product, liquid: liquid, threads: threads, stateOne: stateOne, stateTwo: stateTwo)
        scene.apply(frameIndex: 359); return scene
    }

    func apply(frameIndex: Int) {
        let frame = min(max(frameIndex, 0), 359)
        let rise = NewSceneSupport.smooth(frame, 48, 143)
        let drain = NewSceneSupport.smooth(frame, 192, 291)
        liquid.position.y = NewSceneSupport.mix(-4.9, -0.15, rise) - drain * 5.2
        liquid.scale.y = NewSceneSupport.mix(0.03, 1, rise) * NewSceneSupport.mix(1, 0.04, drain)
        product.isEnabled = frame >= 252
        for (index, thread) in threads.enumerated() {
            let open = NewSceneSupport.smooth(frame, 192 + index * 4, 224 + index * 4)
            thread.isEnabled = open > 0
            thread.scale.y = NewSceneSupport.mix(0.02, 1, open) * NewSceneSupport.mix(1, 0.2, NewSceneSupport.smooth(frame, 292, 359))
        }
        stateOne.isEnabled = frame < 244; stateTwo.isEnabled = frame >= 244
        let pullback = NewSceneSupport.smooth(frame, 292, 335)
        camera.look(at: NewSceneSupport.mix([0, -1, 0.9], [0, 0.15, 0], pullback), from: NewSceneSupport.mix([0, -1.1, 4.1], [0, 0.35, 12.8], pullback), relativeTo: root)
    }
}
