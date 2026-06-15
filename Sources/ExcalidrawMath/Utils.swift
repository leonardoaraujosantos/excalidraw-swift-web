import Foundation

public extension ExcalidrawMath {
    /// Clamp `value` into `[min, max]`.
    static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }

    enum Rounding { case round, floor, ceil }

    /// Round `value` to `precision` decimal places (`round`).
    static func round(_ value: Double, precision: Int, mode: Rounding = .round) -> Double {
        let multiplier = pow(10.0, Double(precision))
        let scaled = (value + .ulpOfOne) * multiplier
        let result: Double
        switch mode {
        case .round: result = scaled.rounded()
        case .floor: result = scaled.rounded(.down)
        case .ceil: result = scaled.rounded(.up)
        }
        return result / multiplier
    }

    /// Round `value` to the nearest multiple of `step` (`roundToStep`).
    static func roundToStep(_ value: Double, step: Double, mode: Rounding = .round) -> Double {
        let factor = 1 / step
        let scaled = value * factor
        let result: Double
        switch mode {
        case .round: result = scaled.rounded()
        case .floor: result = scaled.rounded(.down)
        case .ceil: result = scaled.rounded(.up)
        }
        return result / factor
    }

    static func average(_ a: Double, _ b: Double) -> Double { (a + b) / 2 }

    /// Whether `a` and `b` are within `precision` of each other (`isCloseTo`).
    static func isCloseTo(_ a: Double, _ b: Double, precision: Double = ExcalidrawMath.precision) -> Bool {
        abs(a - b) < precision
    }
}
