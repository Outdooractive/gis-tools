import Foundation

// MARK: - GeoJsonConvertible

/// A protocol for GeoJSON objects that can be read from and written to JSON.
public protocol GeoJsonConvertible: GeoJsonReadable & GeoJsonWritable {}

// MARK: GeoJsonReadable

/// A protocol for GeoJSON objects that can be read from JSON.
public protocol GeoJsonReadable {

    /// Try to initialize a GeoJSON object from any JSON.
    init?(json: Any?)

}

extension GeoJsonReadable {

    /// Try to initialize an object from a file.
    public init?(contentsOf url: URL) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        self.init(jsonData: data)
    }

    /// Try to initialize an object from a data object.
    public init?(jsonData: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: jsonData) else { return nil }
        self.init(json: json)
    }

    /// Try to initialize an object from a string.
    public init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data)
        else { return nil }
        self.init(json: json)
    }

}

// MARK: - GeoJsonWritable

/// A protocol for GeoJSON objects that can write to JSON.
public protocol GeoJsonWritable {

    /// Return the GeoJson object as JSON.
    var asJson: [String: Any] { get }

}

extension GeoJsonWritable {

    /// Dump the object as JSON.
    public func asJsonData(prettyPrinted: Bool = false) -> Data? {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
            options.insert(.prettyPrinted)
            options.insert(.sortedKeys)
        }

        return try? JSONSerialization.data(withJSONObject: asJson, options: options)
    }

    /// Dump the object as JSON.
    public func asJsonString(prettyPrinted: Bool = false) -> String? {
        guard let data = asJsonData(prettyPrinted: prettyPrinted) else { return nil }

        return String(data: data, encoding: .utf8)!
    }

    /// Write the object in it's JSON represenation to a file.
    public func write(to url: URL, prettyPrinted: Bool = false) throws {
        try asJsonData(prettyPrinted: prettyPrinted)?.write(to: url)
    }

}

// MARK: - Convenience

// Helper extension to create a valid json array from a sequence of GeoJsonConvertible objects
extension Sequence where Self.Iterator.Element: GeoJsonWritable {

    /// Returns all elements as an array of JSON objects
    public var asJson: [[String: Any]] {
        return self.map({ $0.asJson })
    }

}
