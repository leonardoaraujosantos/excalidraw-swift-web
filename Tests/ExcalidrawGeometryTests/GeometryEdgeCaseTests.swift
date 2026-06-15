import ExcalidrawMath
import ExcalidrawModel
import XCTest
@testable import ExcalidrawGeometry

final class GeometryEdgeCaseTests: XCTestCase {
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

    func testArrowAbsoluteCoordsFromPoints() {
        let arrow = element(.arrow(ArrowProperties(points: [Point(0, 0), Point(100, 40)])), x: 5, y: 5)
        let coords = ElementGeometry.absoluteCoords(arrow)
        XCTAssertEqual(coords.x1, 5)
        XCTAssertEqual(coords.y1, 5)
        XCTAssertEqual(coords.x2, 105)
        XCTAssertEqual(coords.y2, 45)
    }

    func testLineBoundsFromPoints() {
        let line = LinearProperties(points: [Point(0, 0), Point(100, 0), Point(100, 60), Point(0, 0)], polygon: true)
        let box = ElementGeometry.bounds(element(.line(line), x: 40, y: 200))
        XCTAssertEqual(box, BoundingBox(minX: 40, minY: 200, maxX: 140, maxY: 260))
    }

    func testRotatedArrowBounds() {
        // Points (0,0)->(100,0), center (50,0), rotated 90° => vertical segment.
        let arrow = element(.arrow(ArrowProperties(points: [Point(0, 0), Point(100, 0)])), angle: .pi / 2)
        let box = ElementGeometry.bounds(arrow)
        XCTAssertEqual(box.minX, 50, accuracy: eps)
        XCTAssertEqual(box.maxX, 50, accuracy: eps)
        XCTAssertEqual(box.minY, -50, accuracy: eps)
        XCTAssertEqual(box.maxY, 50, accuracy: eps)
    }

    func testRotatedFreedrawBounds() {
        let free = FreedrawProperties(points: [Point(0, 0), Point(100, 0)])
        let box = ElementGeometry.bounds(element(.freedraw(free), angle: .pi / 2))
        XCTAssertEqual(box.maxY - box.minY, 100, accuracy: eps)
        XCTAssertEqual(box.maxX - box.minX, 0, accuracy: eps)
    }

    func testEmbeddableAndIframeAreInsideDraggable() {
        XCTAssertTrue(HitTest.shouldTestInside(element(.embeddable, w: 100, h: 100)))
        XCTAssertTrue(HitTest.shouldTestInside(element(.iframe, w: 100, h: 100)))
    }

    func testSinglePointFreedrawDistanceAndHit() {
        let free = element(.freedraw(FreedrawProperties(points: [Point(0, 0)])), x: 10, y: 10)
        XCTAssertEqual(HitTest.distance(free, to: Point(13, 14)), 5, accuracy: eps)
        XCTAssertTrue(HitTest.hit(free, at: Point(13, 14), threshold: 10))
    }

    func testDiamondInteriorAndOutline() {
        let diamond = element(.diamond, x: 0, y: 0, w: 100, h: 100, bg: "#ff0000")
        XCTAssertTrue(HitTest.hit(diamond, at: Point(50, 50), threshold: 2)) // center is inside
        XCTAssertFalse(HitTest.hit(diamond, at: Point(5, 5), threshold: 2)) // corner is outside the diamond
        XCTAssertTrue(HitTest.hit(diamond, at: Point(25, 50), threshold: 4)) // near left vertex edge
    }
}
