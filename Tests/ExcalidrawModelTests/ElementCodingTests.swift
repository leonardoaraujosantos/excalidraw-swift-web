import ExcalidrawMath
import XCTest
@testable import ExcalidrawModel

final class ElementCodingTests: XCTestCase {
    private func assertRoundTrips(_ element: ExcalidrawElement, line: UInt = #line) throws {
        let data = try JSONEncoder().encode(element)
        let decoded = try JSONDecoder().decode(ExcalidrawElement.self, from: data)
        XCTAssertEqual(element, decoded, "element did not round-trip", line: line)
        XCTAssertEqual(decoded.type, element.kind.typeName, line: line)
    }

    func testGenericShapesRoundTrip() throws {
        for kind in [ElementKind.rectangle, .diamond, .ellipse, .selection, .embeddable, .iframe] {
            try assertRoundTrips(ExcalidrawElement(base: BaseProperties(id: "g"), kind: kind))
        }
    }

    func testTextRoundTrips() throws {
        let text = TextProperties(
            fontSize: 28, fontFamily: FontFamily.virgil, text: "Hi\nthere",
            textAlign: .center, verticalAlign: .middle, containerId: "rect-1",
            originalText: "Hi\nthere", autoResize: false, lineHeight: 1.2
        )
        try assertRoundTrips(ExcalidrawElement(base: BaseProperties(id: "t"), kind: .text(text)))
    }

    func testFreedrawRoundTrips() throws {
        let free = FreedrawProperties(
            points: [Point(0, 0), Point(3, 4), Point(10, 2)],
            pressures: [0.1, 0.5, 0.9], simulatePressure: false
        )
        try assertRoundTrips(ExcalidrawElement(base: BaseProperties(id: "f"), kind: .freedraw(free)))
    }

    func testLineWithArrowheadsRoundTrips() throws {
        let line = LinearProperties(
            points: [Point(0, 0), Point(50, 0)],
            startArrowhead: .dot, endArrowhead: .triangleOutline, polygon: true
        )
        try assertRoundTrips(ExcalidrawElement(base: BaseProperties(id: "l"), kind: .line(line)))
    }

    func testBoundArrowRoundTrips() throws {
        let arrow = ArrowProperties(
            points: [Point(0, 0), Point(20, 20)],
            startBinding: FixedPointBinding(elementId: "a", fixedPoint: Point(0.5, 0.5), mode: .inside),
            endBinding: FixedPointBinding(elementId: "b", fixedPoint: Point(0, 1), mode: .orbit),
            endArrowhead: .arrow, elbowed: false
        )
        try assertRoundTrips(ExcalidrawElement(base: BaseProperties(id: "ar"), kind: .arrow(arrow)))
    }

    func testElbowArrowRoundTrips() throws {
        let arrow = ArrowProperties(
            points: [Point(0, 0), Point(20, 0), Point(20, 20)],
            elbowed: true,
            fixedSegments: [FixedSegment(start: Point(20, 0), end: Point(20, 20), index: 1)],
            startIsSpecial: false, endIsSpecial: true
        )
        try assertRoundTrips(ExcalidrawElement(base: BaseProperties(id: "el"), kind: .arrow(arrow)))
    }

    func testImageRoundTrips() throws {
        let image = ImageProperties(
            fileId: "file-1", status: .saved, scale: Point(-1, 1),
            crop: ImageCrop(x: 1, y: 2, width: 3, height: 4, naturalWidth: 5, naturalHeight: 6)
        )
        try assertRoundTrips(ExcalidrawElement(base: BaseProperties(id: "im"), kind: .image(image)))
    }

    func testFrameRoundTrips() throws {
        try assertRoundTrips(ExcalidrawElement(base: BaseProperties(id: "fr"), kind: .frame(name: "Frame 1")))
        try assertRoundTrips(ExcalidrawElement(base: BaseProperties(id: "mf"), kind: .magicframe(name: nil)))
    }

    func testBasePropertiesAndCustomDataRoundTrip() throws {
        var base = BaseProperties(id: "x")
        base.roundness = Roundness(type: RoundnessType.adaptiveRadius)
        base.boundElements = [BoundElement(id: "t1", type: .text)]
        base.groupIds = ["g1", "g2"]
        base.link = "https://example.com"
        base.locked = true
        base.customData = ["foo": .string("bar"), "n": .number(42), "flag": .bool(true)]
        try assertRoundTrips(ExcalidrawElement(base: base, kind: .rectangle))
    }

    func testUnknownTypeThrows() {
        let json = Data(#"{"type":"unknownThing","id":"z"}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(ExcalidrawElement.self, from: json))
    }
}
