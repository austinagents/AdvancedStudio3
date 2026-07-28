import AppKit
import CoreGraphics
import Foundation
import ImageIO
import RealityKit
import RealityKitContent
import simd

@MainActor
final class PremiumAdScene {
    static let duration = 8.0
    static let frameRate = 30
    static let frameCount = 240
    static let heroFrame = 210

    let root: Entity
    let camera: PerspectiveCamera

    private let lattice: ModelEntity
    private let innerShell: ModelEntity
    private let productRoot: Entity
    private let productMask: ModelEntity
    private let contactShadow: ModelEntity
    private let interiorLight: PointLight
    private let copyRoot: Entity
    private let copyModels: [ModelEntity]
    private let productAspect: Float

    private init(
        root: Entity,
        camera: PerspectiveCamera,
        lattice: ModelEntity,
        innerShell: ModelEntity,
        productRoot: Entity,
        productMask: ModelEntity,
        contactShadow: ModelEntity,
        interiorLight: PointLight,
        copyRoot: Entity,
        copyModels: [ModelEntity],
        productAspect: Float
    ) {
        self.root = root
        self.camera = camera
        self.lattice = lattice
        self.innerShell = innerShell
        self.productRoot = productRoot
        self.productMask = productMask
        self.contactShadow = contactShadow
        self.interiorLight = interiorLight
        self.copyRoot = copyRoot
        self.copyModels = copyModels
        self.productAspect = productAspect
    }

    static func load(imageURL: URL, productName: String = "Aurelia One") async throws -> PremiumAdScene {
        let root = try await Entity(named: "PrototypeTemplate", in: realityKitContentBundle)
        guard
            let environment = root.findEntity(named: "Environment"),
            let productSlot = root.findEntity(named: "ProductSlot"),
            let cameraRig = root.findEntity(named: "CameraRig"),
            let lightingRig = root.findEntity(named: "LightingRig"),
            let effectRoot = root.findEntity(named: "EffectRoot")
        else {
            throw StudioError.missingSceneEntity("template #195 hierarchy")
        }

        let background = ModelEntity(
            mesh: .generatePlane(width: 22, height: 28),
            materials: [UnlitMaterial(color: NSColor(red: 0.067, green: 0.094, blue: 0.11, alpha: 1))]
        )
        background.name = "BlueBlackBackground"
        background.position = [0, 2.5, -4.6]
        environment.addChild(background)

        let floor = try await makeFloor()
        environment.addChild(floor)

        var wireMaterial = UnlitMaterial(color: NSColor(red: 0.83, green: 0.85, blue: 0.83, alpha: 0.92))
        wireMaterial.faceCulling = .none
        let lattice = ModelEntity(
            mesh: try latticeMesh(form: 0, thickness: 0.009),
            materials: [wireMaterial]
        )
        lattice.name = "OpticalWireLattice"
        effectRoot.addChild(lattice)

        var shellMaterial = PhysicallyBasedMaterial()
        shellMaterial.baseColor = .init(tint: NSColor(red: 0.094, green: 0.13, blue: 0.15, alpha: 0.001))
        shellMaterial.roughness = 0.14
        shellMaterial.metallic = 0.62
        shellMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.001))
        let innerShell = ModelEntity(
            mesh: try shellMesh(form: 0),
            materials: [shellMaterial]
        )
        innerShell.name = "TranslucentInnerShell"
        innerShell.scale = .init(repeating: 0.96)
        effectRoot.addChild(innerShell)

        let environmentURL = try resourceURL(
            "studio_small_08-environment-de3ba64222895aca876b1d1c2e0cf81a",
            extension: "hdr"
        )
        guard
            let environmentSource = CGImageSourceCreateWithURL(environmentURL as CFURL, nil),
            let environmentImage = CGImageSourceCreateImageAtIndex(environmentSource, 0, nil)
        else {
            throw StudioError.missingSceneEntity("studio_small_08 HDR image")
        }
        let imageBasedLight = try await EnvironmentResource(equirectangular: environmentImage)
        let imageLight = Entity()
        imageLight.name = "StudioSmall08IBL"
        imageLight.components.set(
            ImageBasedLightComponent(source: .single(imageBasedLight), intensityExponent: 0.62)
        )
        lightingRig.addChild(imageLight)
        floor.components.set(ImageBasedLightReceiverComponent(imageBasedLight: imageLight))
        innerShell.components.set(ImageBasedLightReceiverComponent(imageBasedLight: imageLight))

        let keyLight = DirectionalLight()
        keyLight.name = "DirectionalKey"
        keyLight.light = DirectionalLightComponent(
            color: NSColor(red: 0.86, green: 0.89, blue: 0.88, alpha: 1),
            intensity: 80,
            isRealWorldProxy: false
        )
        keyLight.shadow = DirectionalLightComponent.Shadow(maximumDistance: 28, depthBias: 0.0002)
        keyLight.look(at: [0, -0.15, 0], from: [-5, 6, 4], relativeTo: root)
        lightingRig.addChild(keyLight)

        let areaApproximation = SpotLight()
        areaApproximation.name = "AreaLightApproximation"
        areaApproximation.light = SpotLightComponent(
            color: NSColor(red: 0.68, green: 0.78, blue: 0.82, alpha: 1),
            intensity: 160,
            innerAngleInDegrees: 34,
            outerAngleInDegrees: 72,
            attenuationRadius: 16
        )
        areaApproximation.look(at: [0, 0, 0], from: [4, 1, 3], relativeTo: root)
        lightingRig.addChild(areaApproximation)

        let interiorLight = PointLight()
        interiorLight.name = "WarmInteriorLight"
        interiorLight.light = PointLightComponent(
            color: NSColor(red: 0.84, green: 0.64, blue: 0.41, alpha: 1),
            intensity: 0,
            attenuationRadius: 10
        )
        interiorLight.position = [0, -0.05, 0]
        lightingRig.addChild(interiorLight)

        let productTexture = try await TextureResource(contentsOf: imageURL)
        let productAspect = imageAspectRatio(imageURL)
        let productHeight: Float = 2.55
        var productMaterial = UnlitMaterial(texture: productTexture)
        productMaterial.blending = .transparent(opacity: .init(floatLiteral: 1))
        productMaterial.opacityThreshold = 0.001

        let productRoot = Entity()
        productRoot.name = "ProductRevealRoot"
        productRoot.position = [0, -0.42, 3.0]
        productSlot.addChild(productRoot)

        let productMask = ModelEntity(
            mesh: try diamondProductMesh(
                width: productHeight * productAspect,
                height: productHeight,
                progress: 0.06
            ),
            materials: [productMaterial]
        )
        productMask.name = "DiamondMaskedProduct"
        productRoot.addChild(productMask)

        var shadowMaterial = UnlitMaterial(
            color: NSColor(red: 0, green: 0, blue: 0, alpha: 0.32)
        )
        shadowMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.32))
        let contactShadow = ModelEntity(
            mesh: .generateSphere(radius: 1),
            materials: [shadowMaterial]
        )
        contactShadow.name = "SoftEllipticalContactShadow"
        contactShadow.scale = [0.72, 0.012, 0.18]
        contactShadow.position = [0, -1.73, 2.86]
        productSlot.addChild(contactShadow)

        let (copyRoot, copyModels) = makeCopy(productName: productName)
        copyRoot.position = [-1.25, -2.35, 3.15]
        productSlot.addChild(copyRoot)

        let camera = PerspectiveCamera()
        camera.name = "Template195Camera"
        camera.camera = PerspectiveCameraComponent(
            near: 0.01,
            far: 100,
            fieldOfViewInDegrees: 43,
            fieldOfViewOrientation: .vertical
        )
        cameraRig.addChild(camera)

        let scene = PremiumAdScene(
            root: root,
            camera: camera,
            lattice: lattice,
            innerShell: innerShell,
            productRoot: productRoot,
            productMask: productMask,
            contactShadow: contactShadow,
            interiorLight: interiorLight,
            copyRoot: copyRoot,
            copyModels: copyModels,
            productAspect: productAspect
        )
        scene.apply(frameIndex: Self.heroFrame)
        return scene
    }

    func apply(frameIndex: Int) {
        let frame = min(max(frameIndex, 0), Self.frameCount - 1)
        let cameraProgress = smoothstep(frame: frame, start: 0, end: 190)
        camera.look(
            at: [0, -0.15, 0],
            from: [0, 0.1, mix(12.4, 10.15, cameraProgress)],
            relativeTo: root
        )

        let form = smoothstep(frame: frame, start: 20, end: 145)
        if let mesh = try? Self.latticeMesh(form: form, thickness: 0.009) {
            lattice.model?.mesh = mesh
        }
        if let mesh = try? Self.shellMesh(form: form) {
            innerShell.model?.mesh = mesh
        }
        if var material = innerShell.model?.materials.first as? PhysicallyBasedMaterial {
            let opacity = max(0.001, 0.17 * form)
            material.baseColor.tint = NSColor(red: 0.094, green: 0.13, blue: 0.15, alpha: CGFloat(opacity))
            material.blending = .transparent(opacity: .init(floatLiteral: opacity))
            innerShell.model?.materials = [material]
        }
        interiorLight.light.intensity = 800 * form

        let productProgress = smoothstep(frame: frame, start: 122, end: 166)
        productRoot.isEnabled = productProgress > 0
        let productScale = mix(0.04, 1, productProgress)
        productRoot.scale = .init(repeating: productScale)
        productRoot.orientation = simd_quatf(
            angle: mix(-12 * .pi / 180, 0, productProgress),
            axis: [0, 0, 1]
        )
        if let mesh = try? Self.diamondProductMesh(
            width: 2.55 * productAspect,
            height: 2.55,
            progress: productProgress
        ) {
            productMask.model?.mesh = mesh
        }
        if var material = productMask.model?.materials.first as? UnlitMaterial {
            material.blending = .transparent(opacity: .init(floatLiteral: productProgress))
            let contrastLift = CGFloat(mix(1.25, 1, productProgress))
            material.color.tint = NSColor(
                red: contrastLift,
                green: contrastLift,
                blue: contrastLift,
                alpha: CGFloat(productProgress)
            )
            productMask.model?.materials = [material]
        }

        contactShadow.isEnabled = productProgress > 0
        contactShadow.scale = [
            0.72 * productScale,
            0.012,
            0.18 * productScale
        ]
        if var material = contactShadow.model?.materials.first as? UnlitMaterial {
            let alpha = 0.32 * productProgress
            material.color.tint = NSColor(red: 0, green: 0, blue: 0, alpha: CGFloat(alpha))
            material.blending = .transparent(opacity: .init(floatLiteral: alpha))
            contactShadow.model?.materials = [material]
        }

        let copyProgress = smoothstep(frame: frame, start: 186, end: 210)
        copyRoot.isEnabled = copyProgress > 0
        copyRoot.scale = .one
        for copyModel in copyModels {
            guard var material = copyModel.model?.materials.first as? UnlitMaterial else { continue }
            material.blending = .transparent(opacity: .init(floatLiteral: copyProgress))
            material.color.tint = material.color.tint.withAlphaComponent(CGFloat(copyProgress))
            copyModel.model?.materials = [material]
        }
    }

    private static func makeFloor() async throws -> ModelEntity {
        let base = try await TextureResource(
            contentsOf: try resourceURL(
                "blue_metal_plate-6189f7c443f0b7767d3e046f021b5495",
                extension: "jpg"
            )
        )
        let normal = try await TextureResource(
            contentsOf: try resourceURL(
                "blue_metal_plate-normal-c460b1b25b5d418218982d8b100822b8",
                extension: "jpg"
            )
        )
        let roughness = try await TextureResource(
            contentsOf: try resourceURL(
                "blue_metal_plate-roughness-4be6436df5c7c5ecce9febb927051d52",
                extension: "jpg"
            )
        )
        let metallic = try await TextureResource(
            contentsOf: try resourceURL(
                "blue_metal_plate-metallic-d0f422ae772522cc3978f2bf2bbb5902",
                extension: "jpg"
            )
        )
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(
            tint: NSColor(red: 0.16, green: 0.2, blue: 0.22, alpha: 1),
            texture: .init(base)
        )
        material.normal = .init(texture: .init(normal))
        material.roughness = .init(floatLiteral: 0.32)
        material.roughness.texture = .init(roughness)
        material.metallic = .init(floatLiteral: 0.48)
        material.metallic.texture = .init(metallic)
        let floor = ModelEntity(
            mesh: .generatePlane(width: 40, depth: 40),
            materials: [material]
        )
        floor.name = "BlueMetalFloor"
        floor.position = [0, -2.75, 0]
        return floor
    }

    private static func latticePoint(column: Int, row: Int, form: Float) -> SIMD3<Float> {
        let u = Float(column) / 34
        let v = Float(row) / 20
        let plane = SIMD3<Float>((u - 0.5) * 6.8, -2.42, (v - 0.5) * 4.5)
        let theta = u * .pi * 2
        let phi = v * .pi
        let sphere = SIMD3<Float>(
            sin(phi) * cos(theta) * 2.55,
            cos(phi) * 2.55 - 0.05,
            sin(phi) * sin(theta) * 2.55
        )
        return simd_mix(plane, sphere, SIMD3<Float>(repeating: form))
    }

    private static func latticeMesh(form: Float, thickness: Float) throws -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        func appendSegment(_ a: SIMD3<Float>, _ b: SIMD3<Float>) {
            let tangent = simd_normalize(b - a)
            var side = simd_cross(tangent, SIMD3<Float>(0, 0, 1))
            if simd_length_squared(side) < 0.0001 {
                side = simd_cross(tangent, SIMD3<Float>(0, 1, 0))
            }
            side = simd_normalize(side) * thickness
            let base = UInt32(positions.count)
            positions.append(contentsOf: [a - side, a + side, b - side, b + side])
            normals.append(contentsOf: Array(repeating: SIMD3<Float>(0, 0, 1), count: 4))
            indices.append(contentsOf: [base, base + 2, base + 1, base + 1, base + 2, base + 3])
        }

        for row in 0...20 {
            for column in 0..<34 {
                appendSegment(
                    latticePoint(column: column, row: row, form: form),
                    latticePoint(column: column + 1, row: row, form: form)
                )
            }
        }
        for column in 0...34 {
            for row in 0..<20 {
                appendSegment(
                    latticePoint(column: column, row: row, form: form),
                    latticePoint(column: column, row: row + 1, form: form)
                )
            }
        }
        for row in 0..<20 {
            for column in 0..<34 {
                appendSegment(
                    latticePoint(column: column, row: row, form: form),
                    latticePoint(column: column + 1, row: row + 1, form: form)
                )
            }
        }

        var descriptor = MeshDescriptor(name: "OpticalMeshWireframe")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }

    private static func shellMesh(form: Float) throws -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for row in 0...20 {
            for column in 0...34 {
                let point = latticePoint(column: column, row: row, form: form)
                positions.append(point)
                normals.append(simd_normalize(point - SIMD3<Float>(0, -0.05, 0)))
                textureCoordinates.append([Float(column) / 34, Float(row) / 20])
            }
        }
        for row in 0..<20 {
            for column in 0..<34 {
                let a = UInt32(row * 35 + column)
                let b = a + 1
                let c = a + 35
                let d = c + 1
                indices.append(contentsOf: [a, c, b, b, c, d])
            }
        }
        var descriptor = MeshDescriptor(name: "OpticalMeshInnerShell")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(textureCoordinates)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }

    private static func diamondProductMesh(
        width: Float,
        height: Float,
        progress: Float
    ) throws -> MeshResource {
        let columns = 40
        let rows = 40
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        var lookup: [Int: UInt32] = [:]

        for row in 0...rows {
            for column in 0...columns {
                let u = Float(column) / Float(columns)
                let v = Float(row) / Float(rows)
                let revealRadius = 0.025 + 0.975 * progress
                if abs(u - 0.5) + abs(v - 0.5) <= revealRadius {
                    lookup[row * (columns + 1) + column] = UInt32(positions.count)
                    positions.append([(u - 0.5) * width, (0.5 - v) * height, 0])
                    normals.append([0, 0, 1])
                    textureCoordinates.append([u, 1 - v])
                }
            }
        }
        for row in 0..<rows {
            for column in 0..<columns {
                let aKey = row * (columns + 1) + column
                let bKey = aKey + 1
                let cKey = aKey + columns + 1
                let dKey = cKey + 1
                if let a = lookup[aKey], let b = lookup[bKey], let c = lookup[cKey] {
                    indices.append(contentsOf: [a, c, b])
                }
                if let b = lookup[bKey], let c = lookup[cKey], let d = lookup[dKey] {
                    indices.append(contentsOf: [b, c, d])
                }
            }
        }
        var descriptor = MeshDescriptor(name: "DiamondProductMask")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(textureCoordinates)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }

    private static func makeCopy(productName: String) -> (Entity, [ModelEntity]) {
        let root = Entity()
        root.name = "FinalCopy"
        let white = UnlitMaterial(color: NSColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1))
        let muted = UnlitMaterial(color: NSColor(red: 0.76, green: 0.75, blue: 0.72, alpha: 1))
        let eyebrow = textEntity(
            "FORM / MATERIAL / PRESENCE",
            font: .systemFont(ofSize: 0.1, weight: .medium),
            material: muted
        )
        eyebrow.position = [0, 0.54, 0]
        root.addChild(eyebrow)
        let headline = textEntity(
            productName,
            font: .systemFont(ofSize: 0.28, weight: .semibold),
            material: white
        )
        root.addChild(headline)
        let cta = textEntity(
            "Discover",
            font: .systemFont(ofSize: 0.09, weight: .medium),
            material: muted
        )
        cta.position = [1.75, 0.05, 0]
        root.addChild(cta)
        return (root, [eyebrow, headline, cta])
    }

    private static func textEntity(_ text: String, font: NSFont, material: UnlitMaterial) -> ModelEntity {
        ModelEntity(
            mesh: .generateText(
                text,
                extrusionDepth: 0.001,
                font: font,
                containerFrame: .zero,
                alignment: .left,
                lineBreakMode: .byClipping
            ),
            materials: [material]
        )
    }

    private static func imageAspectRatio(_ url: URL) -> Float {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
            let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
            height.floatValue > 0
        else {
            return 0.72
        }
        return width.floatValue / height.floatValue
    }

    private static func resourceURL(_ name: String, extension fileExtension: String) throws -> URL {
        guard let url = realityKitContentBundle.url(
            forResource: name,
            withExtension: fileExtension
        ) else {
            throw StudioError.missingSceneEntity("\(name).\(fileExtension)")
        }
        return url
    }

    private func smoothstep(frame: Int, start: Int, end: Int) -> Float {
        let t = min(max(Float(frame - start) / Float(end - start), 0), 1)
        return t * t * (3 - 2 * t)
    }

    private func mix(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }
}
