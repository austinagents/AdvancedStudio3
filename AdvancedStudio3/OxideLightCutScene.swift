import AppKit
import RealityKit

@MainActor
final class OxideLightCutScene {
    let root: Entity
    let camera: PerspectiveCamera
    private let product: ModelEntity
    private let shutters: [ModelEntity]
    private let planes: [ModelEntity]
    private let copy: ModelEntity
    private let spots: [SpotLight]

    private init(root: Entity, camera: PerspectiveCamera, product: ModelEntity, shutters: [ModelEntity], planes: [ModelEntity], copy: ModelEntity, spots: [SpotLight]) {
        self.root = root; self.camera = camera; self.product = product; self.shutters = shutters
        self.planes = planes; self.copy = copy; self.spots = spots
    }

    static func load(imageURL: URL) async throws -> OxideLightCutScene {
        let root = try await NewSceneSupport.entity("OxideLightCut")
        let monolithRoot = try NewSceneSupport.child("RustMonolith", in: root)
        let planeRoot = try NewSceneSupport.child("LightPlaneRoot", in: root)
        let productRoot = try NewSceneSupport.child("ProductIntersectionSlot", in: root)
        let copyRoot = try NewSceneSupport.child("ShadowCopyRoot", in: root)
        let cameraRig = try NewSceneSupport.child("LockedMacroCamera", in: root)
        let lights = try NewSceneSupport.child("SilhouetteLightRig", in: root)
        var rust = try await NewSceneSupport.surfaceMaterial(id: "rust_coarse_01")
        rust.metallic = 0.64
        var floorMaterial = PhysicallyBasedMaterial()
        floorMaterial.baseColor = .init(tint: NSColor(red: 0.16, green: 0.055, blue: 0.025, alpha: 1))
        floorMaterial.roughness = 0.42
        floorMaterial.metallic = 0.46
        let rearWall = ModelEntity(mesh: .generateBox(width: 13, height: 13, depth: 0.35, cornerRadius: 0.12), materials: [floorMaterial])
        rearWall.position = [0, 0.4, -1.15]; monolithRoot.addChild(rearWall)
        let floor = ModelEntity(mesh: .generateBox(width: 13, height: 0.32, depth: 10, cornerRadius: 0.1), materials: [floorMaterial])
        floor.position = [0, -4.0, 1.2]; monolithRoot.addChild(floor)
        let pedestal = ModelEntity(mesh: .generateCylinder(height: 0.5, radius: 1.18), materials: [rust])
        pedestal.position = [0, -2.9, 0.7]; productRoot.addChild(pedestal)
        let product = try await NewSceneSupport.product(imageURL: imageURL, height: 2.65, name: "IntersectionProduct")
        product.position = [0, -1.18, 1.0]; productRoot.addChild(product)
        var shutters: [ModelEntity] = []
        for index in 0..<4 {
            let shutter = ModelEntity(mesh: .generateBox(width: index < 2 ? 2.9 : 5.8, height: index < 2 ? 9.6 : 4.8, depth: 0.72, cornerRadius: 0.08), materials: [rust])
            shutter.position = index == 0 ? [-1.45, 0, 0.35] : index == 1 ? [1.45, 0, 0.35] : index == 2 ? [0, 2.4, 0.35] : [0, -2.4, 0.35]
            monolithRoot.addChild(shutter); shutters.append(shutter)
        }
        let colors: [NSColor] = [.white, .white, .white, .red, .red, .red, NSColor.orange, NSColor.orange, NSColor.orange]
        var planes: [ModelEntity] = []
        for index in 0..<9 {
            var material = UnlitMaterial(color: colors[index].withAlphaComponent(0.14))
            material.blending = .transparent(opacity: .init(floatLiteral: 0.14))
            let plane = ModelEntity(mesh: .generatePlane(width: 0.035 + Float(index % 3) * 0.018, height: 12), materials: [material])
            plane.position = [-6 + Float(index) * 1.5, 0, 1]; plane.orientation = simd_quatf(angle: Float(index % 3) * 0.24 - 0.24, axis: [0, 0, 1])
            planeRoot.addChild(plane); planes.append(plane)
        }
        let copy = NewSceneSupport.text("DEFINED BY LIGHT", fontName: "Bodoni 72 Smallcaps", size: 0.25, color: NSColor(red: 1, green: 0.74, blue: 0.5, alpha: 1), depth: 0.04)
        copy.position = [-1.7, 2.35, 1.2]; copyRoot.addChild(copy)
        let ibl = try await NewSceneSupport.imageLight(id: "clarens_night_01", exponent: 0.45, parent: lights)
        NewSceneSupport.receiveIBL([rearWall, floor, pedestal] + shutters, light: ibl)
        var spots: [SpotLight] = []
        for index in 0..<3 {
            let spot = SpotLight(); spot.light = .init(color: colors[index * 3], intensity: 4_000, innerAngleInDegrees: 5, outerAngleInDegrees: 12, attenuationRadius: 18)
            lights.addChild(spot); spots.append(spot)
        }
        let revealFill = PointLight()
        revealFill.light = .init(color: NSColor(red: 1, green: 0.28, blue: 0.08, alpha: 1), intensity: 22_000, attenuationRadius: 9)
        revealFill.position = [0, 1.2, 3.5]
        lights.addChild(revealFill)
        let camera = NewSceneSupport.camera(focalLength: 52, name: "OxideLockedCamera"); cameraRig.addChild(camera)
        let scene = OxideLightCutScene(root: root, camera: camera, product: product, shutters: shutters, planes: planes, copy: copy, spots: spots)
        scene.apply(frameIndex: 359); return scene
    }

    func apply(frameIndex: Int) {
        let frame = min(max(frameIndex, 0), 359)
        for (index, plane) in planes.enumerated() {
            let group = index / 3
            let starts = [64, 120, 184]
            let progress = NewSceneSupport.smooth(frame, starts[group] + (index % 3) * 8, starts[group] + 55)
            if group < 2 {
                plane.position.x = NewSceneSupport.mix(group == 0 ? -6 : 6, group == 0 ? 5 : -5, progress)
                plane.orientation = simd_quatf(angle: NewSceneSupport.mix(-0.5, 0.5, progress) * (group == 0 ? 1 : -1), axis: [0, 0, 1])
            } else {
                plane.position.y = NewSceneSupport.mix(-6, 6, progress)
            }
            let converge = NewSceneSupport.smooth(frame, 240, 299)
            plane.position = NewSceneSupport.mix(plane.position, [Float(index - 4) * 0.13, 0, 1], converge)
        }
        let aperture = NewSceneSupport.smooth(frame, 300, 331)
        shutters[0].position.x = NewSceneSupport.mix(-1.45, -4.1, aperture)
        shutters[1].position.x = NewSceneSupport.mix(1.45, 4.1, aperture)
        shutters[2].position.y = NewSceneSupport.mix(2.4, 5.8, aperture)
        shutters[3].position.y = NewSceneSupport.mix(-2.4, -5.8, aperture)
        product.isEnabled = frame >= 252
        copy.isEnabled = frame >= 332
        for (index, spot) in spots.enumerated() {
            let sweep = NewSceneSupport.smooth(frame, 332 + index * 6, 351)
            spot.look(at: [0, -3.4, 0], from: [NewSceneSupport.mix(-5, 5, sweep), 2.8, 5], relativeTo: root)
        }
        camera.look(at: [0, -0.25, 0], from: [0.4, 0.1, 12.5], relativeTo: root)
    }
}
