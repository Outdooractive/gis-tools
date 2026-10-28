#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: - GeoJsonGeometry extension

extension GeoJsonGeometry {

    /// Decode a GeoJSON object from TWKB.
    ///
    /// - Parameters:
    ///    - twkb: The TWKB data to decode.
    ///    - sourceSrid: The SRID of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    ///    - calculateBoundingBox: Whether to calculate the bounding box. Defaults to `false`.
    /// - Returns: A GeoJSON geometry object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        twkb: Data,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326,
        calculateBoundingBox: Bool = false
    ) {
        guard let geometry = try? TWKBCoder.decode(
            twkb: twkb,
            sourceSrid: sourceSrid,
            targetProjection: targetProjection) else { return nil }

        self.init(json: geometry.asJson, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON object from TWKB.
    ///
    /// - Parameters:
    ///    - twkb: The TWKB data to decode.
    ///    - sourceProjection: The projection of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    ///    - calculateBoundingBox: Whether to calculate the bounding box. Defaults to `false`.
    /// - Returns: A GeoJSON geometry object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        twkb: Data,
        sourceProjection: Projection? = nil,
        targetProjection: Projection = .epsg4326,
        calculateBoundingBox: Bool = false
    ) {
        guard let geometry = try? TWKBCoder.decode(
            twkb: twkb,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection) else { return nil }

        self.init(json: geometry.asJson, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON object from TWKB.
    ///
    /// - Parameters:
    ///    - twkb: The TWKB data to decode.
    ///    - sourceSrid: The SRID of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    /// - Returns: A GeoJSON geometry object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func parse(
        twkb: Data,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326
    ) -> GeoJsonGeometry? {
        try? TWKBCoder.decode(
            twkb: twkb,
            sourceSrid: sourceSrid,
            targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from TWKB.
    ///
    /// - Parameters:
    ///    - twkb: The TWKB data to decode.
    ///    - sourceProjection: The projection of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    /// - Returns: A GeoJSON geometry object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func parse(
        twkb: Data,
        sourceProjection: Projection? = nil,
        targetProjection: Projection = .epsg4326
    ) -> GeoJsonGeometry? {
        try? TWKBCoder.decode(
            twkb: twkb,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection)
    }

}

// MARK: - Feature extension

extension Feature {

    /// Decode a GeoJSON Feature from TWKB.
    ///
    /// - Parameters:
    ///    - twkb: The TWKB data to decode.
    ///    - sourceSrid: The SRID of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    ///    - id: An optional feature identifier. Defaults to `nil`.
    ///    - properties: A dictionary of feature properties. Defaults to `[:]`.
    ///    - calculateBoundingBox: Whether to calculate the bounding box. Defaults to `false`.
    /// - Returns: A GeoJSON Feature object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        twkb: Data,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326,
        id: Identifier? = nil,
        properties: [String: Sendable] = [:],
        calculateBoundingBox: Bool = false
    ) {
        guard let geometry = try? TWKBCoder.decode(
            twkb: twkb,
            sourceSrid: sourceSrid,
            targetProjection: targetProjection) else { return nil }

        self.init(geometry, id: id, properties: properties, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON Feature from TWKB.
    ///
    /// - Parameters:
    ///    - twkb: The TWKB data to decode.
    ///    - sourceProjection: The projection of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    ///    - id: An optional feature identifier. Defaults to `nil`.
    ///    - properties: A dictionary of feature properties. Defaults to `[:]`.
    ///    - calculateBoundingBox: Whether to calculate the bounding box. Defaults to `false`.
    /// - Returns: A GeoJSON Feature object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        twkb: Data,
        sourceProjection: Projection? = nil,
        targetProjection: Projection = .epsg4326,
        id: Identifier? = nil,
        properties: [String: Sendable] = [:],
        calculateBoundingBox: Bool = false
    ) {
        guard let geometry = try? TWKBCoder.decode(
            twkb: twkb,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection) else { return nil }

        self.init(geometry, id: id, properties: properties, calculateBoundingBox: calculateBoundingBox)
    }

}

// MARK: - FeatureCollection extension

extension FeatureCollection {

    /// Decode a GeoJSON FeatureCollection from TWKB.
    ///
    /// - Parameters:
    ///    - twkb: The TWKB data to decode.
    ///    - sourceSrid: The SRID of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    ///    - calculateBoundingBox: Whether to calculate the bounding box. Defaults to `false`.
    /// - Returns: A GeoJSON FeatureCollection object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        twkb: Data,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326,
        calculateBoundingBox: Bool = false
    ) {
        guard let geometry = try? TWKBCoder.decode(
            twkb: twkb,
            sourceSrid: sourceSrid,
            targetProjection: targetProjection) else { return nil }

        self.init([geometry], calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON FeatureCollection from TWKB.
    ///
    /// - Parameters:
    ///    - twkb: The TWKB data to decode.
    ///    - sourceProjection: The projection of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    ///    - calculateBoundingBox: Whether to calculate the bounding box. Defaults to `false`.
    /// - Returns: A GeoJSON FeatureCollection object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        twkb: Data,
        sourceProjection: Projection? = nil,
        targetProjection: Projection = .epsg4326,
        calculateBoundingBox: Bool = false
    ) {
        guard let geometry = try? TWKBCoder.decode(
            twkb: twkb,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection) else { return nil }

        self.init([geometry], calculateBoundingBox: calculateBoundingBox)
    }

}

// MARK: - Data extensions

extension Data {

    /// Decode a GeoJSON object from TWKB.
    ///
    /// - Parameters:
    ///    - sourceSrid: The SRID of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    /// - Returns: A GeoJSON geometry object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asGeoJsonGeometryFromTWKB(
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326
    ) -> GeoJsonGeometry? {
        GeometryCollection.parse(
            twkb: self,
            sourceSrid: sourceSrid,
            targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from TWKB.
    ///
    /// - Parameters:
    ///    - sourceProjection: The projection of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    /// - Returns: A GeoJSON geometry object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asGeoJsonGeometryFromTWKB(
        sourceProjection: Projection?,
        targetProjection: Projection = .epsg4326
    ) -> GeoJsonGeometry? {
        GeometryCollection.parse(
            twkb: self,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection)
    }

    /// Decode a GeoJSON Feature from TWKB.
    ///
    /// - Parameters:
    ///    - sourceSrid: The SRID of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    ///    - id: An optional feature identifier. Defaults to `nil`.
    ///    - properties: A dictionary of feature properties. Defaults to `[:]`.
    /// - Returns: A GeoJSON Feature object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeatureFromTWKB(
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326,
        id: Feature.Identifier? = nil,
        properties: [String: Sendable] = [:]
    ) -> Feature? {
        Feature(
            twkb: self,
            sourceSrid: sourceSrid,
            targetProjection: targetProjection,
            id: id,
            properties: properties)
    }

    /// Decode a GeoJSON Feature from TWKB.
    ///
    /// - Parameters:
    ///    - sourceProjection: The projection of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    ///    - id: An optional feature identifier. Defaults to `nil`.
    ///    - properties: A dictionary of feature properties. Defaults to `[:]`.
    /// - Returns: A GeoJSON Feature object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeatureFromTWKB(
        sourceProjection: Projection?,
        targetProjection: Projection = .epsg4326,
        id: Feature.Identifier? = nil,
        properties: [String: Sendable] = [:]
    ) -> Feature? {
        Feature(
            twkb: self,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection,
            id: id,
            properties: properties)
    }

    /// Decode a GeoJSON FeatureCollection from TWKB.
    ///
    /// - Parameters:
    ///    - sourceSrid: The SRID of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    /// - Returns: A GeoJSON FeatureCollection object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeatureCollectionFromTWKB(
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326
    ) -> FeatureCollection? {
        FeatureCollection(
            twkb: self,
            sourceSrid: sourceSrid,
            targetProjection: targetProjection)
    }

    /// Decode a GeoJSON FeatureCollection from TWKB.
    ///
    /// - Parameters:
    ///    - sourceProjection: The projection of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    /// - Returns: A GeoJSON FeatureCollection object, or `nil` if decoding fails.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeatureCollectionFromTWKB(
        sourceProjection: Projection?,
        targetProjection: Projection = .epsg4326
    ) -> FeatureCollection? {
        FeatureCollection(
            twkb: self,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection)
    }

}

// https://github.com/TWKB/Specification/blob/master/twkb.md

/// A tool for decoding GeoJSON objects from TWKB.
public enum TWKBCoder {

    /// TWKB decoding errors.
    public enum TWKBError: Error {

        /// The TWKB data is corrupted.
        case dataCorrupted
        /// The geometry is empty.
        case emptyGeometry
        /// The geometry is invalid.
        case invalidGeometry
        /// The SRID is unknown.
        case unknownSRID
        /// The geometry type is unexpected.
        case unexpectedType

    }

    // MARK: - Public decode entry points

    /// Decode a GeoJSON object from TWKB.
    ///
    /// - Parameters:
    ///    - twkb: The TWKB data to decode.
    ///    - sourceSrid: The SRID of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    /// - Returns: A decoded GeoJSON geometry object.
    /// - Throws: A `TWKBError` if the data is corrupted, empty, invalid, or of an unexpected type.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func decode(
        twkb: Data,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326
    ) throws -> GeoJsonGeometry {
        var sourceProjection: Projection?

        if let sourceSrid {
            sourceProjection = Projection(srid: sourceSrid)
            guard sourceProjection != nil else { throw TWKBError.unknownSRID }
        }

        return try decode(
            twkb: twkb,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from TWKB.
    ///
    /// - Parameters:
    ///    - twkb: The TWKB data to decode.
    ///    - sourceProjection: The projection of the source data.
    ///    - targetProjection: The projection to transform the result into. Defaults to EPSG:4326.
    /// - Returns: A decoded GeoJSON geometry object.
    /// - Throws: A `TWKBError` if the data is corrupted, empty, invalid, or of an unexpected type.
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func decode(
        twkb: Data,
        sourceProjection: Projection? = nil,
        targetProjection: Projection = .epsg4326
    ) throws -> GeoJsonGeometry {
        let bytes = [UInt8](twkb)
        var offset = 0

        let geometry = try decodeGeometry(
            bytes: bytes,
            offset: &offset,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection)

        guard offset == bytes.count else {
            throw TWKBError.dataCorrupted
        }

        return geometry
    }

    // MARK: - Internal decode helpers

    private struct Metadata {

        let hasZ: Bool
        let hasM: Bool
        let hasIDList: Bool
        let isEmpty: Bool
        let zScale: Double
        let mScale: Double

    }

    /// Reads the header byte: lower 4 bits = geometry type, upper 4 bits = signed precision.
    private static func decodeHeader(
        bytes: [UInt8],
        offset: inout Int
    ) throws -> (type: Int, scale: Double) {
        guard offset < bytes.count else { throw TWKBError.dataCorrupted }

        let byte = bytes[offset]
        offset += 1
        let geomType = Int(byte & 0x0F)
        let rawPrecision = Int((byte & 0xF0) >> 4)
        let precision = rawPrecision >= 8 ? rawPrecision - 16 : rawPrecision
        return (geomType, pow(10.0, Double(precision)))
    }

    /// Reads the metadata header and all optional attributes that precede the geometry data.
    private static func decodeMetadata(
        bytes: [UInt8],
        offset: inout Int
    ) throws -> Metadata {
        guard offset < bytes.count else { throw TWKBError.dataCorrupted }

        let meta = Int(bytes[offset])
        offset += 1

        let hasBoundingBox = (meta & 0x01) != 0
        let hasSize = (meta & 0x02) != 0
        let hasIDList = (meta & 0x04) != 0
        let hasExtendedDimensions = (meta & 0x08) != 0
        let isEmpty = (meta & 0x10) != 0

        var hasZ = false
        var hasM = false
        var zScale = 1.0
        var mScale = 1.0

        if hasExtendedDimensions {
            guard offset < bytes.count else { throw TWKBError.dataCorrupted }

            let extended = Int(bytes[offset])
            offset += 1

            hasZ = (extended & 0x01) != 0
            hasM = (extended & 0x02) != 0
            let zPrecision = Int((extended & 0x1C) >> 2)
            let mPrecision = Int((extended & 0xE0) >> 5)
            zScale = pow(10.0, Double(zPrecision))
            mScale = pow(10.0, Double(mPrecision))
        }

        if hasSize {
            _ = try decodeVarInt(bytes: bytes, offset: &offset)
        }

        if hasBoundingBox {
            let dimensions = 2 + (hasZ ? 1 : 0) + (hasM ? 1 : 0)
            for _ in 0 ..< (2 * dimensions) {
                _ = try decodeVarInt(bytes: bytes, offset: &offset)
            }
        }

        return Metadata(
            hasZ: hasZ,
            hasM: hasM,
            hasIDList: hasIDList,
            isEmpty: isEmpty,
            zScale: zScale,
            mScale: mScale)
    }

    private static func skipIDList(
        bytes: [UInt8],
        offset: inout Int,
        count: Int
    ) throws {
        for _ in 0 ..< count {
            _ = try decodeVarInt(bytes: bytes, offset: &offset)
        }
    }

    // MARK: - Geometry dispatch

    private static func decodeGeometry(
        bytes: [UInt8],
        offset: inout Int,
        sourceProjection: Projection?,
        targetProjection: Projection
    ) throws -> GeoJsonGeometry {
        guard offset < bytes.count else { throw TWKBError.emptyGeometry }

        let (geomType, scale) = try decodeHeader(bytes: bytes, offset: &offset)
        let metadata = try decodeMetadata(bytes: bytes, offset: &offset)

        if metadata.isEmpty {
            switch geomType {
            case 1, 4:
                return MultiPoint()
            case 2:
                return LineString()
            case 3:
                return Polygon()
            case 5:
                return MultiLineString()
            case 6:
                return MultiPolygon()
            case 7:
                return GeometryCollection([])
            default:
                throw TWKBError.unexpectedType
            }
        }

        let sourceProjection = sourceProjection ?? .epsg4326

        switch geomType {
        case 1:
            return try decodePoint(
                bytes: bytes,
                offset: &offset,
                scale: scale,
                metadata: metadata,
                sourceProjection: sourceProjection,
                targetProjection: targetProjection)

        case 2:
            return try decodeLineString(
                bytes: bytes,
                offset: &offset,
                scale: scale,
                metadata: metadata,
                sourceProjection: sourceProjection,
                targetProjection: targetProjection)

        case 3:
            return try decodePolygon(
                bytes: bytes,
                offset: &offset,
                scale: scale,
                metadata: metadata,
                sourceProjection: sourceProjection,
                targetProjection: targetProjection)

        case 4:
            return try decodeMultiPoint(
                bytes: bytes,
                offset: &offset,
                scale: scale,
                metadata: metadata,
                sourceProjection: sourceProjection,
                targetProjection: targetProjection)

        case 5:
            return try decodeMultiLineString(
                bytes: bytes,
                offset: &offset,
                scale: scale,
                metadata: metadata,
                sourceProjection: sourceProjection,
                targetProjection: targetProjection)

        case 6:
            return try decodeMultiPolygon(
                bytes: bytes,
                offset: &offset,
                scale: scale,
                metadata: metadata,
                sourceProjection: sourceProjection,
                targetProjection: targetProjection)

        case 7:
            return try decodeGeometryCollection(
                bytes: bytes,
                offset: &offset,
                metadata: metadata,
                sourceProjection: sourceProjection,
                targetProjection: targetProjection)

        default:
            throw TWKBError.unexpectedType
        }
    }

    // MARK: - Point

    private static func decodePoint(
        bytes: [UInt8],
        offset: inout Int,
        scale: Double,
        metadata: Metadata,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> Point {
        let coordinate = try decodeCoordinate(
            bytes: bytes,
            offset: &offset,
            scale: scale,
            metadata: metadata,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection)
        return Point(coordinate)
    }

    // MARK: - LineString

    private static func decodeLineString(
        bytes: [UInt8],
        offset: inout Int,
        scale: Double,
        metadata: Metadata,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> LineString {
        let count = try decodeCount(bytes: bytes, offset: &offset)
        let coordinates = try decodeCoordinateSequence(
            bytes: bytes,
            offset: &offset,
            count: count,
            scale: scale,
            metadata: metadata,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection)
        return LineString(unchecked: coordinates)
    }

    // MARK: - Polygon

    private static func decodePolygon(
        bytes: [UInt8],
        offset: inout Int,
        scale: Double,
        metadata: Metadata,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> Polygon {
        let ringCount = try decodeCount(bytes: bytes, offset: &offset)
        var rings: [[Coordinate3D]] = []

        for _ in 0 ..< ringCount {
            let pointCount = try decodeCount(bytes: bytes, offset: &offset)
            let coordinates = try decodeCoordinateSequence(
                bytes: bytes,
                offset: &offset,
                count: pointCount,
                scale: scale,
                metadata: metadata,
                sourceProjection: sourceProjection,
                targetProjection: targetProjection)
            guard coordinates.isNotEmpty else {
                throw TWKBError.invalidGeometry
            }

            var ring = coordinates
            if ring.first != ring.last {
                ring.append(ring[0])
            }
            rings.append(ring)
        }

        guard let polygon = Polygon(rings) else {
            throw TWKBError.invalidGeometry
        }

        return polygon
    }

    // MARK: - Multi-geometries

    private static func decodeMultiPoint(
        bytes: [UInt8],
        offset: inout Int,
        scale: Double,
        metadata: Metadata,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> MultiPoint {
        let count = try decodeCount(bytes: bytes, offset: &offset)
        if metadata.hasIDList {
            try skipIDList(bytes: bytes, offset: &offset, count: count)
        }

        let coordinates = try decodeCoordinateSequence(
            bytes: bytes,
            offset: &offset,
            count: count,
            scale: scale,
            metadata: metadata,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection)
        guard let multiPoint = MultiPoint(coordinates) else {
            throw TWKBError.invalidGeometry
        }

        return multiPoint
    }

    private static func decodeMultiLineString(
        bytes: [UInt8],
        offset: inout Int,
        scale: Double,
        metadata: Metadata,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> MultiLineString {
        let count = try decodeCount(bytes: bytes, offset: &offset)
        if metadata.hasIDList {
            try skipIDList(bytes: bytes, offset: &offset, count: count)
        }

        var lineStrings: [[Coordinate3D]] = []
        for _ in 0 ..< count {
            let pointCount = try decodeCount(bytes: bytes, offset: &offset)
            let coordinates = try decodeCoordinateSequence(
                bytes: bytes,
                offset: &offset,
                count: pointCount,
                scale: scale,
                metadata: metadata,
                sourceProjection: sourceProjection,
                targetProjection: targetProjection)
            lineStrings.append(coordinates)
        }
        return MultiLineString(unchecked: lineStrings)
    }

    private static func decodeMultiPolygon(
        bytes: [UInt8],
        offset: inout Int,
        scale: Double,
        metadata: Metadata,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> MultiPolygon {
        let count = try decodeCount(bytes: bytes, offset: &offset)
        if metadata.hasIDList {
            try skipIDList(bytes: bytes, offset: &offset, count: count)
        }

        var polygons: [Polygon] = []
        for _ in 0 ..< count {
            let ringCount = try decodeCount(bytes: bytes, offset: &offset)
            var rings: [[Coordinate3D]] = []

            for _ in 0 ..< ringCount {
                let pointCount = try decodeCount(bytes: bytes, offset: &offset)
                let coordinates = try decodeCoordinateSequence(
                    bytes: bytes,
                    offset: &offset,
                    count: pointCount,
                    scale: scale,
                    metadata: metadata,
                    sourceProjection: sourceProjection,
                    targetProjection: targetProjection)
                guard coordinates.isNotEmpty else {
                    throw TWKBError.invalidGeometry
                }

                var ring = coordinates
                if ring.first != ring.last {
                    ring.append(ring[0])
                }
                rings.append(ring)
            }

            guard let polygon = Polygon(rings) else {
                throw TWKBError.invalidGeometry
            }

            polygons.append(polygon)
        }
        return MultiPolygon(unchecked: polygons)
    }

    private static func decodeGeometryCollection(
        bytes: [UInt8],
        offset: inout Int,
        metadata: Metadata,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> GeometryCollection {
        let count = try decodeCount(bytes: bytes, offset: &offset)
        if metadata.hasIDList {
            try skipIDList(bytes: bytes, offset: &offset, count: count)
        }

        var geometries: [any GeoJsonGeometry] = []
        for _ in 0 ..< count {
            let geometry = try decodeGeometry(
                bytes: bytes,
                offset: &offset,
                sourceProjection: sourceProjection,
                targetProjection: targetProjection)
            geometries.append(geometry)
        }
        return GeometryCollection(geometries)
    }

    // MARK: - Coordinate decoding

    /// Decodes a single coordinate from zigzag-encoded integer values scaled by `scale`.
    private static func decodeCoordinate(
        bytes: [UInt8],
        offset: inout Int,
        scale: Double,
        metadata: Metadata,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> Coordinate3D {
        let x = try Double(decodeZigZag(decodeVarInt(bytes: bytes, offset: &offset))) / scale
        let y = try Double(decodeZigZag(decodeVarInt(bytes: bytes, offset: &offset))) / scale
        let z: Double? = try metadata.hasZ
            ? Double(decodeZigZag(decodeVarInt(bytes: bytes, offset: &offset))) / metadata.zScale
            : nil
        let m: Double? = try metadata.hasM
            ? Double(decodeZigZag(decodeVarInt(bytes: bytes, offset: &offset))) / metadata.mScale
            : nil

        let coordinate = makeCoordinate(
            x: x,
            y: y,
            z: z,
            m: m,
            sourceProjection: sourceProjection)
        if sourceProjection != targetProjection {
            return coordinate.projected(to: targetProjection)
        }
        return coordinate
    }

    /// Decodes a sequence of `count` coordinates as deltas from a running base.
    private static func decodeCoordinateSequence(
        bytes: [UInt8],
        offset: inout Int,
        count: Int,
        scale: Double,
        metadata: Metadata,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> [Coordinate3D] {
        guard count > 0 else { return [] }

        var coordinates: [Coordinate3D] = []
        var baseX: Int64 = 0
        var baseY: Int64 = 0
        var baseZ: Int64 = 0
        var baseM: Int64 = 0

        for _ in 0 ..< count {
            try baseX += decodeZigZag(decodeVarInt(bytes: bytes, offset: &offset))
            try baseY += decodeZigZag(decodeVarInt(bytes: bytes, offset: &offset))
            if metadata.hasZ {
                try baseZ += decodeZigZag(decodeVarInt(bytes: bytes, offset: &offset))
            }
            if metadata.hasM {
                try baseM += decodeZigZag(decodeVarInt(bytes: bytes, offset: &offset))
            }

            let x = Double(baseX) / scale
            let y = Double(baseY) / scale
            let z: Double? = metadata.hasZ ? Double(baseZ) / metadata.zScale : nil
            let m: Double? = metadata.hasM ? Double(baseM) / metadata.mScale : nil

            coordinates.append(makeCoordinate(
                x: x,
                y: y,
                z: z,
                m: m,
                sourceProjection: sourceProjection))
        }

        // Batch conversion: one conversion setup for the whole sequence.
        return coordinates.projected(to: targetProjection)
    }

    // MARK: - Coordinate construction

    private static func makeCoordinate(
        x: Double,
        y: Double,
        z: Double?,
        m: Double?,
        sourceProjection: Projection
    ) -> Coordinate3D {
        // TWKB always stores x (longitude/easting) first, then y (latitude/northing).
        Coordinate3D(x: x, y: y, z: z, m: m, projection: sourceProjection)
    }

    // MARK: - VarInt

    /// Decodes an unsigned count and rejects values that cannot index the payload.
    private static func decodeCount(
        bytes: [UInt8],
        offset: inout Int
    ) throws -> Int {
        let value = try decodeVarInt(bytes: bytes, offset: &offset)
        guard let count = Int(exactly: value), count <= bytes.count else {
            throw TWKBError.dataCorrupted
        }

        return count
    }

    /// Decodes an unsigned variable-length integer (MSB continuation bit).
    private static func decodeVarInt(
        bytes: [UInt8],
        offset: inout Int
    ) throws -> UInt64 {
        var value: UInt64 = 0
        var shift = 0
        while offset < bytes.count {
            guard shift < 64 else { throw TWKBError.dataCorrupted }

            let byte = bytes[offset]
            offset += 1
            value |= UInt64(byte & 0x7F) << shift
            if (byte & 0x80) == 0 {
                return value
            }
            shift += 7
        }
        throw TWKBError.dataCorrupted
    }

    // MARK: - ZigZag

    private static func decodeZigZag(_ value: UInt64) -> Int64 {
        Int64(bitPattern: (value >> 1) ^ (~(value & 1) &+ 1))
    }

}
