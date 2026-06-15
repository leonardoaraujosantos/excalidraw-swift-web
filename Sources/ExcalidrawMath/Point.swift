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

public enum ExcalidrawMath {
    /// Numerical tolerance used throughout geometry, matching upstream `PRECISION`.
    public static let precision = 1e-5
}
