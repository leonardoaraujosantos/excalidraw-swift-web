import ExcalidrawMath
import ExcalidrawModel
import XCTest
@testable import ExcalidrawEditor

final class ChartTests: XCTestCase {
    private func bars(_ ec: EditorController) -> [ExcalidrawElement] {
        ec.scene.visibleElements.filter { if case .rectangle = $0.kind { return true }; return false }
    }

    func testBarChartHasOneBarPerValueGrouped() throws {
        let ec = EditorController()
        let group = try XCTUnwrap(ec.createChart(at: Point(0, 0), values: [10, 20, 40], kind: .bar))
        XCTAssertEqual(bars(ec).count, 3)
        for bar in bars(ec) {
            XCTAssertEqual(bar.base.groupIds, [group])
        }
        // Bar heights scale with value: the 40 bar is tallest, the 10 shortest.
        let heights = bars(ec).sorted { $0.base.x < $1.base.x }.map(\.base.height)
        XCTAssertEqual(heights[0], heights[2] / 4, accuracy: 1e-6) // 10 vs 40
        XCTAssertGreaterThan(heights[2], heights[1])
    }

    func testBarHeightsAreProportional() {
        let ec = EditorController()
        ec.createChart(at: Point(0, 0), values: [50, 100], kind: .bar)
        let heights = bars(ec).sorted { $0.base.x < $1.base.x }.map(\.base.height)
        XCTAssertEqual(heights[0], heights[1] / 2, accuracy: 1e-6)
    }

    func testLineChartProducesASinglePolyline() {
        let ec = EditorController()
        ec.createChart(at: Point(0, 0), values: [1, 3, 2, 5], kind: .line)
        let lines = ec.scene.visibleElements.compactMap { element -> LinearProperties? in
            if case let .line(props) = element.kind { return props }
            return nil
        }
        // baseline + the series line.
        XCTAssertTrue(lines.contains { $0.points.count == 4 })
    }

    func testLabelsBecomeText() {
        let ec = EditorController()
        ec.createChart(at: Point(0, 0), values: [1, 2], labels: ["A", "B"], kind: .bar)
        let texts = ec.scene.visibleElements.compactMap { element -> String? in
            if case let .text(props) = element.kind { return props.text }
            return nil
        }
        XCTAssertEqual(Set(texts), ["A", "B"])
    }

    func testEmptyValuesProduceNothing() {
        let ec = EditorController()
        XCTAssertNil(ec.createChart(at: Point(0, 0), values: [], kind: .bar))
        XCTAssertTrue(ec.scene.visibleElements.isEmpty)
    }

    func testChartIsOneUndoStep() {
        let ec = EditorController()
        ec.createChart(at: Point(0, 0), values: [1, 2, 3], kind: .bar)
        XCTAssertTrue(ec.undo())
        XCTAssertTrue(ec.scene.visibleElements.isEmpty)
    }
}
