import ExcalidrawMath
import ExcalidrawModel
import XCTest
@testable import ExcalidrawRender

final class SVGExportTests: XCTestCase {
    private func base(_ id: String, x: Double, y: Double, w: Double, h: Double) -> BaseProperties {
        var b = BaseProperties(id: id); b.x = x; b.y = y; b.width = w; b.height = h; b.seed = 1
        return b
    }

    func testEmptySceneSVG() {
        let svg = SVGExporter.svg(Scene())
        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("width=\"0\""))
    }

    func testRectangleSVGHasDimensionsAndPath() {
        let scene = Scene(elements: [ExcalidrawElement(base: base("r", x: 30, y: 30, w: 100, h: 60), kind: .rectangle)])
        let svg = SVGExporter.svg(scene, padding: 10)
        XCTAssertTrue(svg.contains("<svg"))
        // (content 100x60) + 2*padding(10) = 120 x 80.
        XCTAssertTrue(svg.contains("width=\"120.00\""))
        XCTAssertTrue(svg.contains("height=\"80.00\""))
        XCTAssertTrue(svg.contains("<path"))
        XCTAssertTrue(svg.contains("stroke=\"#1e1e1e\""))
    }

    func testFilledRectangleSVGHasFill() {
        var b = base("r", x: 0, y: 0, w: 50, h: 50)
        b.backgroundColor = "#ff0000"; b.fillStyle = .solid
        let svg = SVGExporter.svg(Scene(elements: [ExcalidrawElement(base: b, kind: .rectangle)]))
        XCTAssertTrue(svg.contains("fill=\"#ff0000\""))
    }

    func testTextSVGEmitsTextElement() {
        let b = base("t", x: 0, y: 0, w: 80, h: 25)
        let text = TextProperties(fontSize: 20, text: "Hi <there>")
        let svg = SVGExporter.svg(Scene(elements: [ExcalidrawElement(base: b, kind: .text(text))]))
        XCTAssertTrue(svg.contains("<text"))
        XCTAssertTrue(svg.contains("Hi &lt;there&gt;")) // XML-escaped
    }

    func testRotatedElementHasRotateTransform() {
        var b = base("r", x: 0, y: 0, w: 40, h: 40); b.angle = .pi / 2
        let svg = SVGExporter.svg(Scene(elements: [ExcalidrawElement(base: b, kind: .rectangle)]))
        XCTAssertTrue(svg.contains("rotate("))
    }

    func testFreedrawSVGEmitsFilledPath() {
        let b = base("f", x: 0, y: 0, w: 40, h: 30)
        let free = FreedrawProperties(
            points: [Point(0, 0), Point(20, 15), Point(40, 0)], pressures: [0.5, 0.6, 0.5], simulatePressure: false
        )
        let svg = SVGExporter.svg(Scene(elements: [ExcalidrawElement(base: b, kind: .freedraw(free))]))
        XCTAssertTrue(svg.contains("<path"))
    }
}
