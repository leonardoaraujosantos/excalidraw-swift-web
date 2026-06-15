import Foundation

/// Fill pattern for shape backgrounds (`packages/element/src/types.ts: FillStyle`).
public enum FillStyle: String, Codable, Sendable, CaseIterable {
    case hachure
    case crossHatch = "cross-hatch"
    case solid
    case zigzag
}

/// Stroke line style (`StrokeStyle`).
public enum StrokeStyle: String, Codable, Sendable, CaseIterable {
    case solid
    case dashed
    case dotted
}

/// Horizontal text alignment (`TEXT_ALIGN`).
public enum TextAlign: String, Codable, Sendable, CaseIterable {
    case left
    case center
    case right
}

/// Vertical text alignment (`VERTICAL_ALIGN`).
public enum VerticalAlign: String, Codable, Sendable, CaseIterable {
    case top
    case middle
    case bottom
}

/// Image persistence status (`ExcalidrawImageElement.status`).
public enum ImageStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case saved
    case error
}

/// Arrowhead styles, including legacy values still present in older files
/// (`Arrowhead` + `ArrowheadLegacy`).
public enum Arrowhead: String, Codable, Sendable, CaseIterable {
    case arrow
    case bar
    case circle
    case circleOutline = "circle_outline"
    case triangle
    case triangleOutline = "triangle_outline"
    case diamond
    case diamondOutline = "diamond_outline"
    case cardinalityOne = "cardinality_one"
    case cardinalityMany = "cardinality_many"
    case cardinalityOneOrMany = "cardinality_one_or_many"
    case cardinalityExactlyOne = "cardinality_exactly_one"
    case cardinalityZeroOrOne = "cardinality_zero_or_one"
    case cardinalityZeroOrMany = "cardinality_zero_or_many"
    // Legacy
    case dot
    case crowfootOne = "crowfoot_one"
    case crowfootMany = "crowfoot_many"
    case crowfootOneOrMany = "crowfoot_one_or_many"
}

/// Binding containment mode (`BindMode`).
public enum BindMode: String, Codable, Sendable, CaseIterable {
    case inside
    case orbit
    case skip
}

/// Font family ids are stored as integers in the file. Stable known values from
/// upstream `FONT_FAMILY`; kept as an `Int` namespace (not an enum) so unknown /
/// future ids round-trip losslessly.
public enum FontFamily {
    public static let virgil = 1
    public static let helvetica = 2
    public static let cascadia = 3
    public static let excalifont = 5
    public static let nunito = 6
    public static let lilitaOne = 7
    public static let comicShanns = 8
    public static let liberationSans = 9
    public static let assistant = 10

    /// Default for new text (`DEFAULT_FONT_FAMILY` = Excalifont).
    public static let `default` = excalifont
}

/// Roundness types (`ROUNDNESS`). Stored as an integer in `roundness.type`.
public enum RoundnessType {
    public static let legacy = 1
    public static let proportionalRadius = 2
    public static let adaptiveRadius = 3
}
