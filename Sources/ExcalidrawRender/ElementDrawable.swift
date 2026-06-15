import ExcalidrawMath
import ExcalidrawModel
import Foundation
import RoughKit

/// Generates the rough.js `Drawable` for an element, in element-local
/// coordinates (origin at the element's `x, y`). The scene renderer applies the
/// element's translation and rotation when drawing. Ports the dispatch in
/// `_generateElementShape` (`packages/element/src/shape.ts`).
///
/// Scope: rectangle, diamond, line, arrow this increment. Ellipse, freedraw and
/// text shapes are the next Phase 2 increment.
public enum ElementDrawable {
    private static let generator = RoughGenerator()

    public static func drawable(for element: ExcalidrawElement) -> Drawable? {
        let o = RoughOptionsBuilder.options(for: element)
        let w = element.base.width
        let h = element.base.height

        let rounded = element.base.roundness != nil

        switch element.kind {
        case .rectangle, .embeddable, .iframe:
            return generator.rectangle(x: 0, y: 0, width: w, height: h, options: o)
        case .diamond:
            // Diamond vertices at the midpoints of each bounding-box edge.
            let pts = [Point(w / 2, 0), Point(w, h / 2), Point(w / 2, h), Point(0, h / 2)]
            return generator.polygon(pts, options: o)
        case .ellipse:
            return generator.ellipse(x: w / 2, y: h / 2, width: w, height: h, options: o).drawable
        case let .line(props):
            return linearDrawable(props.points, closed: props.polygon || isLoop(props.points), rounded: rounded, o)
        case let .arrow(props):
            return linearDrawable(props.points, closed: false, rounded: rounded, o)
        default:
            return nil // freedraw / text / image / frame: handled directly by the renderer / later increments
        }
    }

    private static func linearDrawable(_ points: [Point], closed: Bool, rounded: Bool, _ o: RoughOptions) -> Drawable? {
        guard points.count >= 2 else { return nil }
        if rounded, points.count > 2 {
            return generator.curve(points, options: o)
        }
        return closed ? generator.polygon(points, options: o) : generator.linearPath(points, options: o)
    }

    private static func isLoop(_ points: [Point]) -> Bool {
        guard points.count >= 3, let first = points.first, let last = points.last else { return false }
        return first.distance(to: last) <= 40
    }
}
