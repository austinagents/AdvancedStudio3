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
        for index in 0..<43 {
            let row = index / 7
            let column = index % 7
            let width = 0.94 + Float((row + column) % 3) * 0.035
            let height = 1.12 + Float((row * 2 + column) % 3) * 0.045
            let piece = ModelEntity(
                mesh: .generateBox(width: width, height: height, depth: 0.18, cornerRadius: 0.045),
                materials: [tile]
            )
            piece.name = "CeramicFragment\(index)"
            piece.position = [
                (Float(column) - 3) * 1.02,
                (Float(row) - 3) * 1.2,
                Float((row + column) % 2) * 0.025
            ]
            fragmentRoot.addChild(piece)
            fragments.append(piece)
        }
        var wallMaterial = PhysicallyBasedMaterial()
        wallMaterial.baseColor = .init(tint: NSColor(red: 0.075, green: 0.032, blue: 0.024, alpha: 1))
        wallMaterial.roughness = 0.82
        let wall = ModelEntity(
            mesh: .generateBox(width: 9.5, height: 11.5, depth: 0.42, cornerRadius: 0.08),
            materials: [wallMaterial]
        )
        wall.position = [0, 0, -0.42]
        facade.addChild(wall)
        let cavity = ModelEntity(
            mesh: .generateBox(width: 3.5, height: 5.0, depth: 0.3, cornerRadius: 0.28),
            materials: [UnlitMaterial(color: NSColor(red: 0.12, green: 0.035, blue: 0.02, alpha: 1))]
        )
        cavity.position = [0, -0.15, 0.08]
        facade.addChild(cavity)
        let ledge = ModelEntity(
            mesh: .generateBox(width: 3.2, height: 0.34, depth: 1.5, cornerRadius: 0.09),
            materials: [wallMaterial]
        )
        ledge.position = [0, -2.38, 0.45]
        facade.addChild(ledge)

        let product = try await NewSceneSupport.product(imageURL: imageURL, height: 3.15, name: "FixedProduct")
        product.position = [0, -0.72, 0.72]
        productSlot.addChild(product)

        let copy = NewSceneSupport.text("BREAK THROUGH", fontName: "AvenirNextCondensed-Medium", size: 0.30, color: .white, depth: 0.008)
        copy.position = [-1.18, 2.75, 0.72]
        copyRoot.addChild(copy)

        let ibl = try await NewSceneSupport.imageLight(id: "courtyard", exponent: 0.15, parent: lightRig)
        NewSceneSupport.receiveIBL([wall, cavity, ledge] + fragments, light: ibl)
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
            let origin = fragmentOrigins[index]
            let radial = simd_normalize(SIMD3<Float>(origin.x, origin.y + 0.15, 0.8))
            let nearCenter = simd_length(SIMD2<Float>(origin.x, origin.y)) < 2.25
            fragment.position = origin + radial * (impact * impact) * (nearCenter ? 4.8 : 0.55)
            fragment.scale = .init(repeating: NewSceneSupport.mix(1, nearCenter ? 0.78 : 0.98, impact))
            fragment.orientation = simd_quatf(angle: impact * (0.4 + Float(index % 9) * 0.11), axis: simd_normalize([sin(phase), cos(phase), 0.7]))
            if nearCenter {
                fragment.isEnabled = frame < 292
            }
        }
        product.isEnabled = frame >= 252
        copy.isEnabled = frame >= 278
        copy.position.y = NewSceneSupport.mix(-5.7, -4.65, NewSceneSupport.smooth(frame, 278, 307))
        let impulse = frame >= 103 && frame <= 124 ? sin(Float(frame - 103) * 0.9) * exp(-Float(frame - 103) * 0.18) * 0.11 : 0
        camera.look(at: [0, -0.2, 0], from: [0.25, -0.2, 11.8 - impulse], relativeTo: root)
    }
}
