import RealityKit
import SwiftUI

struct ProductSceneView: View {
    let imageURL: URL

    var body: some View {
        RealityView { content in
            do {
                let template = try await PrototypeTemplateScene.load(
                    imageURL: imageURL
                )
                content.add(template)
            } catch {
                do {
                    let fallback = try await PrototypeTemplateScene
                        .makeProgrammaticFallback(imageURL: imageURL)
                    content.add(fallback)
                } catch {
                    assertionFailure("RealityKit could not load the product: \(error)")
                }
            }
        }
        .id(imageURL)
    }
}
