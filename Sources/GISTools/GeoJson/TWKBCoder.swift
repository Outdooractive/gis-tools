#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// https://github.com/TWKB/Specification/blob/master/twkb.md

public enum TWKBCoder {

    public enum TWKBError: Error {
        case dataCorrupted
        case emptyGeometry
        case invalidGeometry
        case unknownSRID
        case unexpectedType
    }

    // MARK: - Public decode entry points

    public static func decode(
        twkb: Data,
        sourceProjection: Projection? = nil,
        targetProjection: Projection = .epsg4326
    ) throws -> (any GeoJsonGeometry)? {
        let bytes = [UInt8](twkb)
        var offset = 0
        return try decodeGeometry(
            bytes: bytes, offset: &offset,
            sourceProjection: sourceProjection,
            targetProjection: targetProjection,
            parentPrecision: nil)
    }

    // MARK: - Internal decode helpers

    /// Reads the header byte: lower 4 bits = geometry type, upper 4 bits = precision exponent.
    private static func decodeHeader(
        bytes: [UInt8], offset: inout Int, parentPrecision: Int?
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
        bytes: [UInt8], offset: inout Int
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
    ) throws -> (any GeoJsonGeometry)? {
        guard offset < bytes.count else { throw TWKBError.emptyGeometry }

        let (geomType, precision) = try decodeHeader(bytes: bytes, offset: &offset, parentPrecision: parentPrecision)
        let (hasZ, hasM, hasSRID, srid) = try decodeMetadata(bytes: bytes, offset: &offset)

        let srcProj = sourceProjection ?? srid.flatMap { Projection(srid: $0) } ?? .epsg4326
        let scale = pow(10.0, Double(precision))

        switch geomType {
        case 1:
            return try decodePoint(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, srcProj: srcProj, target: targetProjection)
        case 2:
            return try decodeLineString(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, precision: precision, srcProj: srcProj, target: targetProjection)
        case 3:
            return try decodePolygon(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, precision: precision, srcProj: srcProj, target: targetProjection)
        case 4:
            return try decodeMultiPoint(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, precision: precision, srcProj: srcProj, target: targetProjection)
        case 5:
            return try decodeMultiLineString(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, precision: precision, srcProj: srcProj, target: targetProjection)
        case 6:
            return try decodeMultiPolygon(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, precision: precision, srcProj: srcProj, target: targetProjection)
        case 7:
            return try decodeGeometryCollection(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, precision: precision, srcProj: srcProj, target: targetProjection)
        default:
            throw TWKBError.unexpectedType
        }
    }

    // MARK: - Point

    private static func decodePoint(
        bytes: [UInt8], offset: inout Int,
        hasZ: Bool, hasM: Bool,
        scale: Double, srcProj: Projection, target: Projection
    ) throws -> Point {
        let coord = try decodeCoordinate(bytes: bytes, offset: &offset, hasZ: hasZ, hasM: hasM, scale: scale, srcProj: srcProj, target: target)
        return Point(coord)
    }

    // MARK: - LineString

    private static func decodeLineString(
        bytes: [UInt8], offset: inout Int,
        hasZ: Bool, hasM: Bool,
        scale: Double, precision: Int,
        srcProj: Projection, target: Projection
    ) throws -> LineString {
        let count = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        let coords = try decodeCoordinateSequence(bytes: bytes, offset: &offset, count: count, hasZ: hasZ, hasM: hasM, scale: scale, srcProj: srcProj, target: target)
        return LineString(unchecked: coords)
    }

    // MARK: - Polygon

    private static func decodePolygon(
        bytes: [UInt8], offset: inout Int,
        hasZ: Bool, hasM: Bool,
        scale: Double, precision: Int,
        srcProj: Projection, target: Projection
    ) throws -> Polygon {
        let ringCount = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        var rings: [[Coordinate3D]] = []
        for _ in 0..<ringCount {
            let pointCount = Int(try decodeVarInt(bytes: bytes, offset: &offset))
            let coords = try decodeCoordinateSequence(bytes: bytes, offset: &offset, count: pointCount, hasZ: hasZ, hasM: hasM, scale: scale, srcProj: srcProj, target: target)
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
        bytes: [UInt8], offset: inout Int,
        hasZ: Bool, hasM: Bool,
        scale: Double, precision: Int,
        srcProj: Projection, target: Projection
    ) throws -> MultiPoint {
        let count = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        var points: [Point] = []
        // MultiPoint stores all coordinates as a single sequence deltas
        let coords = try decodeCoordinateSequence(bytes: bytes, offset: &offset, count: count, hasZ: hasZ, hasM: hasM, scale: scale, srcProj: srcProj, target: target)
        points = coords.map { Point($0) }
        guard let mp = MultiPoint(points.map(\.coordinate)) else { throw TWKBError.invalidGeometry }
        return mp
    }

    private static func decodeMultiLineString(
        bytes: [UInt8], offset: inout Int,
        hasZ: Bool, hasM: Bool,
        scale: Double, precision: Int,
        srcProj: Projection, target: Projection
    ) throws -> MultiLineString {
        let count = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        var lineStrings: [[Coordinate3D]] = []
        for _ in 0..<count {
            let pointCount = Int(try decodeVarInt(bytes: bytes, offset: &offset))
            let coords = try decodeCoordinateSequence(bytes: bytes, offset: &offset, count: pointCount, hasZ: hasZ, hasM: hasM, scale: scale, srcProj: srcProj, target: target)
            lineStrings.append(coords)
        }
        return MultiLineString(unchecked: lineStrings)
    }

    private static func decodeMultiPolygon(
        bytes: [UInt8], offset: inout Int,
        hasZ: Bool, hasM: Bool,
        scale: Double, precision: Int,
        srcProj: Projection, target: Projection
    ) throws -> MultiPolygon {
        let count = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        var polygons: [Polygon] = []
        for _ in 0..<count {
            let ringCount = Int(try decodeVarInt(bytes: bytes, offset: &offset))
            var rings: [[Coordinate3D]] = []
            for _ in 0..<ringCount {
                let pointCount = Int(try decodeVarInt(bytes: bytes, offset: &offset))
                let coords = try decodeCoordinateSequence(bytes: bytes, offset: &offset, count: pointCount, hasZ: hasZ, hasM: hasM, scale: scale, srcProj: srcProj, target: target)
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
        bytes: [UInt8], offset: inout Int,
        hasZ: Bool, hasM: Bool,
        scale: Double, precision: Int,
        srcProj: Projection, target: Projection
    ) throws -> GeometryCollection {
        let count = Int(try decodeVarInt(bytes: bytes, offset: &offset))
        var geoms: [any GeoJsonGeometry] = []
        for _ in 0..<count {
            if let geom = try decodeGeometry(bytes: bytes, offset: &offset, sourceProjection: srcProj, targetProjection: target, parentPrecision: precision) {
                geoms.append(geom)
            }
        }
        return GeometryCollection(geoms)
    }

    // MARK: - Coordinate decoding

    /// Decodes a single coordinate from zigzag-encoded int64 values scaled by `scale`.
    private static func decodeCoordinate(
        bytes: [UInt8], offset: inout Int,
        hasZ: Bool, hasM: Bool,
        scale: Double, srcProj: Projection, target: Projection
    ) throws -> Coordinate3D {
        let x = Double(decodeZigZag(try decodeVarInt(bytes: bytes, offset: &offset))) / scale
        let y = Double(decodeZigZag(try decodeVarInt(bytes: bytes, offset: &offset))) / scale
        let z: Double? = hasZ ? Double(decodeZigZag(try decodeVarInt(bytes: bytes, offset: &offset))) / scale : nil
        let m: Double? = hasM ? Double(decodeZigZag(try decodeVarInt(bytes: bytes, offset: &offset))) / scale : nil

        let coord = makeCoordinate(x: x, y: y, z: z, m: m, srcProj: srcProj)
        if srcProj != target {
            return coord.projected(to: target)
        }
        return coord
    }

    /// Decodes a sequence of `count` coordinates as deltas from a running base.
    private static func decodeCoordinateSequence(
        bytes: [UInt8], offset: inout Int,
        count: Int, hasZ: Bool, hasM: Bool,
        scale: Double, srcProj: Projection, target: Projection
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

            let coord = makeCoordinate(x: x, y: y, z: z, m: m, srcProj: srcProj)
            coords.append(srcProj != target ? coord.projected(to: target) : coord)
        }
        return coords
    }

    // MARK: - Coordinate construction

    private static func makeCoordinate(
        x: Double, y: Double, z: Double?, m: Double?,
        srcProj: Projection
    ) -> Coordinate3D {
        switch srcProj {
        case .epsg4326:
            return Coordinate3D(latitude: y, longitude: x, altitude: z, m: m)
        case .epsg3857:
            return Coordinate3D(x: x, y: y, z: z, m: m)
        case .noSRID:
            return Coordinate3D(x: x, y: y, z: z, m: m, projection: srcProj)
        }
    }

    // MARK: - VarInt

    /// Decodes an unsigned variable-length integer (MSB continuation bit).
    private static func decodeVarInt(
        bytes: [UInt8], offset: inout Int
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
