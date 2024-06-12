import Foundation

// MARK: GeoJsonGeometry extension

extension GeoJsonGeometry {

    /// Decode a GeoJSON object from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkb: Data,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKBCoder.decode(wkb: wkb, sourceSrid: sourceSrid, targetProjection: targetProjection) else { return nil }
        self.init(json: geometry.asJson, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON object from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkb: Data,
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKBCoder.decode(wkb: wkb, sourceProjection: sourceProjection, targetProjection: targetProjection) else { return nil }
        self.init(json: geometry.asJson, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON object from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func parse(
        wkb: Data,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326)
        -> GeoJsonGeometry?
    {
        try? WKBCoder.decode(wkb: wkb, sourceSrid: sourceSrid, targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func parse(
        wkb: Data,
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326)
        -> GeoJsonGeometry?
    {
        try? WKBCoder.decode(wkb: wkb, sourceProjection: sourceProjection, targetProjection: targetProjection)
    }

    /// Returns the receiver as WKB encoded data.
    public var asWKB: Data? {
        WKBCoder.encode(geometry: self)
    }

}

// MARK: - Feature extension

extension Feature {

    /// Decode a GeoJSON Feature from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkb: Data,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326,
        id: Identifier? = nil,
        properties: [String: Sendable] = [:],
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKBCoder.decode(wkb: wkb, sourceSrid: sourceSrid, targetProjection: targetProjection) else { return nil }
        self.init(geometry, id: id, properties: properties, calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON Feature from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkb: Data,
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326,
        id: Identifier? = nil,
        properties: [String: Sendable] = [:],
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKBCoder.decode(wkb: wkb, sourceProjection: sourceProjection, targetProjection: targetProjection) else { return nil }
        self.init(geometry, id: id, properties: properties, calculateBoundingBox: calculateBoundingBox)
    }

    /// Returns the receiver as WKB encoded data.
    public var asWKB: Data? {
        WKBCoder.encode(geometry: self.geometry)
    }

}

// MARK: - FeatureCollection extension

extension FeatureCollection {

    /// Decode a GeoJSON FeatureCollection from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkb: Data,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKBCoder.decode(wkb: wkb, sourceSrid: sourceSrid, targetProjection: targetProjection) else { return nil }
        self.init([geometry], calculateBoundingBox: calculateBoundingBox)
    }

    /// Decode a GeoJSON FeatureCollection from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public init?(
        wkb: Data,
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326,
        calculateBoundingBox: Bool = false)
    {
        guard let geometry = try? WKBCoder.decode(wkb: wkb, sourceProjection: sourceProjection, targetProjection: targetProjection) else { return nil }
        self.init([geometry], calculateBoundingBox: calculateBoundingBox)
    }

    /// Returns the receiver as WKB encoded data.
    public var asWKB: Data? {
        WKBCoder.encode(geometry: GeometryCollection(self.features.map(\.geometry)))
    }

}

// MARK: - Data extensions

extension Data {

    /// Decode a GeoJSON object from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asGeoJsonGeometry(
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326)
        -> GeoJsonGeometry?
    {
        GeometryCollection.parse(wkb: self, sourceSrid: sourceSrid, targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asGeoJsonGeometry(
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326)
        -> GeoJsonGeometry?
    {
        GeometryCollection.parse(wkb: self, sourceProjection: sourceProjection, targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeature(
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326,
        id: Feature.Identifier? = nil,
        properties: [String: Sendable] = [:])
        -> Feature?
    {
        Feature(wkb: self, sourceSrid: sourceSrid, targetProjection: targetProjection, id: id, properties: properties)
    }

    /// Decode a GeoJSON object from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeature(
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326,
        id: Feature.Identifier? = nil,
        properties: [String: Sendable] = [:])
        -> Feature?
    {
        Feature(wkb: self, sourceProjection: sourceProjection, targetProjection: targetProjection, id: id, properties: properties)
    }

    /// Decode a GeoJSON object from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeatureCollection(
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326)
        -> FeatureCollection?
    {
        FeatureCollection(wkb: self, sourceSrid: sourceSrid, targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public func asFeatureCollection(
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326)
        -> FeatureCollection?
    {
        FeatureCollection(wkb: self, sourceProjection: sourceProjection, targetProjection: targetProjection)
    }

}

// MARK: - WKBCoder

// http://portal.opengeospatial.org/files/?artifact_id=25355
//
// This code borrows a lot from https://github.com/plarson/WKCodable

/// A tool for encoding and decoding GeoJSON objects from WKB.
public enum WKBCoder {

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

    /// The WKB byte order (little or big endian).
    public enum ByteOrder: UInt8 {
        case bigEndian = 0
        case littleEndian = 1
    }

    /// WKB errors.
    public enum WKBCoderError: Error {
        case dataCorrupted
        case emptyGeometry
        case invalidGeometry
        case targetProjectionMustBeNoSRID
        case unknownSRID
        case unexpectedType
    }

}

// MARK: - WKB decoding

extension WKBCoder {

    /// Decode a GeoJSON object from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func decode(
        wkb: Data,
        sourceSrid: Int?,
        targetProjection: Projection = .epsg4326)
        throws -> GeoJsonGeometry
    {
        var sourceProjection: Projection?

        if let sourceSrid {
            sourceProjection = Projection(srid: sourceSrid)
            guard sourceProjection != nil else { throw WKBCoderError.unknownSRID }
        }

        let bytes = [UInt8](wkb)
        var offset = 0

        return try decodeGeometry(bytes: bytes, offset: &offset, sourceProjection: sourceProjection, targetProjection: targetProjection)
    }

    /// Decode a GeoJSON object from WKB.
    ///
    /// - Important: The resulting GeoJSON will always be projected to EPSG:4326.
    public static func decode(
        wkb: Data,
        sourceProjection: Projection,
        targetProjection: Projection = .epsg4326)
        throws -> GeoJsonGeometry
    {
        let bytes = [UInt8](wkb)
        var offset = 0

        return try decodeGeometry(bytes: bytes, offset: &offset, sourceProjection: sourceProjection, targetProjection: targetProjection)
    }

    // MARK: -

    private static func decodeGeometry(
        bytes: [UInt8],
        offset: inout Int,
        sourceProjection: Projection?,
        targetProjection: Projection)
        throws -> GeoJsonGeometry
    {
        guard let byteOrder = try ByteOrder(rawValue: decodeUInt8(bytes: bytes, offset: &offset, byteOrder: .bigEndian)) else {
            throw WKBCoderError.dataCorrupted
        }

        var typeCodeValue = try decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder)
        var decodeZ = false
        var decodeM = false

        if typeCodeValue & 0x8000_0000 != 0 {
            decodeZ = true
        }
        if typeCodeValue & 0x4000_0000 != 0 {
            decodeM = true
        }
        typeCodeValue &= 0x0FFF_FFFF

        guard let typeCode = WKBTypeCode(rawValue: Int(typeCodeValue)) else {
            throw WKBCoderError.unexpectedType
        }

        var sourceProjection = sourceProjection
        if sourceProjection == nil {
            let srid = try decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder)
            sourceProjection = Projection(srid: Int(srid))
        }
        guard let sourceProjection else { throw WKBCoderError.unknownSRID }

        if sourceProjection == .noSRID,
           targetProjection != .noSRID
        {
            throw WKBCoderError.targetProjectionMustBeNoSRID
        }

        switch typeCode {
        case .point:
            return try decodePoint(bytes: bytes, offset: &offset, byteOrder: byteOrder, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM)
        case .multiPoint:
            return try decodeMultiPoint(bytes: bytes, offset: &offset, byteOrder: byteOrder, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM)
        case .lineString:
            return try decodeLineString(bytes: bytes, offset: &offset, byteOrder: byteOrder, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM)
        case .multiLineString:
            return try decodeMultiLineString(bytes: bytes, offset: &offset, byteOrder: byteOrder, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM)
        case .polygon, .triangle:
            return try decodePolygon(bytes: bytes, offset: &offset, byteOrder: byteOrder, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM)
        case .multiPolygon:
            return try decodeMultiPolygon(bytes: bytes, offset: &offset, byteOrder: byteOrder, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM)
        case .geometryCollection:
            return try decodeGeometryCollection(bytes: bytes, offset: &offset, byteOrder: byteOrder, sourceProjection: sourceProjection, targetProjection: targetProjection)
        }
    }

    private static func decodeCoordinate(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        sourceProjection: Projection?,
        targetProjection: Projection,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> Coordinate3D
    {
        guard let sourceProjection else { throw WKBCoderError.unknownSRID }

        let x = try decodeDouble(bytes: bytes, offset: &offset, byteOrder: byteOrder)
        let y = try decodeDouble(bytes: bytes, offset: &offset, byteOrder: byteOrder)

        guard x.isFinite, y.isFinite else {
            throw WKBCoderError.invalidGeometry
        }

        var z: Double?
        var m: Double?
        if decodeZ {
            z = try decodeDouble(bytes: bytes, offset: &offset, byteOrder: byteOrder)
            if z?.isFinite == false { z = nil }
        }
        if decodeM {
            m = try decodeDouble(bytes: bytes, offset: &offset, byteOrder: byteOrder)
            if m?.isFinite == false { m = nil }
        }

        switch sourceProjection {
        case .epsg4326:
            switch targetProjection {
            case .epsg3857:
                return Coordinate3D(latitude: y, longitude: x, altitude: z, m: m).projected(to: targetProjection)
            case .epsg4326:
                return Coordinate3D(latitude: y, longitude: x, altitude: z, m: m)
            case .noSRID:
                return Coordinate3D(x: x, y: y, z: z, m: m, projection: targetProjection)
            }

        case .epsg3857:
            switch targetProjection {
            case .epsg3857:
                return Coordinate3D(x: x, y: y, z: z, m: m)
            case .epsg4326:
                return Coordinate3D(x: x, y: y, z: z, m: m).projected(to: targetProjection)
            case .noSRID:
                return Coordinate3D(x: x, y: y, z: z, m: m, projection: targetProjection)
            }

        case .noSRID:
            return Coordinate3D(x: x, y: y, z: z, m: m, projection: targetProjection)
        }
    }

    private static func decodePoint(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        sourceProjection: Projection?,
        targetProjection: Projection,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> Point
    {
        try Point(decodeCoordinate(bytes: bytes, offset: &offset, byteOrder: byteOrder, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM))
    }

    private static func decodeMultiPoint(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        sourceProjection: Projection?,
        targetProjection: Projection,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> MultiPoint
    {
        guard let count = try? decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder) else {
            return MultiPoint()
        }

        var points: [Point] = []

        try count.times {
            guard let point = try decodeGeometry(bytes: bytes, offset: &offset, sourceProjection: sourceProjection, targetProjection: targetProjection) as? Point else {
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
        sourceProjection: Projection?,
        targetProjection: Projection,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> LineString
    {
        guard let count = try? decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder) else {
            return LineString()
        }

        var coordinates: [Coordinate3D] = []

        try count.times {
            try coordinates.append(decodeCoordinate(bytes: bytes, offset: &offset, byteOrder: byteOrder, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM))
        }

        return LineString(coordinates) ?? LineString()
    }

    private static func decodeMultiLineString(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        sourceProjection: Projection?,
        targetProjection: Projection,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> MultiLineString
    {
        guard let count = try? decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder) else {
            return MultiLineString()
        }

        var lineStrings: [LineString] = []

        try count.times {
            guard let lineString = try decodeGeometry(bytes: bytes, offset: &offset, sourceProjection: sourceProjection, targetProjection: targetProjection) as? LineString else {
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
        sourceProjection: Projection?,
        targetProjection: Projection,
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
            if let ring = try Ring(decodeLineString(bytes: bytes, offset: &offset, byteOrder: byteOrder, sourceProjection: sourceProjection, targetProjection: targetProjection, decodeZ: decodeZ, decodeM: decodeM).coordinates) {
                rings.append(ring)
            }
        }

        return Polygon(rings) ?? Polygon()
    }

    private static func decodeMultiPolygon(
        bytes: [UInt8],
        offset: inout Int,
        byteOrder: ByteOrder,
        sourceProjection: Projection?,
        targetProjection: Projection,
        decodeZ: Bool,
        decodeM: Bool)
        throws -> MultiPolygon
    {
        guard let count = try? decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder) else {
            return MultiPolygon()
        }

        var polygons: [Polygon] = []

        try count.times {
            guard let polygon = try decodeGeometry(bytes: bytes, offset: &offset, sourceProjection: sourceProjection, targetProjection: targetProjection) as? Polygon else {
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
        sourceProjection: Projection?,
        targetProjection: Projection)
        throws -> GeometryCollection
    {
        var geometries: [GeoJsonGeometry] = []

        guard let count = try? decodeUInt32(bytes: bytes, offset: &offset, byteOrder: byteOrder) else {
            return GeometryCollection(geometries)
        }

        try count.times {
            try geometries.append(decodeGeometry(bytes: bytes, offset: &offset, sourceProjection: sourceProjection, targetProjection: targetProjection))
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
        try withUnsafeMutablePointer(to: &into) { into in
            try read(
                bytes: bytes,
                offset: &offset,
                byteCount: MemoryLayout<T>.size,
                into: into)
        }
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

    /// Returns the geometry as WKB encoded data.
    public static func encode(
        geometry: GeoJsonGeometry,
        byteOrder: ByteOrder = .littleEndian,
        targetProjection: Projection? = .epsg4326)
        -> Data?
    {
        var data = Data()

        encode(geometry: geometry, byteOrder: byteOrder, targetProjection: targetProjection, to: &data)

        return data.nilIfEmpty
    }

    // MARK: -

    private static func encode(
        geometry: GeoJsonGeometry,
        byteOrder: ByteOrder = .littleEndian,
        targetProjection: Projection?,
        to data: inout Data)
    {
        switch geometry.type {
        case .point:
            encode(geometry as! Point, byteOrder: byteOrder, targetProjection: targetProjection, to: &data)
        case .multiPoint:
            encode(geometry as! MultiPoint, byteOrder: byteOrder, targetProjection: targetProjection, to: &data)
        case .lineString:
            encode(geometry as! LineString, byteOrder: byteOrder, targetProjection: targetProjection, to: &data)
        case .multiLineString:
            encode(geometry as! MultiLineString, byteOrder: byteOrder, targetProjection: targetProjection, to: &data)
        case .polygon:
            encode(geometry as! Polygon, byteOrder: byteOrder, targetProjection: targetProjection, to: &data)
        case .multiPolygon:
            encode(geometry as! MultiPolygon, byteOrder: byteOrder, targetProjection: targetProjection, to: &data)
        case .geometryCollection:
            encode(geometry as! GeometryCollection, byteOrder: byteOrder, targetProjection: targetProjection, to: &data)
        case .feature, .featureCollection, .invalid:
            break
        }
    }

    private static func encode(
        _ value: Point,
        byteOrder: ByteOrder,
        targetProjection: Projection?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.point.rawValue, for: value.coordinate, targetProjection: targetProjection, byteOrder: byteOrder, to: &data)
        appendCoordinate(value.coordinate, targetProjection: targetProjection, byteOrder: byteOrder, to: &data)
    }

    private static func encode(
        _ value: MultiPoint,
        byteOrder: ByteOrder,
        targetProjection: Projection?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.multiPoint.rawValue, for: value.points.first?.coordinate, targetProjection: targetProjection, byteOrder: byteOrder, to: &data)
        appendUInt32(UInt32(value.points.count), byteOrder: byteOrder, to: &data)
        value.points.forEach({ encode(geometry: $0, targetProjection: nil, to: &data) })
    }

    private static func encode(
        _ value: LineString,
        byteOrder: ByteOrder,
        targetProjection: Projection?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.lineString.rawValue, for: value.coordinates.first, targetProjection: targetProjection, byteOrder: byteOrder, to: &data)
        appendLineString(value, targetProjection: targetProjection, byteOrder: byteOrder, to: &data)
    }

    private static func encode(
        _ value: MultiLineString,
        byteOrder: ByteOrder,
        targetProjection: Projection?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.multiLineString.rawValue, for: value.lineStrings.first?.coordinates.first, targetProjection: targetProjection, byteOrder: byteOrder, to: &data)
        appendUInt32(UInt32(value.lineStrings.count), byteOrder: byteOrder, to: &data)
        value.lineStrings.forEach({ encode(geometry: $0, targetProjection: nil, to: &data) })
    }

    private static func encode(
        _ value: Polygon,
        byteOrder: ByteOrder,
        targetProjection: Projection?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.polygon.rawValue, for: value.rings.first?.coordinates.first, targetProjection: targetProjection, byteOrder: byteOrder, to: &data)
        appendUInt32(UInt32(value.rings.count), byteOrder: byteOrder, to: &data)
        value.rings.forEach({ appendLineString(LineString($0.coordinates) ?? LineString(), targetProjection: targetProjection, byteOrder: byteOrder, to: &data) })
    }

    private static func encode(
        _ value: MultiPolygon,
        byteOrder: ByteOrder,
        targetProjection: Projection?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.multiPolygon.rawValue, for: value.polygons.first?.rings.first?.coordinates.first, targetProjection: targetProjection, byteOrder: byteOrder, to: &data)
        appendUInt32(UInt32(value.polygons.count), byteOrder: byteOrder, to: &data)
        value.polygons.forEach({ encode(geometry: $0, targetProjection: nil, to: &data) })
    }

    private static func encode(
        _ value: GeometryCollection,
        byteOrder: ByteOrder,
        targetProjection: Projection?,
        to data: inout Data)
    {
        appendByteOrder(byteOrder: byteOrder, to: &data)
        appendTypeCode(WKBTypeCode.geometryCollection.rawValue, for: nil, targetProjection: targetProjection, byteOrder: byteOrder, to: &data)
        appendUInt32(UInt32(value.geometries.count), byteOrder: byteOrder, to: &data)
        value.geometries.forEach({ encode(geometry: $0, targetProjection: nil, to: &data) })
    }

    // MARK: -

    private static func appendCoordinate(
        _ coordinate: Coordinate3D,
        targetProjection: Projection?,
        byteOrder: ByteOrder,
        to data: inout Data)
    {
        appendDouble(coordinate.longitudeProjected(to: targetProjection ?? .epsg4326), byteOrder: byteOrder, to: &data)
        appendDouble(coordinate.latitudeProjected(to: targetProjection ?? .epsg4326), byteOrder: byteOrder, to: &data)

        if let z = coordinate.altitude {
            appendDouble(z, byteOrder: byteOrder, to: &data)
        }
        if let m = coordinate.m {
            appendDouble(m, byteOrder: byteOrder, to: &data)
        }
    }

    private static func appendLineString(
        _ value: LineString,
        targetProjection: Projection?,
        byteOrder: ByteOrder,
        to data: inout Data)
    {
        appendUInt32(UInt32(value.coordinates.count), byteOrder: byteOrder, to: &data)
        value.coordinates.forEach({ appendCoordinate($0, targetProjection: targetProjection, byteOrder: byteOrder, to: &data) })
    }

    private static func appendByteOrder(
        byteOrder: ByteOrder,
        to data: inout Data)
    {
        appendBytes(of: byteOrder == .bigEndian ? byteOrder.rawValue.bigEndian : byteOrder.rawValue.littleEndian, to: &data)
    }

    private static func appendTypeCode(
        _ typeCode: Int,
        for coordinate: Coordinate3D? = nil,
        targetProjection: Projection?,
        byteOrder: ByteOrder,
        to data: inout Data)
    {
        var typeCode = UInt32(typeCode)

        if coordinate?.altitude != nil {
            typeCode |= 0x8000_0000
        }

        if coordinate?.m != nil {
            typeCode |= 0x4000_0000
        }

        if targetProjection?.srid != nil {
            typeCode |= 0x2000_0000
        }

        appendUInt32(typeCode, byteOrder: byteOrder, to: &data)

        if let srid = targetProjection?.srid {
            appendUInt32(UInt32(srid), byteOrder: byteOrder, to: &data)
        }
    }

    private static func appendUInt32(
        _ value: UInt32,
        byteOrder: ByteOrder,
        to data: inout Data)
    {
        appendBytes(of: byteOrder == .bigEndian ? value.bigEndian : value.littleEndian, to: &data)
    }

    private static func appendDouble(
        _ value: Double,
        byteOrder: ByteOrder,
        to data: inout Data)
    {
        appendBytes(of: byteOrder == .bigEndian ? value.bitPattern.bigEndian : value.bitPattern.littleEndian, to: &data)
    }

    private static func appendBytes(
        of value: some Any,
        to data: inout Data)
    {
        var value = value
        withUnsafeBytes(of: &value) {
            data += $0
        }
    }

}
