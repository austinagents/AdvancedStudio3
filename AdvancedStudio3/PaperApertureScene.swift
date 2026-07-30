import AppKit
import RealityKit

@MainActor
final class PaperApertureScene {
    let root: Entity
    let camera: PerspectiveCamera

    private let blades: [ModelEntity]
    private let product: ModelEntity
    private let copy: Entity

    private init(
        root: Entity,
        camera: PerspectiveCamera,
        blades: [ModelEntity],
        product: ModelEntity,
        copy: Entity
    ) {
        self.root = root
        self.camera = camera
        self.blades = blades
        self.product = product
        self.copy = copy
    }

    static func load(imageURL: URL) async throws -> PaperApertureScene {
        let root = try await NewSceneSupport.entity("PaperAperture")
        let irisRoot = try NewSceneSupport.child("PaperIrisRoot", in: root)
        let wellRoot = try NewSceneSupport.child("ProductWell", in: root)
        let liftRoot = try NewSceneSupport.child("ProductLift", in: root)
        let copyRoot = try NewSceneSupport.child("CircularCopyRoot", in: root)
        let cameraRig = try NewSceneSupport.child("TopCameraRig", in: root)
        let lightRoot = try NewSceneSupport.child("UmbrellaLightRig", in: root)

        let paper = try await NewSceneSupport.surfaceMaterial(id: "decrepit_wallpaper")
        var blades: [ModelEntity] = []
        for index in 0..<27 {
            let ring = index < 12 ? 0 : (index < 21 ? 1 : 2)
            let count = [12, 9, 6][ring]
            let localIndex = index - [0, 12, 21][ring]
            let radius: Float = [2.7, 1.85, 1.1][ring]
            let angle = Float(localIndex) / Float(count) * 2 * .pi
            let blade = ModelEntity(
                mesh: .generateBox(width: 0.72, height: 0.012, depth: radius),
                materials: [paper]
            )
            blade.position = [sin(angle) * radius * 0.48, 0, cos(angle) * radius * 0.48]
            blade.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
            blade.name = "PaperBlade\(index)"
            irisRoot.addChild(blade)
            blades.append(blade)
        }

        var wellMaterial = PhysicallyBasedMaterial()
        wellMaterial.baseColor = .init(tint: NSColor(red: 0.22, green: 0.03, blue: 0.08, alpha: 1))
        wellMaterial.roughness = 0.86
        let well = ModelEntity(
            mesh: .generateCylinder(height: 0.38, radius: 1.22),
            materials: [wellMaterial]
        )
        well.position.y = -0.34
        wellRoot.addChild(well)

        let product = try await NewSceneSupport.product(
            imageURL: imageURL,
            height: 3.0,
            name: "PaperApertureProduct"
        )
        product.position = [0, -1.25, 0.1]
        product.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        liftRoot.addChild(product)

        let copy = NewSceneSupport.text(
            "OPEN  TO  POSSIBILITY",
            fontName: "Didot",
            size: 0.24,
            color: NSColor(red: 0.25, green: 0.04, blue: 0.12, alpha: 1)
        )
        copy.position = [-2.2, -1.7, 0.4]
        copy.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        copyRoot.addChild(copy)

        let ibl = try await NewSceneSupport.imageLight(
            id: "cyclorama_hard_light",
            exponent: 0.7,
            parent: lightRoot
        )
        NewSceneSupport.receiveIBL([well] + blades, light: ibl)

        let camera = NewSceneSupport.camera(focalLength: 90, name: "PaperApertureCamera")
        cameraRig.addChild(camera)
        let scene = PaperApertureScene(
            root: root,
            camera: camera,
            blades: blades,
            product: product,
            copy: copy
        )
        scene.apply(frameIndex: 359)
        return scene
    }

    func apply(frameIndex: Int) {
        let frame = AdSpecification.premiumTwelveSeconds.clamped(frameIndex)
        for index in blades.indices {
            let ring = index < 12 ? 0 : (index < 21 ? 1 : 2)
            let starts = [24, 84, 156]
            let ends = [83, 155, 213]
            let localDelay = index % [12, 9, 6][ring]
            let open = NewSceneSupport.smooth(
                frame,
                starts[ring] + localDelay * (ring == 0 ? 4 : 2),
                ends[ring]
            )
            let count = [12, 9, 6][ring]
            let localIndex = index - [0, 12, 21][ring]
            let angle = Float(localIndex) / Float(count) * 2 * .pi
            let base = simd_quatf(angle: angle, axis: [0, 1, 0])
            let fold = simd_quatf(
                angle: open * (ring == 2 ? -.pi * 0.46 : .pi * 0.54),
                axis: [1, 0, 0]
            )
            blades[index].orientation = base * fold
            let radius: Float = [2.7, 1.85, 1.1][ring]
            let outward = NewSceneSupport.mix(radius * 0.48, radius * 1.08, open)
            blades[index].position = [
                sin(angle) * outward,
                open * (ring == 2 ? -0.5 : 0.35),
                cos(angle) * outward
            ]
        }
        let lift = NewSceneSupport.smooth(frame, 214, 259)
        product.position.y = NewSceneSupport.mix(-1.25, 0.1, lift)
        let cameraProgress = NewSceneSupport.smooth(frame, 260, 315)
        camera.look(
            at: NewSceneSupport.mix([0, 0, 0], [0, -0.25, 0], cameraProgress),
            from: NewSceneSupport.mix([0, 22, 0.15], [0, 18, 6.0], cameraProgress),
            relativeTo: root
        )
        copy.isEnabled = frame >= 316
    }
}
