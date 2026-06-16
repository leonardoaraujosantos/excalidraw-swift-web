import ExcalidrawMath
import ExcalidrawModel
import XCTest
@testable import ExcalidrawEditor

final class RoundnessAndSloppinessTests: XCTestCase {
    private func created(_ tool: Tool, roundEdges: Bool = true) -> ExcalidrawElement {
        let ec = EditorController()
        ec.currentItem.roundEdges = roundEdges
        ec.setTool(tool)
        ec.pointerDown(PointerEvent(scenePoint: Point(0, 0), phase: .down))
        ec.pointerMove(PointerEvent(scenePoint: Point(80, 60), phase: .move))
        ec.pointerUp(PointerEvent(scenePoint: Point(80, 60), phase: .up))
        return ec.scene.visibleElements.first!
    }

    func testLinesAndArrowsDefaultToProportionalRoundness() {
        XCTAssertEqual(created(.line).base.roundness?.type, RoundnessType.proportionalRadius)
        XCTAssertEqual(created(.arrow).base.roundness?.type, RoundnessType.proportionalRadius)
    }

    func testRectangleDefaultsToAdaptiveRoundness() {
        XCTAssertEqual(created(.rectangle).base.roundness?.type, RoundnessType.adaptiveRadius)
    }

    func testSharpEdgesLeaveRoundnessNil() {
        XCTAssertNil(created(.rectangle, roundEdges: false).base.roundness)
        XCTAssertNil(created(.line, roundEdges: false).base.roundness)
    }

    func testRoundnessTypeMapping() {
        XCTAssertEqual(EditorController.roundnessType(for: .line(LinearProperties())), RoundnessType.proportionalRadius)
        XCTAssertEqual(EditorController.roundnessType(for: .rectangle), RoundnessType.adaptiveRadius)
        XCTAssertNil(EditorController.roundnessType(for: .ellipse))
    }
}
