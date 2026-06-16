import XCTest
@testable import ExcalidrawMath

final class CurveMathTests: XCTestCase {
    /// Independent reference: arc length by fine-grained polyline sampling.
    private func sampledLength(_ c: Curve, steps: Int = 20000) -> Double {
        var total = 0.0
        var prev = c.point(at: 0)
        for i in 1 ... steps {
            let cur = c.point(at: Double(i) / Double(steps))
            total += prev.distance(to: cur)
            prev = cur
        }
        return total
    }

    func testStraightCurveLengthIsExact() {
        // Collinear, evenly spaced control points → a straight segment of length 3.
        let c = Curve(Point(0, 0), Point(1, 0), Point(2, 0), Point(3, 0))
        XCTAssertEqual(c.length, 3, accuracy: 1e-9)
    }

    func testCurvedLengthMatchesSampledReference() {
        let c = Curve(Point(0, 0), Point(0, 10), Point(10, 10), Point(10, 0))
        XCTAssertEqual(c.length, sampledLength(c), accuracy: 1e-4)
    }

    func testPartialLengthEndpointsAndMonotonic() {
        let c = Curve(Point(0, 0), Point(0, 10), Point(10, 10), Point(10, 0))
        XCTAssertEqual(c.length(at: 0), 0, accuracy: 1e-12)
        XCTAssertEqual(c.length(at: 1), c.length, accuracy: 1e-9)
        let quarter = c.length(at: 0.25)
        let half = c.length(at: 0.5)
        XCTAssertGreaterThan(half, quarter)
        XCTAssertLessThan(half, c.length)
    }

    func testPointAtLengthEndpointsAndMidpoint() {
        let c = Curve(Point(0, 0), Point(0, 10), Point(10, 10), Point(10, 0))
        XCTAssertEqual(c.point(atLength: 0), c.point(at: 0))
        XCTAssertEqual(c.point(atLength: 1), c.point(at: 1))
        // Half the arc length should land at the symmetric midpoint x = 5.
        XCTAssertEqual(c.point(atLength: 0.5).x, 5, accuracy: 1e-3)
    }

    func testIntersectionWithCrossingSegment() {
        let c = Curve(Point(0, 0), Point(0, 10), Point(10, 10), Point(10, 0))
        let segment = LineSegment(Point(-5, 5), Point(15, 5))
        let hits = c.intersections(with: segment)
        XCTAssertEqual(hits.count, 1)
        // The found point lies on the line (y = 5) and within the curve's span.
        XCTAssertEqual(hits[0].y, 5, accuracy: 1e-2)
        XCTAssertTrue(hits[0].x >= 0 && hits[0].x <= 10)
    }

    func testNoIntersectionWhenSegmentIsFarAway() {
        let c = Curve(Point(0, 0), Point(0, 10), Point(10, 10), Point(10, 0))
        let segment = LineSegment(Point(-5, 100), Point(15, 100))
        XCTAssertTrue(c.intersections(with: segment).isEmpty)
    }

    func testClosestPointOnStraightCurve() {
        let c = Curve(Point(0, 0), Point(1, 0), Point(2, 0), Point(3, 0))
        let closest = c.closestPoint(to: Point(1.5, 5))
        XCTAssertEqual(closest.x, 1.5, accuracy: 1e-2)
        XCTAssertEqual(closest.y, 0, accuracy: 1e-2)
    }

    func testDistanceToCurve() {
        let c = Curve(Point(0, 0), Point(1, 0), Point(2, 0), Point(3, 0))
        XCTAssertEqual(c.distance(to: Point(1.5, 4)), 4, accuracy: 1e-2)
    }
}
