import AppKit
import RealityKit

@MainActor
final class TimberVaultScene {
    let root: Entity
    let camera: PerspectiveCamera
    private let ribs: [Entity]
    private let hatchPanels: [ModelEntity]
    private let product: ModelEntity
    private let plaques: [ModelEntity]
    private let pairLights: [SpotLight]

    private init(root: Entity, camera: PerspectiveCamera, ribs: [Entity], hatchPanels: [ModelEntity], product: ModelEntity, plaques: [ModelEntity], pairLights: [SpotLight]) {
        self.root = root; self.camera = camera; self.ribs = ribs; self.hatchPanels = hatchPanels
        self.product = product; self.plaques = plaques; self.pairLights = pairLights
    }

    static func load(imageURL: URL) async throws -> TimberVaultScene {
        let root = try await NewSceneSupport.entity("TimberVault")
        let axis = try NewSceneSupport.child("MuseumAxis", in: root)
        let ribRoot = try NewSceneSupport.child("RibRoot", in: root)
        let hatchRoot = try NewSceneSupport.child("CenterHatch", in: root)
        let elevator = try NewSceneSupport.child("ProductElevator", in: root)
        let plaqueRoot = try NewSceneSupport.child("SuspendedPlaqueRoot", in: root)
        let cameraRig = try NewSceneSupport.child("AxialDollyRig", in: root)
        let lights = try NewSceneSupport.child("ClerestoryLightRig", in: root)
        let wood = try await NewSceneSupport.surfaceMaterial(id: "dark_wood")
        let floor = ModelEntity(mesh: .generateBox(width: 10, height: 0.2, depth: 18), materials: [SimpleMaterial(color: NSColor(white: 0.055, alpha: 1), roughness: 0.96, isMetallic: false)])
        floor.position = [0, -3.9, -2]; axis.addChild(floor)

        var ribs: [Entity] = []
        for pair in 0..<6 {
            let pairRoot = Entity(); pairRoot.name = "RibPair\(pair + 1)"
            let z = 3.8 - Float(pair) * 2.25
            for side: Float in [-1, 1] {
                for segment in 0..<18 {
                    let t = Float(segment) / 17
                    let x = side * (4.1 * (1 - t))
                    let y = -3.7 + sin(t * .pi / 2) * 7.8
                    let beam = ModelEntity(mesh: .generateBox(width: 0.26, height: 0.52, depth: 0.48, cornerRadius: 0.035), materials: [wood])
                    beam.position = [x, y, z]; beam.orientation = simd_quatf(angle: side * t * 1.1, axis: [0, 0, 1])
                    pairRoot.addChild(beam)
                }
            }
            ribRoot.addChild(pairRoot); ribs.append(pairRoot)
        }
        var hatchPanels: [ModelEntity] = []
        for index in 0..<4 {
            let panel = ModelEntity(mesh: .generateBox(width: 0.86, height: 0.12, depth: 0.86), materials: [wood])
            panel.position = [index % 2 == 0 ? -0.46 : 0.46, -3.72, index < 2 ? -4.46 : -3.54]
            hatchRoot.addChild(panel); hatchPanels.append(panel)
        }
        let product = try await NewSceneSupport.product(imageURL: imageURL, height: 2.7, name: "VaultProduct")
        product.position = [0, -4.6, -4]; elevator.addChild(product)
        var plaques: [ModelEntity] = []
        for (index, word) in ["BUILT", "TO", "FRAME", "FORM"].enumerated() {
            let plaque = NewSceneSupport.text(word, fontName: "Copperplate", size: 0.25, color: NSColor(red: 0.72, green: 0.45, blue: 0.2, alpha: 1), depth: 0.025)
            plaque.position = [-2.3 + Float(index) * 1.35, 6.5, -1.5 - Float(index) * 0.6]
            plaqueRoot.addChild(plaque); plaques.append(plaque)
        }
        let ibl = try await NewSceneSupport.imageLight(id: "church_museum", exponent: 0.7, parent: lights)
        NewSceneSupport.receiveIBL(
            [floor] + hatchPanels + ribs.flatMap { $0.children.compactMap { $0 as? ModelEntity } },
            light: ibl
        )
        var pairLights: [SpotLight] = []
        for index in 0..<6 {
            let light = SpotLight(); light.light = .init(color: NSColor(red: 1, green: 0.68, blue: 0.36, alpha: 1), intensity: 0, innerAngleInDegrees: 30, outerAngleInDegrees: 70, attenuationRadius: 18)
            light.look(at: [0, 0, 3.8 - Float(index) * 2.25], from: [0, 5, 3.8 - Float(index) * 2.25], relativeTo: root)
            lights.addChild(light); pairLights.append(light)
        }
        let camera = NewSceneSupport.camera(focalLength: 20, name: "VaultAxialCamera"); cameraRig.addChild(camera)
        let scene = TimberVaultScene(root: root, camera: camera, ribs: ribs, hatchPanels: hatchPanels, product: product, plaques: plaques, pairLights: pairLights)
        scene.apply(frameIndex: 359); return scene
    }

    func apply(frameIndex: Int) {
        let frame = min(max(frameIndex, 0), 359)
        let starts = [32, 68, 100, 128, 152, 172], ends = [67, 99, 127, 151, 171, 187]
        for index in ribs.indices {
            let grow = NewSceneSupport.smooth(frame, starts[index], ends[index])
            ribs[index].scale = [1, grow, 1]; pairLights[index].light.intensity = grow >= 0.98 ? 22_000 : 0
        }
        let hatch = NewSceneSupport.smooth(frame, 248, 287)
        for (index, panel) in hatchPanels.enumerated() {
            panel.position.x = (index % 2 == 0 ? -0.46 : 0.46) + (index % 2 == 0 ? -1 : 1) * hatch * 0.9
            panel.position.z = (index < 2 ? -4.46 : -3.54) + (index < 2 ? -1 : 1) * hatch * 0.9
        }
        product.position.y = NewSceneSupport.mix(-4.6, -2.4, NewSceneSupport.smooth(frame, 288, 319))
        for (index, plaque) in plaques.enumerated() { plaque.position.y = NewSceneSupport.mix(6.5, 2.7, NewSceneSupport.smooth(frame, 320 + index * 7, 327 + index * 7)) }
        let dolly = NewSceneSupport.smooth(frame, 188, 247)
        camera.look(at: [0, 1.15, -1.8], from: [0, 1.15, NewSceneSupport.mix(15.8, 8.9, dolly)], relativeTo: root)
    }
}
