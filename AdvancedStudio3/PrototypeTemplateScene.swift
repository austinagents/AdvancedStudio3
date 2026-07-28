import Foundation
import ImageIO
import RealityKit
import RealityKitContent

enum PrototypeTemplateScene {
    static func load(imageURL: URL) async throws -> Entity {
        let scene = try await Entity(
            named: "PrototypeTemplate",
            in: realityKitContentBundle
        )
        guard let productSlot = scene.findEntity(named: "ProductSlot") else {
            throw PrototypeTemplateError.missingProductSlot
        }

        let product = try await makeProduct(imageURL: imageURL)
        productSlot.addChild(product)
        return scene
    }

    static func makeProgrammaticFallback(imageURL: URL) async throws -> Entity {
        try await makeProduct(imageURL: imageURL)
    }

    private static func makeProduct(imageURL: URL) async throws -> Entity {
        let texture = try await TextureResource(contentsOf: imageURL)
        let aspectRatio = aspectRatio(of: imageURL)
        let height: Float = 1.6
        let width = height * aspectRatio
        let mesh = MeshResource.generatePlane(width: width, height: height)
        let material = UnlitMaterial(texture: texture)
        let product = ModelEntity(mesh: mesh, materials: [material])
        product.name = "Product"
        return product
    }

    nonisolated private static func aspectRatio(of url: URL) -> Float {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
            let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
            height.floatValue > 0
        else {
            return 1
        }
        return width.floatValue / height.floatValue
    }
}

enum PrototypeTemplateError: LocalizedError {
    case missingProductSlot

    var errorDescription: String? {
        "PrototypeTemplate does not contain an entity named ProductSlot."
    }
}
