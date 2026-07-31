import AppKit
import RealityKit

@MainActor
final class MagneticConvergenceScene {
    let root: Entity
    let camera: PerspectiveCamera
    private let plates: [ModelEntity]
    private let origins: [SIMD3<Float>]
    private let product: ModelEntity
    private let letters: [ModelEntity]
    private let pulses: [PointLight]

    private init(root: Entity, camera: PerspectiveCamera, plates: [ModelEntity], origins: [SIMD3<Float>], product: ModelEntity, letters: [ModelEntity], pulses: [PointLight]) {
        self.root = root; self.camera = camera; self.plates = plates; self.origins = origins
        self.product = product; self.letters = letters; self.pulses = pulses
    }

    static func load(imageURL: URL) async throws -> MagneticConvergenceScene {
        let root = try await NewSceneSupport.entity("MagneticConvergence")
        let plateRoot = try NewSceneSupport.child("FreePlateRoot", in: root)
        let productRoot = try NewSceneSupport.child("ProductSlot", in: root)
        let copyRoot = try NewSceneSupport.child("MechanicalCopyRoot", in: root)
        let cameraRig = try NewSceneSupport.child("OrbitCameraRig", in: root)
        let lights = try NewSceneSupport.child("PulseLightRoot", in: root)
        let metal = try await NewSceneSupport.surfaceMaterial(id: "metal_plate_02", metallic: true)
        var plateMetal = PhysicallyBasedMaterial()
        plateMetal.baseColor = .init(tint: NSColor(white: 0.42, alpha: 1))
        plateMetal.metallic = 0.92
        plateMetal.roughness = 0.24
        let chamber = ModelEntity(
            mesh: .generateBox(width: 13, height: 11, depth: 0.42, cornerRadius: 0.1),
            materials: [metal]
        )
        chamber.position = [0, 0.6, -3.4]
        plateRoot.addChild(chamber)
        let floor = ModelEntity(mesh: .generateBox(width: 13, height: 0.28, depth: 12, cornerRadius: 0.1), materials: [metal])
        floor.position = [0, -3.65, 0.8]
        plateRoot.addChild(floor)
        for side: Float in [-1, 1] {
            let wall = ModelEntity(
                mesh: .generateBox(width: 0.34, height: 10, depth: 11, cornerRadius: 0.07),
                materials: [metal]
            )
            wall.position = [side * 6.1, 0.2, 0.5]
            plateRoot.addChild(wall)
        }
        for index in 0..<5 {
            let rail = ModelEntity(
                mesh: .generateBox(width: 10.8, height: 0.12, depth: 0.18, cornerRadius: 0.035),
                materials: [metal]
            )
            rail.position = [0, -2.5 + Float(index) * 1.65, -3.08]
            plateRoot.addChild(rail)
        }
        for side: Float in [-1, 1] {
            for level in 0..<3 {
                let emitter = ModelEntity(
                    mesh: .generateBox(width: 0.07, height: 1.15, depth: 0.08, cornerRadius: 0.025),
                    materials: [UnlitMaterial(color: NSColor(red: 0.48, green: 0.78, blue: 1, alpha: 1))]
                )
                emitter.position = [side * 3.9, -1.8 + Float(level) * 2.0, -3.12]
                plateRoot.addChild(emitter)
            }
        }
        var plates: [ModelEntity] = [], origins: [SIMD3<Float>] = []
        for index in 0..<96 {
            let size: Float = index < 36 ? 0.18 : index < 72 ? 0.28 : 0.42
            let plate = ModelEntity(mesh: .generateBox(width: size, height: size * 0.58, depth: 0.09, cornerRadius: 0.025), materials: [plateMetal])
            let path = Float(index % 3)
            let phase = Float(index) * 2.399963
            let origin = SIMD3<Float>(cos(phase) * (5.2 + path * 0.8), sin(phase * 0.73) * 4.2, -1.2 + path * 1.2)
            plate.position = origin; plateRoot.addChild(plate); plates.append(plate); origins.append(origin)
        }
        let product = try await NewSceneSupport.litProduct(imageURL: imageURL, height: 2.6, name: "MagneticProduct", roughness: 0.24)
        product.position = [0, -2.18, 0.8]
        productRoot.addChild(product)
        let title = NewSceneSupport.text("DRAWN TOGETHER", fontName: "DINCondensed-Bold", size: 0.22, color: .white)
        title.position = [-1.42, 2.05, 1.1]
        copyRoot.addChild(title)
        let letters = [title]
        let ibl = try await NewSceneSupport.imageLight(id: "aircraft_workshop_01", exponent: 1.0, parent: lights)
        NewSceneSupport.receiveIBL(
            [chamber, floor, product]
                + plateRoot.children.compactMap { $0 as? ModelEntity }
                + plates,
            light: ibl
        )
        let redBack = SpotLight()
        redBack.light = .init(color: NSColor(red: 1, green: 0.06, blue: 0.03, alpha: 1), intensity: 12_000, innerAngleInDegrees: 28, outerAngleInDegrees: 62, attenuationRadius: 16)
        redBack.look(at: [0, 0, 0], from: [0, 1, -5], relativeTo: root)
        lights.addChild(redBack)
        let productKey = SpotLight()
        productKey.light = .init(
            color: NSColor(red: 0.78, green: 0.9, blue: 1, alpha: 1),
            intensity: 12_000,
            innerAngleInDegrees: 24,
            outerAngleInDegrees: 54,
            attenuationRadius: 14
        )
        productKey.look(at: [0, -1.2, 0.8], from: [3.5, 2.8, 5.5], relativeTo: root)
        lights.addChild(productKey)
        var pulses: [PointLight] = []
        for index in 0..<18 {
            let angle = Float(index) / 18 * 2 * Float.pi
            let pulse = PointLight(); pulse.light = .init(color: .white, intensity: 0, attenuationRadius: 2.2)
            pulse.position = [cos(angle) * 2.4, sin(angle) * 2.4, 0.4]; lights.addChild(pulse); pulses.append(pulse)
        }
        let camera = NewSceneSupport.camera(focalLength: 38, name: "MagneticOrbitCamera"); cameraRig.addChild(camera)
        let scene = MagneticConvergenceScene(root: root, camera: camera, plates: plates, origins: origins, product: product, letters: letters, pulses: pulses)
        scene.apply(frameIndex: 359); return scene
    }

    func apply(frameIndex: Int) {
        let frame = min(max(frameIndex, 0), 359)
        product.isEnabled = frame >= 276
        for letter in letters {
            letter.isEnabled = frame >= 320
        }
        for index in plates.indices {
            let group = index / 32
            let attraction = NewSceneSupport.smooth(frame, 32 + group * 62 + (index % 32) / 3, 92 + group * 62)
            let angle = Float(index) / Float(plates.count) * 2 * Float.pi
            let radialOffset = Float(index % 3 - 1) * 0.075
            let target = SIMD3<Float>(
                cos(angle) * (2.72 + radialOffset),
                sin(angle) * (2.72 + radialOffset),
                Float(index % 4) * 0.018
            )
            let curve = SIMD3<Float>(sin(Float(index) * 1.13), cos(Float(index) * 0.77), sin(Float(index) * 0.51)) * sin(attraction * .pi) * 1.8
            plates[index].position = NewSceneSupport.mix(origins[index], target, attraction) + curve
            plates[index].orientation = simd_quatf(angle: angle + attraction * .pi, axis: [0, 0, 1])
        }
        for index in pulses.indices {
            let lockFrame = 224 + index * 3
            let age = max(0, frame - lockFrame)
            pulses[index].light.intensity = age < 6
                ? 7_500 * (1 - Float(age) / 6)
                : (frame >= 276 ? 620 : 0)
        }
        for (index, letter) in letters.enumerated() {
            let snap = NewSceneSupport.smooth(frame, 320 + index * 2, 324 + index * 2)
            letter.position.y = NewSceneSupport.mix(2.65, 2.05, snap)
        }
        let orbit = NewSceneSupport.smooth(frame, 0, 319)
        let angle = NewSceneSupport.mix(-22 * .pi / 180, 0, orbit)
        let radius = NewSceneSupport.mix(12.2, 10.4, orbit)
        let cameraPosition = SIMD3<Float>(sin(angle) * radius, NewSceneSupport.mix(1.9, 0.1, orbit), cos(angle) * radius)
        camera.look(at: [0, -0.25, 0], from: cameraPosition, relativeTo: root)
        let facing = atan2(cameraPosition.x, cameraPosition.z)
        product.orientation = simd_quatf(angle: facing, axis: [0, 1, 0])
        for letter in letters { letter.orientation = simd_quatf(angle: facing, axis: [0, 1, 0]) }
    }
}
