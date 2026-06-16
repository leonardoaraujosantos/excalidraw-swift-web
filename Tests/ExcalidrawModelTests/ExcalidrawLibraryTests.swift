import XCTest
@testable import ExcalidrawModel

final class ExcalidrawLibraryTests: XCTestCase {
    func testDecodesV1Fixture() throws {
        let data = try Fixtures.data("fixture_library.excalidrawlib")
        let library = try ExcalidrawLibrary.decode(from: data)
        XCTAssertFalse(library.items.isEmpty)
        XCTAssertFalse(library.items[0].isEmpty)
    }

    func testEncodeV2RoundTrip() throws {
        var base = BaseProperties(id: "a"); base.width = 50; base.height = 30
        let library = ExcalidrawLibrary(items: [[ExcalidrawElement(base: base, kind: .rectangle)]])
        let reloaded = try ExcalidrawLibrary.decode(from: library.encoded())
        XCTAssertEqual(reloaded.items.count, 1)
        XCTAssertEqual(reloaded.items[0].first?.id, "a")
    }

    func testEncodedIsV2() throws {
        let library = ExcalidrawLibrary(items: [[]])
        let json = try String(bytes: library.encoded(), encoding: .utf8) ?? ""
        XCTAssertTrue(json.contains("\"type\" : \"excalidrawlib\""))
        XCTAssertTrue(json.contains("libraryItems"))
    }

    func testEmptyLibrary() throws {
        let lib = try ExcalidrawLibrary.decode(from: Data("{\"type\":\"excalidrawlib\",\"version\":2}".utf8))
        XCTAssertTrue(lib.items.isEmpty)
    }
}
