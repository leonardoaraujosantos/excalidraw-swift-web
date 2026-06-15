import ExcalidrawMath
import Foundation

/// Fields shared by every Excalidraw element (`_ExcalidrawElementBase`).
///
/// Decoding is lenient — missing keys fall back to upstream defaults so older or
/// partial files still load (the restore step then canonicalises). Encoding
/// always writes the canonical key set; nullable structural keys are emitted as
/// `null` to mirror Excalidraw output.
public struct BaseProperties: Equatable, Sendable {
    public var id: String
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var angle: Double
    public var strokeColor: String
    public var backgroundColor: String
    public var fillStyle: FillStyle
    public var strokeWidth: Double
    public var strokeStyle: StrokeStyle
    public var roundness: Roundness?
    public var roughness: Double
    public var opacity: Double
    public var seed: Int
    public var version: Int
    public var versionNonce: Int
    public var index: String?
    public var isDeleted: Bool
    public var groupIds: [String]
    public var frameId: String?
    public var boundElements: [BoundElement]?
    public var updated: Int
    public var link: String?
    public var locked: Bool
    public var customData: [String: JSONValue]?

    public init(
        id: String,
        x: Double = 0,
        y: Double = 0,
        width: Double = 0,
        height: Double = 0,
        angle: Double = 0,
        strokeColor: String = "#1e1e1e",
        backgroundColor: String = "transparent",
        fillStyle: FillStyle = .solid,
        strokeWidth: Double = 2,
        strokeStyle: StrokeStyle = .solid,
        roundness: Roundness? = nil,
        roughness: Double = 1,
        opacity: Double = 100,
        seed: Int = 1,
        version: Int = 1,
        versionNonce: Int = 0,
        index: String? = nil,
        isDeleted: Bool = false,
        groupIds: [String] = [],
        frameId: String? = nil,
        boundElements: [BoundElement]? = nil,
        updated: Int = 0,
        link: String? = nil,
        locked: Bool = false,
        customData: [String: JSONValue]? = nil
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.angle = angle
        self.strokeColor = strokeColor
        self.backgroundColor = backgroundColor
        self.fillStyle = fillStyle
        self.strokeWidth = strokeWidth
        self.strokeStyle = strokeStyle
        self.roundness = roundness
        self.roughness = roughness
        self.opacity = opacity
        self.seed = seed
        self.version = version
        self.versionNonce = versionNonce
        self.index = index
        self.isDeleted = isDeleted
        self.groupIds = groupIds
        self.frameId = frameId
        self.boundElements = boundElements
        self.updated = updated
        self.link = link
        self.locked = locked
        self.customData = customData
    }
}

extension BaseProperties {
    init(from c: KeyedDecodingContainer<ElementCodingKeys>) throws {
        id = try c.decode(String.self, forKey: .id)
        x = try c.decodeIfPresent(Double.self, forKey: .x) ?? 0
        y = try c.decodeIfPresent(Double.self, forKey: .y) ?? 0
        width = try c.decodeIfPresent(Double.self, forKey: .width) ?? 0
        height = try c.decodeIfPresent(Double.self, forKey: .height) ?? 0
        angle = try c.decodeIfPresent(Double.self, forKey: .angle) ?? 0
        strokeColor = try c.decodeIfPresent(String.self, forKey: .strokeColor) ?? "#1e1e1e"
        backgroundColor = try c.decodeIfPresent(String.self, forKey: .backgroundColor) ?? "transparent"
        fillStyle = try c.decodeIfPresent(FillStyle.self, forKey: .fillStyle) ?? .solid
        strokeWidth = try c.decodeIfPresent(Double.self, forKey: .strokeWidth) ?? 2
        strokeStyle = try c.decodeIfPresent(StrokeStyle.self, forKey: .strokeStyle) ?? .solid
        roundness = try c.decodeIfPresent(Roundness.self, forKey: .roundness)
        roughness = try c.decodeIfPresent(Double.self, forKey: .roughness) ?? 1
        opacity = try c.decodeIfPresent(Double.self, forKey: .opacity) ?? 100
        seed = try c.decodeIfPresent(Int.self, forKey: .seed) ?? 1
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        versionNonce = try c.decodeIfPresent(Int.self, forKey: .versionNonce) ?? 0
        index = try c.decodeIfPresent(String.self, forKey: .index)
        isDeleted = try c.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        groupIds = try c.decodeIfPresent([String].self, forKey: .groupIds) ?? []
        frameId = try c.decodeIfPresent(String.self, forKey: .frameId)
        boundElements = try c.decodeIfPresent([BoundElement].self, forKey: .boundElements)
        updated = try c.decodeIfPresent(Int.self, forKey: .updated) ?? 0
        link = try c.decodeIfPresent(String.self, forKey: .link)
        locked = try c.decodeIfPresent(Bool.self, forKey: .locked) ?? false
        customData = try c.decodeIfPresent([String: JSONValue].self, forKey: .customData)
    }

    func encode(into c: inout KeyedEncodingContainer<ElementCodingKeys>) throws {
        try c.encode(id, forKey: .id)
        try c.encode(x, forKey: .x)
        try c.encode(y, forKey: .y)
        try c.encode(width, forKey: .width)
        try c.encode(height, forKey: .height)
        try c.encode(angle, forKey: .angle)
        try c.encode(strokeColor, forKey: .strokeColor)
        try c.encode(backgroundColor, forKey: .backgroundColor)
        try c.encode(fillStyle, forKey: .fillStyle)
        try c.encode(strokeWidth, forKey: .strokeWidth)
        try c.encode(strokeStyle, forKey: .strokeStyle)
        try c.encode(roundness, forKey: .roundness) // null when nil
        try c.encode(roughness, forKey: .roughness)
        try c.encode(opacity, forKey: .opacity)
        try c.encode(seed, forKey: .seed)
        try c.encode(version, forKey: .version)
        try c.encode(versionNonce, forKey: .versionNonce)
        try c.encode(index, forKey: .index)
        try c.encode(isDeleted, forKey: .isDeleted)
        try c.encode(groupIds, forKey: .groupIds)
        try c.encode(frameId, forKey: .frameId)
        try c.encode(boundElements, forKey: .boundElements)
        try c.encode(updated, forKey: .updated)
        try c.encode(link, forKey: .link)
        try c.encode(locked, forKey: .locked)
        try c.encodeIfPresent(customData, forKey: .customData)
    }
}
