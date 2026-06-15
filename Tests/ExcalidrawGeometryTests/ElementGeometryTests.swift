import ExcalidrawMath
import ExcalidrawModel
import XCTest
@testable import ExcalidrawGeometry

final class ElementGeometryTests: XCTestCase {
    private let eps = 1e-6

    private func element(
        _ kind: ElementKind, x: Double = 0, y: Double = 0,
        w: Double = 0, h: Double = 0, angle: Double = 0, bg: String = "transparent"
    ) -> ExcalidrawElement {
        var base = BaseProperties(id: "e")
        base.x = x; base.y = y; base.width = w; base.height = h; base.angle = angle
        base.backgroundColor = bg
        return ExcalidrawElement(base: base, kind: kind)
    }

    func testRectangleBounds() {
        let box = ElementGeometry.bounds(element(.rectangle, x: 10, y: 20, w: 100, h: 40))
        XCTAssertEqual(box, BoundingBox(minX: 10, minY: 20, maxX: 110, maxY: 60))
    }

    func testRotatedRectangleBounds() {
        // 100x40 rectangle rotated 90° about its center becomes 40x100.
        let box = ElementGeometry.bounds(element(.rectangle, x: 10, y: 20, w: 100, h: 40, angle: .pi / 2))
        XCTAssertEqual(box.minX, 40, accuracy: eps)
        XCTAssertEqual(box.maxX, 80, accuracy: eps)
        XCTAssertEqual(box.minY, -10, accuracy: eps)
        XCTAssertEqual(box.maxY, 90, accuracy: eps)
    }

    func testNonRotatedFlagIgnoresAngle() {
        let box = ElementGeometry.bounds(
            element(.rectangle, x: 0, y: 0, w: 100, h: 40, angle: .pi / 4), nonRotated: true
        )
        XCTAssertEqual(box, BoundingBox(minX: 0, minY: 0, maxX: 100, maxY: 40))
    }

    func testEllipseRotatedBoundsSwapAxes() {
        let box = ElementGeometry.bounds(element(.ellipse, x: 0, y: 0, w: 100, h: 40, angle: .pi / 2))
        XCTAssertEqual(box.maxX - box.minX, 40, accuracy: eps)
        XCTAssertEqual(box.maxY - box.minY, 100, accuracy: eps)
    }

    func testDiamondBoundsMatchBox() {
        let box = ElementGeometry.bounds(element(.diamond, x: 0, y: 0, w: 80, h: 60))
        XCTAssertEqual(box, BoundingBox(minX: 0, minY: 0, maxX: 80, maxY: 60))
    }

    func testFreedrawBoundsFromPoints() {
        let free = FreedrawProperties(points: [Point(0, 0), Point(30, 10), Point(10, 40)])
        let box = ElementGeometry.bounds(element(.freedraw(free), x: 5, y: 5))
        XCTAssertEqual(box, BoundingBox(minX: 5, minY: 5, maxX: 35, maxY: 45))
    }

    func testCommonBounds() {
        let a = element(.rectangle, x: 0, y: 0, w: 10, h: 10)
        let b = element(.rectangle, x: 20, y: 20, w: 10, h: 10)
        XCTAssertEqual(ElementGeometry.commonBounds([a, b]), BoundingBox(minX: 0, minY: 0, maxX: 30, maxY: 30))
        XCTAssertNil(ElementGeometry.commonBounds([]))
    }

    func testAbsoluteCoordsCenter() {
        let coords = ElementGeometry.absoluteCoords(element(.rectangle, x: 10, y: 10, w: 100, h: 20))
        XCTAssertEqual(coords.cx, 60)
        XCTAssertEqual(coords.cy, 20)
    }
}
