import Foundation

/// A cubic Bézier curve with four control points (`packages/math/src/curve.ts`).
///
/// This port covers construction, point evaluation, and the tangent. The
/// heavier algorithms — closest-point search, curve↔line Newton intersection,
/// Legendre–Gauss arc length, and curve offsetting — are scheduled for Phase 7
/// (advanced geometry) per the roadmap.
public struct Curve: Equatable, Sendable {
    public var p0: Point
    public var p1: Point
    public var p2: Point
    public var p3: Point

    public init(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point) {
        self.p0 = p0
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
    }

    /// Point on the curve at parameter `t ∈ [0, 1]` (`bezierEquation`).
    public func point(at t: Double) -> Point {
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

    /// Tangent vector (the derivative) at parameter `t` (`curveTangent`).
    public func tangent(at t: Double) -> Vector {
        let mt = 1 - t
        func component(_ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
            -3 * mt * mt * a
                + 3 * mt * mt * b
                - 6 * t * mt * b
                - 3 * t * t * c
                + 6 * t * mt * c
                + 3 * t * t * d
        }
        return Vector(
            component(p0.x, p1.x, p2.x, p3.x),
            component(p0.y, p1.y, p2.y, p3.y)
        )
    }
}
