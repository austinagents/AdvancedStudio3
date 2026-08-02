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
  case photonGuillotine = "photon-guillotine-201"
  case mercuryLens = "mercury-lens-202"
  case velvetSingularity = "velvet-singularity-203"
  case polarChamber = "polar-chamber-204"
  case chronoSand = "chrono-sand-205"
  case thermalAlloy = "thermal-alloy-206"
  case porcelainEcho = "porcelain-echo-207"
  case gravityScript = "gravity-script-208"
  case crystalTension = "crystal-tension-209"
  case monolithBloom = "monolith-bloom-210"
  case vacuumCast = "vacuum-cast-211"
  case anamorphicCourt = "anamorphic-court-212"
  case moireEngine = "moire-engine-213"
  case axisHouse = "axis-house-214"
  case pressureMark = "pressure-mark-215"
  case contactSheet = "contact-sheet-216"
  case seamRelease = "seam-release-217"
  case escapementZero = "escapement-zero-218"
  case sixAxisCeremony = "six-axis-ceremony-219"
  case threadline = "threadline-220"
  case coastalRelay = "coastal-relay-221"
  case glasshouseRise = "glasshouse-rise-222"
  case alpineWake = "alpine-wake-223"
  case kineticFacade = "kinetic-facade-224"
  case rainlightPavilion = "rainlight-pavilion-225"
  case observatoryTransit = "observatory-transit-226"
  case aerodynamicTrace = "aerodynamic-trace-227"
  case chromaticElevator = "chromatic-elevator-228"
  case terracedDawn = "terraced-dawn-229"
  case haloStage = "halo-stage-230"
  case liquidImpact = "liquid-impact-231"

  static let candidateCases: [StudioTemplate] = [
    .vacuumCast, .anamorphicCourt, .moireEngine, .axisHouse, .pressureMark,
    .contactSheet, .seamRelease, .escapementZero, .sixAxisCeremony, .threadline,
    .photonGuillotine, .mercuryLens, .velvetSingularity, .polarChamber, .chronoSand,
    .thermalAlloy, .porcelainEcho, .gravityScript, .crystalTension, .monolithBloom,
    .opticalCorridor, .paperAperture, .ceramicImpact, .basaltTide,
    .satinCurrent, .canyonExposure, .timberVault, .bluegumHelix,
    .magneticConvergence, .oxideLightCut,
    .coastalRelay, .glasshouseRise, .alpineWake, .kineticFacade,
    .rainlightPavilion, .observatoryTransit, .aerodynamicTrace,
    .chromaticElevator, .terracedDawn, .haloStage, .liquidImpact,
  ]
  static let userFacingCases: [StudioTemplate] = [
    .opticalMesh,
    .vacuumCast,
    .anamorphicCourt,
    .moireEngine,
    .axisHouse,
    .pressureMark,
    .contactSheet,
    .seamRelease,
    .escapementZero,
    .sixAxisCeremony,
    .threadline,
    .canyonExposure,
    .timberVault,
    .bluegumHelix,
    .magneticConvergence,
    .photonGuillotine,
    .mercuryLens,
    .velvetSingularity,
    .polarChamber,
    .chronoSand,
    .thermalAlloy,
    .porcelainEcho,
    .gravityScript,
    .crystalTension,
    .monolithBloom,
    .coastalRelay, .glasshouseRise, .alpineWake, .kineticFacade,
    .rainlightPavilion, .observatoryTransit, .aerodynamicTrace,
    .chromaticElevator, .terracedDawn, .haloStage, .liquidImpact,
  ]
  static let archivedCases: [StudioTemplate] = []
  static let batch2Cases: [StudioTemplate] = [
    .coastalRelay, .glasshouseRise, .alpineWake, .kineticFacade,
    .rainlightPavilion, .observatoryTransit, .aerodynamicTrace,
    .chromaticElevator, .terracedDawn, .haloStage, .liquidImpact,
  ]
  static let batch1Cases = userFacingCases.filter { !batch2Cases.contains($0) }

  var id: String { rawValue }
  var validity: TemplateValidity {
    switch self {
    case .opticalMesh, .canyonExposure, .timberVault, .bluegumHelix, .magneticConvergence,
      .coastalRelay, .glasshouseRise, .alpineWake, .kineticFacade,
      .rainlightPavilion, .observatoryTransit, .aerodynamicTrace,
      .chromaticElevator, .terracedDawn, .haloStage, .liquidImpact:
      .valid
    default:
      .incomplete
    }
  }

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
    case .photonGuillotine: "Photon Guillotine"
    case .mercuryLens: "Mercury Lens"
    case .velvetSingularity: "Velvet Singularity"
    case .polarChamber: "Polar Chamber"
    case .chronoSand: "Chrono Sand"
    case .thermalAlloy: "Thermal Alloy"
    case .porcelainEcho: "Porcelain Echo"
    case .gravityScript: "Gravity Script"
    case .crystalTension: "Crystal Tension"
    case .monolithBloom: "Monolith Bloom"
    case .vacuumCast: "Vacuum Cast"
    case .anamorphicCourt: "Anamorphic Court"
    case .moireEngine: "Moiré Engine"
    case .axisHouse: "Axis House"
    case .pressureMark: "Pressure Mark"
    case .contactSheet: "Contact Sheet"
    case .seamRelease: "Seam Release"
    case .escapementZero: "Escapement Zero"
    case .sixAxisCeremony: "Six-Axis Ceremony"
    case .threadline: "Threadline"
    case .coastalRelay: "Coastal Relay"
    case .glasshouseRise: "Glasshouse Rise"
    case .alpineWake: "Alpine Wake"
    case .kineticFacade: "Kinetic Façade"
    case .rainlightPavilion: "Rainlight Pavilion"
    case .observatoryTransit: "Observatory Transit"
    case .aerodynamicTrace: "Aerodynamic Trace"
    case .chromaticElevator: "Chromatic Elevator"
    case .terracedDawn: "Terraced Dawn"
    case .haloStage: "Halo Stage"
    case .liquidImpact: "Liquid Impact"
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
    case .photonGuillotine: "PREMIUM 12"
    case .mercuryLens: "PREMIUM 13"
    case .velvetSingularity: "PREMIUM 14"
    case .polarChamber: "PREMIUM 15"
    case .chronoSand: "PREMIUM 16"
    case .thermalAlloy: "PREMIUM 17"
    case .porcelainEcho: "PREMIUM 18"
    case .gravityScript: "PREMIUM 19"
    case .crystalTension: "PREMIUM 20"
    case .monolithBloom: "PREMIUM 21"
    case .vacuumCast: "PREMIUM 22"
    case .anamorphicCourt: "PREMIUM 23"
    case .moireEngine: "PREMIUM 24"
    case .axisHouse: "PREMIUM 25"
    case .pressureMark: "PREMIUM 26"
    case .contactSheet: "PREMIUM 27"
    case .seamRelease: "PREMIUM 28"
    case .escapementZero: "PREMIUM 29"
    case .sixAxisCeremony: "PREMIUM 30"
    case .threadline: "PREMIUM 31"
    case .coastalRelay: "PREMIUM 32"
    case .glasshouseRise: "PREMIUM 33"
    case .alpineWake: "PREMIUM 34"
    case .kineticFacade: "PREMIUM 35"
    case .rainlightPavilion: "PREMIUM 36"
    case .observatoryTransit: "PREMIUM 37"
    case .aerodynamicTrace: "PREMIUM 38"
    case .chromaticElevator: "PREMIUM 39"
    case .terracedDawn: "PREMIUM 40"
    case .haloStage: "PREMIUM 41"
    case .liquidImpact: "PREMIUM 42"
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
    case .photonGuillotine: "Light Blade · Photon Guillotine"
    case .mercuryLens: "Optical Merge · Mercury Lens"
    case .velvetSingularity: "Fabric Collapse · Velvet Singularity"
    case .polarChamber: "Polarization · Polar Chamber"
    case .chronoSand: "Reverse Time · Chrono Sand"
    case .thermalAlloy: "Heat Release · Thermal Alloy"
    case .porcelainEcho: "Material Wave · Porcelain Echo"
    case .gravityScript: "Falling Type · Gravity Script"
    case .crystalTension: "Stored Energy · Crystal Tension"
    case .monolithBloom: "Carbon Inversion · Monolith Bloom"
    case .vacuumCast: "Membrane Release · Vacuum Cast"
    case .anamorphicCourt: "Aligned Architecture · Anamorphic Court"
    case .moireEngine: "Interference Decoupling · Moiré Engine"
    case .axisHouse: "Gimbal Transformation · Axis House"
    case .pressureMark: "Die Impression · Pressure Mark"
    case .contactSheet: "Film Transport · Contact Sheet"
    case .seamRelease: "Machined Unfastening · Seam Release"
    case .escapementZero: "Horological Release · Escapement Zero"
    case .sixAxisCeremony: "Robotic Handoff · Six-Axis Ceremony"
    case .threadline: "Threaded Extraction · Threadline"
    case .coastalRelay: "Tidal Passage · Coastal Relay"
    case .glasshouseRise: "Botanical Aperture · Glasshouse Rise"
    case .alpineWake: "Atmospheric Ascent · Alpine Wake"
    case .kineticFacade: "Architectural Choreography · Kinetic Façade"
    case .rainlightPavilion: "Weather Illumination · Rainlight Pavilion"
    case .observatoryTransit: "Celestial Alignment · Observatory Transit"
    case .aerodynamicTrace: "Flow Capture · Aerodynamic Trace"
    case .chromaticElevator: "Prismatic Lift · Chromatic Elevator"
    case .terracedDawn: "Solar Progression · Terraced Dawn"
    case .haloStage: "Luminous Ceremony · Halo Stage"
    case .liquidImpact: "Reactive Environment · Liquid Impact"
    }
  }

  var specification: AdSpecification {
    switch self {
    case .coastalRelay, .glasshouseRise, .alpineWake, .kineticFacade,
      .rainlightPavilion, .observatoryTransit, .aerodynamicTrace,
      .chromaticElevator, .terracedDawn, .haloStage:
      .premiumFifteenSeconds
    default:
      self == .opticalMesh ? .legacyEightSeconds : .premiumTwelveSeconds
    }
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
        .init(title: "COPY / HOLD", range: "6.2–8s", width: 2),
      ]
    }
    if specification == .premiumFifteenSeconds {
      return [
        .init(title: "ARRIVAL", range: "0–4.5s", width: 4.5),
        .init(title: "SPATIAL EVENT", range: "4.5–10s", width: 5.5),
        .init(title: "PRODUCT REVEAL", range: "10–13s", width: 3),
        .init(title: "HERO / HOLD", range: "13–15s", width: 2),
      ]
    }
    return [
      .init(title: "SPATIAL BUILD", range: "0–7.8s", width: 7.8),
      .init(title: "REVEAL TENSION", range: "7.8–8.4s", width: 0.6),
      .init(title: "PRODUCT REVEAL", range: "8.4–10.4s", width: 2),
      .init(title: "BRAND / HOLD", range: "10.4–12s", width: 1.6),
    ]
  }
}
