import Foundation

// MARK: GeoJsonGeometry extension

extension GeoJsonGeometry {

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkt: String,
        srid: Int?,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKTCoder.decode(wkt: wkt, srid: srid) else { return nil }
        self.init(json: geometry.asJson, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkt: String,
        projection: Projection,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKTCoder.decode(wkt: wkt, projection: projection) else { return nil }
        self.init(json: geometry.asJson, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func parse(
        wkt: String,
        srid: Int?)
        -> GeoJsonGeometry?
    {
        try? WKTCoder.decode(wkt: wkt, srid: srid)
    }

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func parse(
        wkt: String,
        projection: Projection)
        -> GeoJsonGeometry?
    {
        try? WKTCoder.decode(wkt: wkt, projection: projection)
    }

    public var asWKT: String? {
        return WKTCoder.encode(geometry: self)
    }

}

// MARK: - Feature extension

extension Feature {

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkt: String,
        srid: Int?,
        properties: [String: Any] = [:],
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKTCoder.decode(wkt: wkt, srid: srid) else { return nil }
        self.init(geometry, properties: properties, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkt: String,
        projection: Projection,
        properties: [String: Any] = [:],
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKTCoder.decode(wkt: wkt, projection: projection) else { return nil }
        self.init(geometry, properties: properties, calculateBoundingBox: calculateBoundingBox)
    }

    public var asWKT: String? {
        return WKTCoder.encode(geometry: self.geometry)
    }

}

// MARK: - FeatureCollection extension

extension FeatureCollection {

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkt: String,
        srid: Int?,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKTCoder.decode(wkt: wkt, srid: srid) else { return nil }
        if let geometryCollection = geometry as? GeometryCollection {
            self.init(geometryCollection.geometries, calculateBoundingBox: calculateBoundingBox)
        }
        else {
            self.init([geometry], calculateBoundingBox: calculateBoundingBox)
        }
    }

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkt: String,
        projection: Projection,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKTCoder.decode(wkt: wkt, projection: projection) else { return nil }
        if let geometryCollection = geometry as? GeometryCollection {
            self.init(geometryCollection.geometries, calculateBoundingBox: calculateBoundingBox)
        }
        else {
            self.init([geometry], calculateBoundingBox: calculateBoundingBox)
        }
    }

    public var asWKT: String? {
        return WKTCoder.encode(geometry: GeometryCollection(self.features.map(\.geometry)))
    }

}

// MARK: - String extensions

extension String {

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asGeoJsonGeometry(srid: Int?) -> GeoJsonGeometry? {
        GeometryCollection.parse(wkt: self, srid: srid)
    }

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asGeoJsonGeometry(projection: Projection) -> GeoJsonGeometry? {
        GeometryCollection.parse(wkt: self, projection: projection)
    }

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeature(
        srid: Int?,
        properties: [String: Any] = [:])
        -> Feature?
    {
        Feature(wkt: self, srid: srid, properties: properties)
    }

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeature(
        projection: Projection,
        properties: [String: Any] = [:])
        -> Feature?
    {
        Feature(wkt: self, projection: projection, properties: properties)
    }

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeatureCollection(srid: Int?) -> FeatureCollection? {
        FeatureCollection(wkt: self, srid: srid)
    }

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeatureCollection(projection: Projection) -> FeatureCollection? {
        FeatureCollection(wkt: self, projection: projection)
    }

}

// MARK: - WKTCoder

// This code borrows a lot from https://github.com/plarson/WKCodable

/// A tool for encoding and decoding GeoJSON objects from WKT.
public struct WKTCoder {

    enum WKTTypeCode: String {
        case point = "point"
        case lineString = "linestring"
        case polygon = "polygon"
        case multiPoint = "multipoint"
        case multiLineString = "multilinestring"
        case multiPolygon = "multipolygon"
        case geometryCollection = "geometrycollection"
        case triangle = "triangle"
    }

    public enum WKTCoderError: Error {
        case dataCorrupted
        case emptyGeometry
        case invalidGeometry
        case unknownSRID
        case unexpectedType
    }

}

// MARK: - WKT decoding

extension WKTCoder {

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func decode(
        wkt: String,
        srid: Int?)
        throws -> GeoJsonGeometry
    {
        var projection: Projection?

        if let srid = srid {
            projection = Projection(srid: srid)
            guard projection != nil, projection != .noSRID else { throw WKTCoderError.unknownSRID }
        }

        return try decode(wkt: wkt, projection: projection)
    }

    /// Decode WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func decode(
        wkt: String,
        projection: Projection?)
        throws -> GeoJsonGeometry
    {
        let scanner = Scanner(string: wkt)
        scanner.charactersToBeSkipped = .whitespaces
        scanner.caseSensitive = false

        var projection = projection
        if projection == nil,
           let srid = try scanSRID(scanner: scanner)
        {
            projection = Projection(srid: srid)
        }
        guard let projection = projection, projection != .noSRID else { throw WKTCoderError.unknownSRID }

        return try scanGeometry(scanner: scanner, projection: projection)
    }

    // MARK: -

    private static func scanGeometry(
        scanner: Scanner,
        projection: Projection)
        throws -> GeoJsonGeometry
    {
        var decodeZ = false
        var decodeM = false

        guard let type = scanType(scanner: scanner, decodeZ: &decodeZ, decodeM: &decodeM) else {
            throw WKTCoderError.dataCorrupted
        }

        switch type {
        case .point:
            guard let coordinate = try scanCoordinates(scanner: scanner, projection: projection, decodeZ: decodeZ, decodeM: decodeM)?.first else {
                throw WKTCoderError.dataCorrupted
            }
            return Point(coordinate)

        case .multiPoint:
            var points: [Point] = []

            // Two options:
            // - Array of points
            // - Array of coordinates
            let location = scanner.currentIndex
            if scanner.scanString("((") != nil {
                scanner.currentIndex = scanner.string.index(after: location)

                while scanner.scanString(")") == nil {
                    if let coordinates = try scanCoordinates(scanner: scanner, projection: projection, decodeZ: decodeZ, decodeM: decodeM) {
                        points.append(contentsOf: coordinates.asPoints)
                    }
                    _ = scanner.scanString(",")
                }
            }
            else {
                if let coordinates = try scanCoordinates(scanner: scanner, projection: projection, decodeZ: decodeZ, decodeM: decodeM) {
                    points.append(contentsOf: coordinates.asPoints)
                }
            }

            return MultiPoint(points) ?? MultiPoint()

        case .lineString:
            return try decodeLineString(scanner: scanner, projection: projection, decodeZ: decodeZ, decodeM: decodeM)

        case .multiLineString:
            var lineStrings: [LineString] = []

            guard scanner.scanString("(") != nil else {
                throw WKTCoderError.dataCorrupted
            }

            while scanner.scanString(")") == nil {
                lineStrings.append(try decodeLineString(scanner: scanner, projection: projection, decodeZ: decodeZ, decodeM: decodeM))
                _ = scanner.scanString(",")
            }

            return MultiLineString(lineStrings) ?? MultiLineString()

        case .polygon, .triangle:
            return try decodePolygon(scanner: scanner, projection: projection, decodeZ: decodeZ, decodeM: decodeM)

        case .multiPolygon:
            var polygons: [Polygon] = []

            guard scanner.scanString("(") != nil else {
                throw WKTCoderError.dataCorrupted
            }

            while scanner.scanString(")") == nil {
                polygons.append(try decodePolygon(scanner: scanner, projection: projection, decodeZ: decodeZ, decodeM: decodeM))
                _ = scanner.scanString(",")
            }

            return MultiPolygon(polygons) ?? MultiPolygon()

        case .geometryCollection:
            var geometries: [GeoJsonGeometry] = []

            guard scanner.scanString("(") != nil else {
                throw WKTCoderError.dataCorrupted
            }

            while scanner.scanString(")") == nil {
                geometries.append(try scanGeometry(scanner: scanner, projection: projection))
                _ = scanner.scanString(",")
            }

            return GeometryCollection(geometries)
        }
    }

    private static func decodeLineString(
        scanner: Scanner,
        projection: Projection,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> LineString
    {
        if let coordinates = try scanCoordinates(scanner: scanner, projection: projection, decodeZ: decodeZ, decodeM: decodeM) {
            guard let lineString = LineString(coordinates) else {
                throw WKTCoderError.dataCorrupted
            }
            return lineString
        }
        return LineString()
    }

    private static func decodePolygon(
        scanner: Scanner,
        projection: Projection,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> Polygon
    {
        var rings: [Ring] = []

        guard scanner.scanString("(") != nil else {
            throw WKTCoderError.dataCorrupted
        }

        while scanner.scanString(")") == nil {
            if let coordinates = try scanCoordinates(scanner: scanner, projection: projection, decodeZ: decodeZ, decodeM: decodeM) {
                guard let ring = Ring(coordinates) else {
                    throw WKTCoderError.dataCorrupted
                }
                rings.append(ring)
            }
            _ = scanner.scanString(",")
        }

        if rings.isEmpty {
            return Polygon()
        }

        guard let polygon = Polygon(rings) else {
            throw WKTCoderError.dataCorrupted
        }
        return polygon
    }

    // MARK: -

    private static func scanSRID(scanner: Scanner) throws -> Int? {
        if scanner.scanString("SRID=") == nil {
            return nil
        }

        guard let srid = scanner.scanInt32() else {
            throw WKTCoderError.dataCorrupted
        }

        if scanner.scanString(";") == nil {
            throw WKTCoderError.dataCorrupted
        }

        return Int(srid)
    }

    private static func scanType(
        scanner: Scanner,
        decodeZ: inout Bool,
        decodeM: inout Bool)
        -> WKTTypeCode?
    {
        let boundarySet = CharacterSet(charactersIn: "(")
        guard let rawType = scanner.scanUpToCharacters(from: boundarySet) else { return nil }

        var rawTypeLowercased = rawType.lowercased().trimmed()

        if rawTypeLowercased.hasSuffix("m") {
            decodeM = true
            rawTypeLowercased.removeLast()
        }
        if rawTypeLowercased.hasSuffix("z") {
            decodeZ = true
            rawTypeLowercased.removeLast()
        }

        guard let type = WKTTypeCode(rawValue: rawTypeLowercased.trimmed()) else {
            return nil
        }

        return type
    }

    private static func scanCoordinates(
        scanner: Scanner,
        projection: Projection,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> [Coordinate3D]?
    {
        guard scanner.scanString("(") != nil else {
            throw WKTCoderError.dataCorrupted
        }

        var coordinates: [Coordinate3D] = []

        while scanner.scanString(")") == nil {
            var vector: [Double] = []

            while scanner.scanString(",") == nil {
                guard let number = scanner.scanDouble() else { break }

                vector.append(number)
            }

            if vector.isEmpty { break }

            guard let x = vector.get(at: 0), let y = vector.get(at: 1) else {
                throw WKTCoderError.dataCorrupted
            }

            var z: Double?
            var m: Double?

            if decodeZ && decodeM {
                z = vector.get(at: 2)
                m = vector.get(at: 3)
            }
            else if decodeZ {
                z = vector.get(at: 2)
            }
            else if decodeM {
                m = vector.get(at: 2)
            }

            switch projection {
            case .epsg4326:
                coordinates.append(Coordinate3D(latitude: y, longitude: x, altitude: z, m: m))
            case .epsg3857:
                coordinates.append(CoordinateXY(x: x, y: y, z: z, m: m).projectedToEpsg4326)
            case .noSRID:
                throw WKTCoderError.unknownSRID
            }
        }

        return coordinates.nilIfEmpty
    }

}

// MARK: - WKT encoding

extension WKTCoder {

    public static func encode(
        geometry: GeoJsonGeometry,
        projection: Projection? = .epsg4326)
        -> String?
    {
        // This GeoJSON implementation always uses EPSG:4326 (the spec uses CRS:84)
        guard projection == nil || projection == .epsg4326 else { return nil }

        var result = ""

        encode(geometry: geometry, srid: projection?.srid, to: &result)

        return result.nilIfEmpty
    }

    // MARK: -

    private static func encode(
        geometry: GeoJsonGeometry,
        srid: Int?,
        to result: inout String)
    {
        switch geometry.type {
        case .point:
            encode(geometry as! Point, srid: srid, to: &result)
        case .multiPoint:
            encode(geometry as! MultiPoint, srid: srid, to: &result)
        case .lineString:
            encode(geometry as! LineString, srid: srid, to: &result)
        case .multiLineString:
            encode(geometry as! MultiLineString, srid: srid, to: &result)
        case .polygon:
            encode(geometry as! Polygon, srid: srid, to: &result)
        case .multiPolygon:
            encode(geometry as! MultiPolygon, srid: srid, to: &result)
        case .geometryCollection:
            encode(geometry as! GeometryCollection, srid: srid, to: &result)
        case .feature, .featureCollection, .invalid:
            break
        }
    }

    private static func encode(
        _ value: Point,
        srid: Int?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.point.rawValue, for: value.coordinate, srid: srid, to: &result)
        appendString(string(for: [value.coordinate]), to: &result)
    }

    private static func encode(
        _ value: MultiPoint,
        srid: Int?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.multiPoint.rawValue, for: value.points.first?.coordinate, srid: srid, to: &result)
        appendString(string(for: value.coordinates), to: &result)
    }

    private static func encode(
        _ value: LineString,
        srid: Int?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.lineString.rawValue, for: value.coordinates.first, srid: srid, to: &result)
        appendString(string(for: value.coordinates), to: &result)
    }

    private static func encode(
        _ value: MultiLineString,
        srid: Int?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.multiLineString.rawValue, for: value.lineStrings.first?.coordinates.first, srid: srid, to: &result)
        appendString("(", to: &result)
        appendString(value.lineStrings.map({ string(for: $0.coordinates) }).joined(separator: ","), to: &result)
        appendString(")", to: &result)
    }

    private static func encode(
        _ value: Polygon,
        srid: Int?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.polygon.rawValue, for: value.rings.first?.coordinates.first, srid: srid, to: &result)
        appendString(string(for: value), to: &result)
    }

    private static func encode(
        _ value: MultiPolygon,
        srid: Int?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.multiPolygon.rawValue, for: value.polygons.first?.rings.first?.coordinates.first, srid: srid, to: &result)
        appendString("(", to: &result)
        appendString(value.polygons.map({ string(for: $0) }).joined(separator: ","), to: &result)
        appendString(")", to: &result)
    }

    private static func encode(
        _ value: GeometryCollection,
        srid: Int?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.geometryCollection.rawValue, for: nil, srid: srid, to: &result)
        appendString("(", to: &result)
        for (i, geometry) in value.geometries.enumerated() {
            encode(geometry: geometry, srid: nil, to: &result)
            if i < (value.geometries.count - 1) {
                appendString(",", to: &result)
            }
        }
        appendString(")", to: &result)
    }

    // MARK: -

    private static func string(
        for coordinates: [Coordinate3D])
        -> String
    {
        var result: [String] = []

        for coordinate in coordinates {
            var values: [String] = [
                String(coordinate.longitude),
                String(coordinate.latitude),
            ]
            if let z = coordinate.altitude {
                values.append(String(z))
            }
            if let m = coordinate.m {
                values.append(String(m))
            }
            result.append(values.joined(separator: " "))
        }

        return "(\(result.joined(separator: ",")))"
    }

    private static func string(
        for polygon: Polygon)
        -> String
    {
        return "(\(polygon.rings.map({ string(for: $0.coordinates) }).joined(separator: ",")))"
    }

    private static func appendTypeCode(
        _ typeCode: String,
        for coordinate: Coordinate3D? = nil,
        srid: Int?,
        to result: inout String)
    {
        var typeCode = typeCode.uppercased()

        if coordinate?.altitude != nil {
            typeCode += "Z"
        }

        if coordinate?.m != nil {
            typeCode += "M"
        }

        if let srid = srid {
            typeCode = "SRID=\(srid);" + typeCode
        }

        appendString(typeCode, to: &result)
    }

    private static func appendUInt32(
        _ value: UInt32,
        to result: inout String)
    {
        result += String(value)
    }

    private static func appendDouble(
        _ value: Double,
        to result: inout String)
    {
        result += String(value)
    }

    private static func appendString(
        _ value: String,
        to result: inout String)
    {
        result += value
    }

}
