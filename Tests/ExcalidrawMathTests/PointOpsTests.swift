import XCTest
@testable import ExcalidrawMath

final class PointOpsTests: XCTestCase {
    private let eps = ExcalidrawMath.precision

    func testRotate90AroundOrigin() {
        let rotated = Point(1, 0).rotated(around: .zero, by: .pi / 2)
        XCTAssertEqual(rotated.x, 0, accuracy: eps)
        XCTAssertEqual(rotated.y, 1, accuracy: eps)
    }

    func testRotateZeroIsIdentity() {
        XCTAssertEqual(Point(3, 7).rotated(around: Point(1, 1), by: 0), Point(3, 7))
    }

    func testRotateAroundCenter() {
        let rotated = Point(2, 1).rotated(around: Point(1, 1), by: .pi)
        XCTAssertEqual(rotated.x, 0, accuracy: eps)
        XCTAssertEqual(rotated.y, 1, accuracy: eps)
    }

    func testTranslate() {
        XCTAssertEqual(Point(1, 2).translated(by: Vector(3, -1)), Point(4, 1))
    }

    func testMidpoint() {
        XCTAssertEqual(Point(0, 0).midpoint(to: Point(4, 6)), Point(2, 3))
    }

    func testDistanceSquared() {
        XCTAssertEqual(Point(0, 0).distanceSquared(to: Point(3, 4)), 25)
    }

    func testScaleFromOrigin() {
        XCTAssertEqual(Point(2, 2).scaled(from: .zero, by: 2), Point(4, 4))
        XCTAssertEqual(Point(3, 3).scaled(from: Point(1, 1), by: 2), Point(5, 5))
    }

    func testIsWithinBounds() {
        XCTAssertTrue(Point(2, 2).isWithin(Point(0, 0), Point(4, 4)))
        XCTAssertFalse(Point(5, 2).isWithin(Point(0, 0), Point(4, 4)))
    }

    func testApproximateEquality() {
        XCTAssertTrue(Point(1, 1).isApproximatelyEqual(to: Point(1 + eps / 2, 1)))
        XCTAssertFalse(Point(1, 1).isApproximatelyEqual(to: Point(1.01, 1)))
    }
}
