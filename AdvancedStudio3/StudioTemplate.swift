import Foundation

nonisolated struct StudioTimelinePhase: Identifiable, Sendable {
    let title: String
    let range: String
    let width: Double

    var id: String { "\(title)-\(range)" }
}

enum StudioTemplate: String, CaseIterable, Identifiable, Sendable {
    case opticalMesh = "optical-mesh-195"
    case mineralFold = "mineral-fold"
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

    /// Templates exposed to customers. Archived and unvalidated work must never
    /// enter the production library through `allCases`.
    static let userFacingCases: [StudioTemplate] = [
        .opticalMesh
    ]

    static let archivedCases: [StudioTemplate] = [
        .mineralFold,
        .opticalCorridor,
        .paperAperture
    ]

    var id: String { rawValue }

    var name: String {
        switch self {
        case .opticalMesh: "Optical Mesh"
        case .mineralFold: "Marble Orbit"
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
        case .mineralFold: "PREMIUM 02"
        case .opticalCorridor: "PREMIUM 03"
        case .paperAperture: "PREMIUM 04"
        case .ceramicImpact: "PREMIUM 05"
        case .basaltTide: "PREMIUM 06"
        case .satinCurrent: "PREMIUM 07"
        case .canyonExposure: "PREMIUM 08"
        case .timberVault: "PREMIUM 09"
        case .bluegumHelix: "PREMIUM 10"
        case .magneticConvergence: "PREMIUM 11"
        case .oxideLightCut: "PREMIUM 12"
        }
    }

    var sceneSubtitle: String {
        switch self {
        case .opticalMesh: "Template 195 · Optical Mesh"
        case .mineralFold: "Orbital Eclipse · Marble Orbit"
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
        switch self {
        case .opticalMesh, .mineralFold:
            .legacyEightSeconds
        default:
            .premiumTwelveSeconds
        }
    }

    var heroFrame: Int {
        switch self {
        case .opticalMesh: 210
        case .mineralFold: 218
        default: specification.finalFrameIndex
        }
    }

    var timelinePhases: [StudioTimelinePhase] {
        switch self {
        case .opticalMesh:
            [
                .init(title: "CAMERA PUSH", range: "0–6.3s", width: 2.0),
                .init(title: "LATTICE FORM", range: "0.7–4.8s", width: 2.5),
                .init(title: "PRODUCT REVEAL", range: "4.1–5.5s", width: 1.5),
                .init(title: "COPY / HOLD", range: "6.2–8s", width: 2.0)
            ]
        case .mineralFold:
            [
                .init(title: "LIQUID FILM", range: "0–3.0s", width: 2.0),
                .init(title: "SCALE HANDOFF", range: "3.0–4.0s", width: 2.5),
                .init(title: "AERIAL / HERO", range: "4.0–6.8s", width: 1.5),
                .init(title: "COPY / HOLD", range: "6.8–8s", width: 2.0)
            ]
        case .opticalCorridor:
            phases("PRISM ENTRY", "SLICE ALIGN", "DOLLY ARC", "COPY", cuts: [4, 4.3, 2.7, 1])
        case .paperAperture:
            phases("OUTER TEAR", "INNER FOLD", "PRODUCT LIFT", "GLYPH RING", cuts: [2.8, 4.3, 2.5, 2.4])
        case .ceramicImpact:
            phases("STILLNESS", "FRACTURE", "SUSPENSION", "TYPE HOLD", cuts: [3.2, 4.2, 1.9, 2.7])
        case .basaltTide:
            phases("LIQUID RISE", "MONOLITH HOLD", "CHANNEL DRAIN", "MACRO HERO", cuts: [4.8, 1.6, 3.3, 2.3])
        case .satinCurrent:
            phases("CURRENT ENTRY", "PRODUCT WRAP", "TRAVELING WIPE", "COUNTER COPY", cuts: [4.7, 2.5, 3.5, 1.3])
        case .canyonExposure:
            phases("GUST ONE", "GUST TWO", "GUST THREE", "CRANE / ETCH", cuts: [3.5, 2.5, 3.2, 2.8])
        case .timberVault:
            phases("RIB BUILD", "AXIAL DOLLY", "HATCH LIFT", "PLAQUES", cuts: [6.3, 2.0, 2.4, 1.3])
        case .bluegumHelix:
            phases("HELIX GROWTH", "BRANCHING", "PHOTOTROPISM", "LIGHT REVEAL", cuts: [5.6, 2.0, 3.1, 1.3])
        case .magneticConvergence:
            phases("FIELD WAVES", "HALO LOCK", "ORBIT BRAKE", "TYPE SNAP", cuts: [7.5, 1.8, 1.4, 1.3])
        case .oxideLightCut:
            phases("WHITE CUT", "RED CUT", "AMBER CUT", "INTERSECTION", cuts: [4, 2.1, 2.0, 3.9])
        }
    }

    private func phases(
        _ first: String,
        _ second: String,
        _ third: String,
        _ fourth: String,
        cuts: [Double]
    ) -> [StudioTimelinePhase] {
        var start = 0.0
        return zip([first, second, third, fourth], cuts).map { title, width in
            defer { start += width }
            let end = start + width
            return .init(
                title: title,
                range: String(format: "%.1f–%.1fs", start, end),
                width: width
            )
        }
    }
}
