import Foundation

// MARK: GeoJsonGeometry extension

extension GeoJsonGeometry {

    public init?(
        wkb: Data,
        srid: Int?,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKBCoder.decode(wkb: wkb, srid: srid) else { return nil }
        self.init(json: geometry.asJson, calculateBoundingBox: calculateBoundingBox)
    }

    public init?(
        wkb: Data,
        projection: Projection,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKBCoder.decode(wkb: wkb, projection: projection) else { return nil }
        self.init(json: geometry.asJson, calculateBoundingBox: calculateBoundingBox)
    }

    public static func parse(
        wkb: Data,
        srid: Int?)
        -> GeoJsonGeometry?
    {
        try? WKBCoder.decode(wkb: wkb, srid: srid)
    }

    public static func parse(
        wkb: Data,
        projection: Projection)
        -> GeoJsonGeometry?
    {
        try? WKBCoder.decode(wkb: wkb, projection: projection)
    }

    public var asWKB: Data? {
        return WKBCoder.encode(geometry: self)
    }

}

// MARK: - Feature extension

extension Feature {

    public init?(
        wkb: Data,
        srid: Int?,
        properties: [String: Any] = [:],
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKBCoder.decode(wkb: wkb, srid: srid) else { return nil }
        self.init(geometry, properties: properties, calculateBoundingBox: calculateBoundingBox)
    }

    public init?(
        wkb: Data,
        projection: Projection,
        properties: [String: Any] = [:],
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKBCoder.decode(wkb: wkb, projection: projection) else { return nil }
        self.init(geometry, properties: properties, calculateBoundingBox: calculateBoundingBox)
    }

    public var asWKB: Data? {
        return WKBCoder.encode(geometry: self.geometry)
    }

}

// MARK: - FeatureCollection extension

extension FeatureCollection {

    public init?(
        wkb: Data,
        srid: Int?,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKBCoder.decode(wkb: wkb, srid: srid) else { return nil }
        self.init([geometry], calculateBoundingBox: calculateBoundingBox)
    }

    public init?(
        wkb: Data,
        projection: Projection,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKBCoder.decode(wkb: wkb, projection: projection) else { return nil }
        self.init([geometry], calculateBoundingBox: calculateBoundingBox)
    }

    public var asWKB: Data? {
        return WKBCoder.encode(geometry: GeometryCollection(self.features.map(\.geometry)))
    }

}

// MARK: - Data extensions

extension Data {

    public func asGeoJsonGeometry(srid: Int?) -> GeoJsonGeometry? {
        GeometryCollection.parse(wkb: self, srid: srid)
    }

    public func asGeoJsonGeometry(projection: Projection) -> GeoJsonGeometry? {
        GeometryCollection.parse(wkb: self, projection: projection)
    }

    public func asFeature(
        srid: Int?,
        properties: [String: Any] = [:])
        -> Feature?
    {
        Feature(wkb: self, srid: srid, properties: properties)
    }

    public func asFeature(
        projection: Projection,
        properties: [String: Any] = [:])
        -> Feature?
    {
        Feature(wkb: self, projection: projection, properties: properties)
    }

    public func asFeatureCollection(srid: Int?) -> FeatureCollection? {
        FeatureCollection(wkb: self, srid: srid)
    }

    public func asFeatureCollection(projection: Projection) -> FeatureCollection? {
        FeatureCollection(wkb: self, projection: projection)
    }

}

// MARK: - WKBCoder

// http://portal.opengeospatial.org/files/?artifact_id=25355
//
// This code borrows a lot from https://github.com/plarson/WKCodable

/// A tool for encoding and decoding GeoJSON objects from WKB.
public struct WKBCoder {

    enum WKBTypeCode: Int {
        case point = 1
        case lineString = 2
        case polygon = 3
        case multiPoint = 4
        case multiLineString = 5
        case multiPolygon = 6
        case geometryCollection = 7
        case triangle = 17
    }

    public enum ByteOrder: UInt8 {
        case bigEndian = 0
        case littleEndian = 1
    }

    public enum WKBCoderError: Error {
        case dataCorrupted
        case emptyGeometry
        case invalidGeometry
        case unknownSRID
        case unexpectedType
    }

}

// MARK: - WKB decoding

extension WKBCoder {

    public static func decode(
        wkb: Data,
        srid: Int?)
        throws -> GeoJsonGeometry
    {
        var projection: Projection?

        if let srid = srid {
            projection = Projection(srid: srid)
            guard projection != nil, projection != .noSRID else { throw WKBCoderError.unknownSRID }
        }

        let bytes = [UInt8](wkb)
        var offset: Int = 0

        return try decodeGeometry(bytes: bytes, offset: &offset, projection: projection)
    }

    public static func decode(
        wkb: Data,
        projection: Projection)
        throws -> GeoJsonGeometry
    {
        let bytes = [UInt8](wkb)
        var offset: Int = 0

        return try decodeGeometry(bytes: bytes, offset: &offset, projection: projection)
    }

    // MARK: -

    private static func decodeGeometry(
        bytes: [UInt8],
        offset: inout Int,
        projection: Projection?)
        throws -> GeoJsonGeometry
    {
        guard let byteOrder = ByteOrder(rawValue: try decodeUInt8(bytes: bytes, offset: &offset, byteOrder: .bigEndian)) else {
            throw WKBCoderError.dataCorrupted
        }

        var typeCodeValue = try decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder)
        var decodeZ = false
        var decodeM = false

        if typeCodeValue & 0x80000000 != 0 {
            decodeZ = true
        }
        if typeCodeValue & 0x40000000 != 0 {
            decodeM = true
        }
        typeCodeValue &= 0x0fffffff

        guard let typeCode = WKBTypeCode(rawValue: Int(typeCodeValue)) else {
            throw WKBCoderError.unexpectedType
        }

        var projection = projection
        if projection == nil {
            let srid = try decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder)
            projection = Projection(srid: Int(srid))
        }
        guard projection != nil, projection != .noSRID else { throw WKBCoderError.unknownSRID }

        switch typeCode {
        case .point:
            return try decodePoint(bytes: bytes, offset: &offset, byteOrder: byteOrder, projection: projection, decodeZ: decodeZ, decodeM: decodeM)
        case .multiPoint:
            return try decodeMultiPoint(bytes: bytes, offset: &offset, byteOrder: byteOrder, projection: projection, decodeZ: decodeZ, decodeM: decodeM)
        case .lineString:
            return try decodeLineString(bytes: bytes, offset: &offset, byteOrder: byteOrder, projection: projection, decodeZ: decodeZ, decodeM: decodeM)
        case .multiLineString:
            return try decodeMultiLineString(bytes: bytes, offset: &offset, byteOrder: byteOrder, projection: projection, decodeZ: decodeZ, decodeM: decodeM)
        case .polygon, .triangle:
            return try decodePolygon(bytes: bytes, offset: &offset, byteOrder: byteOrder, projection: projection, decodeZ: decodeZ, decodeM: decodeM)
        case .multiPolygon:
            return try decodeMultiPolygon(bytes: bytes, offset: &offset, byteOrder: byteOrder, projection: projection, decodeZ: decodeZ, decodeM: decodeM)
        case .geometryCollection:
            return try decodeGeometryCollection(bytes: bytes, offset: &offset, byteOrder: byteOrder, projection: projection)
        }
    }

    private static func decodeCoordinate(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        projection: Projection?,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> Coordinate3D
    {
        guard let projection = projection else { throw WKBCoderError.unknownSRID }

        let x = try decodeDouble(bytes: bytes, offset: &offset, byteOrder: byteOrder)
        let y = try decodeDouble(bytes: bytes, offset: &offset, byteOrder: byteOrder)

        var z: Double?
        var m: Double?
        if decodeZ {
            z = try decodeDouble(bytes: bytes, offset: &offset, byteOrder: byteOrder)
        }
        if decodeM {
            m = try decodeDouble(bytes: bytes, offset: &offset, byteOrder: byteOrder)
        }

        switch projection {
        case .epsg4326:
            return Coordinate3D(latitude: y, longitude: x, altitude: z, m: m)
        case .epsg3857:
            return CoordinateXY(x: x, y: y, z: z, m: m).projectedToEpsg4326
        case .noSRID:
            throw WKBCoderError.unknownSRID
        }
    }

    private static func decodePoint(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        projection: Projection?,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> Point
    {
        return Point(try decodeCoordinate(bytes: bytes, offset: &offset, byteOrder: byteOrder, projection: projection, decodeZ: decodeZ, decodeM: decodeM))
    }

    private static func decodeMultiPoint(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        projection: Projection?,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> MultiPoint
    {
        guard let count = try? decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder) else {
            return MultiPoint()
        }

        var points: [Point] = []

        try count.times {
            guard let point = try decodeGeometry(bytes: bytes, offset: &offset, projection: projection) as? Point else {
                throw WKBCoderError.invalidGeometry
            }
            points.append(point)
        }

        return MultiPoint(points) ?? MultiPoint()
    }

    private static func decodeLineString(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        projection: Projection?,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> LineString
    {
        guard let count = try? decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder) else {
            return LineString()
        }

        var coordinates: [Coordinate3D] = []

        try count.times {
            coordinates.append(try decodeCoordinate(bytes: bytes, offset: &offset, byteOrder: byteOrder, projection: projection, decodeZ: decodeZ, decodeM: decodeM))
        }

        return LineString(coordinates) ?? LineString()
    }

    private static func decodeMultiLineString(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        projection: Projection?,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> MultiLineString
    {
        guard let count = try? decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder) else {
            return MultiLineString()
        }

        var lineStrings: [LineString] = []

        try count.times {
            guard let lineString = try decodeGeometry(bytes: bytes, offset: &offset, projection: projection) as? LineString else {
                throw WKBCoderError.invalidGeometry
            }
            lineStrings.append(lineString)
        }

        return MultiLineString(lineStrings) ?? MultiLineString()
    }

    private static func decodePolygon(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        projection: Projection?,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> Polygon
    {
        let count = try decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder)
        guard count > 0 else {
            return Polygon()
        }

        var rings: [Ring] = []
        try count.times {
            if let ring = Ring(try decodeLineString(bytes: bytes, offset: &offset, byteOrder: byteOrder, projection: projection, decodeZ: decodeZ, decodeM: decodeM).coordinates) {
                rings.append(ring)
            }
        }

        return Polygon(rings) ?? Polygon()
    }

    private static func decodeMultiPolygon(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        projection: Projection?,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> MultiPolygon
    {
        guard let count = try? decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder) else {
            return MultiPolygon()
        }

        var polygons: [Polygon] = []

        try count.times {
            guard let polygon = try decodeGeometry(bytes: bytes, offset: &offset, projection: projection) as? Polygon else {
                throw WKBCoderError.invalidGeometry
            }
            polygons.append(polygon)
        }

        return MultiPolygon(polygons) ?? MultiPolygon()
    }

    private static func decodeGeometryCollection(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        projection: Projection?)
        throws -> GeometryCollection
    {
        var geometries: [GeoJsonGeometry] = []

        guard let count = try? decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder) else {
            return GeometryCollection(geometries)
        }

        try count.times {
            geometries.append(try decodeGeometry(bytes: bytes, offset: &offset, projection: projection))
        }

        return GeometryCollection(geometries)
    }

    // MARK: -

    private static func decodeUInt8(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder)
        throws -> UInt8
    {
        var value: UInt8 = 0
        try read(bytes: bytes, offset: &offset, into: &value)
        return byteOrder == .bigEndian ? value.bigEndian : value.littleEndian
    }

    private static func decodeUInt32(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder)
        throws -> UInt32
    {
        var value: UInt32 = 0
        try read(bytes: bytes, offset: &offset, into: &value)
        return byteOrder == .bigEndian ? value.bigEndian : value.littleEndian
    }

    private static func decodeDouble(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder)
        throws -> Double
    {
        var value = UInt64()
        try read(bytes: bytes, offset: &offset, into: &value)
        return Double(bitPattern: byteOrder == .bigEndian ? value.bigEndian : value.littleEndian)
    }

    private static func read<T>(
        bytes: [UInt8],
        offset: inout Int,
        into: inout T)
        throws
    {
        try read(
            bytes: bytes,
            offset: &offset,
            byteCount: MemoryLayout<T>.size,
            into: &into)
    }

    private static func read(
        bytes: [UInt8],
        offset: inout Int,
        byteCount: Int,
        into: UnsafeMutableRawPointer)
        throws
    {
        if offset + byteCount > bytes.count {
            throw WKBCoderError.dataCorrupted
        }

        bytes.withUnsafeBytes {
            let from = $0.baseAddress! + offset
            memcpy(into, from, byteCount)
        }

        offset += byteCount
    }

}

// MARK: - WKB encoding

extension WKBCoder {

    public static func encode(
        geometry: GeoJsonGeometry,
        byteOrder: ByteOrder = .littleEndian,
        projection: Projection? = .epsg4326)
        -> Data?
    {
        // This GeoJSON implementation always uses EPSG:4326 (the spec uses CRS:84)
        guard projection == nil || projection == .epsg4326 else { return nil }

        var data = Data()

        encode(geometry: geometry, byteOrder: byteOrder, srid: projection?.srid, to: &data)

        return data.nilIfEmpty
    }

    // MARK: -

    private static func encode(
        geometry: GeoJsonGeometry,
        byteOrder: ByteOrder = .littleEndian,
        srid: Int?,
        to data: inout Data)
    {
        switch geometry.type {
        case .point:
            encode(geometry as! Point, byteOrder: byteOrder, srid: srid, to: &data)
        case .multiPoint:
            encode(geometry as! MultiPoint, byteOrder: byteOrder, srid: srid, to: &data)
        case .lineString:
            encode(geometry as! LineString, byteOrder: byteOrder, srid: srid, to: &data)
        case .multiLineString:
            encode(geometry as! MultiLineString, byteOrder: byteOrder, srid: srid, to: &data)
        case .polygon:
            encode(geometry as! Polygon, byteOrder: byteOrder, srid: srid, to: &data)
        case .multiPolygon:
            encode(geometry as! MultiPolygon, byteOrder: byteOrder, srid: srid, to: &data)
        case .geometryCollection:
            encode(geometry as! GeometryCollection, byteOrder: byteOrder, srid: srid, to: &data)
        case .feature, .featureCollection, .invalid:
            break
        }
    }

    private static func encode(
        _ value: Point,
        byteOrder: ByteOrder,
        srid: Int?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.point.rawValue, for: value.coordinate, srid: srid, byteOrder: byteOrder, to: &data)
        appendCoordinate(value.coordinate, byteOrder: byteOrder, to: &data)
    }

    private static func encode(
        _ value: MultiPoint,
        byteOrder: ByteOrder,
        srid: Int?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.multiPoint.rawValue, for: value.points.first?.coordinate, srid: srid, byteOrder: byteOrder, to: &data)
        appendUInt32(UInt32(value.points.count), byteOrder: byteOrder, to: &data)
        value.points.forEach({ encode(geometry: $0, srid: nil, to: &data) })
    }

    private static func encode(
        _ value: LineString,
        byteOrder: ByteOrder,
        srid: Int?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.lineString.rawValue, for: value.coordinates.first, srid: srid, byteOrder: byteOrder, to: &data)
        appendLineString(value, byteOrder: byteOrder, to: &data)
    }

    private static func encode(
        _ value: MultiLineString,
        byteOrder: ByteOrder,
        srid: Int?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.multiLineString.rawValue, for: value.lineStrings.first?.coordinates.first, srid: srid, byteOrder: byteOrder, to: &data)
        appendUInt32(UInt32(value.lineStrings.count), byteOrder: byteOrder, to: &data)
        value.lineStrings.forEach({ encode(geometry: $0, srid: nil, to: &data) })
    }

    private static func encode(
        _ value: Polygon,
        byteOrder: ByteOrder,
        srid: Int?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.polygon.rawValue, for: value.rings.first?.coordinates.first, srid: srid, byteOrder: byteOrder, to: &data)
        appendUInt32(UInt32(value.rings.count), byteOrder: byteOrder, to: &data)
        value.rings.forEach({ appendLineString(LineString($0.coordinates) ?? LineString(), byteOrder: byteOrder, to: &data) })
    }

    private static func encode(
        _ value: MultiPolygon,
        byteOrder: ByteOrder,
        srid: Int?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.multiPolygon.rawValue, for: value.polygons.first?.rings.first?.coordinates.first, srid: srid, byteOrder: byteOrder, to: &data)
        appendUInt32(UInt32(value.polygons.count), byteOrder: byteOrder, to: &data)
        value.polygons.forEach({ encode(geometry: $0, srid: nil, to: &data) })
    }

    private static func encode(
        _ value: GeometryCollection,
        byteOrder: ByteOrder,
        srid: Int?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.geometryCollection.rawValue, for: nil, srid: srid, byteOrder: byteOrder, to: &data)
        appendUInt32(UInt32(value.geometries.count), byteOrder: byteOrder, to: &data)
        value.geometries.forEach({ encode(geometry: $0, srid: nil, to: &data) })
    }

    // MARK: -

    private static func appendCoordinate(
        _ coordinate: Coordinate3D,
        byteOrder: ByteOrder,
        to data: inout Data)
    {
        appendDouble(coordinate.longitude, byteOrder: byteOrder, to: &data)
        appendDouble(coordinate.latitude, byteOrder: byteOrder, to: &data)

        if let z = coordinate.altitude {
            appendDouble(z, byteOrder: byteOrder, to: &data)
        }
        if let m = coordinate.m {
            appendDouble(m, byteOrder: byteOrder, to: &data)
        }
    }

    private static func appendLineString(
        _ value: LineString,
        byteOrder: ByteOrder,
        to data: inout Data)
    {
        appendUInt32(UInt32(value.coordinates.count), byteOrder: byteOrder, to: &data)
        value.coordinates.forEach({ appendCoordinate($0, byteOrder: byteOrder, to: &data) })
    }

    private static func appendByteOrder(
        byteOrder: ByteOrder,
        to data: inout Data)
    {
        appendBytes(of: (byteOrder == .bigEndian ? byteOrder.rawValue.bigEndian : byteOrder.rawValue.littleEndian), to: &data)
    }

    private static func appendTypeCode(
        _ typeCode: Int,
        for coordinate: Coordinate3D? = nil,
        srid: Int?,
        byteOrder: ByteOrder,
        to data: inout Data)
    {
        var typeCode = UInt32(typeCode)

        if coordinate?.altitude != nil {
            typeCode |= 0x80000000
        }

        if coordinate?.m != nil {
            typeCode |= 0x40000000
        }

        if srid != nil {
            typeCode |= 0x20000000
        }

        appendUInt32(typeCode, byteOrder: byteOrder, to: &data)

        if let srid = srid {
            appendUInt32(UInt32(srid), byteOrder: byteOrder, to: &data)
        }
    }

    private static func appendUInt32(
        _ value: UInt32,
        byteOrder: ByteOrder,
        to data: inout Data)
    {
        appendBytes(of: (byteOrder == .bigEndian ? value.bigEndian : value.littleEndian), to: &data)
    }

    private static func appendDouble(
        _ value: Double,
        byteOrder: ByteOrder,
        to data: inout Data)
    {
        appendBytes(of: (byteOrder == .bigEndian ? value.bitPattern.bigEndian : value.bitPattern.littleEndian), to: &data)
    }

    private static func appendBytes<T>(
        of value: T,
        to data: inout Data)
    {
        var value = value
        withUnsafeBytes(of: &value) {
            data += $0
        }
    }

}
