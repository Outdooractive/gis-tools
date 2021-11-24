import Foundation

// MARK: GeoJsonReadable

public protocol GeoJsonReadable {

    // Any GeoJSON object
    init?(json: Any?)

}

extension GeoJsonReadable {

    public init?(contentsOf url: URL) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        self.init(jsonData: data)
    }

    public init?(jsonData: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: jsonData) else { return nil }
        self.init(json: json)
    }

    public init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data)
        else { return nil }
        self.init(json: json)
    }

}

// MARK: - GeoJsonWritable

public protocol GeoJsonWritable {

    // Return the GeoJson object as JSON
    func asJson() -> [String: Any]

}

extension GeoJsonWritable {

    public func asJsonData(prettyPrinted: Bool = false) -> Data? {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
            options.insert(.prettyPrinted)
            if #available(OSX 10.13, iOS 11.0, *) {
                options.insert(.sortedKeys)
            }
        }

        return try? JSONSerialization.data(withJSONObject: asJson(), options: options)
    }

    public func asJsonString(prettyPrinted: Bool = false) -> String? {
        guard let data = asJsonData(prettyPrinted: prettyPrinted) else { return nil }

        return String(data: data, encoding: .utf8)!
    }

    public func write(to url: URL, prettyPrinted: Bool = false) throws {
        try asJsonData(prettyPrinted: prettyPrinted)?.write(to: url)
    }

}

// MARK: - GeoJsonConvertible

public protocol GeoJsonConvertible: GeoJsonReadable & GeoJsonWritable {}

// Helper extension to create a valid json array from a sequence of GeoJsonConvertible objects
public extension Sequence where Self.Iterator.Element: GeoJsonConvertible {

    func asJson() -> [Any] {
        return self.compactMap({ $0.asJson() })
    }

}
