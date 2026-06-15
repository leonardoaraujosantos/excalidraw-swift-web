import Foundation

/// An inclusive numeric range `[start, end]` (`packages/math/src/range.ts`).
public struct InclusiveRange: Equatable, Sendable {
    public var start: Double
    public var end: Double

    public init(_ start: Double, _ end: Double) {
        self.start = start
        self.end = end
    }

    /// Whether this range overlaps `other` (`rangesOverlap`).
    public func overlaps(_ other: InclusiveRange) -> Bool {
        if start <= other.start { return end >= other.start }
        return other.end >= start
    }

    /// The overlapping range, or `nil` when disjoint (`rangeIntersection`).
    public func intersection(_ other: InclusiveRange) -> InclusiveRange? {
        let lo = Swift.max(start, other.start)
        let hi = Swift.min(end, other.end)
        return lo <= hi ? InclusiveRange(lo, hi) : nil
    }

    /// Whether `value` lies inside the range (`rangeIncludesValue`).
    public func includes(_ value: Double) -> Bool {
        value >= start && value <= end
    }
}
