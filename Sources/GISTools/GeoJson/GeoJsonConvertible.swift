import Foundation

/// A protocol for GeoJSON objects that can be read from and written to various datasources.
/// like `URL`s, `Data`, `String`, or any Swift object that looks like GeoJSON.
public protocol GeoJsonConvertible: GeoJsonReadable & GeoJsonWritable {}

// MARK: - GeoJsonReadable

/// A protocol for GeoJSON objects that can be read/parsed from any Swift object that looks like GeoJSON.
public protocol GeoJsonReadable {

    /// Try to initialize a GeoJSON object from anything.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    init?(json: Any?)

}

extension GeoJsonReadable {

    /// Try to initialize a GeoJSON object from a file/URL.
    ///
    /// - Parameters:
    ///    - url: The URL of the file to read
    /// - important: The source is expected to be in EPSG:4326.
    public init?(contentsOf url: URL) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        self.init(jsonData: data)
    }

    /// Try to initialize a GeoJSON object from a data object.
    ///
    /// - Parameters:
    ///    - jsonData: The JSON data
    /// - important: The source is expected to be in EPSG:4326.
    public init?(jsonData: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: jsonData) else { return nil }
        self.init(json: json)
    }

    /// Try to initialize a GeoJSON object from a string.
    ///
    /// - Parameters:
    ///    - jsonString: The JSON string
    /// - important: The source is expected to be in EPSG:4326.
    public init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data)
        else { return nil }
        self.init(json: json)
    }

}

// MARK: - GeoJsonWritable

/// A protocol for GeoJSON objects that can write to Swift dictionaries.
public protocol GeoJsonWritable {

    /// Return the GeoJson object as a Swift dictionary.
    ///
    /// - important: Always projected to EPSG:4326, unless the receiver has no SRID.
    var asJson: [String: Sendable] { get }

}

extension GeoJsonWritable {

    /// Dump the object as JSON data.
    ///
    /// - Parameters:
    ///    - prettyPrinted: When `true`, format the output with indentation and sorted keys
    /// - Returns: The JSON data, or `nil` if serialization failed
    /// - important: Always projected to EPSG:4326, unless the coordinate has no SRID.
    public func asJsonData(prettyPrinted: Bool = false) -> Data? {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
            options.insert(.prettyPrinted)
            options.insert(.sortedKeys)
        }

        return try? JSONSerialization.data(withJSONObject: asJson, options: options)
    }

    /// Dump the object as a JSON string.
    ///
    /// - Parameters:
    ///    - prettyPrinted: When `true`, format the output with indentation and sorted keys
    /// - Returns: The JSON string, or `nil` if serialization failed
    /// - important: Always projected to EPSG:4326, unless the coordinate has no SRID.
    public func asJsonString(prettyPrinted: Bool = false) -> String? {
        guard let data = asJsonData(prettyPrinted: prettyPrinted) else { return nil }

        return String(data: data, encoding: .utf8)
    }

    /// Write the object in it's JSON representation to a file.
    ///
    /// - Parameters:
    ///    - url: The file URL to write to
    ///    - prettyPrinted: When `true`, format the output with indentation and sorted keys
    /// - Returns: `true` if the write succeeded, `false` if serialization failed.
    @discardableResult
    public func write(to url: URL, prettyPrinted: Bool = false) -> Bool {
        guard let data = asJsonData(prettyPrinted: prettyPrinted) else { return false }

        do {
            try data.write(to: url)
            return true
        }
        catch {
            return false
        }
    }

}

// MARK: - Convenience

// Helper extension to create a valid json array from a sequence of GeoJsonConvertible objects
extension Sequence where Self.Iterator.Element: GeoJsonWritable {

    /// Returns all elements as an array of JSON objects
    ///
    /// - Returns: An array of JSON dictionaries
    /// - important: Always projected to EPSG:4326, unless the coordinate has no SRID.
    public var asJson: [[String: Sendable]] {
        self.map({ $0.asJson })
    }

}

// MARK: - Debugging

extension GeoJsonWritable {

    /// Prints the receiver to the console.
    public func dump() {
        guard let stringified = asJsonString(prettyPrinted: true) else { return }

        print(stringified, separator: "")
    }

}
