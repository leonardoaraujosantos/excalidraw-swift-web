import ExcalidrawMath
import ExcalidrawModel
import Foundation

/// Arrow-to-shape binding geometry (`packages/element/src/binding.ts`,
/// simplified). Finds the bindable element near an arrow endpoint and converts
/// between an endpoint and a fixed-point ratio within an element's bounds.
public enum Binding {
    /// Default search distance around an element's bounds, in scene units.
    public static let distance = 16.0

    public static func isBindable(_ element: ExcalidrawElement) -> Bool {
        switch element.kind {
        case .rectangle, .diamond, .ellipse, .text, .image, .frame, .magicframe, .embeddable, .iframe:
            true
        case .arrow, .line, .freedraw, .selection:
            false
        }
    }

    /// The smallest bindable element whose bounds (expanded by `threshold`)
    /// contains `point`, excluding `excluding`.
    public static func bindableElement(
        at point: Point, in elements: [ExcalidrawElement], excluding: Set<String>, threshold: Double = distance
    ) -> ExcalidrawElement? {
        var best: (element: ExcalidrawElement, area: Double)?
        for element in elements where isBindable(element) && !excluding.contains(element.id) {
            let b = ElementGeometry.bounds(element)
            let expanded = BoundingBox(
                minX: b.minX - threshold, minY: b.minY - threshold,
                maxX: b.maxX + threshold, maxY: b.maxY + threshold
            )
            if expanded.contains(point) {
                let area = b.width * b.height
                if best == nil || area < best!.area { best = (element, area) }
            }
        }
        return best?.element
    }

    /// Ratio (0–1 on each axis) of `point` within `bounds`.
    public static func fixedPoint(for point: Point, in bounds: BoundingBox) -> Point {
        Point(
            bounds.width == 0 ? 0.5 : (point.x - bounds.minX) / bounds.width,
            bounds.height == 0 ? 0.5 : (point.y - bounds.minY) / bounds.height
        )
    }

    /// The scene point for a fixed-point ratio within `bounds`.
    public static func point(forFixedPoint fixed: Point, in bounds: BoundingBox) -> Point {
        Point(bounds.minX + fixed.x * bounds.width, bounds.minY + fixed.y * bounds.height)
    }
}
