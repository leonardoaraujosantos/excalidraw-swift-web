import Foundation

public extension ExcalidrawFile {
    /// Decode a `.excalidraw` document from raw JSON bytes.
    static func decode(from data: Data) throws -> ExcalidrawFile {
        try JSONDecoder().decode(ExcalidrawFile.self, from: data)
    }

    /// Encode to JSON. `sortedKeys` makes output stable/diffable; Excalidraw
    /// itself pretty-prints with 2-space indentation.
    func jsonData(prettyPrinted: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        var formatting: JSONEncoder.OutputFormatting = []
        if prettyPrinted { formatting.insert(.prettyPrinted) }
        formatting.insert(.sortedKeys)
        encoder.outputFormatting = formatting
        return try encoder.encode(self)
    }
}
