#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: - GeoJsonGeometry extension

extension GeoJsonGeometry {

    /// Decode a GeoJSON object from TWKB.
    ///
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
            targetProjection: targetProjection
        ) else { return nil }
        self.init(json: geometry.asJson, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON object from TWKB.
    ///
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
            targetProjection: targetProjection
        ) else { return nil }
        self.init(json: geometry.asJson, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON object from TWKB.
    ///
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
            targetProjection: targetProjection
        ) else { return nil }
        self.init(geometry, id: id, properties: properties, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON Feature from TWKB.
    ///
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
            targetProjection: targetProjection
        ) else { return nil }
        self.init(geometry, id: id, properties: properties, calculateBoundingBox: calculateBoundingBox)
    }

}

// MARK: - FeatureCollection extension

extension FeatureCollection {

    /// Decode a GeoJSON FeatureCollection from TWKB.
    ///
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
            targetProjection: targetProjection
        ) else { return nil }
        self.init([geometry], calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON FeatureCollection from TWKB.
    ///
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
            targetProjection: targetProjection
        ) else { return nil }
        self.init([geometry], calculateBoundingBox: calculateBoundingBox)
    }

}

// MARK: - Data extensions

extension Data {

    /// Decode a GeoJSON object from TWKB.
    ///
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

    /// Decode a GeoJSON object from TWKB.
    ///
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

    /// Decode a GeoJSON object from TWKB.
    ///
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

    /// Decode a GeoJSON object from TWKB.
    ///
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

    /// Decode a GeoJSON object from TWKB.
    ///
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
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func decode(
        twkb: Data,
        sourceProjection: Projection? = nil,
        targetProjection: Projection = .epsg4326
    ) throws -> GeoJsonGeometry {
        let bytes = [UInt8](twkb)
        var offset = 0

        return try decodeGeometry(
            bytes: bytes,
            offset: &offset,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection,
            parentPrecision: nil)
    }

    // MARK: - Internal decode helpers

    /// Reads the header byte: lower 4 bits = geometry type, upper 4 bits = precision exponent.
    private static func decodeHeader(
        bytes: [UInt8],
        offset: inout Int,
        parentPrecision: Int?
    ) throws -> (type: Int, precision: Int) {
        guard offset < bytes.count else { throw TWKBError.dataCorrupted }

        let byte = bytes[offset]
        offset += 1
        let geomType = Int(byte & 0x0F)
        let prec = Int((byte & 0xF0) >> 4)
        // A precision byte of 0 means "use parent/global precision"
        let precision = prec == 0 ? (parentPrecision ?? 0) : prec
        return (geomType, precision)
    }

    /// Reads the metadata header varint: flags for Z, M, SRID.
    private static func decodeMetadata(
        bytes: [UInt8],
        offset: inout Int
    ) throws -> (hasZ: Bool, hasM: Bool, hasSRID: Bool, srid: Int?) {
        guard offset < bytes.count else { throw TWKBError.dataCorrupted }

        let meta = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        _ = (meta & 0x01) != 0  // hasBBox
        _ = (meta & 0x02) != 0  // hasSize
        let hasSRID = (meta & 0x04) != 0
        // TWKB uses bits for bbox, size, srid - not Z/M in metadata
        // Z/M are determined by the coordinate dimensionality in varint
        var srid: Int?
        if hasSRID {
            srid = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        }
        return (false, false, hasSRID, srid)
    }

    // MARK: - Geometry dispatch

    private static func decodeGeometry(
        bytes: [UInt8], offset: inout Int,
        sourceProjection: Projection?,
        targetProjection: Projection,
        parentPrecision: Int?
    ) throws -> GeoJsonGeometry {
        guard offset < bytes.count else { throw TWKBError.emptyGeometry }

        let (geomType, precision) = try decodeHeader(bytes: bytes, offset: &offset, parentPrecision: parentPrecision)
        let (hasZ, hasM, _, srid) = try decodeMetadata(bytes: bytes, offset: &offset)

        let srcProj = sourceProjection ?? srid.flatMap { Projection(srid: $0) } ?? .epsg4326
        let scale = pow(10.0, Double(precision))

        switch geomType {
        case 1:
            return try decodePoint(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, sourceProjection: srcProj, targetProjection: targetProjection)
        case 2:
            return try decodeLineString(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, precision: precision, sourceProjection: srcProj, targetProjection: targetProjection)
        case 3:
            return try decodePolygon(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, precision: precision, sourceProjection: srcProj, targetProjection: targetProjection)
        case 4:
            return try decodeMultiPoint(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, precision: precision, sourceProjection: srcProj, targetProjection: targetProjection)
        case 5:
            return try decodeMultiLineString(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, precision: precision, sourceProjection: srcProj, targetProjection: targetProjection)
        case 6:
            return try decodeMultiPolygon(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, precision: precision, sourceProjection: srcProj, targetProjection: targetProjection)
        case 7:
            return try decodeGeometryCollection(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, precision: precision, sourceProjection: srcProj, targetProjection: targetProjection)
        default:
            throw TWKBError.unexpectedType
        }
    }

    // MARK: - Point

    private static func decodePoint(
        bytes: [UInt8],
        offset: inout Int,
        hasZ: Bool,
        hasM: Bool,
        scale: Double,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> Point {
        let coord = try decodeCoordinate(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, sourceProjection: sourceProjection, targetProjection: targetProjection)
        return Point(coord)
    }

    // MARK: - LineString

    private static func decodeLineString(
        bytes: [UInt8],
        offset: inout Int,
        hasZ: Bool,
        hasM: Bool,
        scale: Double,
        precision: Int,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> LineString {
        let count = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        let coords = try decodeCoordinateSequence(bytes: bytes, offset: &offset, count: count, hasZ: hasZ, hasM: hasM, scale: scale, sourceProjection: sourceProjection, targetProjection: targetProjection)
        return LineString(unchecked: coords)
    }

    // MARK: - Polygon

    private static func decodePolygon(
        bytes: [UInt8],
        offset: inout Int,
        hasZ: Bool,
        hasM: Bool,
        scale: Double,
        precision: Int,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> Polygon {
        let ringCount = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        var rings: [[Coordinate3D]] = []
        for _ in 0..<ringCount {
            let pointCount = Int(try decodeVarInt(bytes: bytes, offset: &offset))
            let coords = try decodeCoordinateSequence(bytes: bytes, offset: &offset, count: pointCount, hasZ: hasZ, hasM: hasM, scale: scale, sourceProjection: sourceProjection, targetProjection: targetProjection)
            // Close the ring
            var ring = coords
            ring.append(ring[0])
            rings.append(ring)
        }
        guard let polygon = Polygon(rings) else { throw TWKBError.invalidGeometry }
        return polygon
    }

    // MARK: - Multi-geometries

    private static func decodeMultiPoint(
        bytes: [UInt8],
        offset: inout Int,
        hasZ: Bool,
        hasM: Bool,
        scale: Double,
        precision: Int,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> MultiPoint {
        let count = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        var points: [Point] = []
        // MultiPoint stores all coordinates as a single sequence deltas
        let coords = try decodeCoordinateSequence(bytes: bytes, offset: &offset, count: count, hasZ: hasZ, hasM: hasM, scale: scale, sourceProjection: sourceProjection, targetProjection: targetProjection)
        points = coords.map { Point($0) }
        guard let mp = MultiPoint(points.map(\.coordinate)) else { throw TWKBError.invalidGeometry }
        return mp
    }

    private static func decodeMultiLineString(
        bytes: [UInt8],
        offset: inout Int,
        hasZ: Bool,
        hasM: Bool,
        scale: Double,
        precision: Int,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> MultiLineString {
        let count = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        var lineStrings: [[Coordinate3D]] = []
        for _ in 0..<count {
            let pointCount = Int(try decodeVarInt(bytes: bytes, offset: &offset))
            let coords = try decodeCoordinateSequence(bytes: bytes, offset: &offset, count: pointCount, hasZ: hasZ, hasM: hasM, scale: scale, sourceProjection: sourceProjection, targetProjection: targetProjection)
            lineStrings.append(coords)
        }
        return MultiLineString(unchecked: lineStrings)
    }

    private static func decodeMultiPolygon(
        bytes: [UInt8],
        offset: inout Int,
        hasZ: Bool,
        hasM: Bool,
        scale: Double,
        precision: Int,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> MultiPolygon {
        let count = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        var polygons: [Polygon] = []
        for _ in 0..<count {
            let ringCount = Int(try decodeVarInt(bytes: bytes, offset: &offset))
            var rings: [[Coordinate3D]] = []
            for _ in 0..<ringCount {
                let pointCount = Int(try decodeVarInt(bytes: bytes, offset: &offset))
                let coords = try decodeCoordinateSequence(bytes: bytes, offset: &offset, count: pointCount, hasZ: hasZ, hasM: hasM, scale: scale, sourceProjection: sourceProjection, targetProjection: targetProjection)
                var ring = coords
                if ring.first != ring.last {
                    ring.append(ring[0])
                }
                rings.append(ring)
            }
            guard let polygon = Polygon(rings) else { throw TWKBError.invalidGeometry }
            polygons.append(polygon)
        }
        return MultiPolygon(unchecked: polygons)
    }

    private static func decodeGeometryCollection(
        bytes: [UInt8],
        offset: inout Int,
        hasZ: Bool,
        hasM: Bool,
        scale: Double,
        precision: Int,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> GeometryCollection {
        let count = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        var geoms: [any GeoJsonGeometry] = []
        for _ in 0..<count {
            let geom = try decodeGeometry(bytes: bytes, offset: &offset, sourceProjection: sourceProjection, targetProjection: targetProjection, parentPrecision: precision)
            geoms.append(geom)
        }
        return GeometryCollection(geoms)
    }

    // MARK: - Coordinate decoding

    /// Decodes a single coordinate from zigzag-encoded int64 values scaled by `scale`.
    private static func decodeCoordinate(
        bytes: [UInt8],
        offset: inout Int,
        hasZ: Bool,
        hasM: Bool,
        scale: Double,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> Coordinate3D {
        let x = Double(decodeZigZag(try decodeVarInt(bytes: bytes, offset: &offset))) / scale
        let y = Double(decodeZigZag(try decodeVarInt(bytes: bytes, offset: &offset))) / scale
        let z: Double? = hasZ ? Double(decodeZigZag(try decodeVarInt(bytes: bytes, offset: &offset))) / scale : nil
        let m: Double? = hasM ? Double(decodeZigZag(try decodeVarInt(bytes: bytes, offset: &offset))) / scale : nil

        let coord = makeCoordinate(x: x, y: y, z: z, m: m, sourceProjection: sourceProjection)
        if sourceProjection != targetProjection {
            return coord.projected(to: targetProjection)
        }
        return coord
    }

    /// Decodes a sequence of `count` coordinates as deltas from a running base.
    private static func decodeCoordinateSequence(
        bytes: [UInt8],
        offset: inout Int,
        count: Int,
        hasZ: Bool,
        hasM: Bool,
        scale: Double,
        sourceProjection: Projection,
        targetProjection: Projection
    ) throws -> [Coordinate3D] {
        guard count > 0 else { return [] }

        var coords: [Coordinate3D] = []
        var baseX: Int64 = 0
        var baseY: Int64 = 0
        var baseZ: Int64 = 0
        var baseM: Int64 = 0

        for _ in 0..<count {
            baseX += decodeZigZag(try decodeVarInt(bytes: bytes, offset: &offset))
            baseY += decodeZigZag(try decodeVarInt(bytes: bytes, offset: &offset))
            if hasZ { baseZ += decodeZigZag(try decodeVarInt(bytes: bytes, offset: &offset)) }
            if hasM { baseM += decodeZigZag(try decodeVarInt(bytes: bytes, offset: &offset)) }

            let x = Double(baseX) / scale
            let y = Double(baseY) / scale
            let z: Double? = hasZ ? Double(baseZ) / scale : nil
            let m: Double? = hasM ? Double(baseM) / scale : nil

            let coord = makeCoordinate(x: x, y: y, z: z, m: m, sourceProjection: sourceProjection)
            coords.append(sourceProjection != targetProjection ? coord.projected(to: targetProjection) : coord)
        }
        return coords
    }

    // MARK: - Coordinate construction

    private static func makeCoordinate(
        x: Double,
        y: Double,
        z: Double?,
        m: Double?,
        sourceProjection: Projection
    ) -> Coordinate3D {
        switch sourceProjection {
        case .epsg4326:
            return Coordinate3D(latitude: y, longitude: x, altitude: z, m: m)
        case .epsg3857:
            return Coordinate3D(x: x, y: y, z: z, m: m)
        case .noSRID:
            return Coordinate3D(x: x, y: y, z: z, m: m, projection: sourceProjection)
        }
    }

    // MARK: - VarInt

    /// Decodes an unsigned variable-length integer (MSB continuation bit).
    private static func decodeVarInt(
        bytes: [UInt8],
        offset: inout Int
    ) throws -> UInt64 {
        var value: UInt64 = 0
        var shift = 0
        while offset < bytes.count {
            let byte = bytes[offset]
            offset += 1
            value |= UInt64(byte & 0x7F) << shift
            if (byte & 0x80) == 0 { return value }
            shift += 7
        }
        throw TWKBError.dataCorrupted
    }

    // MARK: - ZigZag

    private static func decodeZigZag(_ value: UInt64) -> Int64 {
        Int64(bitPattern: (value >> 1) ^ (~(value & 1) &+ 1))
    }

}
