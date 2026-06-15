import ExcalidrawMath
import XCTest
@testable import RoughKit

final class RoughShapesTests: XCTestCase {
    private let gen = RoughGenerator()

    private func options(seed: Int = 1, fill: String? = nil, style: String = "hachure") -> RoughOptions {
        var o = RoughOptions()
        o.seed = seed
        o.fill = fill
        o.fillStyle = style
        return o
    }

    // MARK: Ellipse

    func testEllipseIsDeterministicAndBounded() {
        let a = gen.ellipse(x: 0, y: 0, width: 100, height: 60, options: options(seed: 7))
        let b = gen.ellipse(x: 0, y: 0, width: 100, height: 60, options: options(seed: 7))
        XCTAssertEqual(a.drawable, b.drawable)
        XCTAssertFalse(a.drawable.sets[0].ops.isEmpty)
        XCTAssertFalse(a.estimatedPoints.isEmpty)
        for p in a.estimatedPoints {
            XCTAssertLessThan(abs(p.x), 60)
            XCTAssertLessThan(abs(p.y), 40)
        }
    }

    func testEllipseDifferentSeedsDiffer() {
        let a = gen.ellipse(x: 0, y: 0, width: 100, height: 60, options: options(seed: 1)).drawable
        let b = gen.ellipse(x: 0, y: 0, width: 100, height: 60, options: options(seed: 2)).drawable
        XCTAssertNotEqual(a, b)
    }

    func testEllipseStrokeOnlyHasSinglePathSet() {
        let drawable = gen.ellipse(x: 0, y: 0, width: 80, height: 80, options: options()).drawable
        XCTAssertEqual(drawable.sets.count, 1)
        XCTAssertEqual(drawable.sets[0].type, .path)
    }

    // MARK: Curve

    func testCurveDeterministicAndStartsWithMove() {
        let pts = [Point(0, 0), Point(30, 40), Point(70, 10), Point(100, 50)]
        let a = gen.curve(pts, options: options(seed: 3))
        let b = gen.curve(pts, options: options(seed: 3))
        XCTAssertEqual(a, b)
        if case .move = a.sets[0].ops.first {} else { XCTFail("curve should start with a move op") }
    }

    // MARK: Fills

    func testSolidFillProducesFillPath() {
        let rect = gen.rectangle(x: 0, y: 0, width: 50, height: 50, options: options(fill: "#f00", style: "solid"))
        XCTAssertEqual(rect.sets.count, 2)
        XCTAssertEqual(rect.sets[0].type, .fillPath)
        XCTAssertEqual(rect.sets[1].type, .path)
    }

    func testHachureFillProducesSketchLines() {
        let rect = gen.rectangle(x: 0, y: 0, width: 50, height: 50, options: options(fill: "#f00", style: "hachure"))
        XCTAssertEqual(rect.sets[0].type, .fillSketch)
        XCTAssertFalse(rect.sets[0].ops.isEmpty)
    }

    func testCrossHatchHasMoreLinesThanHachure() {
        let hachure = gen.rectangle(x: 0, y: 0, width: 80, height: 80, options: options(fill: "#f00"))
        let cross = gen.rectangle(
            x: 0, y: 0, width: 80, height: 80, options: options(fill: "#f00", style: "cross-hatch")
        )
        XCTAssertGreaterThan(cross.sets[0].ops.count, hachure.sets[0].ops.count)
    }

    func testZigzagFillProducesSketch() {
        let rect = gen.rectangle(x: 0, y: 0, width: 60, height: 60, options: options(fill: "#f00", style: "zigzag"))
        XCTAssertEqual(rect.sets[0].type, .fillSketch)
        XCTAssertFalse(rect.sets[0].ops.isEmpty)
    }

    func testNoFillWhenFillColorNil() {
        let rect = gen.rectangle(x: 0, y: 0, width: 50, height: 50, options: options(fill: nil))
        XCTAssertEqual(rect.sets.count, 1)
        XCTAssertEqual(rect.sets[0].type, .path)
    }

    func testHachureLinesStayWithinPolygon() {
        // Fill lines for a rectangle should not extend far outside it.
        let rect = gen.rectangle(x: 0, y: 0, width: 100, height: 100, options: options(fill: "#f00", style: "hachure"))
        let pts = rect.sets[0].ops.flatMap { op -> [Point] in
            if case let .bcurveTo(_, _, e) = op { return [e] }
            if case let .move(p) = op { return [p] }
            return []
        }
        for p in pts {
            XCTAssertGreaterThan(p.x, -15)
            XCTAssertLessThan(p.x, 115)
        }
    }
}
