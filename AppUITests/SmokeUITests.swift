import XCTest

/// Phase 0 smoke test: the app launches on the target simulator. Real
/// end-to-end drawing flows (draw → move → resize → undo → export) arrive in
/// Phase 3 once the interaction loop exists.
final class SmokeUITests: XCTestCase {
    func testAppLaunchesAndRendersCanvas() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.wait(for: .runningForeground, timeout: 10), true)
        // The scene canvas should be present (it renders the bundled sample).
        XCTAssertTrue(app.otherElements["excalidraw-canvas"].waitForExistence(timeout: 10))
    }
}
