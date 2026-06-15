import XCTest
@testable import ExcalidrawMath

/// Covers the branch-y edge cases of the primitives: degenerate intersections,
/// wrap-around ranges, tangent lines, and rounding modes.
final class MathEdgeCaseTests: XCTestCase {
    private let eps = ExcalidrawMath.precision

    func testParallelSegmentsReturnNil() {
        let a = LineSegment(Point(0, 0), Point(10, 0))
        let b = LineSegment(Point(0, 5), Point(10, 5))
        XCTAssertNil(a.intersection(with: b))
    }

    func testCollinearSegmentsReturnNil() {
        // Shared start point makes u == 0, which upstream treats as no intersection.
        let a = LineSegment(Point(0, 0), Point(10, 0))
        let b = LineSegment(Point(0, 0), Point(0, 10))
        XCTAssertNil(a.intersection(with: b))
    }

    func testLineIntersectionOutsideSegmentBounds() {
        // The infinite lines cross at (5,5) but that is off both short segments.
        let a = LineSegment(Point(0, 0), Point(1, 1))
        let b = LineSegment(Point(10, 0), Point(9, 1))
        XCTAssertNil(a.lineIntersection(with: b))
    }

    func testRangeOverlapWhenFirstStartsLater() {
        XCTAssertTrue(InclusiveRange(4, 6).overlaps(InclusiveRange(1, 5)))
        XCTAssertFalse(InclusiveRange(6, 8).overlaps(InclusiveRange(1, 4)))
    }

    func testEllipseTangentLineReturnsSinglePoint() {
        let circle = Ellipse(center: .zero, halfWidth: 10, halfHeight: 10)
        // Line y = 10 is tangent at (0, 10): the discriminant is zero.
        let points = circle.intersection(with: Line(Point(-100, 10), Point(100, 10)))
        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(points[0].x, 0, accuracy: 1e-3)
        XCTAssertEqual(points[0].y, 10, accuracy: 1e-3)
    }

    func testRoundToStepModes() {
        XCTAssertEqual(ExcalidrawMath.roundToStep(7, step: 5, mode: .floor), 5, accuracy: 1e-9)
        XCTAssertEqual(ExcalidrawMath.roundToStep(6, step: 5, mode: .ceil), 10, accuracy: 1e-9)
    }

    func testTrianglePointOnOppositeSides() {
        let t = Triangle(Point(0, 0), Point(10, 0), Point(5, 10))
        XCTAssertFalse(t.includes(Point(-5, 5)))
        XCTAssertFalse(t.includes(Point(20, 5)))
    }
}
