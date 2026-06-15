import Foundation

/// An infinite line through two points (`packages/math/src/line.ts`).
public struct Line: Equatable, Sendable {
    public var p: Point
    public var q: Point

    public init(_ p: Point, _ q: Point) {
        self.p = p
        self.q = q
    }

    /// Intersection point of two infinite lines, or `nil` if parallel
    /// (`linesIntersectAt`).
    public func intersection(with other: Line) -> Point? {
        let a1 = q.y - p.y
        let b1 = p.x - q.x
        let a2 = other.q.y - other.p.y
        let b2 = other.p.x - other.q.x
        let d = a1 * b2 - a2 * b1
        guard d != 0 else { return nil }
        let c1 = a1 * p.x + b1 * p.y
        let c2 = a2 * other.p.x + b2 * other.p.y
        return Point((c1 * b2 - c2 * b1) / d, (a1 * c2 - a2 * c1) / d)
    }
}
