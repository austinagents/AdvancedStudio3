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
        var bronze = PhysicallyBasedMaterial()
        bronze.baseColor = .init(tint: NSColor(red: 0.20, green: 0.105, blue: 0.045, alpha: 1))
        bronze.roughness = 0.3
        bronze.metallic = 0.82
        let stone = try await NewSceneSupport.surfaceMaterial(
            id: "white_plaster_02",
            tint: NSColor(white: 0.16, alpha: 1)
        )
        let floor = ModelEntity(
            mesh: .generateBox(width: 11.5, height: 0.24, depth: 22, cornerRadius: 0.05),
            materials: [stone]
        )
        floor.position = [0, -3.9, -2]
        axis.addChild(floor)
        for side: Float in [-1, 1] {
            let wall = ModelEntity(
                mesh: .generateBox(width: 0.24, height: 9.4, depth: 22, cornerRadius: 0.04),
                materials: [stone]
            )
            wall.position = [side * 5.55, 0.65, -2]
            axis.addChild(wall)
            for zIndex in 0..<7 {
                let pilaster = ModelEntity(
                    mesh: .generateBox(width: 0.5, height: 7.7, depth: 0.42, cornerRadius: 0.045),
                    materials: [wood]
                )
                pilaster.position = [side * 5.35, 0.0, 4.1 - Float(zIndex) * 2.65]
                axis.addChild(pilaster)
            }
        }
        let rearWall = ModelEntity(
            mesh: .generateBox(width: 11.5, height: 9.4, depth: 0.25, cornerRadius: 0.04),
            materials: [stone]
        )
        rearWall.position = [0, 0.65, -12.8]
        axis.addChild(rearWall)
        for index in 0..<6 {
            let ceilingBay = ModelEntity(
                mesh: .generateBox(width: 8.8, height: 0.24, depth: 1.45, cornerRadius: 0.06),
                materials: [wood]
            )
            ceilingBay.position = [0, 4.55, 3.5 - Float(index) * 2.7]
            axis.addChild(ceilingBay)
        }

        var ribs: [Entity] = []
        for pair in 0..<6 {
            let pairRoot = Entity(); pairRoot.name = "RibPair\(pair + 1)"
            let z = 3.8 - Float(pair) * 2.25
            let rib = ModelEntity(mesh: try vaultRibMesh(pairIndex: pair), materials: [wood])
            rib.position.z = z
            pairRoot.addChild(rib)
            let keystone = ModelEntity(
                mesh: .generateBox(width: 0.48, height: 0.68, depth: 0.72, cornerRadius: 0.055),
                materials: [bronze]
            )
            keystone.position = [0, 4.08, z]
            pairRoot.addChild(keystone)
            ribRoot.addChild(pairRoot); ribs.append(pairRoot)
        }
        var hatchPanels: [ModelEntity] = []
        for index in 0..<4 {
            let panel = ModelEntity(mesh: .generateBox(width: 0.86, height: 0.12, depth: 0.86), materials: [wood])
            panel.position = [index % 2 == 0 ? -0.46 : 0.46, -3.72, index < 2 ? -4.46 : -3.54]
            hatchRoot.addChild(panel); hatchPanels.append(panel)
        }
        let product = try await NewSceneSupport.litProduct(imageURL: imageURL, height: 4.8, name: "VaultProduct", roughness: 0.30)
        product.position = [0, -4.9, -3.92]; elevator.addChild(product)
        var plaques: [ModelEntity] = []
        for (index, line) in ["BUILT TO FRAME", "FORM"].enumerated() {
            let plaque = NewSceneSupport.text(
                line,
                fontName: "HelveticaNeue-Medium",
                size: index == 0 ? 0.22 : 0.42,
                color: NSColor(red: 0.82, green: 0.58, blue: 0.31, alpha: 1),
                depth: 0.012
            )
            plaque.position = [index == 0 ? -1.15 : -0.62, 6.0 + Float(index) * 0.5, -4.8]
            plaqueRoot.addChild(plaque); plaques.append(plaque)
        }
        let ibl = try await NewSceneSupport.imageLight(id: "church_museum", exponent: 0.7, parent: lights)
        NewSceneSupport.receiveIBL(
            [floor, rearWall, product] + hatchPanels
                + axis.children.compactMap { $0 as? ModelEntity }
                + ribs.flatMap { $0.children.compactMap { $0 as? ModelEntity } },
            light: ibl
        )
        var pairLights: [SpotLight] = []
        for index in 0..<6 {
            let light = SpotLight(); light.light = .init(color: NSColor(red: 1, green: 0.72, blue: 0.44, alpha: 1), intensity: 0, innerAngleInDegrees: 24, outerAngleInDegrees: 62, attenuationRadius: 20)
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
            panel.isEnabled = frame < 320
            panel.position.x = (index % 2 == 0 ? -0.46 : 0.46) + (index % 2 == 0 ? -1 : 1) * hatch * 0.9
            panel.position.z = (index < 2 ? -4.46 : -3.54) + (index < 2 ? -1 : 1) * hatch * 0.9
        }
        product.isEnabled = frame >= 276
        product.position.y = NewSceneSupport.mix(-5.2, -1.72, NewSceneSupport.smooth(frame, 276, 316))
        for (index, plaque) in plaques.enumerated() {
            plaque.isEnabled = frame >= 318 + index * 8
            plaque.position.y = NewSceneSupport.mix(6.5 + Float(index) * 0.5, 2.15 - Float(index) * 0.52, NewSceneSupport.smooth(frame, 318 + index * 8, 334 + index * 8))
        }
        let dolly = NewSceneSupport.smooth(frame, 188, 247)
        let hero = NewSceneSupport.smooth(frame, 276, 330)
        camera.look(
            at: NewSceneSupport.mix([0, 0.4, -2.0], [0, -0.35, -3.9], hero),
            from: [
                NewSceneSupport.mix(-0.55, 0.35, hero),
                NewSceneSupport.mix(1.0, 0.2, hero),
                NewSceneSupport.mix(15.8, 9.8, max(dolly, hero))
            ],
            relativeTo: root
        )
    }

    private static func vaultRibMesh(pairIndex: Int) throws -> MeshResource {
        let segments = 32
        let halfWidth: Float = 0.23 + Float(pairIndex % 2) * 0.025
        let halfDepth: Float = 0.31
        var positions: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for segment in 0...segments {
            let t = Float(segment) / Float(segments)
            let angle = t * .pi
            let radial = SIMD2<Float>(cos(angle), sin(angle))
            let center = SIMD2<Float>(4.25 * cos(angle), -3.7 + 7.8 * sin(angle))
            let inner = center - radial * halfWidth
            let outer = center + radial * halfWidth
            positions += [
                [inner.x, inner.y, -halfDepth],
                [inner.x, inner.y, halfDepth],
                [outer.x, outer.y, -halfDepth],
                [outer.x, outer.y, halfDepth]
            ]
            let u = t * 8
            textureCoordinates += [[u, 0], [u, 0.35], [u, 0.65], [u, 1]]
        }
        for segment in 0..<segments {
            let base = UInt32(segment * 4)
            let next = base + 4
            indices += [
                base, next, base + 2, next, next + 2, base + 2,
                base + 1, base + 3, next + 1, next + 1, base + 3, next + 3,
                base, base + 1, next, next, base + 1, next + 1,
                base + 2, next + 2, base + 3, next + 2, next + 3, base + 3
            ]
        }
        var descriptor = MeshDescriptor(name: "ContinuousVaultRib\(pairIndex)")
        descriptor.positions = .init(positions)
        descriptor.textureCoordinates = .init(textureCoordinates)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }
}
