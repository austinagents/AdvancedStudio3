import AppKit
import RealityKit

@MainActor
final class SatinCurrentScene {
    let root: Entity
    let camera: PerspectiveCamera
    private let ribbon: ModelEntity
    private let product: ModelEntity
    private let copy: ModelEntity
    private let strip: SpotLight

    private init(root: Entity, camera: PerspectiveCamera, ribbon: ModelEntity, product: ModelEntity, copy: ModelEntity, strip: SpotLight) {
        self.root = root; self.camera = camera; self.ribbon = ribbon; self.product = product; self.copy = copy; self.strip = strip
    }

    static func load(imageURL: URL) async throws -> SatinCurrentScene {
        let root = try await NewSceneSupport.entity("SatinCurrent")
        let world = try NewSceneSupport.child("WarmCyclorama", in: root)
        let ribbonRoot = try NewSceneSupport.child("RibbonSplineRoot", in: root)
        let productRoot = try NewSceneSupport.child("ProductOcclusionSlot", in: root)
        let copyRoot = try NewSceneSupport.child("CounterCopyRail", in: root)
        let cameraRig = try NewSceneSupport.child("LateralCameraRail", in: root)
        let lights = try NewSceneSupport.child("HorizontalStripRig", in: root)

        let background = ModelEntity(mesh: .generatePlane(width: 22, height: 28), materials: [UnlitMaterial(color: NSColor(red: 0.13, green: 0.105, blue: 0.095, alpha: 1))])
        background.position = [0, 1, -4]; world.addChild(background)
        var satin = try await NewSceneSupport.surfaceMaterial(id: "crepe_satin")
        satin.faceCulling = .none
        let ribbon = ModelEntity(mesh: try ribbonMesh(frame: 0), materials: [satin]); ribbonRoot.addChild(ribbon)
        let product = try await NewSceneSupport.product(imageURL: imageURL, height: 3.65, name: "SatinProduct")
        product.position = [-1.25, -0.35, 0]; productRoot.addChild(product)
        let copy = NewSceneSupport.text("MOVE WITH FORM", fontName: "HelveticaNeue-Italic", size: 0.31, color: NSColor(calibratedRed: 0.96, green: 0.88, blue: 0.74, alpha: 1))
        copy.position = [-5.5, -3.2, 0.7]; copyRoot.addChild(copy)

        let ibl = try await NewSceneSupport.imageLight(id: "ferndale_studio_05", exponent: 0.4, parent: lights)
        NewSceneSupport.receiveIBL([ribbon], light: ibl)
        let strip = SpotLight()
        strip.light = .init(color: NSColor(red: 1, green: 0.16, blue: 0.58, alpha: 1), intensity: 12_000, innerAngleInDegrees: 12, outerAngleInDegrees: 38, attenuationRadius: 18)
        lights.addChild(strip)
        let rim = PointLight(); rim.light = .init(color: NSColor(red: 1, green: 0.48, blue: 0.16, alpha: 1), intensity: 4_600, attenuationRadius: 8)
        rim.position = [-1.25, 0, -2]; lights.addChild(rim)
        let camera = NewSceneSupport.camera(focalLength: 50, name: "SatinLateralCamera"); cameraRig.addChild(camera)
        let scene = SatinCurrentScene(root: root, camera: camera, ribbon: ribbon, product: product, copy: copy, strip: strip)
        scene.apply(frameIndex: 359); return scene
    }

    func apply(frameIndex: Int) {
        let frame = min(max(frameIndex, 0), 359)
        ribbon.model?.mesh = (try? Self.ribbonMesh(frame: frame)) ?? ribbon.model!.mesh
        product.isEnabled = !(frame >= 216 && frame <= 251)
        let travel = Float(frame) / 359
        let cameraX = NewSceneSupport.mix(4.8, -3.6, travel)
        product.position.x = cameraX - 1.25
        camera.look(at: [cameraX - 1.2, 0.05, 0], from: [cameraX, 0.3, 10.4], relativeTo: root)
        let copyTravel = NewSceneSupport.smooth(frame, 308, 343)
        copy.position.x = cameraX - 1.2 + NewSceneSupport.mix(-1.4, 1.4, copyTravel)
        strip.look(at: [0, 0, 0], from: [NewSceneSupport.mix(-5, 5, travel), 2.8, 4], relativeTo: root)
    }

    private static func ribbonMesh(frame: Int) throws -> MeshResource {
        let columns = 96, rows = 12
        var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = [], indices: [UInt32] = []
        let travel = NewSceneSupport.mix(14, -14, Float(frame) / 359)
        for row in 0...rows {
            for column in 0...columns {
                let u = Float(column) / Float(columns)
                let v = Float(row) / Float(rows) - 0.5
                let x = (u - 0.5) * 18 + travel
                let wrap = exp(-pow(x + 1.25, 2) * 0.32) * sin(u * 5 * .pi + Float(frame) * 0.035)
                positions.append([x, v * 2.2 + wrap * 0.75, 0.4 + wrap * 1.1 + v * 0.18])
                normals.append([0, 0.25, 0.97]); uv.append([u * 18 / 0.48, Float(row) / Float(rows)])
            }
        }
        for row in 0..<rows { for column in 0..<columns {
            let a = UInt32(row * (columns + 1) + column), b = a + 1, c = a + UInt32(columns + 1), d = c + 1
            indices += [a, c, b, b, c, d]
        }}
        var descriptor = MeshDescriptor(name: "ContinuousSatinRibbon")
        descriptor.positions = .init(positions); descriptor.normals = .init(normals); descriptor.textureCoordinates = .init(uv); descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }
}
