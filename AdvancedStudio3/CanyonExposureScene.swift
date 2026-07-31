import AppKit
import RealityKit

@MainActor
final class CanyonExposureScene {
    let root: Entity
    let camera: PerspectiveCamera
    private let product: ModelEntity
    private let strata: [ModelEntity]
    private let copy: ModelEntity

    private init(root: Entity, camera: PerspectiveCamera, product: ModelEntity, strata: [ModelEntity], copy: ModelEntity) {
        self.root = root; self.camera = camera; self.product = product; self.strata = strata; self.copy = copy
    }

    static func load(imageURL: URL) async throws -> CanyonExposureScene {
        let root = try await NewSceneSupport.entity("CanyonExposure")
        let world = try NewSceneSupport.child("DesertWorld", in: root)
        let strataRoot = try NewSceneSupport.child("StrataRoot", in: root)
        let productRoot = try NewSceneSupport.child("EmbeddedProductSlot", in: root)
        let copyRoot = try NewSceneSupport.child("GroundEtchedCopy", in: root)
        let cameraRig = try NewSceneSupport.child("CraneCameraRig", in: root)
        let lights = try NewSceneSupport.child("DesertSunRig", in: root)
        let cliff = try await NewSceneSupport.surfaceMaterial(id: "cliff_side")
        let sky = ModelEntity(
            mesh: .generatePlane(width: 24, height: 30),
            materials: [UnlitMaterial(color: NSColor(red: 0.12, green: 0.055, blue: 0.025, alpha: 1))]
        )
        sky.position = [0, 3, -5]
        world.addChild(sky)

        let ground = ModelEntity(mesh: .generateBox(width: 18, height: 0.25, depth: 18), materials: [cliff])
        ground.position = [0, -5.35, -1.5]; world.addChild(ground)
        var strata: [ModelEntity] = []
        for index in 0..<64 {
            let layer = ModelEntity(
                mesh: .generateBox(width: 8.5 - Float(index % 5) * 0.1, height: 0.17, depth: 3.2 - Float(index % 7) * 0.08, cornerRadius: 0.035),
                materials: [cliff]
            )
            layer.position = [sin(Float(index) * 1.91) * 0.22, -5.15 + Float(index) * 0.16, -0.4 + cos(Float(index) * 1.37) * 0.12]
            strataRoot.addChild(layer); strata.append(layer)
        }
        let product = try await NewSceneSupport.product(imageURL: imageURL, height: 2.35, name: "EmbeddedProduct")
        product.position = [1.15, -1, 0.3]; productRoot.addChild(product)
        let copy = NewSceneSupport.text("REVEALED BY TIME", fontName: "Optima-Regular", size: 0.27, color: NSColor(red: 0.42, green: 0.19, blue: 0.07, alpha: 1), depth: 0.012)
        copy.position = [-2.6, -5.1, 2.8]; copy.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0]); copyRoot.addChild(copy)
        let ibl = try await NewSceneSupport.imageLight(id: "goegap", exponent: 0.2, parent: lights)
        NewSceneSupport.receiveIBL([ground] + strata, light: ibl)
        let sun = DirectionalLight(); sun.light = .init(color: NSColor(red: 1, green: 0.56, blue: 0.26, alpha: 1), intensity: 18_000)
        sun.look(at: [0, 0, 0], from: [-8, 2.5, 4], relativeTo: root); lights.addChild(sun)
        let camera = NewSceneSupport.camera(focalLength: 24, name: "CanyonCraneCamera"); cameraRig.addChild(camera)
        let scene = CanyonExposureScene(root: root, camera: camera, product: product, strata: strata, copy: copy)
        scene.apply(frameIndex: 359); return scene
    }

    func apply(frameIndex: Int) {
        let frame = min(max(frameIndex, 0), 359)
        for (index, layer) in strata.enumerated() {
            let removalStart: Int
            if index < 18 { removalStart = 72 + index }
            else if index < 40 { removalStart = 140 + (index - 18) }
            else { removalStart = 224 + (index - 40) * 2 }
            let erosion = NewSceneSupport.smooth(frame, removalStart, removalStart + 14)
            layer.scale.x = NewSceneSupport.mix(1, 0.001, erosion)
            layer.position.x = sin(Float(index) * 1.91) * 0.22 + erosion * (index.isMultiple(of: 2) ? -4.6 : 4.6)
        }
        product.isEnabled = frame >= 252
        let crane = NewSceneSupport.smooth(frame, 0, 339)
        camera.look(at: NewSceneSupport.mix([1.15, -1.1, 0], [0.35, 0.2, 0], crane), from: NewSceneSupport.mix([0.4, -3.1, 6.2], [0.4, 4.8, 13.5], crane), relativeTo: root)
        copy.isEnabled = frame >= 340
    }
}
