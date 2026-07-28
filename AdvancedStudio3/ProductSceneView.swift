import RealityKit
import SwiftUI

struct ProductSceneView: View {
    let scene: PremiumAdScene
    let frameIndex: Int

    var body: some View {
        RealityView { content in
            content.add(scene.root)
            content.camera = .virtual
        } update: { content in
            scene.apply(frameIndex: frameIndex)
            content.camera = .virtual
        } placeholder: {
            ZStack {
                Color.black
                ProgressView("Loading scene…")
                    .tint(.white)
                    .foregroundStyle(.white)
            }
        }
    }
}
