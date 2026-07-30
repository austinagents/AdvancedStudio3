import AppKit
import ImageIO
import RealityKit

@MainActor
final class MarbleOrbitScene {
    let root: Entity
    let camera: PerspectiveCamera
    private let orbitRoot: Entity
    private let product: ModelEntity
    private let copyRoot: Entity
    private let orbiters: [ModelEntity]

    private init(root: Entity, camera: PerspectiveCamera, orbitRoot: Entity, product: ModelEntity, copyRoot: Entity, orbiters: [ModelEntity]) {
        self.root = root
        self.camera = camera
        self.orbitRoot = orbitRoot
        self.product = product
        self.copyRoot = copyRoot
        self.orbiters = orbiters
    }

    static func load(imageURL: URL) async throws -> MarbleOrbitScene {
        let root = try await NewSceneSupport.entity("MarbleOrbit")
        let shell = try NewSceneSupport.child("VoidShell", in: root)
        let orbitRoot = try NewSceneSupport.child("OrbitRoot", in: root)
        let productSlot = try NewSceneSupport.child("ProductSlot", in: root)
        let copyRoot = try NewSceneSupport.child("DiagonalCopyRoot", in: root)
        let cameraRig = try NewSceneSupport.child("RollCameraRig", in: root)
        let lightRig = try NewSceneSupport.child("KnifeLightRig", in: root)

        let background = ModelEntity(
            mesh: .generatePlane(width: 18, height: 28),
            materials: [UnlitMaterial(color: NSColor(red: 0.018, green: 0.016, blue: 0.022, alpha: 1))]
        )
        background.position = [0, 1.5, -4.2]
        shell.addChild(background)

        let marble = try await marbleMaterial()
        var orbiters: [ModelEntity] = []
        for index in 0..<42 {
            let orbiter = ModelEntity(
                mesh: .generateSphere(radius: 0.13 + Float(index % 3) * 0.045),
                materials: [marble]
            )
            orbiter.name = "MarbleOrbiter\(index)"
            orbitRoot.addChild(orbiter)
            orbiters.append(orbiter)
        }

        let product = try await NewSceneSupport.product(imageURL: imageURL, height: 2.65, name: "EclipseProduct")
        productSlot.addChild(product)

        let title = NewSceneSupport.text("IN ORBIT", fontName: "AvenirNextCondensed-DemiBold", size: 0.34, color: .white)
        title.position = [-2.3, -2.75, 0.45]
        copyRoot.addChild(title)

        let imageLight = try await legacyImageLight(parent: lightRig)
        NewSceneSupport.receiveIBL(orbiters, light: imageLight)

        let knife = SpotLight()
        knife.light = SpotLightComponent(
            color: NSColor(red: 0.76, green: 0.82, blue: 1, alpha: 1),
            intensity: 18_000,
            innerAngleInDegrees: 8,
            outerAngleInDegrees: 24,
            attenuationRadius: 18
        )
        knife.look(at: [0, 0, 0], from: [-4.5, 5.5, 5], relativeTo: root)
        lightRig.addChild(knife)

        let camera = NewSceneSupport.camera(focalLength: 72, name: "MarbleRollCamera")
        cameraRig.addChild(camera)
        let scene = MarbleOrbitScene(root: root, camera: camera, orbitRoot: orbitRoot, product: product, copyRoot: copyRoot, orbiters: orbiters)
        scene.apply(frameIndex: 359)
        return scene
    }

    func apply(frameIndex: Int) {
        let frame = min(max(frameIndex, 0), 359)
        let gather = NewSceneSupport.smooth(frame, 18, 176)
        let eclipse = NewSceneSupport.smooth(frame, 154, 242)
        let settle = NewSceneSupport.smooth(frame, 242, 316)

        for (index, orbiter) in orbiters.enumerated() {
            orbiter.isEnabled = index < 18
            let lane = Float(index % 3)
            let phase = Float(index) / Float(orbiters.count) * 2 * Float.pi
            let loosePhase = phase + Float(frame) * (0.004 + lane * 0.0015)
            let ringPhase = phase + Float(frame) * (0.010 - lane * 0.001)
            let angle = NewSceneSupport.mix(loosePhase, ringPhase, gather)
            let radius = NewSceneSupport.mix(4.8 + sin(phase * 5) * 0.8, 2.05 + lane * 0.28, gather)
            orbiter.position = [
                cos(angle) * radius,
                NewSceneSupport.mix(sin(phase * 2.7) * 3.4, sin(angle * (1 + lane * 0.18)) * (0.42 + lane * 0.18), gather),
                -0.8 + sin(angle) * (0.12 + lane * 0.08)
            ]
            orbiter.scale = .init(repeating: 0.62 + 0.08 * sin(Float(frame) * 0.05 + phase * 4))
        }

        orbitRoot.orientation = simd_quatf(angle: NewSceneSupport.mix(-0.48, 0.16, settle), axis: [0, 0, 1])
        product.isEnabled = eclipse > 0
        product.scale = .init(repeating: NewSceneSupport.mix(0.72, 1, eclipse))
        product.position = [0.38, NewSceneSupport.mix(-0.35, -0.12, eclipse), 0]
        copyRoot.isEnabled = frame >= 300
        copyRoot.orientation = simd_quatf(angle: -0.16, axis: [0, 0, 1])
        copyRoot.scale = .init(repeating: NewSceneSupport.smooth(frame, 300, 338))

        let cameraMove = NewSceneSupport.smooth(frame, 206, 318)
        camera.look(
            at: [0.25, -0.15, 0],
            from: NewSceneSupport.mix([-0.7, 0.55, 13.8], [1.1, 0.05, 13.5], cameraMove),
            relativeTo: root
        )
        camera.orientation *= simd_quatf(angle: NewSceneSupport.mix(-0.11, 0.055, cameraMove), axis: [0, 0, 1])
    }

    private static func marbleMaterial() async throws -> PhysicallyBasedMaterial {
        let diffuse = try await TextureResource(contentsOf: NewSceneSupport.resource("marble_01-4eeefea16242cecb3b429ac0c8f88740", extension: "jpg"))
        let normal = try await TextureResource(contentsOf: NewSceneSupport.resource("marble_01-normal-f25efb0b61ec7ac183b3b0f4d032ed17", extension: "jpg"))
        let roughness = try await TextureResource(contentsOf: NewSceneSupport.resource("marble_01-roughness-c4cf0375d84277c6020bf230823efdcc", extension: "jpg"))
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(texture: .init(diffuse))
        material.normal = .init(texture: .init(normal))
        material.roughness = .init(floatLiteral: 0.42)
        material.roughness.texture = .init(roughness)
        material.clearcoat = .init(floatLiteral: 0.18)
        return material
    }

    private static func legacyImageLight(parent: Entity) async throws -> Entity {
        let url = try NewSceneSupport.resource("studio_small_03-74e6ef69ea9024c2cc25b3a7de8ec2f7", extension: "hdr")
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw StudioError.missingSceneEntity("studio_small_03 HDR")
        }
        let environment = try await EnvironmentResource(equirectangular: image)
        let light = Entity()
        light.components.set(ImageBasedLightComponent(source: .single(environment), intensityExponent: 0.5))
        parent.addChild(light)
        return light
    }
}
