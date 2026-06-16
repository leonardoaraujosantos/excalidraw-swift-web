import ExcalidrawMath
import ExcalidrawModel
import XCTest
@testable import ExcalidrawEditor

final class BindingTests: XCTestCase {
    private func shape(_ id: String, x: Double, y: Double, w: Double = 60, h: Double = 60) -> ExcalidrawElement {
        var b = BaseProperties(id: id); b.x = x; b.y = y; b.width = w; b.height = h; b.backgroundColor = "#ff0000"
        return ExcalidrawElement(base: b, kind: .rectangle)
    }

    private func editor(_ elements: [ExcalidrawElement]) -> EditorController {
        var idCount = 0
        return EditorController(
            scene: Scene(elements: elements),
            idProvider: { idCount += 1; return "arrow\(idCount)" }
        )
    }

    /// Draw an arrow starting inside shape "a" and ending inside shape "b".
    private func drawBindingArrow(_ ec: EditorController, from: Point, to: Point) {
        ec.setTool(.arrow)
        ec.pointerDown(PointerEvent(scenePoint: from, phase: .down))
        ec.pointerMove(PointerEvent(scenePoint: to, phase: .move))
        ec.pointerUp(PointerEvent(scenePoint: to, phase: .up))
    }

    func testArrowBindsToShapesAtBothEnds() {
        let ec = editor([shape("a", x: 0, y: 0), shape("b", x: 300, y: 0)])
        drawBindingArrow(ec, from: Point(30, 30), to: Point(330, 30)) // centres of a and b
        let arrow = ec.scene.visibleElements.first { if case .arrow = $0.kind { return true }; return false }
        guard case let .arrow(props) = arrow?.kind else { return XCTFail("arrow") }
        XCTAssertEqual(props.startBinding?.elementId, "a")
        XCTAssertEqual(props.endBinding?.elementId, "b")
        // The shape records the bound arrow.
        XCTAssertEqual(ec.scene.element(id: "a")?.base.boundElements?.first?.type, .arrow)
    }

    func testBoundArrowFollowsWhenShapeMoves() throws {
        let ec = editor([shape("a", x: 0, y: 0), shape("b", x: 300, y: 0)])
        drawBindingArrow(ec, from: Point(30, 30), to: Point(330, 30))
        let arrowID = try XCTUnwrap(ec.scene.visibleElements
            .first { if case .arrow = $0.kind { return true }; return false }?.id)
        let endBefore = try XCTUnwrap(ec.scene.element(id: arrowID).map { e -> Point in
            guard case let .arrow(p) = e.kind else { return .zero }
            return Point(e.base.x + p.points.last!.x, e.base.y + p.points.last!.y)
        })

        // Move shape "b" down by 100 and confirm the arrow's end followed.
        // Grab "b" away from the arrow line (which sits at y≈30).
        ec.setTool(.selection)
        ec.pointerDown(PointerEvent(scenePoint: Point(330, 52), phase: .down))
        ec.pointerMove(PointerEvent(scenePoint: Point(330, 152), phase: .move))
        ec.pointerUp(PointerEvent(scenePoint: Point(330, 152), phase: .up))

        let endAfter = try XCTUnwrap(ec.scene.element(id: arrowID).map { e -> Point in
            guard case let .arrow(p) = e.kind else { return .zero }
            return Point(e.base.x + p.points.last!.x, e.base.y + p.points.last!.y)
        })
        XCTAssertEqual(endAfter.y - endBefore.y, 100, accuracy: 1e-6)
    }

    func testBindingCanBeDisabled() {
        let ec = editor([shape("a", x: 0, y: 0), shape("b", x: 300, y: 0)])
        ec.bindingEnabled = false
        drawBindingArrow(ec, from: Point(30, 30), to: Point(330, 30))
        let arrow = ec.scene.visibleElements.first { if case .arrow = $0.kind { return true }; return false }
        guard case let .arrow(props) = arrow?.kind else { return XCTFail("arrow") }
        XCTAssertNil(props.startBinding)
        XCTAssertNil(props.endBinding)
    }
}
