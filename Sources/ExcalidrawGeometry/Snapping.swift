import ExcalidrawMath
import Foundation

/// The result of snapping a moving box against the grid and/or other elements:
/// an offset to apply plus the matched guide lines (for the overlay).
public struct SnapResult: Equatable, Sendable {
    public var offsetX: Double
    public var offsetY: Double
    /// Scene x-coordinates of vertical guide lines (matched edges/centres).
    public var verticalLines: [Double]
    /// Scene y-coordinates of horizontal guide lines.
    public var horizontalLines: [Double]

    public static let none = SnapResult(offsetX: 0, offsetY: 0, verticalLines: [], horizontalLines: [])
}

/// Grid and object snapping (`packages/excalidraw/snapping.ts`).
public enum Snapping {
    public static let defaultDistance = 8.0

    /// Snap a point to the nearest grid intersection.
    public static func snapToGrid(_ point: Point, gridSize: Double) -> Point {
        guard gridSize > 0 else { return point }
        return Point(
            (point.x / gridSize).rounded() * gridSize,
            (point.y / gridSize).rounded() * gridSize
        )
    }

    /// Snap `moving` to the edges/centres of `statics` within `threshold`,
    /// returning the offset that aligns them plus the matched guide lines.
    public static func snap(
        moving: BoundingBox, statics: [BoundingBox], threshold: Double
    ) -> SnapResult {
        let movingX = [moving.minX, (moving.minX + moving.maxX) / 2, moving.maxX]
        let movingY = [moving.minY, (moving.minY + moving.maxY) / 2, moving.maxY]
        let staticX = statics.flatMap { [$0.minX, ($0.minX + $0.maxX) / 2, $0.maxX] }
        let staticY = statics.flatMap { [$0.minY, ($0.minY + $0.maxY) / 2, $0.maxY] }

        let (offsetX, lineX) = bestSnap(moving: movingX, statics: staticX, threshold: threshold)
        let (offsetY, lineY) = bestSnap(moving: movingY, statics: staticY, threshold: threshold)

        return SnapResult(
            offsetX: offsetX, offsetY: offsetY,
            verticalLines: lineX.map { [$0] } ?? [],
            horizontalLines: lineY.map { [$0] } ?? []
        )
    }

    /// Find the smallest-magnitude offset that brings any moving candidate within
    /// `threshold` of any static candidate. Returns the offset and the matched
    /// static line, or `(0, nil)` if nothing snaps.
    private static func bestSnap(
        moving: [Double], statics: [Double], threshold: Double
    ) -> (offset: Double, line: Double?) {
        var best: (offset: Double, line: Double)?
        for m in moving {
            for s in statics {
                let delta = s - m
                if abs(delta) <= threshold, best == nil || abs(delta) < abs(best!.offset) {
                    best = (delta, s)
                }
            }
        }
        return (best?.offset ?? 0, best?.line)
    }
}
