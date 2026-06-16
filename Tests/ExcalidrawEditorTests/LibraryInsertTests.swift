import ExcalidrawMath
import ExcalidrawModel
import XCTest
@testable import ExcalidrawEditor

final class LibraryInsertTests: XCTestCase {
    private func rect(_ id: String, x: Double, y: Double) -> ExcalidrawElement {
        var b = BaseProperties(id: id); b.x = x; b.y = y; b.width = 20; b.height = 20
        return ExcalidrawElement(base: b, kind: .rectangle)
    }

    func testInsertLibraryItemPlacesAtPoint() {
        var idCount = 0
        let ec = EditorController(idProvider: { idCount += 1; return "n\(idCount)" })
        // A two-element group whose top-left is (100, 100).
        let item = [rect("a", x: 100, y: 100), rect("b", x: 140, y: 130)]
        let ids = ec.insertLibraryItem(item, at: Point(0, 0))
        XCTAssertEqual(ids.count, 2)
        XCTAssertEqual(ec.scene.visibleElements.count, 2)
        // Group top-left moved to (0, 0); relative layout preserved.
        let a = ec.scene.element(id: ids[0])
        let b = ec.scene.element(id: ids[1])
        XCTAssertEqual(a?.base.x, 0)
        XCTAssertEqual(a?.base.y, 0)
        XCTAssertEqual(b?.base.x, 40)
        XCTAssertEqual(b?.base.y, 30)
        XCTAssertEqual(ec.selectedIDs, Set(ids))
    }

    func testInsertIsUndoable() {
        let ec = EditorController()
        ec.insertLibraryItem([rect("a", x: 0, y: 0)], at: Point(50, 50))
        XCTAssertEqual(ec.scene.visibleElements.count, 1)
        XCTAssertTrue(ec.undo())
        XCTAssertEqual(ec.scene.visibleElements.count, 0)
    }
}
