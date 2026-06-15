import ExcalidrawGeometry
import ExcalidrawMath
import ExcalidrawModel
import XCTest
@testable import ExcalidrawEditor

final class EditorActionsTests: XCTestCase {
    private func makeEditor(_ elements: [ExcalidrawElement]) -> EditorController {
        var idCount = 100
        return EditorController(scene: Scene(elements: elements), idProvider: { idCount += 1; return "n\(idCount)" })
    }

    private func rect(_ id: String, x: Double, y: Double, w: Double = 20, h: Double = 20) -> ExcalidrawElement {
        var b = BaseProperties(id: id); b.x = x; b.y = y; b.width = w; b.height = h
        return ExcalidrawElement(base: b, kind: .rectangle)
    }

    func testGroupAndUngroup() {
        let ec = makeEditor([rect("a", x: 0, y: 0), rect("b", x: 50, y: 0)])
        ec.selectAll()
        ec.group()
        let groupIDs = ec.scene.element(id: "a")?.base.groupIds
        XCTAssertEqual(groupIDs?.count, 1)
        XCTAssertEqual(ec.scene.element(id: "b")?.base.groupIds, groupIDs)
        ec.ungroup()
        XCTAssertTrue(ec.scene.element(id: "a")?.base.groupIds.isEmpty ?? false)
    }

    func testDuplicateOffsetsAndSelectsCopies() {
        let ec = makeEditor([rect("a", x: 0, y: 0)])
        ec.selectAll()
        ec.duplicate()
        XCTAssertEqual(ec.scene.visibleElements.count, 2)
        XCTAssertFalse(ec.selectedIDs.contains("a")) // copies are selected, not the original
        let copy = ec.selectedElements.first
        XCTAssertEqual(copy?.base.x, 10)
        XCTAssertEqual(copy?.base.y, 10)
    }

    func testLockUnlock() {
        let ec = makeEditor([rect("a", x: 0, y: 0)])
        ec.selectAll()
        ec.setLocked(true)
        XCTAssertEqual(ec.scene.element(id: "a")?.base.locked, true)
        ec.setLocked(false)
        XCTAssertEqual(ec.scene.element(id: "a")?.base.locked, false)
    }

    private func boxSelect(_ ec: EditorController, from: Point, to: Point) {
        ec.pointerDown(PointerEvent(scenePoint: from, phase: .down))
        ec.pointerMove(PointerEvent(scenePoint: to, phase: .move))
        ec.pointerUp(PointerEvent(scenePoint: to, phase: .up))
    }

    func testZOrder() {
        let ec = makeEditor([rect("a", x: 0, y: 0), rect("b", x: 40, y: 0), rect("c", x: 80, y: 0)])
        // Box-select only "a" (the others are outside the box) and bring it to front.
        boxSelect(ec, from: Point(-5, -5), to: Point(25, 25))
        XCTAssertEqual(ec.selectedIDs, ["a"])
        ec.reorder(.front)
        XCTAssertEqual(ec.scene.elements.map(\.id), ["b", "c", "a"])
        ec.reorder(.backward)
        XCTAssertEqual(ec.scene.elements.map(\.id), ["b", "a", "c"])
        ec.reorder(.back)
        XCTAssertEqual(ec.scene.elements.map(\.id), ["a", "b", "c"])
        ec.reorder(.forward)
        XCTAssertEqual(ec.scene.elements.map(\.id), ["b", "a", "c"])
    }

    func testAlign() {
        let ec = makeEditor([rect("a", x: 0, y: 0), rect("b", x: 100, y: 50)])
        ec.selectAll()
        ec.align(.left)
        XCTAssertEqual(ec.scene.element(id: "a")?.base.x, 0)
        XCTAssertEqual(ec.scene.element(id: "b")?.base.x, 0)
        ec.align(.top)
        XCTAssertEqual(ec.scene.element(id: "b")?.base.y, 0)
    }

    func testFlipHorizontalMirrorsPositions() {
        // Two rects; flipping horizontally swaps their left/right positions.
        let ec = makeEditor([rect("a", x: 0, y: 0, w: 20, h: 20), rect("b", x: 100, y: 0, w: 20, h: 20)])
        ec.selectAll()
        ec.flip(horizontal: true)
        // Selection spans x[0,120]; "a" (was at 0) mirrors to right edge → x 100.
        XCTAssertEqual(ec.scene.element(id: "a")?.base.x, 100)
        XCTAssertEqual(ec.scene.element(id: "b")?.base.x, 0)
    }

    func testActionsAreUndoable() {
        let ec = makeEditor([rect("a", x: 0, y: 0)])
        ec.selectAll()
        ec.setLocked(true)
        XCTAssertTrue(ec.undo())
        XCTAssertEqual(ec.scene.element(id: "a")?.base.locked, false)
    }
}
