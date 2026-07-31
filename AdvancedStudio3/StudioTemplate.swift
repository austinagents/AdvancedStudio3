import Foundation

nonisolated struct StudioTimelinePhase: Identifiable, Sendable {
    let title: String
    let range: String
    let width: Double
    var id: String { "\(title)-\(range)" }
}

enum TemplateValidity: String, Sendable {
    case valid = "VALID"
    case incomplete = "INCOMPLETE"
}

enum StudioTemplate: String, CaseIterable, Identifiable, Sendable {
    case opticalMesh = "optical-mesh-195"
    case opticalCorridor = "optical-corridor"
    case paperAperture = "paper-aperture"
    case ceramicImpact = "ceramic-impact"
    case basaltTide = "basalt-tide"
    case satinCurrent = "satin-current"
    case canyonExposure = "canyon-exposure"
    case timberVault = "timber-vault"
    case bluegumHelix = "bluegum-helix"
    case magneticConvergence = "magnetic-convergence"
    case oxideLightCut = "oxide-light-cut"

    static let candidateCases: [StudioTemplate] = [
        .opticalCorridor, .paperAperture, .ceramicImpact, .basaltTide,
        .satinCurrent, .canyonExposure, .timberVault, .bluegumHelix,
        .magneticConvergence, .oxideLightCut
    ]
    static let userFacingCases: [StudioTemplate] = [
        .opticalMesh,
        .canyonExposure,
        .timberVault,
        .bluegumHelix,
        .magneticConvergence
    ]
    static let archivedCases: [StudioTemplate] = []

    var id: String { rawValue }
    var validity: TemplateValidity { self == .opticalMesh ? .valid : .incomplete }

    var name: String {
        switch self {
        case .opticalMesh: "Optical Mesh"
        case .opticalCorridor: "Optical Corridor"
        case .paperAperture: "Paper Aperture"
        case .ceramicImpact: "Ceramic Impact"
        case .basaltTide: "Basalt Tide"
        case .satinCurrent: "Satin Current"
        case .canyonExposure: "Canyon Exposure"
        case .timberVault: "Timber Vault"
        case .bluegumHelix: "Bluegum Helix"
        case .magneticConvergence: "Magnetic Convergence"
        case .oxideLightCut: "Oxide Light Cut"
        }
    }

    var libraryIndex: String {
        switch self {
        case .opticalMesh: "PREMIUM 01"
        case .opticalCorridor: "PREMIUM 02"
        case .paperAperture: "PREMIUM 03"
        case .ceramicImpact: "PREMIUM 04"
        case .basaltTide: "PREMIUM 05"
        case .satinCurrent: "PREMIUM 06"
        case .canyonExposure: "PREMIUM 07"
        case .timberVault: "PREMIUM 08"
        case .bluegumHelix: "PREMIUM 09"
        case .magneticConvergence: "PREMIUM 10"
        case .oxideLightCut: "PREMIUM 11"
        }
    }

    var sceneSubtitle: String {
        switch self {
        case .opticalMesh: "Template 195 · Optical Mesh"
        case .opticalCorridor: "Refraction · Optical Corridor"
        case .paperAperture: "Torn Iris · Paper Aperture"
        case .ceramicImpact: "Fracture · Ceramic Impact"
        case .basaltTide: "Liquid Drain · Basalt Tide"
        case .satinCurrent: "Traveling Wipe · Satin Current"
        case .canyonExposure: "Erosion · Canyon Exposure"
        case .timberVault: "Construction · Timber Vault"
        case .bluegumHelix: "Phototropism · Bluegum Helix"
        case .magneticConvergence: "Attraction · Magnetic Convergence"
        case .oxideLightCut: "Intersection · Oxide Light Cut"
        }
    }

    var specification: AdSpecification {
        self == .opticalMesh ? .legacyEightSeconds : .premiumTwelveSeconds
    }

    var heroFrame: Int {
        self == .opticalMesh ? 210 : specification.finalFrameIndex
    }

    var timelinePhases: [StudioTimelinePhase] {
        if self == .opticalMesh {
            return [
                .init(title: "CAMERA PUSH", range: "0–6.3s", width: 2),
                .init(title: "LATTICE FORM", range: "0.7–4.8s", width: 2.5),
                .init(title: "PRODUCT REVEAL", range: "4.1–5.5s", width: 1.5),
                .init(title: "COPY / HOLD", range: "6.2–8s", width: 2)
            ]
        }
        return [
            .init(title: "SPATIAL BUILD", range: "0–7.8s", width: 7.8),
            .init(title: "REVEAL TENSION", range: "7.8–8.4s", width: 0.6),
            .init(title: "PRODUCT REVEAL", range: "8.4–10.4s", width: 2),
            .init(title: "BRAND / HOLD", range: "10.4–12s", width: 1.6)
        ]
    }
}
