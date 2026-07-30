import RealityKit
import SwiftUI

@MainActor
enum StudioScene {
    case opticalMesh(PremiumAdScene)
    case marbleOrbit(MarbleOrbitScene)
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

    static func load(
        template: StudioTemplate,
        imageURL: URL
    ) async throws -> StudioScene {
        switch template {
        case .opticalMesh:
            .opticalMesh(try await PremiumAdScene.load(imageURL: imageURL))
        case .mineralFold:
            .marbleOrbit(try await MarbleOrbitScene.load(imageURL: imageURL))
        case .opticalCorridor:
            .opticalCorridor(try await OpticalCorridorScene.load(imageURL: imageURL))
        case .paperAperture:
            .paperAperture(try await PaperApertureScene.load(imageURL: imageURL))
        case .ceramicImpact:
            .ceramicImpact(try await CeramicImpactScene.load(imageURL: imageURL))
        case .basaltTide:
            .basaltTide(try await BasaltTideScene.load(imageURL: imageURL))
        case .satinCurrent:
            .satinCurrent(try await SatinCurrentScene.load(imageURL: imageURL))
        case .canyonExposure:
            .canyonExposure(try await CanyonExposureScene.load(imageURL: imageURL))
        case .timberVault:
            .timberVault(try await TimberVaultScene.load(imageURL: imageURL))
        case .bluegumHelix:
            .bluegumHelix(try await BluegumHelixScene.load(imageURL: imageURL))
        case .magneticConvergence:
            .magneticConvergence(try await MagneticConvergenceScene.load(imageURL: imageURL))
        case .oxideLightCut:
            .oxideLightCut(try await OxideLightCutScene.load(imageURL: imageURL))
        }
    }

    var root: Entity {
        switch self {
        case .opticalMesh(let scene): scene.root
        case .marbleOrbit(let scene): scene.root
        case .opticalCorridor(let scene): scene.root
        case .paperAperture(let scene): scene.root
        case .ceramicImpact(let scene): scene.root
        case .basaltTide(let scene): scene.root
        case .satinCurrent(let scene): scene.root
        case .canyonExposure(let scene): scene.root
        case .timberVault(let scene): scene.root
        case .bluegumHelix(let scene): scene.root
        case .magneticConvergence(let scene): scene.root
        case .oxideLightCut(let scene): scene.root
        }
    }

    var camera: PerspectiveCamera {
        switch self {
        case .opticalMesh(let scene): scene.camera
        case .marbleOrbit(let scene): scene.camera
        case .opticalCorridor(let scene): scene.camera
        case .paperAperture(let scene): scene.camera
        case .ceramicImpact(let scene): scene.camera
        case .basaltTide(let scene): scene.camera
        case .satinCurrent(let scene): scene.camera
        case .canyonExposure(let scene): scene.camera
        case .timberVault(let scene): scene.camera
        case .bluegumHelix(let scene): scene.camera
        case .magneticConvergence(let scene): scene.camera
        case .oxideLightCut(let scene): scene.camera
        }
    }

    func apply(frameIndex: Int) {
        switch self {
        case .opticalMesh(let scene): scene.apply(frameIndex: frameIndex)
        case .marbleOrbit(let scene): scene.apply(frameIndex: frameIndex)
        case .opticalCorridor(let scene): scene.apply(frameIndex: frameIndex)
        case .paperAperture(let scene): scene.apply(frameIndex: frameIndex)
        case .ceramicImpact(let scene): scene.apply(frameIndex: frameIndex)
        case .basaltTide(let scene): scene.apply(frameIndex: frameIndex)
        case .satinCurrent(let scene): scene.apply(frameIndex: frameIndex)
        case .canyonExposure(let scene): scene.apply(frameIndex: frameIndex)
        case .timberVault(let scene): scene.apply(frameIndex: frameIndex)
        case .bluegumHelix(let scene): scene.apply(frameIndex: frameIndex)
        case .magneticConvergence(let scene): scene.apply(frameIndex: frameIndex)
        case .oxideLightCut(let scene): scene.apply(frameIndex: frameIndex)
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
                ProgressView("Loading scene…")
                    .tint(.white)
                    .foregroundStyle(.white)
            }
        }
    }
}
