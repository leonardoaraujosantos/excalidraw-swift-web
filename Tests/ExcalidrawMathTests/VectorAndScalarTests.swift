import XCTest
@testable import ExcalidrawMath

final class VectorTests: XCTestCase {
    private let eps = ExcalidrawMath.precision

    func testFromPoints() {
        XCTAssertEqual(Vector(from: Point(4, 6), origin: Point(1, 2)), Vector(3, 4))
    }

    func testArithmeticAndScale() {
        XCTAssertEqual(Vector(1, 2) + Vector(3, 4), Vector(4, 6))
        XCTAssertEqual(Vector(5, 5) - Vector(2, 1), Vector(3, 4))
        XCTAssertEqual(Vector(2, 3).scaled(by: 2), Vector(4, 6))
    }

    func testDotAndCross() {
        XCTAssertEqual(Vector(1, 0).dot(Vector(0, 1)), 0)
        XCTAssertEqual(Vector(2, 3).dot(Vector(4, 5)), 23)
        XCTAssertEqual(Vector(1, 0).cross(Vector(0, 1)), 1)
    }

    func testMagnitudeAndNormalize() {
        XCTAssertEqual(Vector(3, 4).magnitude, 5, accuracy: eps)
        XCTAssertEqual(Vector(3, 4).magnitudeSquared, 25)
        let n = Vector(0, 5).normalized()
        XCTAssertEqual(n, Vector(0, 1))
        XCTAssertEqual(Vector.zero.normalized(), .zero)
    }

    func testNormalAndPoint() {
        XCTAssertEqual(Vector(1, 0).normal(), Vector(0, -1))
        XCTAssertEqual(Vector(2, 3).point(offset: Point(1, 1)), Point(3, 4))
    }
}

final class AngleTests: XCTestCase {
    private let eps = ExcalidrawMath.precision

    func testNormalizeRadians() {
        XCTAssertEqual(Angle.normalizeRadians(-.pi / 2), 1.5 * .pi, accuracy: eps)
        XCTAssertEqual(Angle.normalizeRadians(2.5 * .pi), 0.5 * .pi, accuracy: eps)
    }

    func testDegreeRadianConversion() {
        XCTAssertEqual(Angle.degreesToRadians(180), .pi, accuracy: eps)
        XCTAssertEqual(Angle.radiansToDegrees(.pi), 180, accuracy: eps)
    }

    func testCartesianToPolar() {
        let polar = Angle.cartesianToPolar(Point(0, 1))
        XCTAssertEqual(polar.radius, 1, accuracy: eps)
        XCTAssertEqual(polar.angle, .pi / 2, accuracy: eps)
    }

    func testIsRightAngle() {
        XCTAssertTrue(Angle.isRightAngle(.pi / 2))
        XCTAssertFalse(Angle.isRightAngle(.pi / 3))
    }

    func testRadiansBetween() {
        XCTAssertTrue(Angle.radiansBetween(.pi / 2, min: 0, max: .pi))
        XCTAssertFalse(Angle.radiansBetween(1.5 * .pi, min: 0, max: .pi))
        // Wrap-around range.
        XCTAssertTrue(Angle.radiansBetween(0, min: 1.5 * .pi, max: 0.5 * .pi))
    }

    func testRadiansDifference() {
        XCTAssertEqual(Angle.radiansDifference(0.1, 6.2), 0.183_185, accuracy: 1e-3)
        XCTAssertEqual(Angle.radiansDifference(.pi, 0), .pi, accuracy: eps)
    }
}

final class ScalarUtilsTests: XCTestCase {
    func testClamp() {
        XCTAssertEqual(ExcalidrawMath.clamp(5, min: 0, max: 10), 5)
        XCTAssertEqual(ExcalidrawMath.clamp(-1, min: 0, max: 10), 0)
        XCTAssertEqual(ExcalidrawMath.clamp(11, min: 0, max: 10), 10)
    }

    func testRound() {
        XCTAssertEqual(ExcalidrawMath.round(3.14159, precision: 2), 3.14, accuracy: 1e-9)
        XCTAssertEqual(ExcalidrawMath.round(3.7, precision: 0, mode: .floor), 3, accuracy: 1e-9)
        XCTAssertEqual(ExcalidrawMath.round(3.1, precision: 0, mode: .ceil), 4, accuracy: 1e-9)
    }

    func testRoundToStep() {
        XCTAssertEqual(ExcalidrawMath.roundToStep(7, step: 5), 5, accuracy: 1e-9)
        XCTAssertEqual(ExcalidrawMath.roundToStep(8, step: 5), 10, accuracy: 1e-9)
    }

    func testAverageAndIsCloseTo() {
        XCTAssertEqual(ExcalidrawMath.average(2, 4), 3)
        XCTAssertTrue(ExcalidrawMath.isCloseTo(1.0, 1.0 + 1e-6))
        XCTAssertFalse(ExcalidrawMath.isCloseTo(1.0, 1.1))
    }
}

final class InclusiveRangeTests: XCTestCase {
    func testOverlaps() {
        XCTAssertTrue(InclusiveRange(1, 3).overlaps(InclusiveRange(2, 4)))
        XCTAssertFalse(InclusiveRange(1, 3).overlaps(InclusiveRange(4, 5)))
    }

    func testIntersection() {
        XCTAssertEqual(InclusiveRange(1, 3).intersection(InclusiveRange(2, 4)), InclusiveRange(2, 3))
        XCTAssertNil(InclusiveRange(1, 2).intersection(InclusiveRange(3, 4)))
    }

    func testIncludes() {
        XCTAssertTrue(InclusiveRange(0, 10).includes(5))
        XCTAssertFalse(InclusiveRange(0, 10).includes(11))
    }
}
