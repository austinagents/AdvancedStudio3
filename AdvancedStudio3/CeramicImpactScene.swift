import AppKit
import RealityKit

@MainActor
final class CeramicImpactScene {
    let root: Entity
    let camera: PerspectiveCamera
    private let product: ModelEntity
    private let fragments: [ModelEntity]
    private let fragmentOrigins: [SIMD3<Float>]
    private let copy: ModelEntity

    private init(root: Entity, camera: PerspectiveCamera, product: ModelEntity, fragments: [ModelEntity], fragmentOrigins: [SIMD3<Float>], copy: ModelEntity) {
        self.root = root
        self.camera = camera
        self.product = product
        self.fragments = fragments
        self.fragmentOrigins = fragmentOrigins
        self.copy = copy
    }

    static func load(imageURL: URL) async throws -> CeramicImpactScene {
        let root = try await NewSceneSupport.entity("CeramicImpact")
        let facade = try NewSceneSupport.child("FacadeRoot", in: root)
        let fragmentRoot = try NewSceneSupport.child("FractureFragmentRoot", in: root)
        let productSlot = try NewSceneSupport.child("FixedProductSlot", in: root)
        let copyRoot = try NewSceneSupport.child("BottomCopyRoot", in: root)
        let cameraRig = try NewSceneSupport.child("LockedCameraRig", in: root)
        let lightRig = try NewSceneSupport.child("SunAndBounceRig", in: root)

        let tile = try await NewSceneSupport.surfaceMaterial(id: "long_white_tiles")
        var fragments: [ModelEntity] = []
        var seed: UInt64 = 0xC3A51C
        func random() -> Float {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1
            return Float((seed >> 40) & 0xFFFFFF) / Float(0xFFFFFF)
        }
        for index in 0..<43 {
            let width = 0.62 + random() * 0.72
            let height = 0.58 + random() * 0.9
            let piece = ModelEntity(mesh: .generateBox(width: width, height: height, depth: 0.08 + random() * 0.08, cornerRadius: 0.025), materials: [tile])
            piece.name = "CeramicFragment\(index)"
            piece.position = [-3.2 + random() * 6.4, -5.1 + random() * 10.2, random() * 0.08]
            fragmentRoot.addChild(piece)
            fragments.append(piece)
        }
        let cavity = ModelEntity(
            mesh: .generateBox(width: 4.4, height: 6.2, depth: 0.16, cornerRadius: 0.18),
            materials: [UnlitMaterial(color: NSColor(red: 0.12, green: 0.035, blue: 0.02, alpha: 1))]
        )
        cavity.position = [-0.68, -0.35, -0.7]
        facade.addChild(cavity)

        let product = try await NewSceneSupport.product(imageURL: imageURL, height: 2.45, name: "FixedProduct")
        product.position = [-0.68, -0.35, -0.35]
        productSlot.addChild(product)

        let copy = NewSceneSupport.text("BREAK THROUGH", fontName: "AvenirNextCondensed-Heavy", size: 0.52, color: .white, depth: 0.008)
        copy.position = [-3.35, -4.65, 0.6]
        copyRoot.addChild(copy)

        let ibl = try await NewSceneSupport.imageLight(id: "courtyard", exponent: 0.15, parent: lightRig)
        NewSceneSupport.receiveIBL(fragments, light: ibl)
        let sun = DirectionalLight()
        sun.light = .init(color: NSColor(red: 1, green: 0.72, blue: 0.48, alpha: 1), intensity: 14_000)
        sun.look(at: [0, 0, 0], from: [-5, 7, 6], relativeTo: root)
        lightRig.addChild(sun)

        let camera = NewSceneSupport.camera(focalLength: 32, name: "LockedImpactCamera")
        cameraRig.addChild(camera)
        let scene = CeramicImpactScene(root: root, camera: camera, product: product, fragments: fragments, fragmentOrigins: fragments.map(\.position), copy: copy)
        scene.apply(frameIndex: 359)
        return scene
    }

    func apply(frameIndex: Int) {
        let frame = min(max(frameIndex, 0), 359)
        let impact = NewSceneSupport.smooth(frame, 103, 219)
        for (index, fragment) in fragments.enumerated() {
            let phase = Float(index) * 2.399963
            let direction = SIMD3<Float>(cos(phase), 0.35 + Float(index % 7) * 0.08, sin(phase) * 0.45 + 0.8)
            fragment.position = fragmentOrigins[index] + direction * (impact * impact) * (4.2 + Float(index % 5) * 0.8)
            fragment.scale = .init(repeating: NewSceneSupport.mix(1, 0.72, impact))
            fragment.orientation = simd_quatf(angle: impact * (0.4 + Float(index % 9) * 0.11), axis: simd_normalize([sin(phase), cos(phase), 0.7]))
        }
        product.isEnabled = frame >= 252
        copy.isEnabled = frame >= 278
        copy.position.y = NewSceneSupport.mix(-5.7, -4.65, NewSceneSupport.smooth(frame, 278, 307))
        let impulse = frame >= 103 && frame <= 124 ? sin(Float(frame - 103) * 0.9) * exp(-Float(frame - 103) * 0.18) * 0.11 : 0
        camera.look(at: [-0.35, -0.15, 0], from: [0.45, -0.6, 10.6 - impulse], relativeTo: root)
    }
}
