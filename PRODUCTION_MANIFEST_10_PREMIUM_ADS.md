# Advanced Studio 3 — Ten Premium Ads Production Manifest

Status: implementation gate  
Target batch: 12.0 seconds, 30 fps, 360 frames, 1080 × 1920  
Toolchain: Xcode 27.0 beta 4 (`27A5228h`)  
Asset catalog snapshot: Poly Haven API, 2026-07-30  

## Non-negotiable production boundary

These ads reuse only Advanced Studio 3's proven #195 infrastructure:

- imported product image;
- Vision foreground extraction;
- Core Image alpha cleanup;
- transparent product texture;
- scene loading and lifecycle;
- deterministic integer-frame evaluation;
- preview, playback, and scrubbing;
- RealityRenderer to Metal texture;
- CVPixelBuffer transfer;
- AVAssetWriter H.264 MOV export;
- metadata, validation, and archive behavior.

Every creative layer is exclusive to one ad. No scene may import another scene's
geometry builder, material builder, HDRI, lighting rig, reveal function, camera
path, composition, typography treatment, motion curve, timing schedule, or USDA
hierarchy.

The 360-frame schedules below belong to this 12-second batch. Future batches
must define a new frame count and receive separately authored timing schedules;
the application must not automatically stretch these creative timelines.

## Poly Haven ingestion rules

- The API asset slug is the canonical asset identifier.
- HDRIs use the verified 1K `.hdr` file, matching the existing #195 production
  approach and avoiding unnecessary runtime memory.
- Surface maps use verified 2K JPG files.
- Diffuse maps load as color/sRGB.
- OpenGL normal maps (`nor_gl`) load as normal data.
- Roughness and metallic maps load as scalar/linear data.
- Displacement is intentionally excluded. Geometry remains procedural and
  deterministic in Swift.
- Every downloaded file must pass MD5 verification before being copied into
  `RealityKitContent`.
- Runtime scenes load local packaged resources. They never call the live API.
- Asset provenance remains in this manifest and in the render metadata.

## Shared product representation

The transparent product image is represented by a camera-facing mesh generated
to the processed image's aspect ratio. This representation is pipeline
infrastructure, not a creative scene component. Each scene independently owns
the mesh's position, scale, reveal mask, lighting relationship, and animation.

---

## Premium 03 — Optical Corridor

Swift implementation: `OpticalCorridorScene.swift`  
USDA: `OpticalCorridor.usda`  
Dominant event: three optical bodies align three displaced product slices into
one coherent product.

### Exclusive assets

- HDRI: `ferndale_studio_02`
- Surface: `white_plaster_02`
- Surface use: the single monolithic floor block only
- Core optical material: procedural RealityKit glass; no scanned surface reused
  from another scene

### USDA hierarchy

```text
OpticalCorridor
├── WorldRoot
├── PlasterBlock
├── PrismRoot
│   ├── PrismNear
│   ├── PrismMiddle
│   └── PrismFar
├── ProductSliceRoot
│   ├── ProductSliceRed
│   ├── ProductSliceGreen
│   └── ProductSliceBlue
├── CopyRoot
├── CameraBezierRig
└── StripLightRoot
```

### Geometry and materials

- Floor block: `8.0 × 0.32 × 10.0 m`, top at `y = -2.15`.
- Prisms: triangular extrusions, length `5.8 m`, circumradii `1.05`, `0.82`,
  and `0.62 m`; bevel approximation `0.018 m`.
- Prism positions at frame 0: `(-2.8, 0.7, 1.2)`, `(2.4, -0.2, 0.0)`,
  `(-1.9, -0.9, -1.4)`.
- Glass PBR: tint `(0.82, 0.95, 1.0)`, roughness `0.055`, metallic `0`,
  opacity `0.16`, clearcoat `1.0`, clearcoat roughness `0.025`.
- Plaster: Poly Haven diffuse + normal + roughness; UV scale `0.55 m/tile`;
  roughness scalar multiplied by `0.92`.
- Product slices use the same product texture with exclusive UV crop masks:
  red `[0.00, 0.34]`, green `[0.33, 0.67]`, blue `[0.66, 1.00]`.

### Lighting

- IBL `ferndale_studio_02`, intensity exponent `0.35`, rotation `-22°`.
- Three rectangular-looking spot rigs:
  `(-3.8, 3.1, 4.0)`, `(0.0, 4.5, 1.0)`, `(3.9, 2.6, -1.5)`.
- Spot colors: `(0.28, 0.76, 1.0)`, `(1.0, 0.18, 0.12)`,
  `(0.15, 1.0, 0.82)`.
- Intensities: `18_000`, `14_000`, `16_000 lm`.
- No directional light and no ambient fill entity.

### Camera and composition

- Perspective focal length: `60 mm`.
- Product final position: `(0.72, -0.18, 0.0)`.
- Product occupies the right `58%` of the portrait frame.
- Cubic Bézier camera path:
  `P0=(-5.2, 0.4, 11.8)`, `P1=(-2.6, 1.2, 10.7)`,
  `P2=(1.2, 0.7, 10.1)`, `P3=(3.1, 0.15, 9.6)`.
- Look target moves from `(0, 0.1, 0)` to `(0.72, -0.05, 0)`.
- Camera has no roll, crane movement, orbit, or focal-length animation.

### Typography

- Copy: `REFRACT` / `REVEAL`.
- Font: `Futura-Medium`, fallback `.systemFont(ofSize:weight:.medium)`.
- Extrusion depth `0.006 m`; cyan unlit material.
- Two vertical words at `x = -2.9`, rotated `90°` around Z.
- Each word appears through a left-to-right character mask, not opacity.

### Exact 360-frame choreography

- `0–35`: floor and empty prisms only.
- `36–119`: three prisms translate on unequal cubic curves.
- `120–191`: product color slices enter from three different X offsets.
- `192–247`: prism rotations converge to `(-12°, 8°, 0°)` and product slices
  converge to a shared transform.
- `248–307`: camera traverses the last `62%` of its Bézier path.
- `308–335`: `REFRACT` character mask.
- `336–351`: `REVEAL` character mask.
- `352–359`: exact hero hold.

Validation frames: `0, 88, 176, 224, 292, 336, 359`.

---

## Premium 04 — Paper Aperture

Swift implementation: `PaperApertureScene.swift`  
USDA: `PaperAperture.usda`  
Dominant event: a sealed distressed-paper iris tears open through sequential
fold rotations and exposes the product through a physical aperture.

### Exclusive assets

- HDRI: `cyclorama_hard_light`
- Surface: `decrepit_wallpaper`
- Surface use: every paper blade; no material from another scene

### USDA hierarchy

```text
PaperAperture
├── CycloramaRoot
├── PaperIrisRoot
│   ├── BladeRingOuter
│   ├── BladeRingMiddle
│   └── BladeRingInner
├── ProductWell
├── ProductLift
├── CircularCopyRoot
├── TopCameraRig
└── UmbrellaLightRig
```

### Geometry and materials

- Twenty-seven tapered quadrilateral blades: `12` outer, `9` middle, `6` inner.
- Blade thickness `0.012 m`; radial lengths `2.7`, `1.85`, `1.1 m`.
- Closed overlap is `18°` per blade; hinge axes are unique to each ring.
- Paper material uses decrepit wallpaper diffuse + normal + roughness,
  UV scale `0.72 m/tile`, roughness floor `0.68`.
- Blade backs use a procedural warm-gray paper material `(0.48, 0.43, 0.37)`,
  roughness `0.94`; this is local to this scene.
- Product well: untextured matte burgundy, radius `1.22 m`, depth `0.38 m`.

### Lighting

- IBL `cyclorama_hard_light`, exponent `0.7`, rotation `103°`.
- One overhead spot at `(0, 6.8, 0)`, warm white `(1.0, 0.88, 0.72)`,
  `24_000 lm`, outer angle `78°`.
- One low violet point light `(0, -0.8, 1.8)`, `2_200 lm`, radius `4.0 m`.
- No moving lights.

### Camera and composition

- Perspective focal length: `90 mm`.
- Camera begins `(0, 8.8, 0.15)`, looking vertically down.
- Camera ends `(0, 6.9, 2.7)`, looking at `(0, -0.25, 0)`.
- The camera descent and pitch occur only after the aperture is mostly open.
- Final composition is radial with the product occupying the central `42%`.
- No lateral motion, orbit, roll, or dolly arc.

### Typography

- Copy: `OPEN / TO / POSSIBILITY`.
- Font: `Didot`, fallback `.systemFont(ofSize:weight:.regular)`.
- Individual glyph meshes follow a `2.46 m` radius circle.
- Dark burgundy PBR material, roughness `0.82`, no emission.
- Glyphs rotate upright sequentially clockwise; they do not fade.

### Exact 360-frame choreography

- `0–23`: sealed iris.
- `24–83`: outer blades tear upward in irregular 4-frame offsets.
- `84–155`: middle ring opens counterclockwise.
- `156–213`: inner ring folds downward into the well.
- `214–259`: product lift rises `1.35 m`.
- `260–315`: camera descends and pitches into final composition.
- `316–347`: circular typography rotates upright.
- `348–359`: exact hero hold.

Validation frames: `0, 52, 128, 188, 238, 288, 332, 359`.

---

## Premium 05 — Ceramic Impact

Swift implementation: `CeramicImpactScene.swift`  
USDA: `CeramicImpact.usda`  
Dominant event: a tiled ceramic plane breaks once, violently and irreversibly,
to expose a product already fixed behind it.

### Exclusive assets

- HDRI: `courtyard`
- Surface: `long_white_tiles`
- Surface use: fracture facade and fragments only

### USDA hierarchy

```text
CeramicImpact
├── CourtyardShell
├── FacadeRoot
├── FractureFragmentRoot
├── ProductCavity
├── FixedProductSlot
├── BottomCopyRoot
├── LockedCameraRig
└── SunAndBounceRig
```

### Geometry and materials

- Facade: `7.2 × 11.8 m`, centered at `(0, 0.4, 0)`.
- Forty-three precomputed Voronoi fragments generated from a fixed seed
  `0xC3A51C`.
- Fragment thickness varies deterministically from `0.07–0.16 m`.
- Tile PBR uses long white tiles diffuse + normal + roughness,
  UV scale `1.35 m/tile`.
- Fracture interiors use local unglazed clay: base `(0.37, 0.09, 0.045)`,
  roughness `0.91`, metallic `0`.
- Product remains at `(-0.68, -0.35, -0.42)` for the entire animation.

### Lighting

- IBL `courtyard`, exponent `0.15`, rotation `47°`.
- Directional sun, color `(1.0, 0.72, 0.48)`, intensity `72_000 lux`,
  rotation `(-38°, -31°, 0°)`.
- Static cool bounce point `(2.4, -1.2, 2.0)`, `3_800 lm`.
- No animated illumination.

### Camera and composition

- Perspective focal length: `32 mm`.
- Locked camera position `(0.45, -0.6, 10.6)`.
- Fixed look target `(-0.35, -0.15, 0)`.
- Only frames `103–111` apply a deterministic `0.11 m` forward impact impulse
  with critically damped return.
- Product resolves on the upper-left third; debris dominates lower-right.

### Typography

- Copy: `BREAK THROUGH`.
- Font: `AvenirNextCondensed-Heavy`, fallback
  `.systemFont(ofSize:weight:.black)`.
- Oversized white text crosses the bottom and is intentionally clipped by the
  portrait frame.
- Text enters as one rigid slab from below at frame 278.

### Exact 360-frame choreography

- `0–95`: motionless facade and hard sunlight.
- `96–102`: emissive crack network flashes from center outward.
- `103–111`: single fracture impulse and camera impact.
- `112–219`: fragments move on unique ballistic arcs and rotate.
- `220–259`: fragment velocities settle to zero in suspended positions.
- `260–277`: product cavity light remains unchanged; clean visual pause.
- `278–307`: typography slab rises and stops without overshoot.
- `308–359`: long hero hold.

Validation frames: `0, 96, 108, 160, 232, 288, 359`.

---

## Premium 06 — Basalt Tide

Swift implementation: `BasaltTideScene.swift`  
USDA: `BasaltTide.usda`  
Dominant event: a procedural viscous sheet rises from a basalt basin, engulfs
the product silhouette, then drains through discrete channels and leaves it
suspended.

### Exclusive assets

- HDRI: `blue_grotto`
- Surface: `dark_rock_02`
- Surface use: basin and channel walls

### USDA hierarchy

```text
BasaltTide
├── GrottoWorld
├── BasaltBasin
├── DrainChannelRoot
├── LiquidSheet
├── LiquidThreadRoot
├── SuspendedProductSlot
├── CornerDataRoot
├── MacroCameraRail
└── UnderwaterLightRig
```

### Geometry and materials

- Basin: elliptical, radii `3.6 × 2.5 m`, depth `0.72 m`.
- Twelve radial drain channels with fixed unequal widths `0.09–0.24 m`.
- Liquid sheet: `54 × 72` vertex grid, height driven by a deterministic
  multi-sine field; no simulation.
- Liquid material: base `(0.005, 0.045, 0.052)`, roughness `0.08`,
  metallic `0.12`, clearcoat `1.0`, clearcoat roughness `0.015`,
  opacity `0.84`.
- Basalt uses dark rock diffuse + normal + roughness, UV scale `1.85 m/tile`.
- Product is fully disabled until the draining sheet falls below its top edge.

### Lighting

- IBL `blue_grotto`, exponent `-0.15`, rotation `-68°`.
- Cyan point beneath basin `(0, -1.4, 0)`, `11_000 lm`, radius `8 m`.
- Narrow green spot behind product `(0, 1.8, -4.2)`, `8_500 lm`, `24°`.
- Both authored lights are static.

### Camera and composition

- Perspective focal length: `110 mm`.
- Starts at `(0.0, -1.1, 4.1)` focused on the near liquid surface.
- Pulls straight backward to `(0.0, 0.35, 12.8)`.
- Look target rises from `(0, -1.0, 0.9)` to `(0, 0.15, 0)`.
- Centered composition with extreme macro start; no orbit, track, crane, or roll.

### Typography

- Copy: `STATE 01 / FLUX` and `STATE 02 / FORM`.
- Font: `SFMono-Regular`, fallback `.monospacedSystemFont`.
- Four corner data blocks, `0.09 m` extrusion, pale cyan unlit material.
- Text switches discretely at frame 244; no entrance animation.

### Exact 360-frame choreography

- `0–47`: macro surface oscillation.
- `48–143`: liquid sheet rises from `0.08 m` to `5.6 m`.
- `144–191`: sheet holds while surface frequency slows.
- `192–243`: twelve drains open in a nonuniform order.
- `244`: typography state changes in one frame.
- `244–291`: sheet drains below the product and threads remain.
- `292–335`: camera executes its straight macro pullback.
- `336–359`: liquid threads continue subpixel motion; product hero remains fixed.

Validation frames: `0, 72, 156, 216, 244, 280, 320, 359`.

---

## Premium 07 — Satin Current

Swift implementation: `SatinCurrentScene.swift`  
USDA: `SatinCurrent.usda`  
Dominant event: one continuous satin ribbon crosses the entire composition,
wraps the product once, and creates a traveling wipe as it exits.

### Exclusive assets

- HDRI: `ferndale_studio_05`
- Surface: `crepe_satin`
- Surface use: continuous ribbon only

### USDA hierarchy

```text
SatinCurrent
├── WarmCyclorama
├── RibbonSplineRoot
├── ProductOcclusionSlot
├── CounterCopyRail
├── LateralCameraRail
└── HorizontalStripRig
```

### Geometry and materials

- One ribbon only: `18.0 m` long, `2.2 m` wide, `96 × 12` vertex grid.
- Ribbon centerline is a deterministic cubic spline with a traveling sine
  displacement; it never subdivides, blooms, or assembles.
- Satin uses crepe satin diffuse + normal + roughness.
- UV orientation follows ribbon tangent; UV scale `0.48 m/tile`.
- RealityKit anisotropy is approximated with tangent-aligned normal response;
  the Poly Haven metallic map is not used because this is cloth.
- Background cyclorama: local matte warm gray `(0.13, 0.105, 0.095)`,
  roughness `1.0`.

### Lighting

- IBL `ferndale_studio_05`, exponent `0.4`, rotation `12°`.
- Horizontal magenta spot sweeps only through light transform:
  start `(-5, 2.8, 4)`, end `(5, 2.8, 4)`, `12_000 lm`.
- Amber rim point fixed behind product, `4_600 lm`.
- No directional light.

### Camera and composition

- Perspective focal length: `50 mm`.
- Camera performs a constant-speed right-to-left translation:
  `(4.8, 0.3, 10.4)` to `(-3.6, 0.3, 10.4)`.
- Look target translates by the same X delta; view direction remains constant.
- Product stays on the left third of the rendered frame.
- No focal change, orbit, pitch, roll, or depth movement.

### Typography

- Copy: `MOVE WITH FORM`.
- Font: `HelveticaNeue-Italic`, fallback
  `.systemFont(ofSize:weight:.light).italic`.
- Text travels left-to-right on a rail, opposite the camera.
- Cream unlit material; no extrusion shadow and no opacity animation.

### Exact 360-frame choreography

- `0–55`: ribbon wave enters from right while camera track begins.
- `56–139`: ribbon crosses behind the product.
- `140–215`: ribbon loops once around the product.
- `216–251`: ribbon passes fully in front, producing the wipe.
- `252–307`: ribbon exits left and uncovers the product.
- `308–343`: counter-moving typography crosses the lower third.
- `344–359`: camera and ribbon continue constant velocities; no static hold.

Validation frames: `0, 70, 152, 224, 268, 324, 359`.

---

## Premium 08 — Canyon Exposure

Swift implementation: `CanyonExposureScene.swift`  
USDA: `CanyonExposure.usda`  
Dominant event: three temporally separated erosion gusts remove strata from a
monumental canyon wall and uncover the product.

### Exclusive assets

- HDRI: `goegap`
- Surface: `cliff_side`
- Surface use: all terrain strata

### USDA hierarchy

```text
CanyonExposure
├── DesertWorld
├── CanyonBase
├── StrataRoot
├── ErosionParticleRoot
├── EmbeddedProductSlot
├── GroundEtchedCopy
├── CraneCameraRig
└── DesertSunRig
```

### Geometry and materials

- Canyon wall: `8.5 × 10.5 × 3.2 m`.
- Sixty-four horizontal strata with unique fixed contour noise, seed
  `0xE20510`.
- Erosion removes complete mesh strips through scale-to-zero along local X;
  it does not use fracture ballistics.
- Cliff-side diffuse + normal + roughness, triplanar-style UV projection,
  scale `2.4 m/tile`.
- Product begins inside a negative cavity at `(1.15, -1.0, 0.3)`.
- Particles are unlit sand-colored quads generated from fixed arrays.

### Lighting

- IBL `goegap`, exponent `0.2`, rotation `131°`.
- Directional sun `(1.0, 0.56, 0.26)`, `88_000 lux`, low angle `17°`.
- Cool sky fill point `(-4, 5, 1)`, `2_400 lm`, radius `15 m`.
- No animated lights.

### Camera and composition

- Perspective focal length: `24 mm`.
- Crane path:
  `(0.4, -3.1, 6.2)` → `(0.4, 4.8, 13.5)`.
- Camera height follows quintic ease; Z follows linear motion.
- Look target moves from `(1.15, -1.1, 0)` to `(0.35, 0.2, 0)`.
- Product resolves in the lower-right quadrant within a monumental wide view.
- No orbit, lateral track, roll, or focal animation.

### Typography

- Copy: `REVEALED BY TIME`.
- Font: `Optima-Regular`, fallback `.systemFont(ofSize:weight:.regular)`.
- Widely tracked glyphs are embedded horizontally in the canyon floor.
- Copy becomes readable only as the fixed sun reaches a grazing camera angle;
  the text itself never moves or fades.

### Exact 360-frame choreography

- `0–71`: quiet canyon; crane begins extremely slowly.
- `72–103`: gust one removes 18 outer strata.
- `104–139`: pause with drifting particles.
- `140–179`: gust two removes 22 middle strata.
- `180–223`: longer pause and continued crane rise.
- `224–275`: accelerating gust three removes 24 inner strata.
- `276–339`: crane reaches full monumental composition.
- `340–359`: grazing angle makes static ground copy legible.

Validation frames: `0, 88, 124, 160, 208, 248, 304, 350, 359`.

---

## Premium 09 — Timber Vault

Swift implementation: `TimberVaultScene.swift`  
USDA: `TimberVault.usda`  
Dominant event: bent timber ribs extrude upward in alternating pairs and lock
into an architectural vault before a central floor hatch presents the product.

### Exclusive assets

- HDRI: `church_museum`
- Surface: `dark_wood`
- Surface use: ribs, hatch, and suspended typographic plaques

### USDA hierarchy

```text
TimberVault
├── MuseumAxis
├── RibRoot
│   ├── RibPair01
│   ├── RibPair02
│   ├── RibPair03
│   ├── RibPair04
│   ├── RibPair05
│   └── RibPair06
├── CenterHatch
├── ProductElevator
├── SuspendedPlaqueRoot
├── AxialDollyRig
└── ClerestoryLightRig
```

### Geometry and materials

- Twelve bent ribs generated as rectangular sweeps along catenary curves.
- Rib cross section `0.26 × 0.48 m`; vault length `13.5 m`, height `7.8 m`.
- Ribs grow by mesh-segment reveal, not scale.
- Dark wood diffuse + normal + roughness; longitudinal UV projection,
  scale `1.1 m/tile`.
- Floor is local matte charcoal concrete, roughness `0.96`.
- Product elevator is a `1.8 m` square hatch at the vanishing point.

### Lighting

- IBL `church_museum`, exponent `-0.05`, rotation `180°`.
- Six fixed warm spotlights positioned between rib pairs, each `5_200 lm`.
- One cool overhead directional fill, `9_000 lux`.
- Lights turn on in paired steps with their corresponding ribs; positions do
  not move.

### Camera and composition

- Perspective focal length: `20 mm`.
- Perfectly axial dolly `(0, 1.15, 15.8)` → `(0, 1.15, 8.9)`.
- Fixed target `(0, 1.15, -1.8)`.
- One-point symmetric perspective throughout.
- No camera rotation, orbit, crane, lateral movement, or lens change.

### Typography

- Copy: `BUILT TO FRAME`.
- Font: `Copperplate`, fallback `.systemFont(ofSize:weight:.semibold)`.
- Four suspended timber plaques between ribs; words are engraved as shallow
  dark inset meshes.
- Plaques descend vertically in four discrete steps.

### Exact 360-frame choreography

- `0–31`: empty architectural axis.
- `32–67`: rib pair 1 grows and lights.
- `68–99`: rib pair 2 grows and lights.
- `100–127`: rib pair 3 grows and lights.
- `128–151`: rib pair 4 grows and lights.
- `152–171`: rib pair 5 grows and lights.
- `172–187`: rib pair 6 grows and lights.
- `188–247`: axial dolly advances through completed vault.
- `248–287`: center hatch opens in four rigid panels.
- `288–319`: product elevator rises.
- `320–347`: four plaques descend.
- `348–359`: exact hero hold.

Validation frames: `0, 48, 112, 180, 220, 264, 304, 336, 359`.

---

## Premium 10 — Bluegum Helix

Swift implementation: `BluegumHelixScene.swift`  
USDA: `BluegumHelix.usda`  
Dominant event: a woody helix grows vertically around a dark product silhouette;
leaf-like reflectors rotate toward a moving skylight and illuminate the product.

### Exclusive assets

- HDRI: `cloudy_netted_nursery`
- Surface: `bark_bluegum`
- Surface use: helix stem and branchlets

### USDA hierarchy

```text
BluegumHelix
├── NurseryWorld
├── SoilIsland
├── HelixStem
├── BranchletRoot
├── ReflectorLeafRoot
├── SilhouetteProductSlot
├── BotanicalTagRoot
├── VerticalPedestalRig
└── MovingSkylightRig
```

### Geometry and materials

- Main stem: tapered tube following `3.25` turns of a helix,
  base radius `1.75 m`, height `8.4 m`, `128` axial segments.
- Eighteen branchlets use fixed phyllotaxis angle `137.5°`.
- Eighteen reflector leaves are thin asymmetric ellipses, each a unique size
  in `0.38–0.92 m`.
- Stem uses bluegum diffuse + normal + roughness, cylindrical UV projection,
  scale `0.8 m/tile`.
- Leaves use local translucent green PBR: `(0.08, 0.34, 0.12)`,
  roughness `0.44`, opacity `0.78`.
- Product starts enabled but receives only a near-black silhouette material
  until the reflector-light event.

### Lighting

- IBL `cloudy_netted_nursery`, exponent `0.55`, rotation `76°`.
- Warm spot moves on an overhead arc from `(-4, 6, 1)` to `(3, 7, -2)`,
  `17_000 lm`.
- Static green floor bounce, `1_800 lm`.
- Leaf normals rotate toward the moving spot and redirect the visual highlight.

### Camera and composition

- Perspective focal length: `85 mm`.
- Pure vertical pedestal from `(0.35, -2.2, 10.9)` to
  `(0.35, 2.7, 10.9)`.
- Fixed look direction; target rises by the same Y delta.
- Product remains low-center and is close-cropped by helix turns.
- No depth change, orbit, lateral track, roll, or lens animation.

### Typography

- Copy: `GROWN TOWARD LIGHT`.
- Font: `AvenirNext-UltraLight`, fallback
  `.systemFont(ofSize:weight:.ultraLight)`.
- Four lowercase botanical tags attached to different branchlets.
- Tags are translucent off-white planes with dark printed meshes.
- Tags become visible only when rotating into profile; no opacity animation.

### Exact 360-frame choreography

- `0–47`: soil island and dark product silhouette.
- `48–167`: helix stem grows continuously upward.
- `168–227`: branchlets extend in Fibonacci order.
- `228–279`: reflector leaves unfold with 3-frame offsets.
- `280–319`: warm skylight travels overhead; leaves rotate toward it.
- `320–339`: product material transitions from silhouette to textured unlit
  product as cumulative reflected-light progress reaches one.
- `340–359`: vertical pedestal completes; tags remain naturally staggered.

Validation frames: `0, 76, 148, 196, 252, 296, 328, 350, 359`.

---

## Premium 11 — Magnetic Convergence

Swift implementation: `MagneticConvergenceScene.swift`  
USDA: `MagneticConvergence.usda`  
Dominant event: 180 steel plates accelerate along three curved field paths and
lock into a segmented halo, clearing the product through ordered attraction.

### Exclusive assets

- HDRI: `aircraft_workshop_01`
- Surface: `metal_plate_02`
- Surface use: all moving plates and final halo

### USDA hierarchy

```text
MagneticConvergence
├── WorkshopWorld
├── FieldPathRoot
├── FreePlateRoot
├── HaloSegmentRoot
├── ProductSlot
├── MechanicalCopyRoot
├── OrbitCameraRig
└── PulseLightRoot
```

### Geometry and materials

- 180 beveled plates in deterministic size classes:
  `72 × 0.16 m`, `54 × 0.24 m`, `36 × 0.34 m`, `18 × 0.48 m`.
- Plate thickness is `0.035 m`; bevel approximation `0.012 m`.
- Three precomputed cubic field splines terminate on a `2.4 m` radius halo.
- Metal plate diffuse + normal + roughness + metallic, UV scale `0.62 m/tile`.
- Final halo contains eighteen segments; every ten plates collapse into one
  segment through transform convergence.
- Product remains stationary at world origin.

### Lighting

- IBL `aircraft_workshop_01`, exponent `0.1`, rotation `-14°`.
- Eighteen white pulse points around the halo, `0` or `7_500 lm`.
- One static red back spot, `6_200 lm`.
- Pulse points fire once on segment lock and decay over exactly six frames.

### Camera and composition

- Perspective focal length: `38 mm`.
- Counterclockwise `162°` orbit, radius decreases `11.2 → 8.6 m`.
- Camera height falls `2.8 → 0.4 m`.
- Angular velocity accelerates through frame 205, then decelerates sharply.
- Final composition is centered with an exact circular halo.
- No Bézier dolly, crane, lateral rail, roll, or focal change.

### Typography

- Copy: `DRAWN TOGETHER`.
- Font: `DINCondensed-Bold`, fallback
  `.systemFont(ofSize:weight:.bold)`.
- Fourteen individual character blocks snap onto a baseline from random fixed
  offsets, synchronized to the last fourteen halo locks.
- White emissive material, intensity `1.7`.

### Exact 360-frame choreography

- `0–31`: sparse plates drift at constant low velocity.
- `32–95`: first field path attracts 60 plates.
- `96–159`: second path attracts 60 plates at `1.4×` acceleration.
- `160–223`: third path attracts 60 plates at `2.0×` acceleration.
- `224–277`: eighteen halo segments lock at 3-frame intervals with recoil.
- `278–319`: orbit decelerates into frontal view.
- `320–347`: character blocks snap to baseline at 2-frame intervals.
- `348–359`: pulse lights decay; exact final geometry hold.

Validation frames: `0, 48, 112, 176, 232, 272, 304, 336, 359`.

---

## Premium 12 — Oxide Light Cut

Swift implementation: `OxideLightCutScene.swift`  
USDA: `OxideLightCut.usda`  
Dominant event: moving light planes cut narrow illuminated sections across a
rusted monolith; only their intersection exposes the product.

### Exclusive assets

- HDRI: `clarens_night_01`
- Surface: `rust_coarse_01`
- Surface use: monolith and physical typographic shadow objects

### USDA hierarchy

```text
OxideLightCut
├── NightWorld
├── RustMonolith
├── LightPlaneRoot
├── ProductIntersectionSlot
├── ShadowCopyRoot
├── LockedMacroCamera
└── SilhouetteLightRig
```

### Geometry and materials

- Monolith: `5.8 × 9.6 × 0.9 m`, close-cropped by the portrait frame.
- Nine zero-thickness light planes with unique normal vectors.
- Rust monolith uses rust coarse diffuse + normal + roughness,
  UV scale `1.3 m/tile`; metallic is a constant `0.64`.
- Light planes use exclusive unlit gradients:
  white `6.0`, red `4.5`, amber `3.2` visual emission multipliers.
- Product visibility is calculated from the intersection of three analytic
  plane masks; it is not revealed by object translation or scale.

### Lighting

- IBL `clarens_night_01`, exponent `-1.4`, rotation `205°`.
- One fixed silhouette directional light, cool white, `2_800 lux`.
- No point lights and no HDRI-driven visible background.
- Moving illumination is represented entirely by authored light-plane
  materials and matching narrow spots.

### Camera and composition

- Perspective focal length: `135 mm`.
- Camera locked at `(0, 0.15, 13.2)`, target `(0, 0.15, 0)`.
- No camera animation of any kind.
- Product and monolith are close-cropped; product top remains outside frame
  until the monolith aperture widens.

### Typography

- Copy: `DEFINED BY LIGHT`.
- Font: `Bodoni 72 Smallcaps`, fallback
  `.systemFont(ofSize:weight:.semibold)`.
- Solid extruded rust letters sit `0.12 m` in front of the monolith and become
  readable only through moving cast shadows.
- Typography entities never animate.

### Exact 360-frame choreography

- `0–63`: near-dark monolith; only silhouette edge is visible.
- `64–119`: three white planes sweep at constant but unequal angular speeds.
- `120–183`: three red planes cross in reverse angular direction.
- `184–239`: three amber planes translate vertically without rotation.
- `240–299`: all nine planes converge on the product intersection.
- `300–331`: intersection aperture expands from `8%` to `100%`.
- `332–351`: matching spots traverse static typography and expose its shadows.
- `352–359`: all planes stop simultaneously; exact final hold.

Validation frames: `0, 80, 144, 208, 264, 316, 340, 359`.

---

## Verified Poly Haven HDRI files

| Scene | Asset ID | Local filename | Bytes | MD5 |
|---|---|---:|---:|---|
| Optical Corridor | `ferndale_studio_02` | `ferndale_studio_02_1k.hdr` | 1,264,564 | `f8f3acbe4e8cf440f8587cafadb48dfe` |
| Paper Aperture | `cyclorama_hard_light` | `cyclorama_hard_light_1k.hdr` | 1,409,707 | `dc91db55904c205bd6b44e4029972962` |
| Ceramic Impact | `courtyard` | `courtyard_1k.hdr` | 1,716,791 | `c9f92690f97deab491c5f97dd652cee2` |
| Basalt Tide | `blue_grotto` | `blue_grotto_1k.hdr` | 1,789,553 | `990c847a1b93def5cdaeffc3a104b0ce` |
| Satin Current | `ferndale_studio_05` | `ferndale_studio_05_1k.hdr` | 1,373,092 | `f629f69d7cbd924601505c3cc1cfc63c` |
| Canyon Exposure | `goegap` | `goegap_1k.hdr` | 1,361,485 | `136ccde9732506fad64b090cdb535601` |
| Timber Vault | `church_museum` | `church_museum_1k.hdr` | 1,728,746 | `e56e742a25d4128ca89c6929322432a8` |
| Bluegum Helix | `cloudy_netted_nursery` | `cloudy_netted_nursery_1k.hdr` | 1,710,698 | `18a9bd359c92f7de3a2691771942ca8d` |
| Magnetic Convergence | `aircraft_workshop_01` | `aircraft_workshop_01_1k.hdr` | 1,771,415 | `a50268d898067babd9f45aae44cdf73f` |
| Oxide Light Cut | `clarens_night_01` | `clarens_night_01_1k.hdr` | 1,691,137 | `f6d7e43aed2cc4bd943dcaac9cdbc300` |

Download URL pattern is the verified URL returned by `/files/{id}`:

```text
https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/1k/{id}_1k.hdr
```

## Verified Poly Haven surface files

All files below use the verified URL form:

```text
https://dl.polyhaven.org/file/ph-assets/Textures/jpg/2k/{id}/{filename}
```

| Asset ID | Map | Local filename | Bytes | MD5 |
|---|---|---|---:|---|
| `white_plaster_02` | diffuse | `white_plaster_02_diff_2k.jpg` | 2,568,315 | `35f9c96c16aa0d934da7884b232f6d07` |
| `white_plaster_02` | normal GL | `white_plaster_02_nor_gl_2k.jpg` | 3,379,814 | `a9fa643c4a200686ad89598b545b2adc` |
| `white_plaster_02` | roughness | `white_plaster_02_rough_2k.jpg` | 1,604,444 | `47f989e9fd3e69e667244ff4b9f406f8` |
| `decrepit_wallpaper` | diffuse | `decrepit_wallpaper_diff_2k.jpg` | 3,325,490 | `6d8cef16eecb7b4c84d77008ffc375b5` |
| `decrepit_wallpaper` | normal GL | `decrepit_wallpaper_nor_gl_2k.jpg` | 2,906,832 | `8ae2cd9b5d40327c6a0193fa9fd97058` |
| `decrepit_wallpaper` | roughness | `decrepit_wallpaper_rough_2k.jpg` | 1,660,507 | `08511294c9cdbaa4e50c28ac05ae2248` |
| `long_white_tiles` | diffuse | `long_white_tiles_diff_2k.jpg` | 2,439,827 | `5bbacf1598466e2e6f56e8a44c5f734b` |
| `long_white_tiles` | normal GL | `long_white_tiles_nor_gl_2k.jpg` | 2,541,844 | `e72a483dab9f34be6aeacf1215a83401` |
| `long_white_tiles` | roughness | `long_white_tiles_rough_2k.jpg` | 2,059,646 | `f864ca86bf492eaaf578bc3fb10991af` |
| `dark_rock_02` | diffuse | `dark_rock_02_diff_2k.jpg` | 2,441,558 | `492ae574844fa49cba63aee89ef226d1` |
| `dark_rock_02` | normal GL | `dark_rock_02_nor_gl_2k.jpg` | 3,870,014 | `bfde991c327e33704686fb7ede0561a7` |
| `dark_rock_02` | roughness | `dark_rock_02_rough_2k.jpg` | 2,022,528 | `b21b552d0b78eb3824ac159b51ddba14` |
| `crepe_satin` | diffuse | `crepe_satin_diff_2k.jpg` | 3,179,570 | `239e951740cabd339d3672442a2a8d9c` |
| `crepe_satin` | normal GL | `crepe_satin_nor_gl_2k.jpg` | 3,644,711 | `8c65e96062503e831bc647dc588f89dd` |
| `crepe_satin` | roughness | `crepe_satin_rough_2k.jpg` | 4,043,250 | `61c1c4294e114a66a5613f0897e14e7f` |
| `cliff_side` | diffuse | `cliff_side_diff_2k.jpg` | 3,387,348 | `6d129836144e271b30071281241e237d` |
| `cliff_side` | normal GL | `cliff_side_nor_gl_2k.jpg` | 3,585,856 | `8209033c3ad15185977d91c92cf5866f` |
| `cliff_side` | roughness | `cliff_side_rough_2k.jpg` | 1,765,122 | `44abb195b6c4c7b6da902e97e5bbbef2` |
| `dark_wood` | diffuse | `dark_wood_diff_2k.jpg` | 2,894,186 | `f6e205a05ff7f1b45c675795b18ea0f5` |
| `dark_wood` | normal GL | `dark_wood_nor_gl_2k.jpg` | 1,603,278 | `0b47748d5559eb91c1fe19b9394ef95f` |
| `dark_wood` | roughness | `dark_wood_rough_2k.jpg` | 2,325,418 | `e270e270d5feb0281bce7a49e801a64b` |
| `bark_bluegum` | diffuse | `bark_bluegum_diff_2k.jpg` | 3,508,793 | `0af5e06ee043b3e9f8db7884d53de166` |
| `bark_bluegum` | normal GL | `bark_bluegum_nor_gl_2k.jpg` | 4,649,162 | `edc5c285e14c5b10690cec6b712911ba` |
| `bark_bluegum` | roughness | `bark_bluegum_rough_2k.jpg` | 1,320,090 | `3846ba7c036c6ffaa68165b7d123a86c` |
| `metal_plate_02` | diffuse | `metal_plate_02_diff_2k.jpg` | 2,604,239 | `519b43cf88b4b6ea74bd259e976f2170` |
| `metal_plate_02` | normal GL | `metal_plate_02_nor_gl_2k.jpg` | 565,185 | `59a2c571e7dd601276f0efbd9c75bb3a` |
| `metal_plate_02` | roughness | `metal_plate_02_rough_2k.jpg` | 3,818,263 | `4d719f94800aaf6a77cf8b22ce503116` |
| `metal_plate_02` | metallic | `metal_plate_02_metal_2k.jpg` | 2,021,136 | `9f65637f90a08e036f978d8d2ca288ca` |
| `rust_coarse_01` | diffuse | `rust_coarse_01_diff_2k.jpg` | 3,519,719 | `c1f3d0f3e8ea08bfed17bd27a5bb4a45` |
| `rust_coarse_01` | normal GL | `rust_coarse_01_nor_gl_2k.jpg` | 3,685,688 | `70e8ba5a8244cffb052b9ba194610867` |
| `rust_coarse_01` | roughness | `rust_coarse_01_rough_2k.jpg` | 2,845,362 | `10a240a8a6e841e9667497377df90f72` |

## Cross-template uniqueness audit

| Scene | Event | Primary geometry | Surface family | Reveal | Camera | Composition | Timing signature |
|---|---|---|---|---|---|---|---|
| Optical Corridor | optical convergence | triangular prisms | glass + plaster | slice alignment | 60 mm Bézier dolly | right-weighted corridor | long convergence, short copy |
| Paper Aperture | tearing unfold | hinged iris blades | distressed paper | physical aperture | 90 mm overhead descent | radial center | three sequential rings |
| Ceramic Impact | single fracture | Voronoi facade fragments | glazed ceramic | destructive occlusion | 32 mm locked impulse | upper-left cavity | abrupt impact, long hold |
| Basalt Tide | rise and drainage | liquid grid + channels | liquid + basalt | draining subtraction | 110 mm macro pullback | centered macro | rise, suspension, drain |
| Satin Current | continuous flow | single spline ribbon | satin textile | traveling wipe | 50 mm lateral rail | left-third asymmetry | uninterrupted constant motion |
| Canyon Exposure | staged erosion | layered terrain strips | sedimentary stone | material removal | 24 mm crane | monumental lower-right | three gusts with unequal pauses |
| Timber Vault | architectural construction | catenary timber ribs | dark wood | hatch elevator | 20 mm axial dolly | one-point symmetry | six shortening build beats |
| Bluegum Helix | phototropic growth | helical stem + reflectors | bark + leaves | redirected light | 85 mm vertical pedestal | organic close crop | growth, unfold, light response |
| Magnetic Convergence | accelerating attraction | plates + segmented halo | corroded steel | ordered clearance | 38 mm decelerating orbit | circular center | three acceleration waves |
| Oxide Light Cut | intersecting illumination | monolith + light planes | coarse rust | analytic light mask | 135 mm locked macro | extreme crop | three directional light families |

No row duplicates another row in any creative column.

## Implementation gate

Before adding a scene to `StudioTemplate`, it must pass:

1. USDA hierarchy name validation.
2. Poly Haven resource existence and MD5 validation.
3. Determinism check: two evaluations of every representative frame produce
   identical entity transforms and material scalar values.
4. Preview/export frame parity at every representative frame.
5. H.264 metadata validation: 1080 × 1920, 30 fps, exactly 12.0 seconds.
6. Representative frame readability and content-change validation.
7. Cross-template contact-sheet review against all previously accepted ads.
8. Confirmation that it imports no creative builder or resource belonging to
   another scene.
