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
        let bark = try await NewSceneSupport.surfaceMaterial(
            id: "bark_bluegum",
            tint: NSColor(red: 0.48, green: 0.32, blue: 0.19, alpha: 1)
        )
        let nurseryWall = try await NewSceneSupport.surfaceMaterial(
            id: "white_plaster_02",
            tint: NSColor(red: 0.52, green: 0.64, blue: 0.55, alpha: 1)
        )
        let nurseryFloor = try await NewSceneSupport.surfaceMaterial(
            id: "dark_rock_02",
            tint: NSColor(red: 0.15, green: 0.17, blue: 0.13, alpha: 1)
        )
        let backdrop = ModelEntity(mesh: .generateBox(width: 13, height: 13, depth: 0.35, cornerRadius: 0.16), materials: [nurseryWall])
        backdrop.position = [0, 0.5, -3.8]; soilRoot.addChild(backdrop)
        let floor = ModelEntity(mesh: .generateBox(width: 13, height: 0.28, depth: 12, cornerRadius: 0.12), materials: [nurseryFloor])
        floor.position = [0, -4.35, 0.5]; soilRoot.addChild(floor)
        for side: Float in [-1, 1] {
            let sidePanel = ModelEntity(
                mesh: .generateBox(width: 0.32, height: 10, depth: 11, cornerRadius: 0.08),
                materials: [nurseryWall]
            )
            sidePanel.position = [side * 6.2, 0.2, 0.2]
            soilRoot.addChild(sidePanel)
        }
        for index in 0..<7 {
            let roofRib = ModelEntity(
                mesh: .generateBox(width: 11.8, height: 0.14, depth: 0.22, cornerRadius: 0.045),
                materials: [nurseryWall]
            )
            roofRib.position = [0, 5.6, -2.7 + Float(index) * 1.25]
            soilRoot.addChild(roofRib)
        }
        let soil = ModelEntity(
            mesh: .generateBox(width: 5.8, height: 0.18, depth: 4.4, cornerRadius: 0.16),
            materials: [nurseryFloor]
        )
        soil.position = [-0.35, -4.2, -0.2]
        soil.orientation = simd_quatf(angle: -0.08, axis: [0, 1, 0])
        soilRoot.addChild(soil)
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
        leafMaterial.baseColor = .init(tint: NSColor(red: 0.14, green: 0.48, blue: 0.21, alpha: 0.92))
        leafMaterial.roughness = 0.48; leafMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.92))
        for index in 0..<14 {
            let t = 0.18 + Float(index) / 18
            let angle = Float(index) * 137.5 * .pi / 180
            let base = SIMD3<Float>(cos(angle) * 1.25, -3.75 + t * 8.4, -1.05 + sin(angle) * 0.25)
            let direction = simd_normalize(SIMD3<Float>(
                cos(angle) * 0.9,
                0.12 + sin(Float(index) * 1.3) * 0.18,
                0.16 + sin(angle) * 0.16
            ))
            let branch = ModelEntity(mesh: .generateCylinder(height: 0.42, radius: 0.018), materials: [bark])
            branch.position = base + direction * 0.21
            branch.orientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: direction)
            branchRoot.addChild(branch); branches.append(branch)
            let leaf = ModelEntity(mesh: try leafMesh(index: index), materials: [leafMaterial])
            leaf.scale = [1.0, 1.0, 1.0]
            leaf.position = base + direction * 0.55
            leaf.orientation =
                simd_quatf(angle: angle, axis: [0, 1, 0])
                * simd_quatf(angle: -0.18 + Float(index % 3) * 0.16, axis: [1, 0, 0])
            leafRoot.addChild(leaf); leaves.append(leaf)
        }
        let botanicalCopy = NewSceneSupport.text(
            "GROWN TOWARD LIGHT",
            fontName: "AvenirNext-Medium",
            size: 0.20,
            color: NSColor(white: 0.94, alpha: 0.94)
        )
        botanicalCopy.position = [-1.55, 1.35, 1.2]
        tagRoot.addChild(botanicalCopy)
        tags.append(botanicalCopy)
        for index in 0..<3 {
            let root = ModelEntity(
                mesh: .generateBox(
                    width: 0.95 + Float(index % 2) * 0.3,
                    height: 0.065,
                    depth: 0.10,
                    cornerRadius: 0.04
                ),
                materials: [bark]
            )
            root.position = [
                -0.55 + Float(index) * 0.55,
                -4.16,
                0.65 + sin(Float(index) * 1.4) * 0.42
            ]
            root.orientation = simd_quatf(angle: -0.55 + Float(index) * 0.27, axis: [0, 1, 0])
            productRoot.addChild(root)
        }
        let product = try await NewSceneSupport.litProduct(imageURL: imageURL, height: 2.55, name: "BotanicalProduct", roughness: 0.42)
        product.position = [0, -4.8, 0.85]; productRoot.addChild(product)
        let ibl = try await NewSceneSupport.imageLight(id: "cloudy_netted_nursery", exponent: 1.25, parent: lights)
        NewSceneSupport.receiveIBL(
            [backdrop, floor, soil, product]
                + soilRoot.children.compactMap { $0 as? ModelEntity }
                + productRoot.children.compactMap { $0 as? ModelEntity }
                + [continuousStem] + stems + branches + leaves,
            light: ibl
        )
        let skylight = SpotLight(); skylight.light = .init(color: NSColor(red: 1, green: 0.78, blue: 0.48, alpha: 1), intensity: 38_000, innerAngleInDegrees: 32, outerAngleInDegrees: 72, attenuationRadius: 20)
        lights.addChild(skylight)
        let fill = PointLight()
        fill.light = .init(color: NSColor(red: 0.45, green: 0.82, blue: 0.62, alpha: 1), intensity: 18_000, attenuationRadius: 10)
        fill.position = [-2.5, 0.5, 2.5]
        lights.addChild(fill)
        let botanicalBacklight = DirectionalLight()
        botanicalBacklight.light = .init(
            color: NSColor(red: 0.72, green: 0.95, blue: 0.76, alpha: 1),
            intensity: 8_500
        )
        botanicalBacklight.look(at: [0, 0, 0], from: [4, 7, -5], relativeTo: root)
        lights.addChild(botanicalBacklight)
        let camera = NewSceneSupport.camera(focalLength: 42, name: "BotanicalPedestalCamera"); cameraRig.addChild(camera)
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
            let unfold = NewSceneSupport.smooth(frame, 228 + index * 3, 240 + index * 3)
            leaf.scale = [unfold, unfold, unfold]
        }
        let lightTravel = NewSceneSupport.smooth(frame, 280, 319)
        skylight.look(at: [0, -0.3, 0], from: NewSceneSupport.mix([-4, 6, 1], [3, 7, -2], lightTravel), relativeTo: root)
        product.isEnabled = frame >= 276
        for tag in tags { tag.isEnabled = frame >= 320 }
        let revealProgress = NewSceneSupport.smooth(frame, 276, 322)
        product.position.y = NewSceneSupport.mix(-4.8, -2.93, revealProgress)
        camera.look(
            at: NewSceneSupport.mix([0, 0, -0.6], [0, -1.75, 0.2], revealProgress),
            from: NewSceneSupport.mix([-1.8, 0.6, 13.8], [1.1, -0.15, 11.8], revealProgress),
            relativeTo: root
        )
    }

    private static func leafMesh(index: Int) throws -> MeshResource {
        let length = 0.86 + Float(index % 4) * 0.09
        let width = 0.30 + Float(index % 3) * 0.04
        let segments = 14
        var positions: [SIMD3<Float>] = [[0, length * 0.48, 0.035]]
        var textureCoordinates: [SIMD2<Float>] = [[0.5, 0.5]]
        var indices: [UInt32] = []
        for segment in 0..<segments {
            let angle = Float(segment) / Float(segments) * 2 * Float.pi
            let x = cos(angle) * width * (0.82 + 0.18 * sin(angle))
            let y = length * 0.5 + sin(angle) * length * 0.5
            let curl = sin(angle * 2 + Float(index)) * 0.045
            positions.append([x, y, curl])
            textureCoordinates.append([
                0.5 + cos(angle) * 0.5,
                0.5 + sin(angle) * 0.5
            ])
        }
        for segment in 0..<segments {
            indices += [
                0,
                UInt32(segment + 1),
                UInt32((segment + 1) % segments + 1)
            ]
        }
        var descriptor = MeshDescriptor(name: "BluegumLeaf\(index)")
        descriptor.positions = .init(positions)
        descriptor.normals = .init(Array(repeating: SIMD3<Float>(0, 0, 1), count: positions.count))
        descriptor.textureCoordinates = .init(textureCoordinates)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
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
