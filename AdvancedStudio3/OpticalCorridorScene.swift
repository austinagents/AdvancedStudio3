import AppKit
import RealityKit

@MainActor
final class OpticalCorridorScene {
    let root: Entity
    let camera: PerspectiveCamera

    private let prisms: [ModelEntity]
    private let productSlices: [ModelEntity]
    private let copy: Entity

    private init(
        root: Entity,
        camera: PerspectiveCamera,
        prisms: [ModelEntity],
        productSlices: [ModelEntity],
        copy: Entity
    ) {
        self.root = root
        self.camera = camera
        self.prisms = prisms
        self.productSlices = productSlices
        self.copy = copy
    }

    static func load(imageURL: URL) async throws -> OpticalCorridorScene {
        let root = try await NewSceneSupport.entity("OpticalCorridor")
        let world = try NewSceneSupport.child("WorldRoot", in: root)
        let blockRoot = try NewSceneSupport.child("PlasterBlock", in: root)
        let prismRoot = try NewSceneSupport.child("PrismRoot", in: root)
        let sliceRoot = try NewSceneSupport.child("ProductSliceRoot", in: root)
        let copyRoot = try NewSceneSupport.child("CopyRoot", in: root)
        let cameraRig = try NewSceneSupport.child("CameraBezierRig", in: root)
        let lightRoot = try NewSceneSupport.child("StripLightRoot", in: root)

        let plaster = try await NewSceneSupport.surfaceMaterial(id: "white_plaster_02")
        var graphite = PhysicallyBasedMaterial()
        graphite.baseColor = .init(tint: NSColor(red: 0.018, green: 0.026, blue: 0.042, alpha: 1))
        graphite.roughness = 0.34
        graphite.metallic = 0.5
        let rearWall = ModelEntity(
            mesh: .generateBox(width: 15, height: 12, depth: 0.3, cornerRadius: 0.08),
            materials: [graphite]
        )
        rearWall.position = [0, 2.8, -5.6]
        world.addChild(rearWall)
        for side: Float in [-1, 1] {
            let wall = ModelEntity(
                mesh: .generateBox(width: 0.28, height: 11.5, depth: 15, cornerRadius: 0.05),
                materials: [graphite]
            )
            wall.position = [side * 6.6, 2.5, 1.2]
            world.addChild(wall)
            for index in 0..<4 {
                let practical = ModelEntity(
                    mesh: .generateBox(width: 0.055, height: 6.2, depth: 0.055, cornerRadius: 0.02),
                    materials: [UnlitMaterial(color: index.isMultiple(of: 2) ? .cyan : .orange)]
                )
                practical.position = [side * 6.42, 1.8, -3.7 + Float(index) * 2.45]
                practical.orientation = simd_quatf(angle: side * 0.18, axis: [0, 0, 1])
                world.addChild(practical)
            }
        }
        let block = ModelEntity(
            mesh: .generateBox(width: 11.6, height: 0.34, depth: 15, cornerRadius: 0.08),
            materials: [plaster]
        )
        block.position = [0, -2.3, 0.8]
        blockRoot.addChild(block)
        var pedestalMaterial = PhysicallyBasedMaterial()
        pedestalMaterial.baseColor = .init(tint: NSColor(red: 0.055, green: 0.075, blue: 0.11, alpha: 1))
        pedestalMaterial.roughness = 0.18
        pedestalMaterial.metallic = 0.72
        let pedestal = ModelEntity(
            mesh: .generateCylinder(height: 0.48, radius: 1.18),
            materials: [pedestalMaterial]
        )
        pedestal.position = [0.42, -2.0, 0.0]
        blockRoot.addChild(pedestal)

        var glass = PhysicallyBasedMaterial()
        glass.baseColor = .init(tint: NSColor(red: 0.68, green: 0.9, blue: 1, alpha: 0.28))
        glass.roughness = 0.035
        glass.metallic = .init(floatLiteral: 0)
        glass.blending = .transparent(opacity: .init(floatLiteral: 0.28))
        let radii: [Float] = [0.68, 0.54, 0.42]
        let starts: [SIMD3<Float>] = [[-2.8, 0.7, 1.2], [2.4, -0.2, 0], [-1.9, -0.9, -1.4]]
        var prisms: [ModelEntity] = []
        for (radius, position) in zip(radii, starts) {
            let entity = ModelEntity(
                mesh: try triangularPrismMesh(radius: radius, length: 3.8),
                materials: [glass]
            )
            entity.position = position
            entity.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
            prismRoot.addChild(entity)
            prisms.append(entity)
        }

        var slices: [ModelEntity] = []
        for index in 0..<3 {
            let product = try await productSlice(imageURL: imageURL, index: index, height: 2.1)
            product.position = [Float(index - 1) * 2.4, -0.68, 0.15]
            sliceRoot.addChild(product)
            slices.append(product)
        }

        let copy = NewSceneSupport.text(
            "REFRACT / REVEAL",
            fontName: "Futura-Medium",
            size: 0.18,
            color: NSColor(red: 0.68, green: 0.94, blue: 1, alpha: 1)
        )
        copy.position = [-0.48, 1.08, 1.2]
        copyRoot.addChild(copy)

        let ibl = try await NewSceneSupport.imageLight(
            id: "ferndale_studio_02",
            exponent: 0.35,
            parent: lightRoot
        )
        NewSceneSupport.receiveIBL(
            [rearWall, block, pedestal] + world.children.compactMap { $0 as? ModelEntity } + prisms,
            light: ibl
        )
        let colors: [NSColor] = [
            NSColor(red: 0.28, green: 0.76, blue: 1, alpha: 1),
            NSColor(red: 1, green: 0.18, blue: 0.12, alpha: 1),
            NSColor(red: 0.15, green: 1, blue: 0.82, alpha: 1)
        ]
        let positions: [SIMD3<Float>] = [[-3.8, 3.1, 4], [0, 4.5, 1], [3.9, 2.6, -1.5]]
        for index in 0..<3 {
            let light = SpotLight()
            light.light = .init(color: colors[index], intensity: [4_500, 3_800, 4_200][index], innerAngleInDegrees: 24, outerAngleInDegrees: 52, attenuationRadius: 16)
            light.look(at: [0, 0, 0], from: positions[index], relativeTo: root)
            lightRoot.addChild(light)
        }

        let camera = NewSceneSupport.camera(focalLength: 60, name: "OpticalCorridorCamera")
        cameraRig.addChild(camera)
        let scene = OpticalCorridorScene(
            root: root,
            camera: camera,
            prisms: prisms,
            productSlices: slices,
            copy: copy
        )
        scene.apply(frameIndex: 359)
        return scene
    }

    func apply(frameIndex: Int) {
        let frame = AdSpecification.premiumTwelveSeconds.clamped(frameIndex)
        let entry = NewSceneSupport.smooth(frame, 36, 119)
        let alignment = NewSceneSupport.smooth(frame, 192, 247)
        let starts: [SIMD3<Float>] = [[-2.8, 0.7, 1.2], [2.4, -0.2, 0], [-1.9, -0.9, -1.4]]
        for index in prisms.indices {
            prisms[index].position = NewSceneSupport.mix(
                starts[index],
                [Float(index - 1) * 1.25, 0, Float(1 - index) * 0.45],
                entry
            )
            prisms[index].orientation = simd_quatf(
                angle: NewSceneSupport.mix(.pi / 2, [-0.62, 0.28, 0.72][index], alignment),
                axis: [0, 0, 1]
            )
            productSlices[index].position = NewSceneSupport.mix(
                [Float(index - 1) * 2.4, -0.18, 0.15],
                [0.42, -0.68, 0.15 + Float(index - 1) * 0.004],
                alignment
            )
            productSlices[index].isEnabled = frame >= 252
        }
        let cameraProgress = NewSceneSupport.smooth(frame, 248, 307)
        camera.look(
            at: NewSceneSupport.mix([0, 0.1, 0], [0.38, -0.22, 0], cameraProgress),
            from: NewSceneSupport.mix([-4.6, 0.75, 12.8], [2.35, 0.35, 10.8], cameraProgress),
            relativeTo: root
        )
        copy.isEnabled = frame >= 308
    }

    private static func triangularPrismMesh(
        radius: Float,
        length: Float
    ) throws -> MeshResource {
        var positions: [SIMD3<Float>] = []
        for y in [-length / 2, length / 2] {
            for index in 0..<3 {
                let angle = Float(index) / 3 * 2 * .pi
                positions.append([cos(angle) * radius, y, sin(angle) * radius])
            }
        }
        let normals = positions.map { simd_normalize(SIMD3<Float>($0.x, 0.001, $0.z)) }
        let indices: [UInt32] = [
            0, 1, 2, 3, 5, 4,
            0, 3, 1, 1, 3, 4,
            1, 4, 2, 2, 4, 5,
            2, 5, 0, 0, 5, 3
        ]
        var descriptor = MeshDescriptor(name: "TriangularOpticalPrism")
        descriptor.positions = .init(positions)
        descriptor.normals = .init(normals)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }

    private static func productSlice(imageURL: URL, index: Int, height: Float) async throws -> ModelEntity {
        let texture = try await TextureResource(contentsOf: imageURL)
        let totalWidth = height * 0.72
        let partWidth = totalWidth / 3
        let left = -totalWidth / 2 + Float(index) * partWidth
        let right = left + partWidth
        let u0 = Float(index) / 3, u1 = Float(index + 1) / 3
        var descriptor = MeshDescriptor(name: "OpticalProductSlice\(index)")
        descriptor.positions = .init([[left, -height / 2, 0], [right, -height / 2, 0], [left, height / 2, 0], [right, height / 2, 0]])
        descriptor.normals = .init(Array(repeating: SIMD3<Float>(0, 0, 1), count: 4))
        descriptor.textureCoordinates = .init([[u0, 0], [u1, 0], [u0, 1], [u1, 1]])
        descriptor.primitives = .triangles([0, 1, 2, 1, 3, 2])
        var material = UnlitMaterial(texture: texture)
        material.blending = .transparent(opacity: .init(floatLiteral: 1))
        material.opacityThreshold = 0.001
        material.faceCulling = .none
        let product = ModelEntity(mesh: try MeshResource.generate(from: [descriptor]), materials: [material])
        product.name = "OpticalProductSlice\(index)"
        return product
    }
}
