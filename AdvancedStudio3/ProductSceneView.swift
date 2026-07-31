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
  case photonGuillotine(PhotonGuillotineScene)
  case mercuryLens(MercuryLensScene)
  case velvetSingularity(VelvetSingularityScene)
  case polarChamber(PolarChamberScene)
  case chronoSand(ChronoSandScene)
  case thermalAlloy(ThermalAlloyScene)
  case porcelainEcho(PorcelainEchoScene)
  case gravityScript(GravityScriptScene)
  case crystalTension(CrystalTensionScene)
  case monolithBloom(MonolithBloomScene)
  case vacuumCast(VacuumCastScene)
  case anamorphicCourt(AnamorphicCourtScene)
  case moireEngine(MoireEngineScene)
  case axisHouse(AxisHouseScene)
  case pressureMark(PressureMarkScene)
  case contactSheet(ContactSheetScene)
  case seamRelease(SeamReleaseScene)
  case escapementZero(EscapementZeroScene)
  case sixAxisCeremony(SixAxisCeremonyScene)
  case threadline(ThreadlineScene)

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
    case .magneticConvergence:
      .magneticConvergence(try await MagneticConvergenceScene.load(imageURL: imageURL))
    case .oxideLightCut: .oxideLightCut(try await OxideLightCutScene.load(imageURL: imageURL))
    case .photonGuillotine:
      .photonGuillotine(try await PhotonGuillotineScene.load(imageURL: imageURL))
    case .mercuryLens: .mercuryLens(try await MercuryLensScene.load(imageURL: imageURL))
    case .velvetSingularity:
      .velvetSingularity(try await VelvetSingularityScene.load(imageURL: imageURL))
    case .polarChamber: .polarChamber(try await PolarChamberScene.load(imageURL: imageURL))
    case .chronoSand: .chronoSand(try await ChronoSandScene.load(imageURL: imageURL))
    case .thermalAlloy: .thermalAlloy(try await ThermalAlloyScene.load(imageURL: imageURL))
    case .porcelainEcho: .porcelainEcho(try await PorcelainEchoScene.load(imageURL: imageURL))
    case .gravityScript: .gravityScript(try await GravityScriptScene.load(imageURL: imageURL))
    case .crystalTension: .crystalTension(try await CrystalTensionScene.load(imageURL: imageURL))
    case .monolithBloom: .monolithBloom(try await MonolithBloomScene.load(imageURL: imageURL))
    case .vacuumCast: .vacuumCast(try await VacuumCastScene.load(imageURL: imageURL))
    case .anamorphicCourt: .anamorphicCourt(try await AnamorphicCourtScene.load(imageURL: imageURL))
    case .moireEngine: .moireEngine(try await MoireEngineScene.load(imageURL: imageURL))
    case .axisHouse: .axisHouse(try await AxisHouseScene.load(imageURL: imageURL))
    case .pressureMark: .pressureMark(try await PressureMarkScene.load(imageURL: imageURL))
    case .contactSheet: .contactSheet(try await ContactSheetScene.load(imageURL: imageURL))
    case .seamRelease: .seamRelease(try await SeamReleaseScene.load(imageURL: imageURL))
    case .escapementZero: .escapementZero(try await EscapementZeroScene.load(imageURL: imageURL))
    case .sixAxisCeremony: .sixAxisCeremony(try await SixAxisCeremonyScene.load(imageURL: imageURL))
    case .threadline: .threadline(try await ThreadlineScene.load(imageURL: imageURL))
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
    case .photonGuillotine(let v): v.root
    case .mercuryLens(let v): v.root
    case .velvetSingularity(let v): v.root
    case .polarChamber(let v): v.root
    case .chronoSand(let v): v.root
    case .thermalAlloy(let v): v.root
    case .porcelainEcho(let v): v.root
    case .gravityScript(let v): v.root
    case .crystalTension(let v): v.root
    case .monolithBloom(let v): v.root
    case .vacuumCast(let v): v.root
    case .anamorphicCourt(let v): v.root
    case .moireEngine(let v): v.root
    case .axisHouse(let v): v.root
    case .pressureMark(let v): v.root
    case .contactSheet(let v): v.root
    case .seamRelease(let v): v.root
    case .escapementZero(let v): v.root
    case .sixAxisCeremony(let v): v.root
    case .threadline(let v): v.root
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
    case .photonGuillotine(let v): v.camera
    case .mercuryLens(let v): v.camera
    case .velvetSingularity(let v): v.camera
    case .polarChamber(let v): v.camera
    case .chronoSand(let v): v.camera
    case .thermalAlloy(let v): v.camera
    case .porcelainEcho(let v): v.camera
    case .gravityScript(let v): v.camera
    case .crystalTension(let v): v.camera
    case .monolithBloom(let v): v.camera
    case .vacuumCast(let v): v.camera
    case .anamorphicCourt(let v): v.camera
    case .moireEngine(let v): v.camera
    case .axisHouse(let v): v.camera
    case .pressureMark(let v): v.camera
    case .contactSheet(let v): v.camera
    case .seamRelease(let v): v.camera
    case .escapementZero(let v): v.camera
    case .sixAxisCeremony(let v): v.camera
    case .threadline(let v): v.camera
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
    case .photonGuillotine(let v): v.apply(frameIndex: frameIndex)
    case .mercuryLens(let v): v.apply(frameIndex: frameIndex)
    case .velvetSingularity(let v): v.apply(frameIndex: frameIndex)
    case .polarChamber(let v): v.apply(frameIndex: frameIndex)
    case .chronoSand(let v): v.apply(frameIndex: frameIndex)
    case .thermalAlloy(let v): v.apply(frameIndex: frameIndex)
    case .porcelainEcho(let v): v.apply(frameIndex: frameIndex)
    case .gravityScript(let v): v.apply(frameIndex: frameIndex)
    case .crystalTension(let v): v.apply(frameIndex: frameIndex)
    case .monolithBloom(let v): v.apply(frameIndex: frameIndex)
    case .vacuumCast(let v): v.apply(frameIndex: frameIndex)
    case .anamorphicCourt(let v): v.apply(frameIndex: frameIndex)
    case .moireEngine(let v): v.apply(frameIndex: frameIndex)
    case .axisHouse(let v): v.apply(frameIndex: frameIndex)
    case .pressureMark(let v): v.apply(frameIndex: frameIndex)
    case .contactSheet(let v): v.apply(frameIndex: frameIndex)
    case .seamRelease(let v): v.apply(frameIndex: frameIndex)
    case .escapementZero(let v): v.apply(frameIndex: frameIndex)
    case .sixAxisCeremony(let v): v.apply(frameIndex: frameIndex)
    case .threadline(let v): v.apply(frameIndex: frameIndex)
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
