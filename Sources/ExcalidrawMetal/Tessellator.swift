import ExcalidrawMath
import Foundation
import RoughKit

/// Converts rough.js path operations into triangle geometry for the GPU.
///
/// All work here is pure Double math with no Metal/CoreGraphics dependency, so
/// it is unit-testable on any host: flatten Bézier ops into polylines, then
/// tessellate those polylines into fill triangles (ear clipping) or stroke
/// triangles (per-segment quads + round joins/caps). Coordinates are passed
/// through unchanged — the caller is responsible for any element transform and
/// the final scene→NDC projection.
public enum Tessellator {
    /// A flat list of triangle corners (every three consecutive points form one
    /// triangle). Chosen over indexed geometry to keep the GPU buffer build
    /// trivial; rough scenes are small enough that the vertex duplication cost
    /// is irrelevant next to the readback.
    public typealias Triangles = [Point]

    /// Split `ops` into polylines, subdividing cubic Béziers. A `.move` starts a
    /// new subpath. `curveSegments` controls Bézier smoothness.
    public static func flatten(_ ops: [PathOp], curveSegments: Int = 16) -> [[Point]] {
        var subpaths: [[Point]] = []
        var current: [Point] = []
        var cursor = Point(0, 0)

        func endSubpath() {
            if current.count >= 2 { subpaths.append(current) }
            current = []
        }

        for op in ops {
            switch op {
            case let .move(p):
                endSubpath()
                current = [p]
                cursor = p
            case let .lineTo(p):
                if current.isEmpty { current = [cursor] }
                current.append(p)
                cursor = p
            case let .bcurveTo(c1, c2, end):
                if current.isEmpty { current = [cursor] }
                let start = cursor
                // Sample the cubic at evenly spaced t (skip t=0, already present).
                for step in 1 ... curveSegments {
                    let t = Double(step) / Double(curveSegments)
                    current.append(cubic(start, c1, c2, end, t))
                }
                cursor = end
            }
        }
        endSubpath()
        return subpaths
    }

    private static func cubic(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point, _ t: Double) -> Point {
        let mt = 1 - t
        let a = mt * mt * mt
        let b = 3 * mt * mt * t
        let c = 3 * mt * t * t
        let d = t * t * t
        return Point(
            a * p0.x + b * p1.x + c * p2.x + d * p3.x,
            a * p0.y + b * p1.y + c * p2.y + d * p3.y
        )
    }

    // MARK: - Strokes

    /// Tessellate a polyline into triangles of width `2 * halfWidth`, with round
    /// joins at interior vertices and round caps at the ends (matching the
    /// round line cap/join the Core Graphics renderer uses for rough strokes).
    public static func strokeTriangles(
        _ polyline: [Point], halfWidth: Double, closed: Bool = false, capSegments: Int = 8
    ) -> Triangles {
        guard polyline.count >= 2, halfWidth > 0 else { return [] }
        var points = polyline
        if closed, let first = points.first, let last = points.last, first != last {
            points.append(first)
        }

        var tris: Triangles = []
        tris.reserveCapacity(points.count * 6)

        for i in 0 ..< (points.count - 1) {
            let a = points[i], b = points[i + 1]
            let dx = b.x - a.x, dy = b.y - a.y
            let len = (dx * dx + dy * dy).squareRoot()
            guard len > 1e-9 else { continue }
            // Left normal of the segment direction, scaled to half the width.
            let nx = -dy / len * halfWidth
            let ny = dx / len * halfWidth
            let a0 = Point(a.x + nx, a.y + ny), a1 = Point(a.x - nx, a.y - ny)
            let b0 = Point(b.x + nx, b.y + ny), b1 = Point(b.x - nx, b.y - ny)
            tris.append(contentsOf: [a0, a1, b0, b0, a1, b1])
        }

        // Round joins/caps: a disc at every vertex closes the gaps a miter would
        // leave and rounds the open ends. Cheap and gap-free for hand-drawn
        // strokes where exact join geometry is imperceptible.
        for p in points {
            appendDisc(center: p, radius: halfWidth, segments: capSegments, into: &tris)
        }
        return tris
    }

    private static func appendDisc(center: Point, radius: Double, segments: Int, into tris: inout Triangles) {
        guard segments >= 3, radius > 0 else { return }
        var prev = Point(center.x + radius, center.y)
        for step in 1 ... segments {
            let a = 2 * Double.pi * Double(step) / Double(segments)
            let next = Point(center.x + radius * cos(a), center.y + radius * sin(a))
            tris.append(contentsOf: [center, prev, next])
            prev = next
        }
    }

    // MARK: - Fills

    /// Triangulate a (closed) polygon into fill triangles via ear clipping.
    /// Falls back to a centroid fan for the residual when the polygon is not a
    /// simple polygon (rough fills are occasionally slightly self-intersecting).
    public static func fillTriangles(_ polygon: [Point]) -> Triangles {
        var poly = polygon
        if let first = poly.first, let last = poly.last, first == last { poly.removeLast() }
        guard poly.count >= 3 else { return [] }
        return PolygonTriangulator.earClip(poly)
    }
}
