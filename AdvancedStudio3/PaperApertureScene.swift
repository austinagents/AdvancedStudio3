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
        let cycloramaRoot = try NewSceneSupport.child("CycloramaRoot", in: root)
        let irisRoot = try NewSceneSupport.child("PaperIrisRoot", in: root)
        let wellRoot = try NewSceneSupport.child("ProductWell", in: root)
        let liftRoot = try NewSceneSupport.child("ProductLift", in: root)
        let copyRoot = try NewSceneSupport.child("CircularCopyRoot", in: root)
        let cameraRig = try NewSceneSupport.child("TopCameraRig", in: root)
        let lightRoot = try NewSceneSupport.child("UmbrellaLightRig", in: root)

        let paper = try await NewSceneSupport.surfaceMaterial(
            id: "decrepit_wallpaper",
            tint: NSColor(red: 0.78, green: 0.69, blue: 0.57, alpha: 1)
        )
        var backdropMaterial = PhysicallyBasedMaterial()
        backdropMaterial.baseColor = .init(tint: NSColor(red: 0.12, green: 0.032, blue: 0.045, alpha: 1))
        backdropMaterial.roughness = 0.78
        let backdrop = ModelEntity(
            mesh: .generateCylinder(height: 0.24, radius: 7.2),
            materials: [backdropMaterial]
        )
        backdrop.position.y = -0.72
        cycloramaRoot.addChild(backdrop)
        let innerField = ModelEntity(
            mesh: .generateCylinder(height: 0.12, radius: 2.7),
            materials: [SimpleMaterial(
                color: NSColor(red: 0.31, green: 0.075, blue: 0.095, alpha: 1),
                roughness: 0.88,
                isMetallic: false
            )]
        )
        innerField.position.y = -0.53
        cycloramaRoot.addChild(innerField)
        var blades: [ModelEntity] = []
        for index in 0..<27 {
            let ring = index < 12 ? 0 : (index < 21 ? 1 : 2)
            let count = [12, 9, 6][ring]
            let localIndex = index - [0, 12, 21][ring]
            let radius: Float = [2.7, 1.85, 1.1][ring]
            let angle = Float(localIndex) / Float(count) * 2 * .pi
            let blade = ModelEntity(
                mesh: try taperedPaperMesh(
                    innerWidth: [0.34, 0.30, 0.24][ring],
                    outerWidth: [1.18, 0.92, 0.64][ring],
                    length: radius
                ),
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
            mesh: .generateCylinder(height: 0.48, radius: 1.28),
            materials: [wellMaterial]
        )
        well.position.y = -0.34
        wellRoot.addChild(well)
        var rimMaterial = PhysicallyBasedMaterial()
        rimMaterial.baseColor = .init(tint: NSColor(red: 0.62, green: 0.46, blue: 0.31, alpha: 1))
        rimMaterial.roughness = 0.42
        rimMaterial.metallic = 0.16
        let rim = ModelEntity(
            mesh: .generateCylinder(height: 0.08, radius: 1.40),
            materials: [rimMaterial]
        )
        rim.position.y = -0.06
        wellRoot.addChild(rim)

        let product = try await NewSceneSupport.product(
            imageURL: imageURL,
            height: 2.0,
            name: "PaperApertureProduct"
        )
        product.position = [0, -1.4, 0.1]
        product.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        liftRoot.addChild(product)

        let copy = NewSceneSupport.text(
            "OPEN / POSSIBILITY",
            fontName: "Didot",
            size: 0.11,
            color: NSColor(red: 0.93, green: 0.82, blue: 0.68, alpha: 1)
        )
        copy.position = [-0.9, 0.9, -2.15]
        copy.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        copyRoot.addChild(copy)

        let ibl = try await NewSceneSupport.imageLight(
            id: "cyclorama_hard_light",
            exponent: 0.7,
            parent: lightRoot
        )
        NewSceneSupport.receiveIBL([backdrop, innerField, well, rim] + blades, light: ibl)
        let key = SpotLight()
        key.light = .init(
            color: NSColor(red: 1, green: 0.79, blue: 0.62, alpha: 1),
            intensity: 16_000,
            innerAngleInDegrees: 28,
            outerAngleInDegrees: 65,
            attenuationRadius: 28
        )
        key.look(at: [0, 0, 0], from: [-5, 10, 6], relativeTo: root)
        lightRoot.addChild(key)

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
            blades[index].isEnabled = true
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
                angle: open * (ring == 2 ? -.pi * 0.18 : .pi * 0.24),
                axis: [1, 0, 0]
            )
            blades[index].orientation = base * fold
            let radius: Float = [2.7, 1.85, 1.1][ring]
            let finalClear = NewSceneSupport.smooth(frame, 286, 318)
            let outward = NewSceneSupport.mix(
                radius * 0.48,
                radius * NewSceneSupport.mix(0.76, 1.08, finalClear),
                open
            )
            blades[index].position = [
                sin(angle) * outward,
                open * (ring == 2 ? -0.5 : 0.35),
                cos(angle) * outward
            ]
            if ring == 2 {
                blades[index].isEnabled = frame < 300
            } else if frame >= 316 && (index == 6 || index == 16 || index == 17) {
                blades[index].isEnabled = false
            }
        }
        product.isEnabled = frame >= 252
        product.position.y = NewSceneSupport.mix(-1.4, 0.12, NewSceneSupport.smooth(frame, 252, 292))
        let cameraProgress = NewSceneSupport.smooth(frame, 260, 315)
        camera.look(
            at: NewSceneSupport.mix([0, 0, 0], [0, -0.25, 0], cameraProgress),
            from: NewSceneSupport.mix([0, 22, 0.15], [0, 20, 5.0], cameraProgress),
            relativeTo: root
        )
        copy.isEnabled = frame >= 316
    }

    private static func taperedPaperMesh(
        innerWidth: Float,
        outerWidth: Float,
        length: Float
    ) throws -> MeshResource {
        let halfInner = innerWidth / 2
        let halfOuter = outerWidth / 2
        let halfLength = length / 2
        var descriptor = MeshDescriptor(name: "TaperedPaperBlade")
        descriptor.positions = .init([
            [-halfInner, 0, -halfLength],
            [halfInner, 0.008, -halfLength],
            [-halfOuter, -0.006, halfLength],
            [halfOuter, 0.012, halfLength]
        ])
        descriptor.normals = .init(Array(repeating: SIMD3<Float>(0, 1, 0), count: 4))
        descriptor.textureCoordinates = .init([[0.32, 0], [0.68, 0], [0, 1], [1, 1]])
        descriptor.primitives = .triangles([0, 2, 1, 1, 2, 3])
        return try MeshResource.generate(from: [descriptor])
    }
}
