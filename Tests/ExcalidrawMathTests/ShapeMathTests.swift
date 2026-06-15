import XCTest
@testable import ExcalidrawMath

final class LineAndSegmentTests: XCTestCase {
    private let eps = ExcalidrawMath.precision

    func testLineIntersection() {
        let a = Line(Point(0, 0), Point(2, 2))
        let b = Line(Point(0, 2), Point(2, 0))
        let p = a.intersection(with: b)
        XCTAssertEqual(p?.x ?? .nan, 1, accuracy: eps)
        XCTAssertEqual(p?.y ?? .nan, 1, accuracy: eps)
    }

    func testParallelLinesDoNotIntersect() {
        XCTAssertNil(Line(Point(0, 0), Point(1, 0)).intersection(with: Line(Point(0, 1), Point(1, 1))))
    }

    func testDistanceToSegment() {
        let segment = LineSegment(Point(0, 0), Point(10, 0))
        XCTAssertEqual(segment.distance(to: Point(5, 3)), 3, accuracy: eps)
        XCTAssertEqual(segment.distance(to: Point(-5, 0)), 5, accuracy: eps) // beyond endpoint
    }

    func testSegmentContains() {
        let segment = LineSegment(Point(0, 0), Point(10, 0))
        XCTAssertTrue(segment.contains(Point(5, 0)))
        XCTAssertFalse(segment.contains(Point(5, 1)))
    }

    func testSegmentsIntersect() {
        let a = LineSegment(Point(0, 0), Point(10, 10))
        let b = LineSegment(Point(0, 10), Point(10, 0))
        let p = a.intersection(with: b)
        XCTAssertEqual(p?.x ?? .nan, 5, accuracy: eps)
        XCTAssertEqual(p?.y ?? .nan, 5, accuracy: eps)
    }

    func testNonCrossingSegmentsReturnNil() {
        let a = LineSegment(Point(0, 0), Point(1, 0))
        let b = LineSegment(Point(0, 5), Point(1, 5))
        XCTAssertNil(a.intersection(with: b))
    }

    func testSegmentDistanceBetween() {
        let a = LineSegment(Point(0, 0), Point(10, 0))
        let b = LineSegment(Point(0, 4), Point(10, 4))
        XCTAssertEqual(a.distance(to: b), 4, accuracy: eps)
        // Crossing segments have distance 0.
        let c = LineSegment(Point(5, -5), Point(5, 5))
        XCTAssertEqual(a.distance(to: c), 0, accuracy: eps)
    }
}

final class TriangleAndRectangleTests: XCTestCase {
    func testTriangleIncludes() {
        let t = Triangle(Point(0, 0), Point(10, 0), Point(0, 10))
        XCTAssertTrue(t.includes(Point(2, 2)))
        XCTAssertFalse(t.includes(Point(8, 8)))
    }

    func testRectangleIntersectsSegment() {
        let rect = Rectangle(minX: 0, minY: 0, maxX: 10, maxY: 10)
        let crossing = rect.intersection(with: LineSegment(Point(-5, 5), Point(15, 5)))
        XCTAssertEqual(crossing.count, 2)
    }

    func testRectangleIntersectsRectangle() {
        let a = Rectangle(minX: 0, minY: 0, maxX: 10, maxY: 10)
        XCTAssertTrue(a.intersects(Rectangle(minX: 5, minY: 5, maxX: 15, maxY: 15)))
        XCTAssertFalse(a.intersects(Rectangle(minX: 20, minY: 20, maxX: 30, maxY: 30)))
    }
}

final class PolygonTests: XCTestCase {
    private let square = Polygon([Point(0, 0), Point(10, 0), Point(10, 10), Point(0, 10)])

    func testIncludes() {
        XCTAssertTrue(square.includes(Point(5, 5)))
        XCTAssertFalse(square.includes(Point(15, 5)))
    }

    func testIncludesNonZero() {
        XCTAssertTrue(square.includesNonZero(Point(5, 5)))
        XCTAssertFalse(square.includesNonZero(Point(-1, 5)))
    }

    func testPointOnEdge() {
        XCTAssertTrue(square.contains(Point(5, 0)))
        XCTAssertFalse(square.contains(Point(5, 5)))
    }

    func testAutoCloses() {
        XCTAssertEqual(square.points.first, square.points.last)
    }
}

final class EllipseAndCurveTests: XCTestCase {
    private let eps = ExcalidrawMath.precision
    private let circle = Ellipse(center: .zero, halfWidth: 10, halfHeight: 10)

    func testIncludes() {
        XCTAssertTrue(circle.includes(Point(5, 0)))
        XCTAssertFalse(circle.includes(Point(11, 0)))
    }

    func testDistanceFromPoint() {
        XCTAssertEqual(circle.distance(from: Point(20, 0)), 10, accuracy: 1e-3)
        XCTAssertTrue(circle.touches(Point(10, 0), threshold: 1e-2))
    }

    func testSegmentIntersection() {
        let points = circle.intersection(with: LineSegment(Point(-100, 0), Point(100, 0)))
        XCTAssertEqual(points.count, 2)
        let xs = points.map(\.x).sorted()
        XCTAssertEqual(xs.first ?? .nan, -10, accuracy: eps)
        XCTAssertEqual(xs.last ?? .nan, 10, accuracy: eps)
    }

    func testLineIntersection() {
        let points = circle.intersection(with: Line(Point(-100, 0), Point(100, 0)))
        XCTAssertEqual(points.count, 2)
    }

    func testCurveEvaluation() {
        let curve = Curve(Point(0, 0), Point(0, 10), Point(10, 10), Point(10, 0))
        XCTAssertEqual(curve.point(at: 0), Point(0, 0))
        XCTAssertEqual(curve.point(at: 1), Point(10, 0))
        let mid = curve.point(at: 0.5)
        XCTAssertEqual(mid.x, 5, accuracy: eps)
        XCTAssertEqual(mid.y, 7.5, accuracy: eps)
    }

    func testCurveTangent() {
        let curve = Curve(Point(0, 0), Point(1, 0), Point(2, 0), Point(3, 0))
        // A straight horizontal curve has a horizontal tangent.
        XCTAssertEqual(curve.tangent(at: 0.5).v, 0, accuracy: eps)
        XCTAssertGreaterThan(curve.tangent(at: 0.5).u, 0)
    }
}
