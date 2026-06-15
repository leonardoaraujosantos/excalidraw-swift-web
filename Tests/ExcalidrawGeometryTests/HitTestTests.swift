import ExcalidrawMath
import ExcalidrawModel
import XCTest
@testable import ExcalidrawGeometry

final class HitTestTests: XCTestCase {
    private func element(
        _ kind: ElementKind, x: Double = 0, y: Double = 0,
        w: Double = 0, h: Double = 0, angle: Double = 0,
        bg: String = "transparent", boundElements: [BoundElement]? = nil
    ) -> ExcalidrawElement {
        var base = BaseProperties(id: "e")
        base.x = x; base.y = y; base.width = w; base.height = h; base.angle = angle
        base.backgroundColor = bg
        base.boundElements = boundElements
        return ExcalidrawElement(base: base, kind: kind)
    }

    private let filledRect = "#ff0000"

    func testShouldTestInside() {
        XCTAssertTrue(HitTest.shouldTestInside(element(.rectangle, w: 100, h: 100, bg: filledRect)))
        XCTAssertFalse(HitTest.shouldTestInside(element(.rectangle, w: 100, h: 100, bg: "transparent")))
        XCTAssertTrue(HitTest.shouldTestInside(element(.text(TextProperties()), w: 50, h: 20)))
        XCTAssertTrue(HitTest.shouldTestInside(element(.image(ImageProperties()), w: 50, h: 50)))
        XCTAssertFalse(HitTest.shouldTestInside(element(.arrow(ArrowProperties()), w: 100, h: 0)))
    }

    func testTransparentHexAlphaIsTransparent() {
        // 8-digit hex with 00 alpha counts as transparent → not inside-draggable.
        XCTAssertFalse(HitTest.shouldTestInside(element(.rectangle, w: 100, h: 100, bg: "#ff000000")))
    }

    func testFilledRectangleHit() {
        let rect = element(.rectangle, x: 0, y: 0, w: 100, h: 100, bg: filledRect)
        XCTAssertTrue(HitTest.hit(rect, at: Point(50, 50), threshold: 10)) // interior
        XCTAssertTrue(HitTest.hit(rect, at: Point(105, 50), threshold: 10)) // just outside edge, within threshold
        XCTAssertFalse(HitTest.hit(rect, at: Point(200, 50), threshold: 10)) // far away
    }

    func testTransparentRectangleHitsOnlyOutline() {
        let rect = element(.rectangle, x: 0, y: 0, w: 100, h: 100, bg: "transparent")
        XCTAssertFalse(HitTest.hit(rect, at: Point(50, 50), threshold: 10)) // interior is not a hit
        XCTAssertTrue(HitTest.hit(rect, at: Point(2, 50), threshold: 10)) // near left edge
    }

    func testEllipseHit() {
        let ellipse = element(.ellipse, x: 0, y: 0, w: 100, h: 100, bg: filledRect)
        XCTAssertTrue(HitTest.hit(ellipse, at: Point(50, 50), threshold: 5))
        XCTAssertFalse(HitTest.hit(ellipse, at: Point(95, 95), threshold: 5)) // corner outside circle
    }

    func testArrowHitOnLine() {
        let arrow = element(.arrow(ArrowProperties(points: [Point(0, 0), Point(100, 0)])), w: 100, h: 0)
        XCTAssertTrue(HitTest.hit(arrow, at: Point(50, 3), threshold: 10))
        XCTAssertFalse(HitTest.hit(arrow, at: Point(50, 30), threshold: 10))
    }

    func testRotatedRectangleInteriorHit() {
        // A point outside the axis-aligned box but inside the rotated rectangle.
        let rect = element(.rectangle, x: 0, y: 0, w: 100, h: 20, angle: .pi / 2, bg: filledRect)
        // Rotated 90° about center (50,10): occupies roughly x∈[40,60], y∈[-40,60].
        XCTAssertTrue(HitTest.hit(rect, at: Point(50, 50), threshold: 2))
        XCTAssertFalse(HitTest.hit(rect, at: Point(90, 10), threshold: 2))
    }

    func testClosedFreedrawIsInsideDraggable() {
        let loop = FreedrawProperties(points: [Point(0, 0), Point(50, 0), Point(50, 50), Point(0, 50), Point(0, 0)])
        let element = element(.freedraw(loop), w: 50, h: 50, bg: filledRect)
        XCTAssertTrue(HitTest.shouldTestInside(element))
        XCTAssertTrue(HitTest.isPointInside(element, point: Point(25, 25)))
    }

    func testBoundTextMakesShapeInsideDraggable() {
        let rect = element(
            .rectangle, w: 100, h: 100, bg: "transparent",
            boundElements: [BoundElement(id: "t", type: .text)]
        )
        XCTAssertTrue(HitTest.shouldTestInside(rect))
    }

    func testDistanceToRectangleOutline() {
        let rect = element(.rectangle, x: 0, y: 0, w: 100, h: 100)
        XCTAssertEqual(HitTest.distance(rect, to: Point(110, 50)), 10, accuracy: 1e-6)
    }
}
