import AppKit
import RealityKit

@MainActor
final class BluegumHelixScene {
    let root: Entity
    let camera: PerspectiveCamera
    private let stemSegments: [ModelEntity]
    private let continuousStem: ModelEntity
    private let branchlets: [ModelEntity]
    private let leaves: [ModelEntity]
    private let product: ModelEntity
    private let tags: [ModelEntity]
    private let skylight: SpotLight

    private init(root: Entity, camera: PerspectiveCamera, stemSegments: [ModelEntity], continuousStem: ModelEntity, branchlets: [ModelEntity], leaves: [ModelEntity], product: ModelEntity, tags: [ModelEntity], skylight: SpotLight) {
        self.root = root; self.camera = camera; self.stemSegments = stemSegments; self.branchlets = branchlets
        self.continuousStem = continuousStem
        self.leaves = leaves; self.product = product; self.tags = tags; self.skylight = skylight
    }

    static func load(imageURL: URL) async throws -> BluegumHelixScene {
        let root = try await NewSceneSupport.entity("BluegumHelix")
        let soilRoot = try NewSceneSupport.child("SoilIsland", in: root)
        let stemRoot = try NewSceneSupport.child("HelixStem", in: root)
        let branchRoot = try NewSceneSupport.child("BranchletRoot", in: root)
        let leafRoot = try NewSceneSupport.child("ReflectorLeafRoot", in: root)
        let productRoot = try NewSceneSupport.child("SilhouetteProductSlot", in: root)
        let tagRoot = try NewSceneSupport.child("BotanicalTagRoot", in: root)
        let cameraRig = try NewSceneSupport.child("VerticalPedestalRig", in: root)
        let lights = try NewSceneSupport.child("MovingSkylightRig", in: root)
        let bark = try await NewSceneSupport.surfaceMaterial(id: "bark_bluegum")
        let soil = ModelEntity(mesh: .generateCylinder(height: 0.45, radius: 3.1), materials: [SimpleMaterial(color: NSColor(red: 0.08, green: 0.055, blue: 0.035, alpha: 1), roughness: 1, isMetallic: false)])
        soil.position.y = -4.1; soilRoot.addChild(soil)
        var stems: [ModelEntity] = []
        for index in 0..<96 {
            let t = Float(index) / 95
            let angle = t * 3.25 * 2 * Float.pi
            let radius = NewSceneSupport.mix(1.75, 0.58, t)
            let segment = ModelEntity(mesh: .generateCylinder(height: 0.16, radius: NewSceneSupport.mix(0.18, 0.07, t)), materials: [bark])
            segment.position = [cos(angle) * radius, -3.75 + t * 8.4, -1.4 + sin(angle) * 0.35]
            segment.orientation = simd_quatf(angle: angle + .pi / 2, axis: [0, 1, 0])
            stemRoot.addChild(segment); stems.append(segment)
        }
        let continuousStem = ModelEntity(mesh: try helixMesh(progress: 0.01), materials: [bark])
        continuousStem.name = "ContinuousBluegumHelix"
        stemRoot.addChild(continuousStem)
        for segment in stems { segment.isEnabled = false }
        var branches: [ModelEntity] = [], leaves: [ModelEntity] = [], tags: [ModelEntity] = []
        var leafMaterial = PhysicallyBasedMaterial()
        leafMaterial.baseColor = .init(tint: NSColor(red: 0.08, green: 0.34, blue: 0.12, alpha: 0.78))
        leafMaterial.roughness = 0.44; leafMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.78))
        for index in 0..<18 {
            let t = 0.18 + Float(index) / 22
            let angle = Float(index) * 137.5 * .pi / 180
            let base = SIMD3<Float>(cos(angle) * 1.25, -3.75 + t * 8.4, -1.05 + sin(angle) * 0.25)
            let branch = ModelEntity(mesh: .generateCylinder(height: 0.68, radius: 0.025), materials: [bark])
            branch.position = base; branch.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1]); branchRoot.addChild(branch); branches.append(branch)
            let leaf = ModelEntity(mesh: .generateSphere(radius: 0.18 + Float(index % 5) * 0.035), materials: [leafMaterial])
            leaf.scale = [1.5, 0.12, 0.72]; leaf.position = base + SIMD3<Float>(cos(angle) * 0.8, 0, -0.15)
            leafRoot.addChild(leaf); leaves.append(leaf)
            if index.isMultiple(of: 5) {
                let tag = NewSceneSupport.text(["grown", "toward", "light", "naturally"][tags.count], fontName: "AvenirNext-UltraLight", size: 0.16, color: NSColor(white: 0.92, alpha: 0.9))
                tag.position = leaf.position + [0.15, -0.15, 0.2]; tagRoot.addChild(tag); tags.append(tag)
            }
        }
        let product = try await NewSceneSupport.product(imageURL: imageURL, height: 2.0, name: "BotanicalProduct")
        product.position = [0, -1.85, 0.2]; productRoot.addChild(product)
        let ibl = try await NewSceneSupport.imageLight(id: "cloudy_netted_nursery", exponent: 0.55, parent: lights)
        NewSceneSupport.receiveIBL([soil] + stems + branches + leaves, light: ibl)
        let skylight = SpotLight(); skylight.light = .init(color: NSColor(red: 1, green: 0.7, blue: 0.35, alpha: 1), intensity: 17_000, innerAngleInDegrees: 28, outerAngleInDegrees: 60, attenuationRadius: 16)
        lights.addChild(skylight)
        let camera = NewSceneSupport.camera(focalLength: 85, name: "BotanicalPedestalCamera"); cameraRig.addChild(camera)
        let scene = BluegumHelixScene(root: root, camera: camera, stemSegments: stems, continuousStem: continuousStem, branchlets: branches, leaves: leaves, product: product, tags: tags, skylight: skylight)
        scene.apply(frameIndex: 359); return scene
    }

    func apply(frameIndex: Int) {
        let frame = min(max(frameIndex, 0), 359)
        continuousStem.model?.mesh = (try? Self.helixMesh(progress: NewSceneSupport.smooth(frame, 48, 167))) ?? continuousStem.model!.mesh
        for (index, branch) in branchlets.enumerated() {
            let grow = NewSceneSupport.smooth(frame, 168 + index * 3, 181 + index * 3); branch.scale.y = grow
        }
        for (index, leaf) in leaves.enumerated() {
            let unfold = NewSceneSupport.smooth(frame, 228 + index * 3, 240 + index * 3); leaf.scale = [1.5 * unfold, 0.12, 0.72 * unfold]
            leaf.orientation = simd_quatf(angle: NewSceneSupport.mix(-1.2, 0.12, unfold), axis: [0, 1, 0])
        }
        let lightTravel = NewSceneSupport.smooth(frame, 280, 319)
        skylight.look(at: [0, -0.3, 0], from: NewSceneSupport.mix([-4, 6, 1], [3, 7, -2], lightTravel), relativeTo: root)
        product.isEnabled = frame >= 320
        for (index, tag) in tags.enumerated() { tag.isEnabled = frame >= 292 + index * 9 }
        let pedestal = NewSceneSupport.smooth(frame, 320, 359)
        product.position.y = NewSceneSupport.mix(-1.85, 1.2, pedestal)
        camera.look(at: [0.35, product.position.y, 0], from: [0.35, NewSceneSupport.mix(-2.2, 2.7, pedestal), 14.0], relativeTo: root)
    }

    private static func helixMesh(progress: Float) throws -> MeshResource {
        let axialSegments = max(2, Int(128 * max(progress, 0.01)))
        let radialSegments = 10
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for axial in 0...axialSegments {
            let t = Float(axial) / 128
            let angle = t * 3.25 * 2 * Float.pi
            let radius = NewSceneSupport.mix(1.75, 0.58, t)
            let center = SIMD3<Float>(cos(angle) * radius, -3.75 + t * 8.4, -1.4 + sin(angle) * 0.35)
            for radial in 0..<radialSegments {
                let ring = Float(radial) / Float(radialSegments) * 2 * Float.pi
                let normal = simd_normalize(SIMD3<Float>(cos(ring) * cos(angle), sin(ring), cos(ring) * sin(angle)))
                positions.append(center + normal * NewSceneSupport.mix(0.16, 0.055, t))
                normals.append(normal)
                textureCoordinates.append([Float(radial) / Float(radialSegments), t * 10])
            }
        }
        for axial in 0..<axialSegments {
            for radial in 0..<radialSegments {
                let next = (radial + 1) % radialSegments
                let a = UInt32(axial * radialSegments + radial)
                let b = UInt32(axial * radialSegments + next)
                let c = UInt32((axial + 1) * radialSegments + radial)
                let d = UInt32((axial + 1) * radialSegments + next)
                indices += [a, c, b, b, c, d]
            }
        }
        var descriptor = MeshDescriptor(name: "BluegumHelixTube")
        descriptor.positions = .init(positions)
        descriptor.normals = .init(normals)
        descriptor.textureCoordinates = .init(textureCoordinates)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }
}
