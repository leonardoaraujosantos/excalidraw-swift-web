import ExcalidrawMath
import XCTest
@testable import ExcalidrawGeometry

final class SnappingTests: XCTestCase {
    func testSnapToGrid() {
        XCTAssertEqual(Snapping.snapToGrid(Point(23, 38), gridSize: 20), Point(20, 40))
        XCTAssertEqual(Snapping.snapToGrid(Point(5, 5), gridSize: 0), Point(5, 5)) // no grid
    }

    func testObjectSnapAlignsLeftEdges() {
        // Moving box left edge at 102, a static box left edge at 100 → snap by -2.
        let moving = BoundingBox(minX: 102, minY: 200, maxX: 152, maxY: 240)
        let stat = BoundingBox(minX: 100, minY: 0, maxX: 140, maxY: 40)
        let result = Snapping.snap(moving: moving, statics: [stat], threshold: 8)
        XCTAssertEqual(result.offsetX, -2, accuracy: 1e-9)
        XCTAssertEqual(result.verticalLines, [100])
    }

    func testObjectSnapCenters() {
        // Both centred on x=50 already; a y near-match snaps.
        let moving = BoundingBox(minX: 40, minY: 103, maxX: 60, maxY: 123)
        let stat = BoundingBox(minX: 0, minY: 100, maxX: 100, maxY: 100) // center y = 100
        let result = Snapping.snap(moving: moving, statics: [stat], threshold: 8)
        XCTAssertEqual(result.offsetY, -3, accuracy: 1e-9) // top 103 -> 100
    }

    func testNoSnapBeyondThreshold() {
        let moving = BoundingBox(minX: 200, minY: 200, maxX: 220, maxY: 220)
        let stat = BoundingBox(minX: 0, minY: 0, maxX: 20, maxY: 20)
        let result = Snapping.snap(moving: moving, statics: [stat], threshold: 8)
        XCTAssertEqual(result, .none)
    }
}
