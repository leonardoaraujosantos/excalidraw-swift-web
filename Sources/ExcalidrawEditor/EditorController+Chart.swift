import ExcalidrawGeometry
import ExcalidrawMath
import ExcalidrawModel
import Foundation

public enum ChartKind: String, Sendable {
    case bar
    case line
}

/// Charts: turn a series of numbers into a grouped diagram of standard
/// elements (bars as rectangles, a line series as a polyline, plus a baseline
/// and category labels), the way Excalidraw's chart feature does.
public extension EditorController {
    private static var chartHeight: Double {
        200
    }

    private static var barWidth: Double {
        44
    }

    private static var barGap: Double {
        22
    }

    /// Build a `kind` chart for `values` at `point` (top-left), grouped and
    /// selected. `labels` (optional) annotate each column. Returns the group id.
    @discardableResult
    func createChart(at point: Point, values: [Double], labels: [String] = [], kind: ChartKind = .bar) -> String? {
        let values = values.filter(\.isFinite)
        guard !values.isEmpty else { return nil }
        let maxValue = max(values.max() ?? 1, 1e-9)
        let step = Self.barWidth + Self.barGap
        let width = Double(values.count) * step - Self.barGap
        let height = Self.chartHeight
        let fill = currentItem.backgroundColor == "transparent" ? "#a5d8ff" : currentItem.backgroundColor
        let groupID = nextID()

        store.transaction { scene in
            // Baseline carries the source data for potential re-editing.
            var axis = currentItem.makeBase(id: nextID(), seed: nextSeed(), x: point.x, y: point.y + height)
            axis.width = width
            axis.groupIds = [groupID]
            axis.customData = ["chart": .object([
                "kind": .string(kind.rawValue),
                "values": .array(values.map(JSONValue.number))
            ])]
            scene.add(ExcalidrawElement(
                base: axis,
                kind: .line(LinearProperties(points: [Point(0, 0), Point(width, 0)]))
            ))

            switch kind {
            case .bar:
                for (i, value) in values.enumerated() {
                    let barHeight = value / maxValue * height
                    let x = point.x + Double(i) * step
                    var bar = currentItem.makeBase(
                        id: nextID(),
                        seed: nextSeed(),
                        x: x,
                        y: point.y + height - barHeight
                    )
                    bar.width = Self.barWidth
                    bar.height = barHeight
                    bar.backgroundColor = fill
                    bar.fillStyle = .solid
                    bar.groupIds = [groupID]
                    scene.add(ExcalidrawElement(base: bar, kind: .rectangle))
                }
            case .line:
                let points = values.enumerated().map { i, value in
                    Point(Double(i) * step + Self.barWidth / 2, height - value / maxValue * height)
                }
                var series = currentItem.makeBase(id: nextID(), seed: nextSeed(), x: point.x, y: point.y)
                series.groupIds = [groupID]
                series.roundness = Roundness(type: RoundnessType.proportionalRadius)
                let xs = points.map(\.x), ys = points.map(\.y)
                series.width = (xs.max() ?? 0) - (xs.min() ?? 0)
                series.height = (ys.max() ?? 0) - (ys.min() ?? 0)
                scene.add(ExcalidrawElement(base: series, kind: .line(LinearProperties(points: points))))
            }

            // Category labels under each column.
            for (i, label) in labels.enumerated() where i < values.count && !label.isEmpty {
                let x = point.x + Double(i) * step
                var text = currentItem.makeBase(id: nextID(), seed: nextSeed(), x: x, y: point.y + height + 6)
                text.groupIds = [groupID]
                text.backgroundColor = "transparent"
                let props = TextProperties(fontSize: 14, text: label, textAlign: .center, originalText: label)
                scene.add(ExcalidrawElement(base: text, kind: .text(props)))
            }
        }
        selectedIDs = groupSiblings(of: scene.visibleElements.last(where: { $0.base.groupIds.contains(groupID) })?
            .id ?? "")
        return groupID
    }
}
