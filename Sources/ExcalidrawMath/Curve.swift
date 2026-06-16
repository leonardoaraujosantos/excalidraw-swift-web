import Foundation

/// A cubic Bézier curve with four control points (`packages/math/src/curve.ts`).
///
/// Covers construction, point evaluation, the tangent, Legendre–Gauss arc
/// length, length-parameterization, curve↔line-segment Newton intersection, and
/// closest-point search.
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

    // MARK: Arc length (Legendre–Gauss N=24 quadrature)

    /// Approximate arc length of the whole curve (`curveLength`).
    public var length: Double {
        length(at: 1)
    }

    /// Arc length from `t = 0` to `t` using 24-point Legendre–Gauss quadrature
    /// (`curveLengthAtParameter`).
    public func length(at t: Double) -> Double {
        if t <= 0 { return 0 }
        // Integrate |C'(u)| over [0, t]; map the quadrature interval [-1, 1]
        // onto [0, t] via u = (t/2)·x + (t/2).
        let half = t / 2
        var sum = 0.0
        for i in 0 ..< 24 {
            let u = half * LegendreGauss.n24TValues[i] + half
            sum += LegendreGauss.n24CValues[i] * tangent(at: u).magnitude
        }
        return half * sum
    }

    /// The point at `percent` (0–1) of the curve's total arc length, found by
    /// binary search on the length parameterization (`curvePointAtLength`).
    public func point(atLength percent: Double) -> Point {
        if percent <= 0 { return point(at: 0) }
        if percent >= 1 { return point(at: 1) }

        let total = length
        let target = total * percent
        var tMin = 0.0
        var tMax = 1.0
        var t = percent
        let tolerance = total * 0.0001

        for _ in 0 ..< 20 {
            let current = length(at: t)
            if abs(current - target) < tolerance { break }
            if current < target { tMin = t } else { tMax = t }
            t = (tMin + tMax) / 2
        }
        return point(at: t)
    }

    // MARK: Curve ↔ line-segment intersection (Newton with analytical Jacobian)

    /// Intersection points between this curve and a line segment, solved with
    /// Newton's method from a few seed guesses (`curveIntersectLineSegment`).
    /// Returns at most one point per converged seed.
    public func intersections(
        with segment: LineSegment, tolerance: Double = 1e-2, iterationLimit: Int = 4
    ) -> [Point] {
        let seeds: [(Double, Double)] = [(0.5, 0), (0.2, 0), (0.8, 0)]
        for seed in seeds {
            if let point = solve(
                segment,
                t0: seed.0,
                s0: seed.1,
                tolerance: tolerance,
                iterationLimit: iterationLimit
            ) {
                return [point]
            }
        }
        return []
    }

    /// One Newton solve from a seed `(t0, s0)`; `nil` if it fails to converge or
    /// lands outside the curve/segment parameter range.
    private func solve(
        _ segment: LineSegment, t0: Double, s0: Double, tolerance: Double, iterationLimit: Int
    ) -> Point? {
        var t = t0
        var s = s0
        var iteration = 0
        var error = Double.infinity

        while error >= tolerance {
            if iteration >= iterationLimit { return nil }
            let bezier = point(at: t)
            let lineX = segment.a.x + s * (segment.b.x - segment.a.x)
            let lineY = segment.a.y + s * (segment.b.y - segment.a.y)
            let fx = bezier.x - lineX
            let fy = bezier.y - lineY
            error = abs(fx) + abs(fy)
            if error < tolerance { break }

            let d = tangent(at: t) // ∂bezier/∂t
            let dfxds = -(segment.b.x - segment.a.x)
            let dfyds = -(segment.b.y - segment.a.y)
            let det = d.u * dfyds - dfxds * d.v
            if abs(det) < 1e-12 { return nil }

            let invDet = 1 / det
            t += invDet * (dfyds * -fx - dfxds * -fy)
            s += invDet * (-d.v * -fx + d.u * -fy)
            iteration += 1
        }

        if t < 0 || t > 1 || s < 0 || s > 1 { return nil }
        return point(at: t)
    }

    // MARK: Closest point

    /// The closest point on the curve to `p`, via a coarse scan refined by a
    /// golden-section-style local minimum search (`curveClosestPoint`).
    public func closestPoint(to p: Point, tolerance: Double = 1e-3) -> Point {
        let maxSteps = 30
        var closestStep = 0
        var minDistance = Double.infinity
        for step in 0 ... maxSteps {
            let d = p.distance(to: point(at: Double(step) / Double(maxSteps)))
            if d < minDistance {
                minDistance = d
                closestStep = step
            }
        }

        let t0 = max(Double(closestStep - 1) / Double(maxSteps), 0)
        let t1 = min(Double(closestStep + 1) / Double(maxSteps), 1)
        let t = localMinimum(t0, t1, tolerance) { p.distance(to: point(at: $0)) }
        return point(at: t)
    }

    /// Distance from `p` to the closest point on the curve (`curvePointDistance`).
    public func distance(to p: Point) -> Double {
        p.distance(to: closestPoint(to: p))
    }

    private func localMinimum(_ min: Double, _ max: Double, _ e: Double, _ f: (Double) -> Double) -> Double {
        var m = min
        var n = max
        var k = (m + n) / 2
        while n - m > e {
            k = (n + m) / 2
            if f(k - e) < f(k + e) { n = k } else { m = k }
        }
        return k
    }
}
