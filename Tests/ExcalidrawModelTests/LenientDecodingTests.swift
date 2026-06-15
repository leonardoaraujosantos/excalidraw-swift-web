import ExcalidrawMath
import XCTest
@testable import ExcalidrawModel

/// Exercises the lenient-decode paths: older or hand-written files that omit
/// fields should load with upstream defaults rather than fail.
final class LenientDecodingTests: XCTestCase {
    private func decode(_ json: String) throws -> ExcalidrawElement {
        try JSONDecoder().decode(ExcalidrawElement.self, from: Data(json.utf8))
    }

    func testRectangleWithOnlyTypeAndId() throws {
        let element = try decode(##"{"type":"rectangle","id":"r"}"##)
        XCTAssertEqual(element.base.strokeColor, "#1e1e1e")
        XCTAssertEqual(element.base.backgroundColor, "transparent")
        XCTAssertEqual(element.base.fillStyle, .solid)
        XCTAssertEqual(element.base.strokeWidth, 2)
        XCTAssertEqual(element.base.opacity, 100)
        XCTAssertEqual(element.base.roughness, 1)
        XCTAssertEqual(element.base.version, 1)
        XCTAssertTrue(element.base.groupIds.isEmpty)
        XCTAssertFalse(element.base.locked)
        XCTAssertNil(element.base.roundness)
    }

    func testTextWithDefaults() throws {
        let element = try decode(##"{"type":"text","id":"t"}"##)
        guard case let .text(text) = element.kind else { return XCTFail("expected text") }
        XCTAssertEqual(text.fontSize, 20)
        XCTAssertEqual(text.fontFamily, FontFamily.excalifont)
        XCTAssertEqual(text.textAlign, .left)
        XCTAssertEqual(text.verticalAlign, .top)
        XCTAssertTrue(text.autoResize)
        XCTAssertEqual(text.lineHeight, 1.25)
    }

    func testLinearAndFreedrawAndImageDefaults() throws {
        if case let .line(line) = try decode(##"{"type":"line","id":"l"}"##).kind {
            XCTAssertTrue(line.points.isEmpty)
            XCTAssertFalse(line.polygon)
            XCTAssertNil(line.startArrowhead)
        } else { XCTFail("expected line") }

        if case let .arrow(arrow) = try decode(##"{"type":"arrow","id":"a"}"##).kind {
            XCTAssertFalse(arrow.elbowed)
        } else { XCTFail("expected arrow") }

        if case let .freedraw(free) = try decode(##"{"type":"freedraw","id":"f"}"##).kind {
            XCTAssertTrue(free.pressures.isEmpty)
            XCTAssertTrue(free.simulatePressure)
        } else { XCTFail("expected freedraw") }

        if case let .image(image) = try decode(##"{"type":"image","id":"i"}"##).kind {
            XCTAssertEqual(image.status, .pending)
            XCTAssertEqual(image.scale, Point(1, 1))
            XCTAssertNil(image.fileId)
        } else { XCTFail("expected image") }
    }

    func testFrameDefaultsAndEmbeddable() throws {
        if case let .frame(name) = try decode(##"{"type":"frame","id":"fr"}"##).kind {
            XCTAssertNil(name)
        } else { XCTFail("expected frame") }
        guard case .embeddable = try decode(##"{"type":"embeddable","id":"e"}"##).kind else {
            return XCTFail("expected embeddable")
        }
    }

    func testFileDecodesEmptyObjectWithDefaults() throws {
        let file = try ExcalidrawFile.decode(from: Data("{}".utf8))
        XCTAssertEqual(file.type, "excalidraw")
        XCTAssertEqual(file.version, 2)
        XCTAssertEqual(file.source, "unknown")
        XCTAssertTrue(file.elements.isEmpty)
        XCTAssertTrue(file.files.isEmpty)
        XCTAssertTrue(file.appState.raw.isEmpty)
    }

    func testAppStateFromNonObjectFallsBack() throws {
        // A malformed appState (array instead of object) decodes to empty, not a throw.
        let appState = try JSONDecoder().decode(AppState.self, from: Data("[1,2,3]".utf8))
        XCTAssertTrue(appState.raw.isEmpty)
        XCTAssertNil(appState.viewBackgroundColor)
        XCTAssertNil(appState.gridModeEnabled)
    }

    func testBinaryFilesDecodeAndRoundTrip() throws {
        let json = ##"""
        {"mimeType":"image/png","id":"file-1","dataURL":"data:image/png;base64,AA==","created":123,"version":1}
        """##
        let fileData = try JSONDecoder().decode(BinaryFileData.self, from: Data(json.utf8))
        XCTAssertEqual(fileData.mimeType, "image/png")
        let reencoded = try JSONEncoder().encode(fileData)
        XCTAssertEqual(try JSONDecoder().decode(BinaryFileData.self, from: reencoded), fileData)
    }
}
