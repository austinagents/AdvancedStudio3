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
        let distantCliff = try await NewSceneSupport.surfaceMaterial(
            id: "cliff_side",
            tint: NSColor(red: 0.36, green: 0.17, blue: 0.09, alpha: 1)
        )
        let rearEscarpment = ModelEntity(
            mesh: .generateBox(width: 18, height: 14, depth: 0.8, cornerRadius: 0.18),
            materials: [distantCliff]
        )
        rearEscarpment.position = [0, 1.8, -7.2]
        world.addChild(rearEscarpment)
        for side: Float in [-1, 1] {
            let canyonWall = ModelEntity(
                mesh: .generateBox(width: 3.6, height: 12, depth: 15, cornerRadius: 0.22),
                materials: [cliff]
            )
            canyonWall.position = [side * 6.7, 0.4, -0.8]
            canyonWall.orientation = simd_quatf(angle: side * 0.045, axis: [0, 1, 0])
            world.addChild(canyonWall)
        }

        let ground = ModelEntity(mesh: .generateBox(width: 18, height: 0.35, depth: 20, cornerRadius: 0.12), materials: [cliff])
        ground.position = [0, -4.35, -1.5]; world.addChild(ground)
        var strata: [ModelEntity] = []
        for index in 0..<36 {
            let side: Float = index.isMultiple(of: 2) ? -1 : 1
            let level = index / 2
            let layer = ModelEntity(
                mesh: .generateBox(
                    width: 3.8 + Float(index % 4) * 0.22,
                    height: 0.42 + Float(index % 3) * 0.05,
                    depth: 5.5 - Float(index % 5) * 0.24,
                    cornerRadius: 0.10
                ),
                materials: [cliff]
            )
            layer.position = [
                side * (3.2 + sin(Float(level) * 1.37) * 0.28),
                -4.0 + Float(level) * 0.43,
                -0.7 + cos(Float(level) * 1.11) * 0.35
            ]
            layer.orientation = simd_quatf(angle: side * (0.035 + Float(level % 4) * 0.012), axis: [0, 0, 1])
            strataRoot.addChild(layer); strata.append(layer)
        }
        let product = try await NewSceneSupport.product(imageURL: imageURL, height: 3.0, name: "EmbeddedProduct")
        product.position = [0.4, -2.65, 0.65]; productRoot.addChild(product)
        let copy = NewSceneSupport.text("REVEALED BY TIME", fontName: "Optima-Regular", size: 0.22, color: NSColor(red: 0.96, green: 0.72, blue: 0.48, alpha: 1), depth: 0.012)
        copy.position = [-1.18, 2.0, 0.8]; copyRoot.addChild(copy)
        let ibl = try await NewSceneSupport.imageLight(id: "goegap", exponent: 0.2, parent: lights)
        NewSceneSupport.receiveIBL(
            [rearEscarpment, ground]
                + world.children.compactMap { $0 as? ModelEntity }
                + strata,
            light: ibl
        )
        let sun = DirectionalLight(); sun.light = .init(color: NSColor(red: 1, green: 0.56, blue: 0.26, alpha: 1), intensity: 18_000)
        sun.look(at: [0, 0, 0], from: [-8, 2.5, 4], relativeTo: root); lights.addChild(sun)
        let camera = NewSceneSupport.camera(focalLength: 24, name: "CanyonCraneCamera"); cameraRig.addChild(camera)
        let scene = CanyonExposureScene(root: root, camera: camera, product: product, strata: strata, copy: copy)
        scene.apply(frameIndex: 359); return scene
    }

    func apply(frameIndex: Int) {
        let frame = min(max(frameIndex, 0), 359)
        for (index, layer) in strata.enumerated() {
            let removalStart = 82 + (index / 2) * 8
            let erosion = NewSceneSupport.smooth(frame, removalStart, removalStart + 14)
            let side: Float = index.isMultiple(of: 2) ? -1 : 1
            let level = index / 2
            let baseX = side * (3.2 + sin(Float(level) * 1.37) * 0.28)
            layer.position.x = baseX + side * erosion * 0.85
        }
        product.isEnabled = frame >= 252
        let crane = NewSceneSupport.smooth(frame, 0, 315)
        camera.look(at: NewSceneSupport.mix([0.4, -1.1, 0], [0.4, -0.35, 0.2], crane), from: NewSceneSupport.mix([-1.4, -1.2, 8.2], [1.2, 1.5, 12.0], crane), relativeTo: root)
        copy.isEnabled = frame >= 320
    }
}
