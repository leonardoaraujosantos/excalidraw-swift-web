import ExcalidrawMath
import Foundation
import XCTest

@testable import ExcalidrawModel

final class SceneDecodeDiagTests: XCTestCase {
    /// Regression: an arrow binding that omits `fixedPoint`/`mode` (agent-authored
    /// connectors, upstream focus/gap bindings) must still decode — one strict
    /// failure here previously made `[ExcalidrawElement]` throw and blanked the
    /// whole board on iOS.
    func testArrowBindingWithoutFixedPointDecodes() throws {
        let json = """
        [{
          "id": "a1", "type": "arrow", "x": 0, "y": 0, "width": 10, "height": 10,
          "version": 1, "versionNonce": 0, "points": [[0,0],[10,10]],
          "startBinding": { "elementId": "src", "focus": 0.1, "gap": 4 },
          "endBinding": { "elementId": "dst" }
        }]
        """
        let els = try JSONDecoder().decode([ExcalidrawElement].self, from: Data(json.utf8))
        XCTAssertEqual(els.count, 1)
        guard case let .arrow(props) = els[0].kind else { return XCTFail("expected arrow") }
        XCTAssertEqual(props.startBinding?.elementId, "src")
        XCTAssertEqual(props.startBinding?.fixedPoint, Point(0, 0)) // defaulted
        XCTAssertEqual(props.endBinding?.elementId, "dst")
    }

    /// Optional: decode a dumped real scene if present (left by the ops probe).
    func testDecodeRealSceneIfPresent() throws {
        let path = "/tmp/eshani_scene.json"
        guard FileManager.default.fileExists(atPath: path) else { throw XCTSkip("no dump") }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let all = try JSONDecoder().decode([ExcalidrawElement].self, from: data)
        XCTAssertFalse(all.isEmpty, "the real scene should decode to a non-empty element set")
        print("DIAG: decoded \(all.count) elements")
    }
}
