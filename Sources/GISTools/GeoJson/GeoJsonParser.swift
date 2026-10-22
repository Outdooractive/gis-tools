import Foundation

// MARK: - GeoJson parsing

/// How ``GeoJsonParser`` treats malformed input.
public enum GeoJsonParsingMode: Sendable, Equatable {

    /// Return the parsed object and report skipped or malformed elements in
    /// ``GeoJsonParseResult/issues``.
    case lenient

    /// Throw a ``GeoJsonParsingError`` for the first malformed element.
    case strict

}

/// One problem found while parsing a GeoJSON document.
public struct GeoJsonParseIssue: Sendable, Equatable, Hashable, CustomStringConvertible {

    /// A JSON Pointer to the offending element (e.g. `/features/0/geometry/coordinates/1`).
    public let path: String

    /// A human-readable description of the problem.
    public let message: String

    /// Create an issue.
    ///
    /// - Parameters:
    ///    - path: The JSON Pointer to the offending element
    ///    - message: A human-readable description
    public init(path: String, message: String) {
        self.path = path
        self.message = message
    }

    public var description: String {
        path.isEmpty ? message : "\(path): \(message)"
    }

}

/// The result of a lenient parse.
public struct GeoJsonParseResult: Sendable {

    /// The parsed object, or `nil` if nothing could be parsed.
    public let object: GeoJson?

    /// Everything that was malformed or skipped. Empty for a clean document.
    public let issues: [GeoJsonParseIssue]

}

/// A parsing error raised in strict mode or for unreadable JSON data.
public struct GeoJsonParsingError: Error, Sendable, CustomStringConvertible, LocalizedError {

    /// The first problem that stopped parsing.
    public let issue: GeoJsonParseIssue

    public var description: String {
        issue.description
    }

    public var errorDescription: String? {
        issue.description
    }

}

/// Recursively validates GeoJSON input and reports malformed elements.
///
/// The lenient object is still produced by the regular initializers, so
/// `issues` describes exactly what those initializers dropped or accepted
/// despite being malformed.
public enum GeoJsonParser {

    /// Parse GeoJSON data.
    ///
    /// - Parameters:
    ///    - jsonData: The JSON data, optionally gzip-compressed
    ///    - mode: `.strict` throws on the first issue, `.lenient` reports issues
    /// - Returns: The parsed object and any issues
    /// - Throws: ``GeoJsonParsingError`` for unreadable JSON, or for the first
    ///   issue in strict mode
    public static func parse(
        jsonData: Data,
        mode: GeoJsonParsingMode = .lenient
    ) throws -> GeoJsonParseResult {
        guard let jsonData = Gzip.decompressIfNeeded(jsonData),
              let json = try? JSONSerialization.jsonObject(with: jsonData)
        else {
            throw GeoJsonParsingError(issue: GeoJsonParseIssue(
                path: "",
                message: "Invalid JSON data"))
        }
        return try parse(json: json, mode: mode)
    }

    /// Parse a GeoJSON string.
    ///
    /// - Parameters:
    ///    - jsonString: The JSON string
    ///    - mode: `.strict` throws on the first issue, `.lenient` reports issues
    /// - Returns: The parsed object and any issues
    /// - Throws: ``GeoJsonParsingError`` for unreadable JSON, or for the first
    ///   issue in strict mode
    public static func parse(
        jsonString: String,
        mode: GeoJsonParsingMode = .lenient
    ) throws -> GeoJsonParseResult {
        guard let data = jsonString.data(using: .utf8) else {
            throw GeoJsonParsingError(issue: GeoJsonParseIssue(
                path: "",
                message: "String is not valid UTF-8"))
        }
        return try parse(jsonData: data, mode: mode)
    }

    /// Parse a GeoJSON-compatible Swift object.
    ///
    /// - Parameters:
    ///    - json: A GeoJSON-compatible Swift object
    ///    - mode: `.strict` throws on the first issue, `.lenient` reports issues
    /// - Returns: The parsed object and any issues
    /// - Throws: ``GeoJsonParsingError`` for the first issue in strict mode
    public static func parse(
        json: Any?,
        mode: GeoJsonParsingMode = .lenient
    ) throws -> GeoJsonParseResult {
        var issues = validate(json: json, path: "")

        let object = GeoJsonReader.geoJsonFrom(json: json)
        if object == nil, issues.isEmpty {
            issues.append(GeoJsonParseIssue(
                path: "",
                message: "Not a GeoJSON object"))
        }

        if mode == .strict, let first = issues.first {
            throw GeoJsonParsingError(issue: first)
        }

        return GeoJsonParseResult(object: object, issues: issues)
    }

    /// Parse GeoJSON data and require a specific GeoJSON type.
    ///
    /// - Parameters:
    ///    - jsonData: The JSON data
    ///    - type: The expected GeoJSON type
    ///    - mode: `.strict` throws on the first issue, `.lenient` reports issues
    /// - Returns: The object as `T`, or `nil` if the document has another type,
    ///   plus any issues
    /// - Throws: ``GeoJsonParsingError`` for the first issue in strict mode or
    ///   for a type mismatch
    public static func parse<T: GeoJson>(
        jsonData: Data,
        as type: T.Type,
        mode: GeoJsonParsingMode = .lenient
    ) throws -> (object: T?, issues: [GeoJsonParseIssue]) {
        let result = try parse(jsonData: jsonData, mode: mode)
        return try typed(result, as: type, mode: mode)
    }

    /// Parse a GeoJSON string and require a specific GeoJSON type.
    ///
    /// - Parameters:
    ///    - jsonString: The JSON string
    ///    - type: The expected GeoJSON type
    ///    - mode: `.strict` throws on the first issue, `.lenient` reports issues
    /// - Returns: The object as `T`, or `nil` if the document has another type,
    ///   plus any issues
    /// - Throws: ``GeoJsonParsingError`` for the first issue in strict mode or
    ///   for a type mismatch
    public static func parse<T: GeoJson>(
        jsonString: String,
        as type: T.Type,
        mode: GeoJsonParsingMode = .lenient
    ) throws -> (object: T?, issues: [GeoJsonParseIssue]) {
        let result = try parse(jsonString: jsonString, mode: mode)
        return try typed(result, as: type, mode: mode)
    }

    /// Parse a GeoJSON-compatible Swift object and require a specific type.
    ///
    /// - Parameters:
    ///    - json: A GeoJSON-compatible Swift object
    ///    - type: The expected GeoJSON type
    ///    - mode: `.strict` throws on the first issue, `.lenient` reports issues
    /// - Returns: The object as `T`, or `nil` if the document has another type,
    ///   plus any issues
    /// - Throws: ``GeoJsonParsingError`` for the first issue in strict mode or
    ///   for a type mismatch
    public static func parse<T: GeoJson>(
        json: Any?,
        as type: T.Type,
        mode: GeoJsonParsingMode = .lenient
    ) throws -> (object: T?, issues: [GeoJsonParseIssue]) {
        let result = try parse(json: json, mode: mode)
        return try typed(result, as: type, mode: mode)
    }

    private static func typed<T: GeoJson>(
        _ result: GeoJsonParseResult,
        as type: T.Type,
        mode: GeoJsonParsingMode
    ) throws -> (object: T?, issues: [GeoJsonParseIssue]) {
        var issues = result.issues

        guard let object = result.object else {
            return (nil, issues)
        }

        if let typedObject = object as? T {
            return (typedObject, issues)
        }

        let issue = GeoJsonParseIssue(
            path: "",
            message: "expected a \(String(describing: T.self)) object")
        issues.append(issue)

        if mode == .strict {
            throw GeoJsonParsingError(issue: issue)
        }

        return (nil, issues)
    }

}

// MARK: - Validation

extension GeoJsonParser {

    private static let featureMembers: Set<String> = [
        "type", "geometry", "properties", "id", "bbox",
    ]

    private static let geometryTypes: Set<GeoJsonType> = [
        .point, .multiPoint, .lineString, .multiLineString,
        .polygon, .multiPolygon, .geometryCollection,
    ]

    private static func validate(json: Any?, path: String) -> [GeoJsonParseIssue] {
        guard let dictionary = JsonCoercion.rawDictionary(json) else {
            return [issue(path, "expected a JSON object")]
        }

        guard let typeString = dictionary["type"] as? String,
              let type = GeoJsonType(rawValue: typeString),
              type != .invalid
        else {
            return [issue(path.isEmpty ? "/type" : "\(path)/type", "missing or unknown GeoJSON type")]
        }

        switch type {
        case .feature:
            return validateFeature(dictionary, path: path)

        case .featureCollection:
            return validateFeatureCollection(dictionary, path: path)

        case .point, .multiPoint, .lineString, .multiLineString,
             .polygon, .multiPolygon, .geometryCollection:
            return validateGeometry(dictionary, type: type, path: path)

        case .invalid:
            return [issue(path, "invalid GeoJSON type")]
        }
    }

    private static func validateFeature(
        _ dictionary: [String: Sendable],
        path: String
    ) -> [GeoJsonParseIssue] {
        var issues: [GeoJsonParseIssue] = []

        guard dictionary["type"] as? String == GeoJsonType.feature.rawValue else {
            issues.append(issue(path + "/type", "expected \"Feature\""))
            return issues
        }

        guard let geometry = dictionary["geometry"] else {
            issues.append(issue(path + "/geometry", "missing geometry member"))
            return issues
        }

        if !(geometry is NSNull) {
            if let geometryDictionary = JsonCoercion.dictionary(geometry),
               let typeString = geometryDictionary["type"] as? String,
               let type = GeoJsonType(rawValue: typeString),
               geometryTypes.contains(type)
            {
                issues.append(contentsOf: validateGeometry(
                    geometryDictionary,
                    type: type,
                    path: path + "/geometry"))
            }
            else {
                issues.append(issue(
                    path + "/geometry",
                    "expected a GeoJSON geometry or null"))
            }
        }

        if let properties = dictionary["properties"], !(properties is NSNull) {
            if JsonCoercion.dictionary(properties) == nil {
                issues.append(issue(path + "/properties", "properties must be an object or null"))
            }
        }

        if let id = dictionary["id"], !(id is NSNull) {
            if JsonCoercion.string(id) == nil, JsonCoercion.double(id) == nil {
                issues.append(issue(path + "/id", "feature id must be a string or number"))
            }
        }

        if let bbox = dictionary["bbox"] {
            issues.append(contentsOf: validateBoundingBox(bbox, path: path + "/bbox"))
        }

        for key in dictionary.keys where !featureMembers.contains(key) {
            if JSONValue(value: dictionary[key]) == nil {
                issues.append(issue("\(path)/\(escape(key))", "value is not JSON-compatible"))
            }
        }

        return issues
    }

    private static func validateFeatureCollection(
        _ dictionary: [String: Sendable],
        path: String
    ) -> [GeoJsonParseIssue] {
        var issues: [GeoJsonParseIssue] = []

        guard dictionary["type"] as? String == GeoJsonType.featureCollection.rawValue else {
            issues.append(issue(path + "/type", "expected \"FeatureCollection\""))
            return issues
        }

        guard let featuresJSON = dictionary["features"],
              let features = JsonCoercion.array(featuresJSON)
        else {
            issues.append(issue(path + "/features", "missing or invalid features array"))
            return issues
        }

        for (index, feature) in features.enumerated() {
            let featurePath = "\(path)/features/\(index)"

            guard let featureDictionary = JsonCoercion.dictionary(feature),
                  featureDictionary["type"] as? String == GeoJsonType.feature.rawValue
            else {
                issues.append(issue(featurePath, "expected a Feature"))
                continue
            }

            issues.append(contentsOf: validateFeature(
                featureDictionary,
                path: featurePath))
        }

        if let bbox = dictionary["bbox"] {
            issues.append(contentsOf: validateBoundingBox(bbox, path: path + "/bbox"))
        }

        return issues
    }

    private static func validateGeometry(
        _ dictionary: [String: Sendable],
        type: GeoJsonType,
        path: String
    ) -> [GeoJsonParseIssue] {
        switch type {
        case .point:
            guard let coordinates = dictionary["coordinates"] else {
                return [issue(path + "/coordinates", "missing coordinates")]
            }
            return validatePosition(coordinates, path: path + "/coordinates")

        case .multiPoint:
            return validatePositionArray(
                dictionary["coordinates"],
                path: path + "/coordinates",
                minimumCount: 1,
                description: "MultiPoint")

        case .lineString:
            return validatePositionArray(
                dictionary["coordinates"],
                path: path + "/coordinates",
                minimumCount: 2,
                description: "LineString")

        case .multiLineString:
            guard let coordinates = dictionary["coordinates"],
                  let lines = JsonCoercion.array(coordinates)
            else {
                return [issue(path + "/coordinates", "missing or invalid coordinates")]
            }

            return lines.enumerated().flatMap { index, line in
                validatePositionArray(
                    line,
                    path: "\(path)/coordinates/\(index)",
                    minimumCount: 2,
                    description: "LineString")
            }

        case .polygon:
            guard let coordinates = dictionary["coordinates"] else {
                return [issue(path + "/coordinates", "missing coordinates")]
            }
            return validatePolygonCoordinates(coordinates, path: path + "/coordinates")

        case .multiPolygon:
            guard let coordinates = dictionary["coordinates"],
                  let polygons = JsonCoercion.array(coordinates)
            else {
                return [issue(path + "/coordinates", "missing or invalid coordinates")]
            }

            return polygons.enumerated().flatMap { index, polygon in
                validatePolygonCoordinates(
                    polygon,
                    path: "\(path)/coordinates/\(index)")
            }

        case .geometryCollection:
            guard let geometriesJSON = dictionary["geometries"],
                  let geometries = JsonCoercion.array(geometriesJSON)
            else {
                return [issue(path + "/geometries", "missing or invalid geometries array")]
            }

            return geometries.enumerated().flatMap { index, geometry in
                let geometryPath = "\(path)/geometries/\(index)"

                guard let geometryDictionary = JsonCoercion.dictionary(geometry),
                      let typeString = geometryDictionary["type"] as? String,
                      let type = GeoJsonType(rawValue: typeString),
                      geometryTypes.contains(type)
                else {
                    return [issue(geometryPath, "expected a GeoJSON geometry")]
                }

                return validateGeometry(
                    geometryDictionary,
                    type: type,
                    path: geometryPath)
            }

        default:
            return [issue(path, "invalid GeoJSON geometry type")]
        }
    }

    private static func validatePositionArray(
        _ json: Any?,
        path: String,
        minimumCount: Int,
        description: String
    ) -> [GeoJsonParseIssue] {
        guard let positions = JsonCoercion.array(json) else {
            return [issue(path, "missing or invalid \(description) coordinates")]
        }

        var issues: [GeoJsonParseIssue] = []
        if positions.count < minimumCount {
            issues.append(issue(
                path,
                "\(description) requires at least \(minimumCount) positions"))
        }

        for (index, position) in positions.enumerated() {
            issues.append(contentsOf: validatePosition(
                position,
                path: "\(path)/\(index)"))
        }

        return issues
    }

    private static func validatePolygonCoordinates(
        _ json: Any?,
        path: String
    ) -> [GeoJsonParseIssue] {
        guard let rings = JsonCoercion.array(json), rings.isNotEmpty else {
            return [issue(path, "polygon requires at least one ring")]
        }

        return rings.enumerated().flatMap { index, ring in
            validateRing(ring, path: "\(path)/\(index)")
        }
    }

    private static func validateRing(
        _ json: Any?,
        path: String
    ) -> [GeoJsonParseIssue] {
        guard let positions = JsonCoercion.array(json) else {
            return [issue(path, "invalid polygon ring")]
        }

        var issues: [GeoJsonParseIssue] = []
        if positions.count < 4 {
            issues.append(issue(
                path,
                "polygon ring requires at least four positions"))
        }

        for (index, position) in positions.enumerated() {
            issues.append(contentsOf: validatePosition(
                position,
                path: "\(path)/\(index)"))
        }

        return issues
    }

    private static func validatePosition(
        _ json: Any?,
        path: String
    ) -> [GeoJsonParseIssue] {
        guard let values = JsonCoercion.array(json) else {
            return [issue(path, "expected a position array")]
        }

        guard values.count >= 2 else {
            return [issue(path, "position requires at least two numbers")]
        }

        var issues: [GeoJsonParseIssue] = []

        for index in 0 ..< min(values.count, 2)
            where JsonCoercion.double(values[index]) == nil
        {
            issues.append(issue("\(path)/\(index)", "expected a number"))
        }

        for index in 2 ..< values.count {
            if values[index] is NSNull {
                continue
            }
            if JsonCoercion.double(values[index]) == nil {
                issues.append(issue("\(path)/\(index)", "expected a number or null"))
            }
        }

        return issues
    }

    private static func validateBoundingBox(
        _ json: Any?,
        path: String
    ) -> [GeoJsonParseIssue] {
        guard let values = JsonCoercion.array(json),
              values.count == 4 || values.count == 6
        else {
            return [issue(path, "bbox must contain four or six numbers")]
        }

        var issues: [GeoJsonParseIssue] = []
        for (index, value) in values.enumerated() where JsonCoercion.double(value) == nil {
            issues.append(issue("\(path)/\(index)", "expected a number"))
        }
        return issues
    }

    private static func issue(_ path: String, _ message: String) -> GeoJsonParseIssue {
        GeoJsonParseIssue(path: path, message: message)
    }

    /// Escape a JSON Pointer path segment.
    private static func escape(_ segment: String) -> String {
        segment
            .replacingOccurrences(of: "~", with: "~0")
            .replacingOccurrences(of: "/", with: "~1")
    }

}

// MARK: - FeatureCollection convenience

extension FeatureCollection {

    /// Parse GeoJSON data as a `FeatureCollection`, reporting issues.
    ///
    /// Any GeoJSON object is normalized into a collection, matching
    /// ``FeatureCollection/init(_:calculateBoundingBox:)``.
    ///
    /// - Parameters:
    ///    - jsonData: The JSON data
    ///    - issues: Receives every malformed or skipped element
    /// - Returns: A feature collection, or `nil` if nothing could be parsed
    public init?(
        jsonData: Data,
        issues: inout [GeoJsonParseIssue]
    ) {
        do {
            let result = try GeoJsonParser.parse(jsonData: jsonData)
            issues = result.issues

            guard let collection = FeatureCollection(result.object) else {
                return nil
            }
            self = collection
        }
        catch let error as GeoJsonParsingError {
            issues = [error.issue]
            return nil
        }
        catch {
            issues = [GeoJsonParseIssue(
                path: "",
                message: error.localizedDescription)]
            return nil
        }
    }

    /// Parse a GeoJSON string as a `FeatureCollection`, reporting issues.
    ///
    /// Any GeoJSON object is normalized into a collection, matching
    /// ``FeatureCollection/init(_:calculateBoundingBox:)``.
    ///
    /// - Parameters:
    ///    - jsonString: The JSON string
    ///    - issues: Receives every malformed or skipped element
    /// - Returns: A feature collection, or `nil` if nothing could be parsed
    public init?(
        jsonString: String,
        issues: inout [GeoJsonParseIssue]
    ) {
        guard let data = jsonString.data(using: .utf8) else {
            issues = [GeoJsonParseIssue(
                path: "",
                message: "String is not valid UTF-8")]
            return nil
        }

        self.init(jsonData: data, issues: &issues)
    }

    /// Parse a GeoJSON-compatible Swift object as a `FeatureCollection`,
    /// reporting issues.
    ///
    /// Any GeoJSON object is normalized into a collection, matching
    /// ``FeatureCollection/init(_:calculateBoundingBox:)``.
    ///
    /// - Parameters:
    ///    - json: A GeoJSON-compatible Swift object
    ///    - issues: Receives every malformed or skipped element
    /// - Returns: A feature collection, or `nil` if nothing could be parsed
    public init?(
        json: Any?,
        issues: inout [GeoJsonParseIssue]
    ) {
        do {
            let result = try GeoJsonParser.parse(json: json)
            issues = result.issues

            guard let collection = FeatureCollection(result.object) else {
                return nil
            }
            self = collection
        }
        catch let error as GeoJsonParsingError {
            issues = [error.issue]
            return nil
        }
        catch {
            issues = [GeoJsonParseIssue(
                path: "",
                message: error.localizedDescription)]
            return nil
        }
    }

}
