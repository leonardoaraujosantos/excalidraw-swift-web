import XCTest
@testable import ExcalidrawEditor

final class FormFactorTests: XCTestCase {
    func testBreakpoints() {
        XCTAssertEqual(DeviceClass(width: 390, height: 844).formFactor, .phone)
        XCTAssertEqual(DeviceClass(width: 834, height: 1112).formFactor, .tablet)
        XCTAssertEqual(DeviceClass(width: 1400, height: 900).formFactor, .desktop)
    }

    func testLayoutFlags() {
        let iphone = DeviceClass(width: 390, height: 844)
        XCTAssertTrue(iphone.usesCompactLayout)
        XCTAssertFalse(iphone.canDockSidebar)
        XCTAssertFalse(iphone.isLandscape)

        let ipadLandscape = DeviceClass(width: 1180, height: 820)
        XCTAssertFalse(ipadLandscape.usesCompactLayout)
        XCTAssertTrue(ipadLandscape.canDockSidebar)
        XCTAssertTrue(ipadLandscape.isLandscape)
    }
}

final class ShortcutsTests: XCTestCase {
    func testToolShortcuts() {
        XCTAssertEqual(Shortcuts.command(for: KeyChord("r")), .selectTool(.rectangle))
        XCTAssertEqual(Shortcuts.command(for: KeyChord("V")), .selectTool(.selection)) // case-insensitive
        XCTAssertEqual(Shortcuts.command(for: KeyChord("t")), .selectTool(.text))
        XCTAssertEqual(Shortcuts.command(for: KeyChord("8")), .selectTool(.text))
    }

    func testEditShortcuts() {
        XCTAssertEqual(Shortcuts.command(for: KeyChord("z", command: true)), .undo)
        XCTAssertEqual(Shortcuts.command(for: KeyChord("z", command: true, shift: true)), .redo)
        XCTAssertEqual(Shortcuts.command(for: KeyChord("d", command: true)), .duplicate)
        XCTAssertEqual(Shortcuts.command(for: KeyChord("a", command: true)), .selectAll)
        XCTAssertEqual(Shortcuts.command(for: KeyChord("g", command: true, shift: true)), .ungroup)
        XCTAssertEqual(Shortcuts.command(for: KeyChord("\u{8}")), .delete)
        XCTAssertEqual(Shortcuts.command(for: KeyChord("=", command: true)), .zoomIn)
        XCTAssertEqual(Shortcuts.command(for: KeyChord("0", command: true)), .resetZoom)
    }

    func testUnmappedReturnsNil() {
        XCTAssertNil(Shortcuts.command(for: KeyChord("q")))
        XCTAssertNil(Shortcuts.command(for: KeyChord("k", command: true)))
    }
}

final class CommandRegistryTests: XCTestCase {
    func testSearchAll() {
        XCTAssertEqual(CommandRegistry.search("").count, CommandRegistry.all.count)
    }

    func testFuzzySearch() {
        let results = CommandRegistry.search("rect")
        XCTAssertTrue(results.contains { $0.command == .selectTool(.rectangle) })
        XCTAssertFalse(results.contains { $0.command == .undo })
    }

    func testSubsequenceMatch() {
        XCTAssertTrue(CommandRegistry.isSubsequence("zf", of: "zoom to fit"))
        XCTAssertFalse(CommandRegistry.isSubsequence("zzz", of: "zoom"))
    }
}
