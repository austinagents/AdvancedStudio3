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
        var plates: [ModelEntity] = [], origins: [SIMD3<Float>] = []
        for index in 0..<180 {
            let size: Float = index < 72 ? 0.16 : index < 126 ? 0.24 : index < 162 ? 0.34 : 0.48
            let plate = ModelEntity(mesh: .generateBox(width: size, height: size * 0.62, depth: 0.035, cornerRadius: 0.012), materials: [metal])
            let path = Float(index % 3)
            let phase = Float(index) * 2.399963
            let origin = SIMD3<Float>(cos(phase) * (5.8 + path), sin(phase * 0.73) * 4.6, -1.8 + path * 1.8)
            plate.position = origin; plateRoot.addChild(plate); plates.append(plate); origins.append(origin)
        }
        let product = try await NewSceneSupport.product(imageURL: imageURL, height: 3.4, name: "MagneticProduct")
        productRoot.addChild(product)
        var letters: [ModelEntity] = []
        for (index, character) in Array("DRAWN TOGETHER").enumerated() {
            guard character != " " else { continue }
            let letter = NewSceneSupport.text(String(character), fontName: "DINCondensed-Bold", size: 0.25, color: .white)
            letter.position = [2.5 - Float(index) * 0.38, -3.4 + sin(Float(index) * 1.7), 0.6]
            copyRoot.addChild(letter); letters.append(letter)
        }
        let ibl = try await NewSceneSupport.imageLight(id: "aircraft_workshop_01", exponent: 1.0, parent: lights)
        NewSceneSupport.receiveIBL(plates, light: ibl)
        let redBack = SpotLight()
        redBack.light = .init(color: NSColor(red: 1, green: 0.06, blue: 0.03, alpha: 1), intensity: 12_000, innerAngleInDegrees: 28, outerAngleInDegrees: 62, attenuationRadius: 16)
        redBack.look(at: [0, 0, 0], from: [0, 1, -5], relativeTo: root)
        lights.addChild(redBack)
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
        for index in plates.indices {
            let group = index / 60
            let attraction = NewSceneSupport.smooth(frame, 32 + group * 64 + (index % 60) / 4, 95 + group * 64)
            let haloIndex = index / 10
            let angle = Float(haloIndex) / 18 * 2 * Float.pi + Float(index % 10 - 5) * 0.018
            let target = SIMD3<Float>(cos(angle) * 2.4, sin(angle) * 2.4, Float(index % 10) * 0.018)
            let curve = SIMD3<Float>(sin(Float(index) * 1.13), cos(Float(index) * 0.77), sin(Float(index) * 0.51)) * sin(attraction * .pi) * 1.8
            plates[index].position = NewSceneSupport.mix(origins[index], target, attraction) + curve
            plates[index].orientation = simd_quatf(angle: angle + attraction * .pi, axis: [0, 0, 1])
        }
        for index in pulses.indices {
            let lockFrame = 224 + index * 3
            let age = max(0, frame - lockFrame)
            pulses[index].light.intensity = age < 6 ? 7_500 * (1 - Float(age) / 6) : 0
        }
        for (index, letter) in letters.enumerated() {
            let snap = NewSceneSupport.smooth(frame, 320 + index * 2, 324 + index * 2)
            letter.position.y = NewSceneSupport.mix(-3.4 + sin(Float(index) * 1.7), -3.0, snap)
        }
        let orbit = NewSceneSupport.smooth(frame, 0, 319)
        let angle = NewSceneSupport.mix(0, 162 * .pi / 180, orbit)
        let radius = NewSceneSupport.mix(11.2, 8.6, orbit)
        let cameraPosition = SIMD3<Float>(sin(angle) * radius, NewSceneSupport.mix(2.8, 0.4, orbit), cos(angle) * radius)
        camera.look(at: [0, 0, 0], from: cameraPosition, relativeTo: root)
        let facing = atan2(cameraPosition.x, cameraPosition.z)
        product.orientation = simd_quatf(angle: facing, axis: [0, 1, 0])
        for letter in letters { letter.orientation = simd_quatf(angle: facing, axis: [0, 1, 0]) }
    }
}
