import RealityKit
import SwiftUI

@MainActor
enum StudioScene {
    case opticalMesh(PremiumAdScene)
    case opticalCorridor(OpticalCorridorScene)
    case paperAperture(PaperApertureScene)
    case ceramicImpact(CeramicImpactScene)
    case basaltTide(BasaltTideScene)
    case satinCurrent(SatinCurrentScene)
    case canyonExposure(CanyonExposureScene)
    case timberVault(TimberVaultScene)
    case bluegumHelix(BluegumHelixScene)
    case magneticConvergence(MagneticConvergenceScene)
    case oxideLightCut(OxideLightCutScene)

    static func load(template: StudioTemplate, imageURL: URL) async throws -> StudioScene {
        switch template {
        case .opticalMesh: .opticalMesh(try await PremiumAdScene.load(imageURL: imageURL))
        case .opticalCorridor: .opticalCorridor(try await OpticalCorridorScene.load(imageURL: imageURL))
        case .paperAperture: .paperAperture(try await PaperApertureScene.load(imageURL: imageURL))
        case .ceramicImpact: .ceramicImpact(try await CeramicImpactScene.load(imageURL: imageURL))
        case .basaltTide: .basaltTide(try await BasaltTideScene.load(imageURL: imageURL))
        case .satinCurrent: .satinCurrent(try await SatinCurrentScene.load(imageURL: imageURL))
        case .canyonExposure: .canyonExposure(try await CanyonExposureScene.load(imageURL: imageURL))
        case .timberVault: .timberVault(try await TimberVaultScene.load(imageURL: imageURL))
        case .bluegumHelix: .bluegumHelix(try await BluegumHelixScene.load(imageURL: imageURL))
        case .magneticConvergence: .magneticConvergence(try await MagneticConvergenceScene.load(imageURL: imageURL))
        case .oxideLightCut: .oxideLightCut(try await OxideLightCutScene.load(imageURL: imageURL))
        }
    }

    var root: Entity {
        switch self {
        case .opticalMesh(let value): value.root
        case .opticalCorridor(let value): value.root
        case .paperAperture(let value): value.root
        case .ceramicImpact(let value): value.root
        case .basaltTide(let value): value.root
        case .satinCurrent(let value): value.root
        case .canyonExposure(let value): value.root
        case .timberVault(let value): value.root
        case .bluegumHelix(let value): value.root
        case .magneticConvergence(let value): value.root
        case .oxideLightCut(let value): value.root
        }
    }

    var camera: PerspectiveCamera {
        switch self {
        case .opticalMesh(let value): value.camera
        case .opticalCorridor(let value): value.camera
        case .paperAperture(let value): value.camera
        case .ceramicImpact(let value): value.camera
        case .basaltTide(let value): value.camera
        case .satinCurrent(let value): value.camera
        case .canyonExposure(let value): value.camera
        case .timberVault(let value): value.camera
        case .bluegumHelix(let value): value.camera
        case .magneticConvergence(let value): value.camera
        case .oxideLightCut(let value): value.camera
        }
    }

    func apply(frameIndex: Int) {
        switch self {
        case .opticalMesh(let value): value.apply(frameIndex: frameIndex)
        case .opticalCorridor(let value): value.apply(frameIndex: frameIndex)
        case .paperAperture(let value): value.apply(frameIndex: frameIndex)
        case .ceramicImpact(let value): value.apply(frameIndex: frameIndex)
        case .basaltTide(let value): value.apply(frameIndex: frameIndex)
        case .satinCurrent(let value): value.apply(frameIndex: frameIndex)
        case .canyonExposure(let value): value.apply(frameIndex: frameIndex)
        case .timberVault(let value): value.apply(frameIndex: frameIndex)
        case .bluegumHelix(let value): value.apply(frameIndex: frameIndex)
        case .magneticConvergence(let value): value.apply(frameIndex: frameIndex)
        case .oxideLightCut(let value): value.apply(frameIndex: frameIndex)
        }
    }
}

struct ProductSceneView: View {
    let scene: StudioScene
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
                ProgressView("Loading scene…").tint(.white).foregroundStyle(.white)
            }
        }
    }
}
