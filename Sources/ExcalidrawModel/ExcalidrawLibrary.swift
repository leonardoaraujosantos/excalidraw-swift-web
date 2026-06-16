import Foundation

/// A reusable library of element groups (`.excalidrawlib`). Reads both the v1
/// shape (`library: [[element, ...], ...]`) and v2 (`libraryItems: [{ elements }]`),
/// and writes v2 (the current Excalidraw format).
public struct ExcalidrawLibrary: Equatable, Sendable {
    /// Each item is a group of elements stamped onto the canvas as a unit.
    public var items: [[ExcalidrawElement]]

    public init(items: [[ExcalidrawElement]] = []) {
        self.items = items
    }

    public static func decode(from data: Data) throws -> ExcalidrawLibrary {
        try JSONDecoder().decode(ExcalidrawLibrary.self, from: data)
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

extension ExcalidrawLibrary: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, version, library, libraryItems
    }

    private struct LibraryItemV2: Codable {
        var id: String?
        var status: String?
        var created: Int?
        var name: String?
        var elements: [ExcalidrawElement]
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v1 = try c.decodeIfPresent([[ExcalidrawElement]].self, forKey: .library) {
            items = v1
        } else if let v2 = try c.decodeIfPresent([LibraryItemV2].self, forKey: .libraryItems) {
            items = v2.map(\.elements)
        } else {
            items = []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode("excalidrawlib", forKey: .type)
        try c.encode(2, forKey: .version)
        let v2 = items.map { LibraryItemV2(id: nil, status: "unpublished", created: 0, name: nil, elements: $0) }
        try c.encode(v2, forKey: .libraryItems)
    }
}
