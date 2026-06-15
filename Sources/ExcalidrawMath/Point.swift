import Foundation

/// A 2D point in scene coordinates.
///
/// Mirrors Excalidraw's `LocalPoint`/`GlobalPoint` tuple `[number, number]`
/// (see `packages/math/src/point.ts`). Encodes to/from a two-element JSON
/// array `[x, y]` to match the `.excalidraw` wire format (points, scale,
/// fixedPoint, fixedSegment endpoints are all stored this way).
public struct Point: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }

    /// Euclidean distance to another point.
    public func distance(to other: Point) -> Double {
        (self - other).magnitude
    }

    /// Vector magnitude treating the point as a vector from the origin.
    public var magnitude: Double {
        (x * x + y * y).squareRoot()
    }

    public static func - (lhs: Point, rhs: Point) -> Point {
        Point(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    public static func + (lhs: Point, rhs: Point) -> Point {
        Point(lhs.x + rhs.x, lhs.y + rhs.y)
    }
}

extension Point: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Double.self)
        let y = try container.decode(Double.self)
        self.init(x, y)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
}

public extension Point {
    /// The origin, `(0, 0)`.
    static let zero = Point(0, 0)

    /// Rotate this point around `center` by `angle` radians (`pointRotateRads`).
    func rotated(around center: Point, by angle: Double) -> Point {
        guard angle != 0 else { return self }
        let dx = x - center.x
        let dy = y - center.y
        return Point(
            dx * cos(angle) - dy * sin(angle) + center.x,
            dx * sin(angle) + dy * cos(angle) + center.y
        )
    }

    /// Translate this point by a vector (`pointTranslate`).
    func translated(by v: Vector) -> Point {
        Point(x + v.u, y + v.v)
    }

    /// The midpoint between this point and `other` (`pointCenter`).
    func midpoint(to other: Point) -> Point {
        Point((x + other.x) / 2, (y + other.y) / 2)
    }

    /// Squared Euclidean distance (`pointDistanceSq`) — avoids a `sqrt`.
    func distanceSquared(to other: Point) -> Double {
        let dx = other.x - x
        let dy = other.y - y
        return dx * dx + dy * dy
    }

    /// Scale this point away from `origin` by `multiplier` (`pointScaleFromOrigin`).
    func scaled(from origin: Point, by multiplier: Double) -> Point {
        origin.translated(by: Vector(from: self, origin: origin).scaled(by: multiplier))
    }

    /// Whether this point lies within the axis-aligned box bounded by `a` and
    /// `b` (`isPointWithinBounds`).
    func isWithin(_ a: Point, _ b: Point) -> Bool {
        x <= Swift.max(a.x, b.x) && x >= Swift.min(a.x, b.x) &&
            y <= Swift.max(a.y, b.y) && y >= Swift.min(a.y, b.y)
    }

    /// Coordinate-wise comparison within `tolerance` (`pointsEqual`).
    func isApproximatelyEqual(to other: Point, tolerance: Double = ExcalidrawMath.precision) -> Bool {
        abs(x - other.x) < tolerance && abs(y - other.y) < tolerance
    }
}

public enum ExcalidrawMath {
    /// Numerical tolerance used throughout geometry, matching upstream
    /// `PRECISION` (`10e-5`, i.e. `1e-4`).
    public static let precision = 10e-5
}
