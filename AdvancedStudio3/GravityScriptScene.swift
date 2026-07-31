import AppKit
import RealityKit

@MainActor final class GravityScriptScene {
  let root: Entity
  let camera: PerspectiveCamera
  private let glyphs: [ModelEntity]
  private init(_ r: Entity, _ c: PerspectiveCamera, _ g: [ModelEntity]) {
    root = r
    camera = c
    glyphs = g
  }
  static func load(imageURL: URL) async throws -> GravityScriptScene {
    let r = try await NewSceneSupport.entity("GravityScript")
    let x = try NewSceneSupport.child("GlyphRoot", in: r)
    let p = try NewSceneSupport.child("ProductRoot", in: r)
    let c = try NewSceneSupport.child("CameraRig", in: r)
    let l = try NewSceneSupport.child("LightRoot", in: r)
    var g: [ModelEntity] = []
    for (i, ch) in Array("DESIRE").enumerated() {
      let e = NewSceneSupport.text(
        String(ch), fontName: "HelveticaNeue-Bold", size: 1.1,
        color: NSColor(red: 0.72, green: 0.13, blue: 0.08, alpha: 1), depth: 0.18)
      e.position = [-3 + Float(i) * 1.1, 3.8 + Float(i % 2), 0]
      x.addChild(e)
      g.append(e)
    }
    let pr = try await NewSceneSupport.product(
      imageURL: imageURL, height: 1.7, name: "ScriptProduct")
    pr.position = [0.5, -0.5, -0.25]
    p.addChild(pr)
    let ib = try await NewSceneSupport.imageLight(id: "church_museum", exponent: 0.8, parent: l)
    NewSceneSupport.receiveIBL(g, light: ib)
    let cam = NewSceneSupport.camera(focalLength: 62, name: "ScriptCamera")
    c.addChild(cam)
    let s = GravityScriptScene(r, cam, g)
    s.apply(frameIndex: 359)
    return s
  }
  func apply(frameIndex: Int) {
    let f = min(max(frameIndex, 0), 359)
    let fall = NewSceneSupport.smooth(f, 0, 176)
    let clear = NewSceneSupport.smooth(f, 180, 258)
    let h = NewSceneSupport.smooth(f, 270, 359)
    for i in glyphs.indices {
      let landing = NewSceneSupport.smooth(f, i * 12, 90 + i * 12)
      glyphs[i].position.y = NewSceneSupport.mix(4 + Float(i % 2), -0.3, landing)
      glyphs[i].position.x = (-3 + Float(i) * 1.1) + sin(Float(i)) * fall * 0.2
      glyphs[i].position.y -= clear * 3.8
      glyphs[i].orientation = simd_quatf(angle: (1 - landing) * Float(i) * 0.25, axis: [0, 0, 1])
    }
    camera.look(
      at: [0, -0.2, 0],
      from: [
        NewSceneSupport.mix(-1.4, 0.55, clear) + h * 0.08, 0.1, NewSceneSupport.mix(8, 12, clear),
      ], relativeTo: root)
  }
}
