import Foundation

// MARK: GeoJsonGeometry extension

extension GeoJsonGeometry {

    /// Decode a GeoJSON object from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkt: String,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKTCoder.decode(wkt: wkt, sourceSrid: sourceSrid, targetProjection: targetProjection) else { return nil }
        self.init(json: geometry.asJson, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON object from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkt: String,
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKTCoder.decode(wkt: wkt, sourceProjection: sourceProjection, targetProjection: targetProjection) else { return nil }
        self.init(json: geometry.asJson, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON object from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func parse(
        wkt: String,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326)
        -> GeoJsonGeometry?
    {
        try? WKTCoder.decode(wkt: wkt, sourceSrid: sourceSrid, targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func parse(
        wkt: String,
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326)
        -> GeoJsonGeometry?
    {
        try? WKTCoder.decode(wkt: wkt, sourceProjection: sourceProjection, targetProjection: targetProjection)
    }

    /// Returns the receiver as a WKT encoded string.
    public var asWKT: String? {
        WKTCoder.encode(geometry: self)
    }

}

// MARK: - Feature extension

extension Feature {

    /// Decode a GeoJSON Feature from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkt: String,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326,
        id: Identifier? = nil,
        properties: [String: Sendable] = [:],
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKTCoder.decode(wkt: wkt, sourceSrid: sourceSrid, targetProjection: targetProjection) else { return nil }
        self.init(geometry, id: id, properties: properties, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON Feature from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkt: String,
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326,
        id: Identifier? = nil,
        properties: [String: Sendable] = [:],
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKTCoder.decode(wkt: wkt, sourceProjection: sourceProjection, targetProjection: targetProjection) else { return nil }
        self.init(geometry, id: id, properties: properties, calculateBoundingBox: calculateBoundingBox)
    }

    /// Returns the receiver as a WKT encoded string.
    public var asWKT: String? {
        WKTCoder.encode(geometry: self.geometry)
    }

}

// MARK: - FeatureCollection extension

extension FeatureCollection {

    /// Decode a GeoJSON FeatureCollection from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkt: String,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKTCoder.decode(wkt: wkt, sourceSrid: sourceSrid, targetProjection: targetProjection) else { return nil }
        if let geometryCollection = geometry as? GeometryCollection {
            self.init(geometryCollection.geometries, calculateBoundingBox: calculateBoundingBox)
        }
        else {
            self.init([geometry], calculateBoundingBox: calculateBoundingBox)
        }
    }

    /// Decode a GeoJSON FeatureCollection from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkt: String,
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKTCoder.decode(wkt: wkt, sourceProjection: sourceProjection, targetProjection: targetProjection) else { return nil }
        if let geometryCollection = geometry as? GeometryCollection {
            self.init(geometryCollection.geometries, calculateBoundingBox: calculateBoundingBox)
        }
        else {
            self.init([geometry], calculateBoundingBox: calculateBoundingBox)
        }
    }

    /// Returns the receiver as a WKT encoded string.
    public var asWKT: String? {
        WKTCoder.encode(geometry: GeometryCollection(self.features.map(\.geometry)))
    }

}

// MARK: - String extensions

extension String {

    /// Decode a GeoJSON object from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asGeoJsonGeometry(
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326)
        -> GeoJsonGeometry?
    {
        GeometryCollection.parse(wkt: self, sourceSrid: sourceSrid, targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asGeoJsonGeometry(
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326)
        -> GeoJsonGeometry?
    {
        GeometryCollection.parse(wkt: self, sourceProjection: sourceProjection, targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeature(
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326,
        id: Feature.Identifier? = nil,
        properties: [String: Sendable] = [:])
        -> Feature?
    {
        Feature(wkt: self, sourceSrid: sourceSrid, targetProjection: targetProjection, id: id, properties: properties)
    }

    /// Decode a GeoJSON object from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeature(
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326,
        id: Feature.Identifier? = nil,
        properties: [String: Sendable] = [:])
        -> Feature?
    {
        Feature(wkt: self, sourceProjection: sourceProjection, targetProjection: targetProjection, id: id, properties: properties)
    }

    /// Decode a GeoJSON object from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeatureCollection(
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326)
        -> FeatureCollection?
    {
        FeatureCollection(wkt: self, sourceSrid: sourceSrid, targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeatureCollection(
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326)
        -> FeatureCollection?
    {
        FeatureCollection(wkt: self, sourceProjection: sourceProjection, targetProjection: targetProjection)
    }

}

// MARK: - WKTCoder

// This code borrows a lot from https://github.com/plarson/WKCodable

/// A tool for encoding and decoding GeoJSON objects from WKT.
public enum WKTCoder {

    enum WKTTypeCode: String {
        case point
        case lineString = "linestring"
        case linearRing = "linearring"
        case polygon
        case multiPoint = "multipoint"
        case multiLineString = "multilinestring"
        case multiPolygon = "multipolygon"
        case geometryCollection = "geometrycollection"
        case triangle
    }

    /// WKT errors.
    public enum WKTCoderError: Error {
        case dataCorrupted
        case emptyGeometry
        case invalidGeometry
        case targetProjectionMustBeNoSRID
        case unknownSRID
        case unexpectedType
    }

}

// MARK: - WKT decoding

extension WKTCoder {

    /// Decode a GeoJSON object from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func decode(
        wkt: String,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326)
        throws -> GeoJsonGeometry
    {
        var sourceProjection: Projection?

        if let sourceSrid {
            sourceProjection = Projection(srid: sourceSrid)
            guard sourceProjection != nil else { throw WKTCoderError.unknownSRID }
        }

        return try decode(wkt: wkt, sourceProjection: sourceProjection, targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from WKT.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func decode(
        wkt: String,
        sourceProjection: Projection?,
        targetProjection: Projection = .epsg4326)
        throws -> GeoJsonGeometry
    {
        let scanner = Scanner(string: wkt)
        scanner.charactersToBeSkipped = .whitespaces
        scanner.caseSensitive = false

        var sourceProjection = sourceProjection
        if sourceProjection == nil,
           let srid = try scanSRID(scanner: scanner)
        {
            sourceProjection = Projection(srid: srid)
        }
        guard let sourceProjection else { throw WKTCoderError.unknownSRID }

        if sourceProjection == .noSRID,
           targetProjection != .noSRID
        {
            throw WKTCoderError.targetProjectionMustBeNoSRID
        }

        return try scanGeometry(scanner: scanner, sourceProjection: sourceProjection, targetProjection: targetProjection)
    }

    // MARK: -

    private static func scanGeometry(
        scanner: Scanner,
        sourceProjection: Projection,
        targetProjection: Projection)
        throws -> GeoJsonGeometry
    {
        var decodeZ = false
        var decodeM = false

        guard let type = scanType(scanner: scanner, decodeZ: &decodeZ, decodeM: &decodeM) else {
            throw WKTCoderError.dataCorrupted
        }

        switch type {
        case .point:
            guard let coordinate = try scanCoordinates(scanner: scanner, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM)?.first else {
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
                    if let coordinates = try scanCoordinates(scanner: scanner, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM) {
                        points.append(contentsOf: coordinates.asPoints)
                    }
                    _ = scanner.scanString(",")
                }
            }
            else {
                if let coordinates = try scanCoordinates(scanner: scanner, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM) {
                    points.append(contentsOf: coordinates.asPoints)
                }
            }

            return MultiPoint(points) ?? MultiPoint()

        case .linearRing, .lineString:
            return try decodeLineString(scanner: scanner, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM)

        case .multiLineString:
            var lineStrings: [LineString] = []

            guard scanner.scanString("(") != nil else {
                throw WKTCoderError.dataCorrupted
            }

            while scanner.scanString(")") == nil {
                try lineStrings.append(decodeLineString(scanner: scanner, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM))
                _ = scanner.scanString(",")
            }

            return MultiLineString(lineStrings) ?? MultiLineString()

        case .polygon, .triangle:
            return try decodePolygon(scanner: scanner, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM)

        case .multiPolygon:
            var polygons: [Polygon] = []

            guard scanner.scanString("(") != nil else {
                throw WKTCoderError.dataCorrupted
            }

            while scanner.scanString(")") == nil {
                try polygons.append(decodePolygon(scanner: scanner, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM))
                _ = scanner.scanString(",")
            }

            return MultiPolygon(polygons) ?? MultiPolygon()

        case .geometryCollection:
            var geometries: [GeoJsonGeometry] = []

            guard scanner.scanString("(") != nil else {
                throw WKTCoderError.dataCorrupted
            }

            while scanner.scanString(")") == nil {
                try geometries.append(scanGeometry(scanner: scanner, sourceProjection: sourceProjection, targetProjection: targetProjection))
                _ = scanner.scanString(",")
            }

            return GeometryCollection(geometries)
        }
    }

    private static func decodeLineString(
        scanner: Scanner,
        sourceProjection: Projection,
        targetProjection: Projection,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> LineString
    {
        if let coordinates = try scanCoordinates(scanner: scanner, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM) {
            guard let lineString = LineString(coordinates) else {
                throw WKTCoderError.dataCorrupted
            }
            return lineString
        }
        return LineString()
    }

    private static func decodePolygon(
        scanner: Scanner,
        sourceProjection: Projection,
        targetProjection: Projection,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> Polygon
    {
        var rings: [Ring] = []

        guard scanner.scanString("(") != nil else {
            throw WKTCoderError.dataCorrupted
        }

        while scanner.scanString(")") == nil {
            if let coordinates = try scanCoordinates(scanner: scanner, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM) {
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
        sourceProjection: Projection,
        targetProjection: Projection,
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

            guard x.isFinite, y.isFinite else {
                throw WKTCoderError.invalidGeometry
            }

            var z: Double?
            var m: Double?

            if decodeZ, decodeM {
                z = vector.get(at: 2)
                m = vector.get(at: 3)
            }
            else if decodeZ {
                z = vector.get(at: 2)
            }
            else if decodeM {
                m = vector.get(at: 2)
            }

            if z?.isFinite == false { z = nil }
            if m?.isFinite == false { m = nil }

            switch sourceProjection {
            case .epsg4326:
                switch targetProjection {
                case .epsg3857:
                    coordinates.append(Coordinate3D(latitude: y, longitude: x, altitude: z, m: m).projected(to: targetProjection))
                case .epsg4326:
                    coordinates.append(Coordinate3D(latitude: y, longitude: x, altitude: z, m: m))
                case .noSRID:
                    coordinates.append(Coordinate3D(x: x, y: y, z: z, m: m, projection: targetProjection))
                }

            case .epsg3857:
                switch targetProjection {
                case .epsg3857:
                    coordinates.append(Coordinate3D(x: x, y: y, z: z, m: m))
                case .epsg4326:
                    coordinates.append(Coordinate3D(x: x, y: y, z: z, m: m).projected(to: targetProjection))
                case .noSRID:
                    coordinates.append(Coordinate3D(x: x, y: y, z: z, m: m, projection: targetProjection))
                }

            case .noSRID:
                coordinates.append(Coordinate3D(x: x, y: y, z: z, m: m, projection: targetProjection))
            }
        }

        return coordinates.nilIfEmpty
    }

}

// MARK: - WKT encoding

extension WKTCoder {

    /// Returns a geometry as a WKT encoded string.
    public static func encode(
        geometry: GeoJsonGeometry,
        targetProjection: Projection? = .epsg4326)
        -> String?
    {
        var result = ""

        encode(geometry: geometry, targetProjection: targetProjection, to: &result)

        return result.nilIfEmpty
    }

    // MARK: -

    private static func encode(
        geometry: GeoJsonGeometry,
        targetProjection: Projection?,
        to result: inout String)
    {
        switch geometry.type {
        case .point:
            encode(geometry as! Point, targetProjection: targetProjection, to: &result)
        case .multiPoint:
            encode(geometry as! MultiPoint, targetProjection: targetProjection, to: &result)
        case .lineString:
            encode(geometry as! LineString, targetProjection: targetProjection, to: &result)
        case .multiLineString:
            encode(geometry as! MultiLineString, targetProjection: targetProjection, to: &result)
        case .polygon:
            encode(geometry as! Polygon, targetProjection: targetProjection, to: &result)
        case .multiPolygon:
            encode(geometry as! MultiPolygon, targetProjection: targetProjection, to: &result)
        case .geometryCollection:
            encode(geometry as! GeometryCollection, targetProjection: targetProjection, to: &result)
        case .feature, .featureCollection, .invalid:
            break
        }
    }

    private static func encode(
        _ value: Point,
        targetProjection: Projection?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.point.rawValue, for: value.coordinate, targetProjection: targetProjection, to: &result)
        appendString(string(for: [value.coordinate], targetProjection: targetProjection), to: &result)
    }

    private static func encode(
        _ value: MultiPoint,
        targetProjection: Projection?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.multiPoint.rawValue, for: value.points.first?.coordinate, targetProjection: targetProjection, to: &result)
        appendString(string(for: value.coordinates, targetProjection: targetProjection), to: &result)
    }

    private static func encode(
        _ value: LineString,
        targetProjection: Projection?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.lineString.rawValue, for: value.coordinates.first, targetProjection: targetProjection, to: &result)
        appendString(string(for: value.coordinates, targetProjection: targetProjection), to: &result)
    }

    private static func encode(
        _ value: MultiLineString,
        targetProjection: Projection?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.multiLineString.rawValue, for: value.lineStrings.first?.coordinates.first, targetProjection: targetProjection, to: &result)
        appendString("(", to: &result)
        appendString(value.lineStrings.map({ string(for: $0.coordinates, targetProjection: targetProjection) }).joined(separator: ","), to: &result)
        appendString(")", to: &result)
    }

    private static func encode(
        _ value: Polygon,
        targetProjection: Projection?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.polygon.rawValue, for: value.rings.first?.coordinates.first, targetProjection: targetProjection, to: &result)
        appendString(string(for: value, targetProjection: targetProjection), to: &result)
    }

    private static func encode(
        _ value: MultiPolygon,
        targetProjection: Projection?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.multiPolygon.rawValue, for: value.polygons.first?.rings.first?.coordinates.first, targetProjection: targetProjection, to: &result)
        appendString("(", to: &result)
        appendString(value.polygons.map({ string(for: $0, targetProjection: targetProjection) }).joined(separator: ","), to: &result)
        appendString(")", to: &result)
    }

    private static func encode(
        _ value: GeometryCollection,
        targetProjection: Projection?,
        to result: inout String)
    {
        appendTypeCode(WKTTypeCode.geometryCollection.rawValue, for: nil, targetProjection: targetProjection, to: &result)
        appendString("(", to: &result)
        for (i, geometry) in value.geometries.enumerated() {
            encode(geometry: geometry, targetProjection: nil, to: &result)
            if i < (value.geometries.count - 1) {
                appendString(",", to: &result)
            }
        }
        appendString(")", to: &result)
    }

    // MARK: -

    private static func string(
        for coordinates: [Coordinate3D],
        targetProjection: Projection?)
        -> String
    {
        var result: [String] = []

        for coordinate in coordinates {
            var values: [String] = [
                String(coordinate.longitudeProjected(to: targetProjection ?? .epsg4326)),
                String(coordinate.latitudeProjected(to: targetProjection ?? .epsg4326)),
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
        for polygon: Polygon,
        targetProjection: Projection?)
        -> String
    {
        "(\(polygon.rings.map({ string(for: $0.coordinates, targetProjection: targetProjection) }).joined(separator: ",")))"
    }

    private static func appendTypeCode(
        _ typeCode: String,
        for coordinate: Coordinate3D? = nil,
        targetProjection: Projection?,
        to result: inout String)
    {
        var typeCode = typeCode.uppercased()

        if coordinate?.altitude != nil {
            typeCode += "Z"
        }

        if coordinate?.m != nil {
            typeCode += "M"
        }

        if let srid = targetProjection?.srid {
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
