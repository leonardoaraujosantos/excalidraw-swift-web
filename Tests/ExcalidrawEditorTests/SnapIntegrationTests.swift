import ExcalidrawMath
import ExcalidrawModel
import XCTest
@testable import ExcalidrawEditor

final class SnapIntegrationTests: XCTestCase {
    private func rect(_ id: String, x: Double, y: Double, w: Double = 40, h: Double = 40) -> ExcalidrawElement {
        var b = BaseProperties(id: id); b.x = x; b.y = y; b.width = w; b.height = h
        b.backgroundColor = "#ff0000" // filled, so interior taps select it
        return ExcalidrawElement(base: b, kind: .rectangle)
    }

    func testMoveSnapsToOtherElement() {
        // "target" at x=0; drag "mover" so its left edge lands near x=0.
        let ec = EditorController(scene: Scene(elements: [
            rect("target", x: 0, y: 0),
            rect("mover", x: 300, y: 300)
        ]))
        ec.snapEnabled = true
        // Select + move "mover" so its left edge reaches x≈3 (within 8 of target's 0).
        ec.pointerDown(PointerEvent(scenePoint: Point(320, 320), phase: .down)) // inside mover
        ec.pointerMove(PointerEvent(scenePoint: Point(23, 320), phase: .move)) // dx = -297 → left ≈ 3
        ec.pointerUp(PointerEvent(scenePoint: Point(23, 320), phase: .up))
        // Snapped exactly onto x=0.
        XCTAssertEqual(ec.scene.element(id: "mover")?.base.x ?? .nan, 0, accuracy: 1e-6)
    }

    func testSnapDisabledByDefault() {
        let ec = EditorController(scene: Scene(elements: [
            rect("target", x: 0, y: 0),
            rect("mover", x: 300, y: 300)
        ]))
        ec.pointerDown(PointerEvent(scenePoint: Point(320, 320), phase: .down))
        ec.pointerMove(PointerEvent(scenePoint: Point(23, 320), phase: .move))
        ec.pointerUp(PointerEvent(scenePoint: Point(23, 320), phase: .up))
        // No snap: left edge stays at 3, not 0.
        XCTAssertEqual(ec.scene.element(id: "mover")?.base.x ?? .nan, 3, accuracy: 1e-6)
    }

    func testSnapLinesClearedOnPointerUp() {
        let ec = EditorController(scene: Scene(elements: [rect("a", x: 0, y: 0), rect("b", x: 300, y: 0)]))
        ec.snapEnabled = true
        ec.pointerDown(PointerEvent(scenePoint: Point(320, 20), phase: .down))
        ec.pointerMove(PointerEvent(scenePoint: Point(23, 20), phase: .move))
        XCTAssertFalse(ec.snapLinesX.isEmpty)
        ec.pointerUp(PointerEvent(scenePoint: Point(23, 20), phase: .up))
        XCTAssertTrue(ec.snapLinesX.isEmpty)
    }
}
