import AppKit
import CoreGraphics
import Foundation
import ImageIO
import RealityKit
import RealityKitContent
import simd

@MainActor
final class MineralFoldScene {
    static let duration = 8.0
    static let frameRate = 30
    static let frameCount = 240
    static let heroFrame = 218

    let root: Entity
    let camera: PerspectiveCamera

    private let terrain: ModelEntity
    private let mineralVein: ModelEntity
    private let originSeed: ModelEntity
    private let productRoot: Entity
    private let productPlane: ModelEntity
    private let contactShadow: ModelEntity
    private let veinLight: PointLight
    private let productLight: SpotLight
    private let copyRoot: Entity
    private let copyModels: [ModelEntity]
    private let productAspect: Float

    private init(
        root: Entity,
        camera: PerspectiveCamera,
        terrain: ModelEntity,
        mineralVein: ModelEntity,
        originSeed: ModelEntity,
        productRoot: Entity,
        productPlane: ModelEntity,
        contactShadow: ModelEntity,
        veinLight: PointLight,
        productLight: SpotLight,
        copyRoot: Entity,
        copyModels: [ModelEntity],
        productAspect: Float
    ) {
        self.root = root
        self.camera = camera
        self.terrain = terrain
        self.mineralVein = mineralVein
        self.originSeed = originSeed
        self.productRoot = productRoot
        self.productPlane = productPlane
        self.contactShadow = contactShadow
        self.veinLight = veinLight
        self.productLight = productLight
        self.copyRoot = copyRoot
        self.copyModels = copyModels
        self.productAspect = productAspect
    }

    static func load(imageURL: URL) async throws -> MineralFoldScene {
        let root = try await Entity(named: "MineralFold", in: realityKitContentBundle)
        guard
            let environment = root.findEntity(named: "Environment"),
            let terrainRoot = root.findEntity(named: "TerrainRoot"),
            let veinRoot = root.findEntity(named: "VeinRoot"),
            let productSlot = root.findEntity(named: "ProductSlot"),
            let authoredCopyRoot = root.findEntity(named: "CopyRoot"),
            let cameraRig = root.findEntity(named: "CameraRig"),
            let lightingRig = root.findEntity(named: "LightingRig")
        else {
            throw StudioError.missingSceneEntity("Mineral Fold scale-reveal hierarchy")
        }

        var skyMaterial = UnlitMaterial(
            color: NSColor(red: 0.035, green: 0.075, blue: 0.12, alpha: 1)
        )
        skyMaterial.faceCulling = .none
        let sky = ModelEntity(
            mesh: .generateSphere(radius: 40),
            materials: [skyMaterial]
        )
        sky.name = "PolarDuskSky"
        sky.position = .zero
        environment.addChild(sky)

        var horizonMaterial = UnlitMaterial(
            color: NSColor(red: 0.72, green: 0.79, blue: 0.84, alpha: 0.28)
        )
        horizonMaterial.faceCulling = .none
        horizonMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.2))
        let horizon = ModelEntity(
            mesh: .generatePlane(width: 26, height: 2.6),
            materials: [horizonMaterial]
        )
        horizon.name = "PolarHorizon"
        horizon.position = [0, 1.2, -17.75]
        horizon.orientation = simd_quatf(
            angle: .pi / 2,
            axis: SIMD3<Float>(1, 0, 0)
        )
        environment.addChild(horizon)

        let terrainMaterial = try await makeTerrainMaterial()
        let terrain = ModelEntity(
            mesh: try terrainMesh(reveal: 0),
            materials: [terrainMaterial]
        )
        terrain.name = "MatchScaleTerrain"
        terrainRoot.addChild(terrain)

        let veinMaterial = makeVeinMaterial()
        let mineralVein = ModelEntity(
            mesh: try veinMesh(growth: 0.02, terrainReveal: 0),
            materials: [veinMaterial]
        )
        mineralVein.name = "GrowingMineralVein"
        veinRoot.addChild(mineralVein)

        let originSeed = ModelEntity(
            mesh: .generateSphere(radius: 1),
            materials: [veinMaterial]
        )
        originSeed.name = "AmbiguousMineralSeed"
        originSeed.position = [pathX(z: 5.5), 0.045, 5.5]
        originSeed.scale = [0.22, 0.008, 0.16]
        veinRoot.addChild(originSeed)

        let environmentURL = try resourceURL(
            "studio_small_03-74e6ef69ea9024c2cc25b3a7de8ec2f7",
            extension: "hdr"
        )
        guard
            let source = CGImageSourceCreateWithURL(environmentURL as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw StudioError.missingSceneEntity("studio_small_03 HDR image")
        }
        let environmentResource = try await EnvironmentResource(equirectangular: image)
        let imageLight = Entity()
        imageLight.name = "StudioSmall03IBL"
        imageLight.components.set(
            ImageBasedLightComponent(source: .single(environmentResource), intensityExponent: 0.18)
        )
        lightingRig.addChild(imageLight)
        terrain.components.set(ImageBasedLightReceiverComponent(imageBasedLight: imageLight))
        mineralVein.components.set(ImageBasedLightReceiverComponent(imageBasedLight: imageLight))
        originSeed.components.set(ImageBasedLightReceiverComponent(imageBasedLight: imageLight))

        let grazingKey = DirectionalLight()
        grazingKey.name = "GrazingWarmKey"
        grazingKey.light = DirectionalLightComponent(
            color: NSColor(red: 0.78, green: 0.9, blue: 1, alpha: 1),
            intensity: 260,
            isRealWorldProxy: false
        )
        grazingKey.shadow = .init(maximumDistance: 40, depthBias: 0.0003)
        grazingKey.look(at: [0, 0, 1], from: [-3, 7, 10], relativeTo: root)
        lightingRig.addChild(grazingKey)

        let veinLight = PointLight()
        veinLight.name = "VeinGlow"
        veinLight.light = PointLightComponent(
            color: NSColor(red: 0.12, green: 0.84, blue: 1, alpha: 1),
            intensity: 0,
            attenuationRadius: 5
        )
        veinLight.position = [0, 1.4, 3.4]
        lightingRig.addChild(veinLight)

        let productLight = SpotLight()
        productLight.name = "ProductRevealLight"
        productLight.light = SpotLightComponent(
            color: NSColor(red: 1, green: 0.88, blue: 0.72, alpha: 1),
            intensity: 0,
            innerAngleInDegrees: 22,
            outerAngleInDegrees: 52,
            attenuationRadius: 16
        )
        productLight.look(at: [1.3, 1.9, 3], from: [-2.6, 6.2, 7], relativeTo: root)
        lightingRig.addChild(productLight)

        let productTexture = try await TextureResource(contentsOf: imageURL)
        let productAspect = imageAspectRatio(imageURL)
        var productMaterial = UnlitMaterial(texture: productTexture)
        productMaterial.blending = .transparent(opacity: .init(floatLiteral: 1))
        productMaterial.opacityThreshold = 0.001

        let productRoot = Entity()
        productRoot.name = "LateHeroRoot"
        productRoot.position = [1.3, 2.68, 3]
        productSlot.addChild(productRoot)

        let productPlane = ModelEntity(
            mesh: try verticalRevealMesh(
                width: 2.75 * productAspect,
                height: 2.75,
                progress: 0.02
            ),
            materials: [productMaterial]
        )
        productPlane.name = "VisionProductCutout"
        productRoot.addChild(productPlane)

        var shadowMaterial = UnlitMaterial(
            color: NSColor(red: 0.004, green: 0.003, blue: 0.002, alpha: 0.2)
        )
        shadowMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.2))
        let contactShadow = ModelEntity(
            mesh: .generateSphere(radius: 1),
            materials: [shadowMaterial]
        )
        contactShadow.name = "TerrainContactShadow"
        contactShadow.position = [1.3, 1.28, 3.06]
        contactShadow.scale = [0.66, 0.012, 0.18]
        productSlot.addChild(contactShadow)

        let (copyRoot, copyModels) = makeCopy()
        authoredCopyRoot.addChild(copyRoot)

        let camera = PerspectiveCamera()
        camera.name = "MatchScaleCamera"
        camera.camera = PerspectiveCameraComponent(
            near: 0.01,
            far: 100,
            fieldOfViewInDegrees: 38,
            fieldOfViewOrientation: .vertical
        )
        cameraRig.addChild(camera)

        let scene = MineralFoldScene(
            root: root,
            camera: camera,
            terrain: terrain,
            mineralVein: mineralVein,
            originSeed: originSeed,
            productRoot: productRoot,
            productPlane: productPlane,
            contactShadow: contactShadow,
            veinLight: veinLight,
            productLight: productLight,
            copyRoot: copyRoot,
            copyModels: copyModels,
            productAspect: productAspect
        )
        scene.apply(frameIndex: heroFrame)
        return scene
    }

    func apply(frameIndex: Int) {
        let frame = min(max(frameIndex, 0), Self.frameCount - 1)

        let channelGrowth = smoothstep(frame: frame, start: 4, end: 86)
        let terrainReveal = smoothstep(frame: frame, start: 90, end: 108)
        if let mesh = try? Self.terrainMesh(reveal: terrainReveal) {
            terrain.model?.mesh = mesh
        }
        if let mesh = try? Self.veinMesh(
            growth: max(0.02, channelGrowth),
            terrainReveal: terrainReveal
        ) {
            mineralVein.model?.mesh = mesh
        }

        let seedDissolve = smoothstep(frame: frame, start: 70, end: 94)
        originSeed.isEnabled = seedDissolve < 1
        originSeed.scale = [
            mix(0.22, 0.1, channelGrowth),
            mix(0.008, 0.005, channelGrowth),
            mix(0.16, 0.3, channelGrowth)
        ] * (1 - 0.75 * seedDissolve)

        let cameraScale = smoothstep(frame: frame, start: 0, end: 88)
        let cameraReveal = smoothstep(frame: frame, start: 90, end: 116)
        let cameraAerial = smoothstep(frame: frame, start: 116, end: 174)
        let cameraHero = smoothstep(frame: frame, start: 174, end: 210)
        let macroPosition = mix(
            SIMD3<Float>(0.1, 1.05, 7.5),
            SIMD3<Float>(0.12, 1.2, 8.0),
            cameraScale
        )
        let macroTarget = mix(
            SIMD3<Float>(0.02, 0.015, 5.35),
            SIMD3<Float>(0, 0.025, 1.9),
            cameraScale
        )
        let revealPosition = mix(
            macroPosition,
            SIMD3<Float>(0.3, 5.0, 12.2),
            cameraReveal
        )
        let revealTarget = mix(
            macroTarget,
            SIMD3<Float>(0, 0.1, -0.8),
            cameraReveal
        )
        let aerialPosition = mix(
            revealPosition,
            SIMD3<Float>(0.45, 6.0, 14.8),
            cameraAerial
        )
        let aerialTarget = mix(
            revealTarget,
            SIMD3<Float>(0, 0.05, -1.8),
            cameraAerial
        )
        camera.look(
            at: mix(aerialTarget, [1.15, 1.45, 3], cameraHero),
            from: mix(aerialPosition, [0.85, 4.0, 10.6], cameraHero),
            relativeTo: root
        )

        veinLight.light.intensity =
            (420 + 980 * smoothstep(frame: frame, start: 72, end: 112))
            * (1 - 0.3 * smoothstep(frame: frame, start: 176, end: 210))

        let productProgress = smoothstep(frame: frame, start: 164, end: 202)
        productRoot.isEnabled = productProgress > 0
        productRoot.position.y = mix(2.12, 2.68, productProgress)
        productRoot.scale = .init(repeating: mix(0.92, 1, productProgress))
        if let mesh = try? Self.verticalRevealMesh(
            width: 2.75 * productAspect,
            height: 2.75,
            progress: productProgress
        ) {
            productPlane.model?.mesh = mesh
        }
        contactShadow.isEnabled = productProgress > 0
        contactShadow.scale = [
            0.66 * productProgress,
            0.012,
            0.18 * productProgress
        ]
        if var material = contactShadow.model?.materials.first as? UnlitMaterial {
            let alpha = 0.2 * productProgress
            material.color.tint = NSColor(
                red: 0.004,
                green: 0.003,
                blue: 0.002,
                alpha: CGFloat(alpha)
            )
            material.blending = .transparent(opacity: .init(floatLiteral: alpha))
            contactShadow.model?.materials = [material]
        }
        productLight.light.intensity =
            650 * smoothstep(frame: frame, start: 170, end: 208)

        let copyProgress = smoothstep(frame: frame, start: 204, end: 218)
        copyRoot.isEnabled = copyProgress > 0
        copyRoot.position = [-0.2, mix(3.2, 3.32, copyProgress), 2.6]
        for copyModel in copyModels {
            guard var material = copyModel.model?.materials.first as? UnlitMaterial else {
                continue
            }
            material.blending = .transparent(opacity: .init(floatLiteral: copyProgress))
            material.color.tint = material.color.tint.withAlphaComponent(CGFloat(copyProgress))
            copyModel.model?.materials = [material]
        }
    }

    private static func makeTerrainMaterial() async throws -> PhysicallyBasedMaterial {
        let normal = try await TextureResource(
            contentsOf: try resourceURL(
                "marble_01-normal-f25efb0b61ec7ac183b3b0f4d032ed17",
                extension: "jpg"
            )
        )
        let roughness = try await TextureResource(
            contentsOf: try resourceURL(
                "marble_01-roughness-c4cf0375d84277c6020bf230823efdcc",
                extension: "jpg"
            )
        )
        let metallic = try await TextureResource(
            contentsOf: try resourceURL(
                "marble_01-metallic-63305599b8b82c5769c0ac2a4a951ba6",
                extension: "jpg"
            )
        )
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = NSColor(
            red: 0.42, green: 0.53, blue: 0.62, alpha: 1
        )
        material.normal = .init(texture: .init(normal))
        material.roughness = .init(floatLiteral: 0.56)
        material.roughness.texture = .init(roughness)
        material.metallic = .init(floatLiteral: 0.0)
        material.metallic.texture = .init(metallic)
        return material
    }

    private static func makeVeinMaterial() -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = NSColor(
            red: 0.7,
            green: 0.88,
            blue: 0.96,
            alpha: 1
        )
        material.roughness = .init(floatLiteral: 0.07)
        material.metallic = .init(floatLiteral: 0.72)
        material.emissiveColor = .init(
            color: NSColor(red: 0.01, green: 0.12, blue: 0.18, alpha: 1)
        )
        material.emissiveIntensity = 0.45
        return material
    }

    private static func pathX(z: Float) -> Float {
        0.42 * sin(z * 0.68)
            + 0.18 * sin(z * 1.73 + 0.8)
            + 0.055 * z
    }

    private static func macroHeight(x: Float, z: Float) -> Float {
        0.035 * sin(x * 4.4 + z * 0.35)
            + 0.018 * sin(z * 2.8 - x * 1.2)
    }

    private static func landscapeHeight(x: Float, z: Float) -> Float {
        let channelDistance = abs(x - pathX(z: z))
        let basin: Float = -0.3 * exp(-channelDistance * channelDistance * 7)
        let foldedA = abs(sin(x * 0.88 + z * 0.16))
        let foldedB = abs(sin(x * 1.62 - z * 0.23 + 0.7))
        let broadRidges =
            0.34 * pow(foldedA, 4.2)
            + 0.16 * pow(foldedB, 5.4)
        let erosion = 0.055 * pow(abs(sin(x * 5.6 + z * 0.54)), 4)
        let edgeLift = 0.012 * x * x
        return 0.05 + basin + broadRidges + erosion + edgeLift
    }

    private static func terrainPoint(
        column: Int,
        row: Int,
        reveal: Float
    ) -> SIMD3<Float> {
        let columns: Float = 112
        let rows: Float = 144
        let u = Float(column) / columns
        let v = Float(row) / rows
        let x = (u - 0.5) * 11
        let z = (v - 0.5) * 17
        let revealFront = reveal * 1.32 - v + 0.16
        let localReveal = cubicSmooth(min(max(revealFront / 0.26, 0), 1))
        let y = mixStatic(
            macroHeight(x: x, z: z),
            landscapeHeight(x: x, z: z),
            localReveal
        )
        return [x, y, z]
    }

    private static func terrainMesh(reveal: Float) throws -> MeshResource {
        let columns = 112
        let rows = 144
        var positions: [SIMD3<Float>] = []
        var coordinates: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for row in 0...rows {
            for column in 0...columns {
                positions.append(terrainPoint(column: column, row: row, reveal: reveal))
                coordinates.append([
                    Float(column) / Float(columns),
                    Float(row) / Float(rows)
                ])
            }
        }
        for row in 0..<rows {
            for column in 0..<columns {
                let a = UInt32(row * (columns + 1) + column)
                let b = a + 1
                let c = a + UInt32(columns + 1)
                let d = c + 1
                indices.append(contentsOf: [a, c, b, b, c, d])
            }
        }
        let normals = accumulatedNormals(positions: positions, indices: indices)
        var descriptor = MeshDescriptor(name: "MatchScaleTerrain")
        descriptor.positions = .init(positions)
        descriptor.normals = .init(normals)
        descriptor.textureCoordinates = .init(coordinates)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }

    private static func veinMesh(
        growth: Float,
        terrainReveal: Float
    ) throws -> MeshResource {
        let segments = 120
        let visibleSegments = max(2, min(segments, Int(Float(segments) * growth)))
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var coordinates: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        let crossSections = 8
        let routes: [(offset: Float, branchStart: Float)] = [
            (0, 0),
            (-2.1, 0.46),
            (1.8, 0.56)
        ]
        for route in routes {
            let firstSegment = route.offset == 0
                ? 0
                : Int(Float(segments) * route.branchStart)
            guard visibleSegments > firstSegment else { continue }
            let firstVertex = positions.count
            for index in firstSegment...visibleSegments {
                let t = Float(index) / Float(segments)
                let z = 5.65 - t * 13.2
                let branchProgress = cubicSmooth(
                    min(
                        max(
                            (t - route.branchStart)
                                / max(0.001, 1 - route.branchStart),
                            0
                        ),
                        1
                    )
                )
                let x = pathX(z: z) + route.offset * branchProgress
                let nextT = min(1, t + 0.004)
                let nextZ = 5.65 - nextT * 13.2
                let nextBranchProgress = cubicSmooth(
                    min(
                        max(
                            (nextT - route.branchStart)
                                / max(0.001, 1 - route.branchStart),
                            0
                        ),
                        1
                    )
                )
                let nextX = pathX(z: nextZ)
                    + route.offset * nextBranchProgress
                let tangent = simd_normalize(
                    SIMD2<Float>(nextX - x, nextZ - z)
                )
                let side = SIMD2<Float>(-tangent.y, tangent.x)
                let routeScale: Float = route.offset == 0 ? 1 : 0.72
                let width = routeScale
                    * (0.085 + 0.035 * sin(t * .pi) + 0.012 * sin(t * 11))
                let v = (z / 17) + 0.5
                let localReveal = cubicSmooth(
                    min(max((terrainReveal * 1.32 - v + 0.16) / 0.26, 0), 1)
                )
                let y = mixStatic(
                    macroHeight(x: x, z: z),
                    landscapeHeight(x: x, z: z),
                    localReveal
                ) + 0.008
                for crossSection in 0...crossSections {
                    let angle = Float(crossSection)
                        / Float(crossSections) * .pi
                    let lateral = cos(angle)
                    let vertical = sin(angle)
                    positions.append([
                        x + side.x * width * lateral,
                        y + vertical * width * 0.055,
                        z + side.y * width * lateral
                    ])
                    normals.append(
                        simd_normalize([
                            side.x * lateral,
                            vertical,
                            side.y * lateral
                        ])
                    )
                    coordinates.append([
                        Float(crossSection) / Float(crossSections),
                        t
                    ])
                }
            }
            let routeSegments = visibleSegments - firstSegment
            for index in 0..<routeSegments {
                for crossSection in 0..<crossSections {
                    let a = UInt32(
                        firstVertex + index * (crossSections + 1) + crossSection
                    )
                    let b = a + 1
                    let c = a + UInt32(crossSections + 1)
                    let d = c + 1
                    indices.append(contentsOf: [a, c, b, b, c, d])
                }
            }
        }
        var descriptor = MeshDescriptor(name: "GrowingMineralVein")
        descriptor.positions = .init(positions)
        descriptor.normals = .init(normals)
        descriptor.textureCoordinates = .init(coordinates)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }

    private static func accumulatedNormals(
        positions: [SIMD3<Float>],
        indices: [UInt32]
    ) -> [SIMD3<Float>] {
        var normals = Array(repeating: SIMD3<Float>.zero, count: positions.count)
        for index in stride(from: 0, to: indices.count, by: 3) {
            let a = Int(indices[index])
            let b = Int(indices[index + 1])
            let c = Int(indices[index + 2])
            let normal = simd_cross(positions[b] - positions[a], positions[c] - positions[a])
            normals[a] += normal
            normals[b] += normal
            normals[c] += normal
        }
        return normals.map {
            simd_length_squared($0) > 0.000001
                ? simd_normalize($0)
                : SIMD3<Float>(0, 1, 0)
        }
    }

    private static func verticalRevealMesh(
        width: Float,
        height: Float,
        progress: Float
    ) throws -> MeshResource {
        let columns = 24
        let rows = 40
        let firstVisibleRow = max(0, min(rows - 1, Int(Float(rows) * (1 - progress))))
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var coordinates: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for row in firstVisibleRow...rows {
            let v = Float(row) / Float(rows)
            for column in 0...columns {
                let u = Float(column) / Float(columns)
                positions.append([(u - 0.5) * width, (0.5 - v) * height, 0])
                normals.append([0, 0, 1])
                coordinates.append([u, 1 - v])
            }
        }
        let visibleRows = rows - firstVisibleRow
        for row in 0..<visibleRows {
            for column in 0..<columns {
                let a = UInt32(row * (columns + 1) + column)
                let b = a + 1
                let c = a + UInt32(columns + 1)
                let d = c + 1
                indices.append(contentsOf: [a, c, b, b, c, d])
            }
        }
        var descriptor = MeshDescriptor(name: "LateProductReveal")
        descriptor.positions = .init(positions)
        descriptor.normals = .init(normals)
        descriptor.textureCoordinates = .init(coordinates)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }

    private static func makeCopy() -> (Entity, [ModelEntity]) {
        let root = Entity()
        root.name = "FinalCopy"
        let primary = UnlitMaterial(
            color: NSColor(red: 0.94, green: 0.88, blue: 0.76, alpha: 1)
        )
        let secondary = UnlitMaterial(
            color: NSColor(red: 0.72, green: 0.46, blue: 0.26, alpha: 1)
        )
        let eyebrow = textEntity(
            "FROM ELEMENT / TO ICON",
            font: .systemFont(ofSize: 0.092, weight: .medium),
            material: secondary
        )
        eyebrow.position = [0, 0.34, 0]
        root.addChild(eyebrow)
        let headline = textEntity(
            "DISCOVER",
            font: .systemFont(ofSize: 0.22, weight: .semibold),
            material: primary
        )
        root.addChild(headline)
        return (root, [eyebrow, headline])
    }

    private static func textEntity(
        _ text: String,
        font: NSFont,
        material: UnlitMaterial
    ) -> ModelEntity {
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
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
            let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
            height.floatValue > 0
        else {
            return 0.72
        }
        return width.floatValue / height.floatValue
    }

    private static func resourceURL(
        _ name: String,
        extension fileExtension: String
    ) throws -> URL {
        guard let url = realityKitContentBundle.url(
            forResource: name,
            withExtension: fileExtension
        ) else {
            throw StudioError.missingSceneEntity("\(name).\(fileExtension)")
        }
        return url
    }

    private static func cubicSmooth(_ t: Float) -> Float {
        t * t * (3 - 2 * t)
    }

    private static func mixStatic(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }

    private func smoothstep(frame: Int, start: Int, end: Int) -> Float {
        let t = min(max(Float(frame - start) / Float(end - start), 0), 1)
        return Self.cubicSmooth(t)
    }

    private func mix(_ a: Float, _ b: Float, _ t: Float) -> Float {
        Self.mixStatic(a, b, t)
    }

    private func mix(
        _ a: SIMD3<Float>,
        _ b: SIMD3<Float>,
        _ t: Float
    ) -> SIMD3<Float> {
        simd_mix(a, b, SIMD3<Float>(repeating: t))
    }
}
