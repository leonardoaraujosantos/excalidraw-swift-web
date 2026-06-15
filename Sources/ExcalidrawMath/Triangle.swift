import Foundation

/// A triangle defined by three points (`packages/math/src/triangle.ts`).
public struct Triangle: Equatable, Sendable {
    public var a: Point
    public var b: Point
    public var c: Point

    public init(_ a: Point, _ b: Point, _ c: Point) {
        self.a = a
        self.b = b
        self.c = c
    }

    /// Whether `p` lies strictly inside the triangle. Returns `false` for points
    /// exactly on an edge (`triangleIncludesPoint`).
    public func includes(_ p: Point) -> Bool {
        func sign(_ p1: Point, _ p2: Point, _ p3: Point) -> Double {
            (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
        }
        let d1 = sign(p, a, b)
        let d2 = sign(p, b, c)
        let d3 = sign(p, c, a)
        let hasNeg = d1 < 0 || d2 < 0 || d3 < 0
        let hasPos = d1 > 0 || d2 > 0 || d3 > 0
        return !(hasNeg && hasPos)
    }
}
