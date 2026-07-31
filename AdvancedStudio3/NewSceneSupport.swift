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
