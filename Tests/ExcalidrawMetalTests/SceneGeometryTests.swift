import ExcalidrawMath
import ExcalidrawModel
import ExcalidrawRender
import XCTest
@testable import ExcalidrawMetal

/// Pure-logic coverage for the scene → triangle builder: fills, arrowheads,
/// rotation, opacity and theming, none of which need a GPU.
final class SceneGeometryTests: XCTestCase {
    private func base(_ id: String, _ x: Double, _ y: Double, _ w: Double, _ h: Double) -> BaseProperties {
        var b = BaseProperties(id: id); b.x = x; b.y = y; b.width = w; b.height = h; b.seed = 7
        b.strokeColor = "#1e1e1e"
        return b
    }

    private func geometry(_ elements: [ExcalidrawElement], theme: Theme = .light) -> SceneGeometry {
        SceneGeometry(scene: Scene(elements: elements), theme: theme)
    }

    func testSolidFillEmitsTriangles() {
        var rect = base("r", 10, 10, 100, 60)
        rect.backgroundColor = "#ffc9c9"; rect.fillStyle = .solid
        let g = geometry([ExcalidrawElement(base: rect, kind: .rectangle)])
        XCTAssertGreaterThan(g.triangleCount, 0)
        XCTAssertTrue(g.handledIDs.contains("r"))
    }

    func testHachureFillEmitsStrokeTriangles() {
        var rect = base("r", 10, 10, 100, 60)
        rect.backgroundColor = "#ffc9c9"; rect.fillStyle = .hachure
        let g = geometry([ExcalidrawElement(base: rect, kind: .rectangle)])
        XCTAssertGreaterThan(g.triangleCount, 0)
    }

    func testTransparentFillEmitsOnlyStroke() {
        var rect = base("r", 10, 10, 100, 60)
        rect.backgroundColor = "transparent"
        let filled = geometry([ExcalidrawElement(base: { var b = rect; b.backgroundColor = "#a5d8ff"
            b.fillStyle = .solid; return b
        }(), kind: .rectangle)])
        let strokeOnly = geometry([ExcalidrawElement(base: rect, kind: .rectangle)])
        XCTAssertGreaterThan(filled.triangleCount, strokeOnly.triangleCount)
    }

    func testTransparentStrokeEmitsNothingForStrokeOnlyShape() {
        var rect = base("r", 10, 10, 100, 60)
        rect.strokeColor = "transparent"; rect.backgroundColor = "transparent"
        let g = geometry([ExcalidrawElement(base: rect, kind: .rectangle)])
        XCTAssertTrue(g.isEmpty)
        // Still recorded as handled so the CG overlay doesn't double-draw it.
        XCTAssertTrue(g.handledIDs.contains("r"))
    }

    func testArrowWithTriangleAndLineArrowheads() {
        let triangleHead = ArrowProperties(
            points: [Point(0, 0), Point(100, 0)], startArrowhead: .arrow, endArrowhead: .triangle
        )
        let g = geometry([ExcalidrawElement(base: base("a", 20, 20, 100, 0), kind: .arrow(triangleHead))])
        XCTAssertGreaterThan(g.triangleCount, 0)
        XCTAssertTrue(g.handledIDs.contains("a"))
    }

    func testRotationTransformMovesVertices() {
        var rect = base("r", 0, 0, 100, 100)
        let upright = geometry([ExcalidrawElement(base: rect, kind: .rectangle)])
        rect.angle = .pi / 4
        let rotated = geometry([ExcalidrawElement(base: rect, kind: .rectangle)])
        XCTAssertEqual(upright.vertices.count, rotated.vertices.count)
        XCTAssertNotEqual(upright.vertices, rotated.vertices, "rotation must change vertex positions")
    }

    func testElementTransformRotatesAboutCentre() {
        var b = base("r", 0, 0, 100, 100); b.angle = .pi / 2 // 90° about the centre (50,50)
        let transform = SceneGeometry.elementTransform(b)
        let mapped = transform(Point(0, 0)) // top-left → top-right after a 90° turn
        XCTAssertEqual(mapped.x, 100, accuracy: 1e-6)
        XCTAssertEqual(mapped.y, 0, accuracy: 1e-6)
    }

    func testOpacityScalesAlpha() {
        var rect = base("r", 0, 0, 100, 60); rect.backgroundColor = "#a5d8ff"; rect.fillStyle = .solid
        rect.opacity = 50
        let g = geometry([ExcalidrawElement(base: rect, kind: .rectangle)])
        // Alpha is the 6th float of each vertex; with 50% opacity it must be ~0.5.
        let alphas = stride(from: 5, to: g.vertices.count, by: 6).map { g.vertices[$0] }
        XCTAssertFalse(alphas.isEmpty)
        XCTAssertEqual(alphas.max() ?? 1, 0.5, accuracy: 0.02)
    }

    func testDarkThemeChangesColors() {
        var rect = base("r", 0, 0, 100, 60); rect.backgroundColor = "#a5d8ff"; rect.fillStyle = .solid
        let light = geometry([ExcalidrawElement(base: rect, kind: .rectangle)], theme: .light)
        let dark = geometry([ExcalidrawElement(base: rect, kind: .rectangle)], theme: .dark)
        XCTAssertNotEqual(light.vertices, dark.vertices)
    }

    func testLinePolygonIsTessellated() {
        let line = LinearProperties(points: [Point(0, 0), Point(100, 0), Point(100, 50)], polygon: true)
        let g = geometry([ExcalidrawElement(base: base("l", 0, 0, 100, 50), kind: .line(line))])
        XCTAssertGreaterThan(g.triangleCount, 0)
    }
}
