import AppKit
import ImageIO
import RealityKit
import RealityKitContent

@MainActor
enum NewSceneSupport {
    static func entity(_ sceneName: String) async throws -> Entity {
        try await Entity(named: sceneName, in: realityKitContentBundle)
    }

    static func child(_ name: String, in root: Entity) throws -> Entity {
        guard let entity = root.findEntity(named: name) else {
            throw StudioError.missingSceneEntity(name)
        }
        return entity
    }

    static func resource(_ name: String, extension fileExtension: String) throws -> URL {
        guard let url = realityKitContentBundle.url(
            forResource: name,
            withExtension: fileExtension
        ) else {
            throw StudioError.missingSceneEntity("\(name).\(fileExtension)")
        }
        return url
    }

    static func surfaceMaterial(
        id: String,
        tint: NSColor = .white,
        metallic: Bool = false
    ) async throws -> PhysicallyBasedMaterial {
        let diffuse = try await TextureResource(
            contentsOf: resource("\(id)_diff_2k", extension: "jpg")
        )
        let normal = try await TextureResource(
            contentsOf: resource("\(id)_nor_gl_2k", extension: "jpg")
        )
        let roughness = try await TextureResource(
            contentsOf: resource("\(id)_rough_2k", extension: "jpg")
        )
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: tint, texture: .init(diffuse))
        material.normal = .init(texture: .init(normal))
        material.roughness = .init(floatLiteral: 0.6)
        material.roughness.texture = .init(roughness)
        if metallic {
            let map = try await TextureResource(
                contentsOf: resource("\(id)_metal_2k", extension: "jpg")
            )
            material.metallic = .init(floatLiteral: 0.8)
            material.metallic.texture = .init(map)
        }
        return material
    }

    static func imageLight(
        id: String,
        exponent: Float,
        parent: Entity
    ) async throws -> Entity {
        let url = try resource("\(id)_1k", extension: "hdr")
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw StudioError.missingSceneEntity("\(id)_1k.hdr")
        }
        let environment = try await EnvironmentResource(equirectangular: image)
        let light = Entity()
        light.name = "\(id)IBL"
        light.components.set(
            ImageBasedLightComponent(
                source: .single(environment),
                intensityExponent: exponent
            )
        )
        parent.addChild(light)
        return light
    }

    static func receiveIBL(_ entities: [ModelEntity], light: Entity) {
        for entity in entities {
            entity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: light))
        }
    }

    static func receiveIBL(in root: Entity, light: Entity) {
        if let model = root as? ModelEntity {
            model.components.set(ImageBasedLightReceiverComponent(imageBasedLight: light))
        }
        for child in root.children {
            receiveIBL(in: child, light: light)
        }
    }

    static func product(
        imageURL: URL,
        height: Float,
        name: String
    ) async throws -> ModelEntity {
        let texture = try await TextureResource(contentsOf: imageURL)
        var material = UnlitMaterial(texture: texture)
        material.blending = .transparent(opacity: .init(floatLiteral: 1))
        material.opacityThreshold = 0.001
        material.faceCulling = .none
        let entity = ModelEntity(
            mesh: .generatePlane(
                width: height * imageAspectRatio(imageURL),
                height: height
            ),
            materials: [material]
        )
        entity.name = name
        return entity
    }

    static func litProduct(
        imageURL: URL,
        height: Float,
        name: String,
        roughness: Float = 0.34
    ) async throws -> ModelEntity {
        let texture = try await TextureResource(contentsOf: imageURL)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .white, texture: .init(texture))
        material.roughness = .init(floatLiteral: roughness)
        material.metallic = .init(floatLiteral: 0.02)
        material.blending = .transparent(opacity: .init(floatLiteral: 1))
        material.opacityThreshold = 0.001
        material.faceCulling = .none
        let entity = ModelEntity(
            mesh: .generatePlane(
                width: height * imageAspectRatio(imageURL),
                height: height
            ),
            materials: [material]
        )
        entity.name = name
        return entity
    }

    // Experimental shallow-volume product representation.
    // Isolated to templates that explicitly opt into spatialProduct().
    // The source cutout is repeated through real Z space so modest
    // perspective movement produces depth/parallax instead of a single plane.
    static func spatialProduct(
        imageURL: URL,
        height: Float,
        name: String,
        depth: Float = 0.12
    ) async throws -> Entity {
        let root = Entity()
        root.name = name

        let texture = try await TextureResource(contentsOf: imageURL)
        let width = height * imageAspectRatio(imageURL)

        // Back-to-front shallow volume.
        // Center layers carry most of the visible product.
        let layerCount = 9

        for index in 0..<layerCount {
            let normalized =
                Float(index) / Float(layerCount - 1) * 2.0 - 1.0

            // Slightly taper rear/front layers to imply curved volume.
            let profile =
                sqrt(max(0, 1.0 - normalized * normalized))

            let layerScale =
                0.965 + profile * 0.035

            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(
                tint: .white,
                texture: .init(texture)
            )
            material.roughness = .init(
                floatLiteral: 0.20 + abs(normalized) * 0.12
            )
            material.metallic = .init(floatLiteral: 0.025)
            material.blending = .transparent(
                opacity: .init(floatLiteral: 1)
            )
            material.opacityThreshold = 0.025
            material.faceCulling = .none

            let layer = ModelEntity(
                mesh: .generatePlane(
                    width: width,
                    height: height
                ),
                materials: [material]
            )

            layer.name = "\(name)_DepthLayer_\(index)"

            // RealityKit plane faces camera; Z gives actual spatial separation.
            layer.position.z = normalized * depth * 0.5

            layer.scale = [
                layerScale,
                1.0,
                1.0
            ]

            root.addChild(layer)
        }

        // Thin dark backing gives the silhouette visual mass when viewed
        // slightly off-axis without pretending we know the unseen backside.
        var backingMaterial = PhysicallyBasedMaterial()
        backingMaterial.baseColor = .init(
            tint: NSColor(
                red: 0.035,
                green: 0.040,
                blue: 0.050,
                alpha: 1
            )
        )
        backingMaterial.roughness = .init(floatLiteral: 0.30)
        backingMaterial.metallic = .init(floatLiteral: 0.08)

        let backing = ModelEntity(
            mesh: .generateBox(
                width: width * 0.94,
                height: height * 0.94,
                depth: depth * 0.72,
                cornerRadius: min(width, height) * 0.035
            ),
            materials: [backingMaterial]
        )

        backing.name = "\(name)_DepthCore"
        backing.position.z = -depth * 0.42

        root.addChild(backing)

        return root
    }

    static func camera(focalLength: Float, name: String) -> PerspectiveCamera {
        let camera = PerspectiveCamera()
        camera.name = name
        let verticalFOV = 2 * atan(12 / focalLength) * 180 / .pi
        camera.camera = PerspectiveCameraComponent(
            near: 0.01,
            far: 120,
            fieldOfViewInDegrees: verticalFOV,
            fieldOfViewOrientation: .vertical
        )
        return camera
    }

    static func text(
        _ value: String,
        fontName: String,
        size: CGFloat,
        color: NSColor,
        depth: Float = 0.004
    ) -> ModelEntity {
        let font = NSFont(name: fontName, size: size)
            ?? .systemFont(ofSize: size, weight: .semibold)
        return ModelEntity(
            mesh: .generateText(
                value,
                extrusionDepth: depth,
                font: font,
                containerFrame: .zero,
                alignment: .left,
                lineBreakMode: .byClipping
            ),
            materials: [UnlitMaterial(color: color)]
        )
    }

    static func smooth(_ frame: Int, _ start: Int, _ end: Int) -> Float {
        guard end > start else { return frame >= end ? 1 : 0 }
        let value = min(max(Float(frame - start) / Float(end - start), 0), 1)
        return value * value * (3 - 2 * value)
    }

    static func mix(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }

    static func mix(
        _ a: SIMD3<Float>,
        _ b: SIMD3<Float>,
        _ t: Float
    ) -> SIMD3<Float> {
        simd_mix(a, b, SIMD3<Float>(repeating: t))
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
}
