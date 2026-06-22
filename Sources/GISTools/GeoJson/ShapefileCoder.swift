#if EnableShapefileSupport
#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: - FeatureCollection convenience extensions

extension FeatureCollection {

    /// Initialize a ``FeatureCollection`` by reading a Shapefile from the given base URL.
    ///
    /// Loads `<url>.shp` (required), `<url>.dbf` (required),
    /// and optionally `<url>.prj` for projection.
    ///
    /// - Parameter url: The base URL (may include `.shp` extension)
    /// - Parameter calculateBoundingBox: Whether to calculate a bounding box (default `false`)
    public init?(
        shapefile url: URL,
        calculateBoundingBox: Bool = false
    ) {
        guard let collection = try? ShapefileCoder.read(from: url, calculateBoundingBox: calculateBoundingBox) else { return nil }
        self = collection
    }

    /// Write the receiver as a Shapefile to the given base URL.
    ///
    /// Writes `<url>.shp`, `<url>.dbf`, and `<url>.prj`.
    ///
    /// - Parameter url: The base output URL (without extension)
    public func writeShapefile(to url: URL) throws {
        try ShapefileCoder.write(self, to: url)
    }

}

// MARK: - ShapefileCoder

/// The canonical "no data" value for measure (M) coordinates in Shapefiles (-1e38).
private let shapefileNoData: Double = -1_000_000_000_000_000_000_000_000_000_000_000_000_000.0

/// Reads and writes ESRI Shapefiles (.shp / .dbf / .prj).
///
/// This implementation reads and writes the full multi-file Shapefile format:
/// - ``.shp`` — geometry (big-endian binary)
/// - ``.dbf`` — attributes (dBase III, little-endian)
/// - ``.prj`` — projection (WKT, optional)
///
/// Geometry types are mapped between Shapefile and GeoJSON as follows:
///
/// | Shape type               | GeoJSON type                      |
/// |--------------------------|-----------------------------------|
/// | Point \| PointZ \| PointM | ``Point``                         |
/// | PolyLine \| Z \| M       | ``LineString`` \| ``MultiLineString`` |
/// | Polygon \| Z \| M        | ``Polygon`` \| ``MultiPolygon``   |
/// | MultiPoint \| Z \| M     | ``MultiPoint``                    |
/// | MultiPatch               | ``GeometryCollection``            |
public enum ShapefileCoder {

    public enum ShapefileCoderError: Error {
        case invalidFileCode
        case unsupportedShapeType(Int)
        case corruptedRecord
        case invalidDbfHeader(String)
        case unsupportedDbfFieldType(Character)
        case ioError(String)
    }

}

// MARK: - Shape types

extension ShapefileCoder {

    private enum ShapeType: Int {
        case nullShape     = 0
        case point         = 1
        case polyLine      = 3
        case polygon       = 5
        case multiPoint    = 8
        case pointZ        = 11
        case polyLineZ     = 13
        case polygonZ      = 15
        case multiPointZ   = 18
        case pointM        = 21
        case polyLineM     = 23
        case polygonM      = 25
        case multiPointM   = 28
        case multiPatch    = 31

        var hasZ: Bool {
            switch self {
            case .pointZ, .polyLineZ, .polygonZ, .multiPointZ, .multiPatch: true
            default: false
            }
        }

        var hasM: Bool {
            switch self {
            case .pointM, .polyLineM, .polygonM, .multiPointM: true
            case .pointZ, .polyLineZ, .polygonZ, .multiPointZ, .multiPatch: true
            default: false
            }
        }
    }

    private enum MultiPatchPartType: Int {
        case triangleStrip = 0
        case triangleFan   = 1
        case outerRing     = 2
        case innerRing     = 3
        case firstRing     = 4
        case ring          = 5
    }

}

// MARK: - Binary I/O helpers

extension Data {

    fileprivate mutating func appendBigEndian(_ value: Int32) {
        Swift.withUnsafeBytes(of: value.bigEndian) { append(contentsOf: $0) }
    }

    fileprivate mutating func appendBigEndian(_ value: Double) {
        let bits = value.bitPattern.bigEndian
        Swift.withUnsafeBytes(of: bits) { append(contentsOf: $0) }
    }

    fileprivate mutating func appendLittleEndian(_ value: Int32) {
        Swift.withUnsafeBytes(of: value) { append(contentsOf: $0) }
    }

    fileprivate mutating func appendLittleEndian(_ value: Int16) {
        Swift.withUnsafeBytes(of: value) { append(contentsOf: $0) }
    }

    fileprivate mutating func appendLittleEndian(_ value: Double) {
        Swift.withUnsafeBytes(of: value) { append(contentsOf: $0) }
    }

    fileprivate func readBigEndianInt32(at offset: Int) -> Int32 {
        withUnsafeBytes { Int32(bigEndian: $0.loadUnaligned(fromByteOffset: offset, as: Int32.self)) }
    }

    fileprivate func readLittleEndianInt32(at offset: Int) -> Int32 {
        withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: Int32.self) }
    }

    fileprivate func readLittleEndianInt16(at offset: Int) -> Int16 {
        withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: Int16.self) }
    }

    fileprivate func readBigEndianDouble(at offset: Int) -> Double {
        withUnsafeBytes {
            Double(bitPattern: UInt64(bigEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt64.self)))
        }
    }

    fileprivate func readLittleEndianDouble(at offset: Int) -> Double {
        withUnsafeBytes {
            $0.loadUnaligned(fromByteOffset: offset, as: Double.self)
        }
    }

}

// MARK: - DBF field types

extension ShapefileCoder {

    private enum DbfFieldType: Character {
        case character  = "C"
        case numeric    = "N"
        case logical    = "L"
        case date       = "D"
        case float      = "F"
        case memo       = "M"
    }

    private struct DbfFieldDescriptor {
        let name: String
        let type: DbfFieldType
        let length: UInt8
        let decimalCount: UInt8
    }

}

// MARK: - Reading

extension ShapefileCoder {

    /// Read a Shapefile from a base URL. Loads `<url>.shp` (required), `<url>.dbf` (required),
    /// and optionally `<url>.prj` for projection.
    ///
    /// - Parameter url: The base URL (without extension) or the full path to the `.shp` file
    /// - Parameter calculateBoundingBox: Whether to calculate a bounding box (default `false`)
    /// - Returns: A ``FeatureCollection`` with one ``Feature`` per record
    public static func read(
        from url: URL,
        calculateBoundingBox: Bool = false
    ) throws -> FeatureCollection {
        let shpURL = url.pathExtension == "shp" ? url : url.appendingPathExtension("shp")
        let dbfURL = url.pathExtension == "shp"
            ? url.deletingPathExtension().appendingPathExtension("dbf")
            : url.appendingPathExtension("dbf")
        let prjURL = url.pathExtension == "shp"
            ? url.deletingPathExtension().appendingPathExtension("prj")
            : url.appendingPathExtension("prj")

        let shpData = try Data(contentsOf: shpURL)
        let dbfData = try Data(contentsOf: dbfURL)
        guard !dbfData.isEmpty else { return FeatureCollection() }

        let prjString = (try? Data(contentsOf: prjURL)).flatMap { String(data: $0, encoding: .utf8) }
        let projection = prjString.flatMap(Projection.init(wkt:)) ?? .epsg4326

        let geometries = try readShp(shpData, projection: projection)
        let properties = try readDbf(dbfData)

        let count = min(geometries.count, properties.count)
        var features: [Feature] = []
        features.reserveCapacity(count)

        for i in 0..<count {
            if let geometry = geometries[i] {
                var feature = Feature(geometry, calculateBoundingBox: calculateBoundingBox)
                feature.properties = properties[i]
                features.append(feature)
            }
        }

        var fc = FeatureCollection(features)
        if calculateBoundingBox {
            fc.boundingBox = fc.calculateBoundingBox()
        }
        return fc
    }

    // MARK: - .shp reading

    private static func readShp(
        _ data: Data,
        projection: Projection
    ) throws -> [GeoJsonGeometry?] {
        guard data.count >= 100 else { throw ShapefileCoderError.corruptedRecord }
        guard data.readBigEndianInt32(at: 0) == 9994 else {
            throw ShapefileCoderError.invalidFileCode
        }

        let fileLength = Int(data.readBigEndianInt32(at: 24)) * 2
        // File code (0-3) and file length (24-27) are big-endian.
        // Shape type (32-35) and all other header fields are little-endian.
        let shapeType = Int(data.readLittleEndianInt32(at: 32))

        guard fileLength <= data.count else { throw ShapefileCoderError.corruptedRecord }

        var geometries: [GeoJsonGeometry?] = []
        var offset = 100

        while offset + 8 <= fileLength {
            _ = data.readBigEndianInt32(at: offset)
            let contentLength = Int(data.readBigEndianInt32(at: offset + 4)) * 2
            offset += 8

            guard offset + contentLength <= fileLength else { break }

            if contentLength < 4 { continue }

            // Record content uses little-endian (shapefile quirk: header=BE, content=LE)
            let recordType = Int(data.readLittleEndianInt32(at: offset))

            // Skip null shapes
            if recordType == 0 {
                geometries.append(nil)
                offset += contentLength
                continue
            }

            guard recordType == shapeType else {
                offset += contentLength
                continue
            }

            let geometry = try readShape(data: data, offset: offset, shapeType: shapeType)
            let projected = geometry?.projected(to: projection)
            geometries.append(projected)
            offset += contentLength
        }

        return geometries
    }

    private static func readShape(
        data: Data,
        offset: Int,
        shapeType: Int
    ) throws -> GeoJsonGeometry? {
        guard let type = ShapeType(rawValue: shapeType) else {
            throw ShapefileCoderError.unsupportedShapeType(shapeType)
        }

        switch type {
        case .nullShape:
            return nil
        case .point:
            return readPoint(data: data, offset: offset)
        case .pointZ:
            return readPointZ(data: data, offset: offset)
        case .pointM:
            return readPointM(data: data, offset: offset)
        case .polyLine, .polyLineZ, .polyLineM:
            return try readPolyLine(data: data, offset: offset, type: type)
        case .polygon, .polygonZ, .polygonM:
            return try readPolygon(data: data, offset: offset, type: type)
        case .multiPoint, .multiPointZ, .multiPointM:
            return try readMultiPoint(data: data, offset: offset, type: type)
        case .multiPatch:
            return try readMultiPatch(data: data, offset: offset)
        }
    }

    // MARK: - Point readers

    private static func readPoint(data: Data, offset: Int) -> Point {
        let x = data.readLittleEndianDouble(at: offset + 4)
        let y = data.readLittleEndianDouble(at: offset + 12)
        return Point(Coordinate3D(latitude: y, longitude: x))
    }

    private static func readPointZ(data: Data, offset: Int) -> Point {
        let x = data.readLittleEndianDouble(at: offset + 4)
        let y = data.readLittleEndianDouble(at: offset + 12)
        let z = data.readLittleEndianDouble(at: offset + 20)
        let m = data.readLittleEndianDouble(at: offset + 28)
        let altitude = z.isFinite ? z : nil
        let mValue = (m.isFinite && abs(m) < abs(shapefileNoData)) ? m : nil
        return Point(Coordinate3D(latitude: y, longitude: x, altitude: altitude, m: mValue))
    }

    private static func readPointM(data: Data, offset: Int) -> Point {
        let x = data.readLittleEndianDouble(at: offset + 4)
        let y = data.readLittleEndianDouble(at: offset + 12)
        let m = data.readLittleEndianDouble(at: offset + 20)
        let mValue = (m.isFinite && abs(m) < abs(shapefileNoData)) ? m : nil
        return Point(Coordinate3D(latitude: y, longitude: x, m: mValue))
    }

    // MARK: - PolyLine reader

    private static func readPolyLine(
        data: Data,
        offset: Int,
        type: ShapeType
    ) throws -> GeoJsonGeometry {
        let numParts = Int(data.readLittleEndianInt32(at: offset + 36))
        let numPoints = Int(data.readLittleEndianInt32(at: offset + 40))

        guard numParts > 0, numPoints > 0 else {
            return MultiLineString([] as [LineString])!
        }

        var partStarts: [Int] = []
        partStarts.reserveCapacity(numParts)
        for i in 0..<numParts {
            partStarts.append(Int(data.readLittleEndianInt32(at: offset + 44 + i * 4)))
        }

        let pointsOffset = offset + 44 + numParts * 4
        let zOffset = pointsOffset + numPoints * 16
        let mOffset: Int

        if type.hasZ {
            mOffset = zOffset + 16 + numPoints * 8
        }
        else if type.hasM {
            mOffset = zOffset
        }
        else {
            mOffset = 0
        }

        let zAvailable = type.hasZ
        let mAvailable = type.hasZ || type.hasM

        let coordinates = readCoordinates(
            data: data,
            numPoints: numPoints,
            pointsOffset: pointsOffset,
            zOffset: zOffset,
            mOffset: mOffset,
            zAvailable: zAvailable,
            mAvailable: mAvailable)

        var lineStrings: [LineString] = []
        lineStrings.reserveCapacity(numParts)

        for i in 0..<numParts {
            let start = partStarts[i]
            let end = (i + 1 < numParts) ? partStarts[i + 1] : numPoints
            let partCoords = Array(coordinates[start..<end])
            if let line = LineString(partCoords) {
                lineStrings.append(line)
            }
        }

        if lineStrings.count == 1 {
            return lineStrings[0]
        }
        else {
            return MultiLineString(lineStrings as [LineString])!
        }
    }

    // MARK: - Polygon reader

    private static func readPolygon(
        data: Data,
        offset: Int,
        type: ShapeType
    ) throws -> GeoJsonGeometry {
        let numParts = Int(data.readLittleEndianInt32(at: offset + 36))
        let numPoints = Int(data.readLittleEndianInt32(at: offset + 40))

        guard numParts > 0, numPoints > 0 else {
            return MultiPolygon([] as [Polygon])!
        }

        var partStarts: [Int] = []
        partStarts.reserveCapacity(numParts)
        for i in 0..<numParts {
            partStarts.append(Int(data.readLittleEndianInt32(at: offset + 44 + i * 4)))
        }

        let pointsOffset = offset + 44 + numParts * 4
        let zOffset = pointsOffset + numPoints * 16
        let mOffset: Int

        if type.hasZ {
            mOffset = zOffset + 16 + numPoints * 8
        }
        else if type.hasM {
            mOffset = zOffset
        }
        else {
            mOffset = 0
        }

        let zAvailable = type.hasZ
        let mAvailable = type.hasZ || type.hasM

        let coordinates = readCoordinates(
            data: data,
            numPoints: numPoints,
            pointsOffset: pointsOffset,
            zOffset: zOffset,
            mOffset: mOffset,
            zAvailable: zAvailable,
            mAvailable: mAvailable)

        // Group parts into polygons: an outer ring (CW) followed by its holes (CCW)
        let rings: [Ring] = partStarts.enumerated().compactMap { i, start in
            let end = (i + 1 < numParts) ? partStarts[i + 1] : numPoints
            let partCoords = Array(coordinates[start..<end])
            return Ring(partCoords)
        }

        // In shapefile, outer rings are CW, inner rings are CCW
        var polygons: [Polygon] = []
        var currentOuter: Ring?
        var currentHoles: [Ring] = []

        for ring in rings {
            if ShapefileCoder.isClockwise(ring) {
                // CW → outer ring in shapefile convention
                if let outer = currentOuter {
                    if let polygon = Polygon([outer] + currentHoles) {
                        polygons.append(polygon)
                    }
                }
                currentOuter = ring
                currentHoles = []
            }
            else {
                currentHoles.append(ring)
            }
        }

        if let outer = currentOuter {
            if let polygon = Polygon([outer] + currentHoles) {
                polygons.append(polygon)
            }
        }

        if polygons.count == 1 {
            return polygons[0]
        }
        else {
            return MultiPolygon(polygons as [Polygon])!
        }
    }

    // MARK: - MultiPoint reader

    private static func readMultiPoint(
        data: Data,
        offset: Int,
        type: ShapeType
    ) throws -> MultiPoint {
        let numPoints = Int(data.readLittleEndianInt32(at: offset + 36))
        guard numPoints > 0 else { return MultiPoint([] as [Coordinate3D])! }

        let pointsOffset = offset + 40
        let zOffset = pointsOffset + numPoints * 16
        let mOffset: Int

        if type.hasZ {
            mOffset = zOffset + 16 + numPoints * 8
        }
        else if type.hasM {
            mOffset = zOffset
        }
        else {
            mOffset = 0
        }

        let coordinates = readCoordinates(
            data: data,
            numPoints: numPoints,
            pointsOffset: pointsOffset,
            zOffset: zOffset,
            mOffset: mOffset,
            zAvailable: type.hasZ,
            mAvailable: type.hasZ || type.hasM)

        return MultiPoint(coordinates as [Coordinate3D])!
    }

    // MARK: - MultiPatch reader

    private static func readMultiPatch(
        data: Data,
        offset: Int
    ) throws -> GeometryCollection {
        let numParts = Int(data.readLittleEndianInt32(at: offset + 36))
        let numPoints = Int(data.readLittleEndianInt32(at: offset + 40))

        guard numParts > 0, numPoints > 0 else { return GeometryCollection([]) }

        var partStarts: [Int] = []
        partStarts.reserveCapacity(numParts)
        for i in 0..<numParts {
            partStarts.append(Int(data.readLittleEndianInt32(at: offset + 44 + i * 4)))
        }

        let partTypesOffset = offset + 44 + numParts * 4
        var partTypes: [MultiPatchPartType] = []
        partTypes.reserveCapacity(numParts)
        for i in 0..<numParts {
            let raw = Int(data.readLittleEndianInt32(at: partTypesOffset + i * 4))
            partTypes.append(MultiPatchPartType(rawValue: raw) ?? .ring)
        }

        let pointsOffset = partTypesOffset + numParts * 4
        let zOffset = pointsOffset + numPoints * 16
        let mOffset = zOffset + 16 + numPoints * 8

        let coordinates = readCoordinates(
            data: data,
            numPoints: numPoints,
            pointsOffset: pointsOffset,
            zOffset: zOffset,
            mOffset: mOffset,
            zAvailable: true,
            mAvailable: true)

        var geometries: [GeoJsonGeometry] = []
        var currentRing: [Coordinate3D]?
        var currentHoles: [[Coordinate3D]] = []

        for i in 0..<numParts {
            let start = partStarts[i]
            let end = (i + 1 < numParts) ? partStarts[i + 1] : numPoints
            let partCoords = Array(coordinates[start..<end])
            let partType = partTypes[i]

            switch partType {
            case .outerRing, .firstRing, .ring:
                if let existing = currentRing {
                    if let polygon = Polygon([existing] + currentHoles) {
                        geometries.append(polygon)
                    }
                }
                currentRing = partCoords
                currentHoles = []

            case .innerRing:
                currentHoles.append(partCoords)

            case .triangleStrip, .triangleFan:
                if let existing = currentRing {
                    if let polygon = Polygon([existing] + currentHoles) {
                        geometries.append(polygon)
                    }
                    currentRing = nil
                    currentHoles = []
                }
                // Decompose triangle strip/fan into individual triangle polygons
                let triangles = decomposeTriangleMesh(partCoords, type: partType)
                geometries.append(contentsOf: triangles)
            }
        }

        if let ring = currentRing {
            if let polygon = Polygon([ring] + currentHoles) {
                geometries.append(polygon)
            }
        }

        return GeometryCollection(geometries)
    }

    private static func decomposeTriangleMesh(
        _ coords: [Coordinate3D],
        type: MultiPatchPartType
    ) -> [Polygon] {
        guard coords.count >= 3 else { return [] }

        var polygons: [Polygon] = []

        switch type {
        case .triangleStrip:
            // Every 3 consecutive vertices form a triangle: [0,1,2], [1,2,3], [2,3,4], ...
            for i in 0..<(coords.count - 2) {
                let tri: [Coordinate3D]
                if i % 2 == 0 {
                    tri = [coords[i], coords[i + 1], coords[i + 2], coords[i]]
                }
                else {
                    tri = [coords[i + 1], coords[i], coords[i + 2], coords[i + 1]]
                }
                if let polygon = Polygon([tri]) {
                    polygons.append(polygon)
                }
            }

        case .triangleFan:
            // All triangles share vertex 0: [0,1,2], [0,2,3], [0,3,4], ...
            for i in 1..<(coords.count - 1) {
                let tri = [coords[0], coords[i], coords[i + 1], coords[0]]
                if let polygon = Polygon([tri]) {
                    polygons.append(polygon)
                }
            }

        default:
            break
        }

        return polygons
    }

    // MARK: - Coordinate reader

    private static func readCoordinates(
        data: Data,
        numPoints: Int,
        pointsOffset: Int,
        zOffset: Int,
        mOffset: Int,
        zAvailable: Bool,
        mAvailable: Bool
    ) -> [Coordinate3D] {
        var coordinates: [Coordinate3D] = []
        coordinates.reserveCapacity(numPoints)

        for i in 0..<numPoints {
            let x = data.readLittleEndianDouble(at: pointsOffset + i * 16)
            let y = data.readLittleEndianDouble(at: pointsOffset + i * 16 + 8)

            let altitude: CLLocationDistance?
            if zAvailable {
                let z = data.readLittleEndianDouble(at: zOffset + 8 + i * 8)
                altitude = z.isFinite ? z : nil
            }
            else {
                altitude = nil
            }

            let m: Double?
            if mAvailable {
                let rawM = data.readLittleEndianDouble(at: mOffset + 8 + i * 8)
                m = (rawM.isFinite && abs(rawM) < abs(shapefileNoData)) ? rawM : nil
            }
            else {
                m = nil
            }

            coordinates.append(Coordinate3D(latitude: y, longitude: x, altitude: altitude, m: m))
        }

        return coordinates
    }

}

// MARK: - DBF reading

extension ShapefileCoder {

    private static func readDbf(_ data: Data) throws -> [[String: Sendable]] {
        guard data.count >= 32 else { throw ShapefileCoderError.invalidDbfHeader("File too small") }

        let recordCount = Int(data.readLittleEndianInt32(at: 4))
        let headerLength = Int(data.readLittleEndianInt16(at: 8))
        let recordLength = Int(data.readLittleEndianInt16(at: 10))

        guard recordCount > 0 else { return [] }
        guard headerLength >= 33 else { throw ShapefileCoderError.invalidDbfHeader("Header too small") }
        guard headerLength + recordCount * recordLength <= data.count
        else { throw ShapefileCoderError.invalidDbfHeader("Truncated data") }

        let fieldCount = (headerLength - 32 - 1) / 32
        var fields: [DbfFieldDescriptor] = []
        fields.reserveCapacity(fieldCount)

        for i in 0..<fieldCount {
            let fo = 32 + i * 32
            let nameData = data[fo..<fo + 11]
            let name = nameData.prefix(while: { $0 != 0 }).reduce(into: "") { $0 += String(UnicodeScalar($1)) }

            guard let typeChar = UnicodeScalar(Int(data[fo + 11])),
                  let fieldType = DbfFieldType(rawValue: Character(typeChar))
            else {
                throw ShapefileCoderError.unsupportedDbfFieldType(Character(UnicodeScalar(data[fo + 11])))
            }

            let length = data[fo + 16]
            let decimalCount = data[fo + 17]

            fields.append(DbfFieldDescriptor(name: name, type: fieldType, length: length, decimalCount: decimalCount))
        }

        var records: [[String: Sendable]] = []
        records.reserveCapacity(recordCount)

        let dataStart = headerLength

        for r in 0..<recordCount {
            let recordOffset = dataStart + r * recordLength
            guard recordOffset + recordLength <= data.count else { break }

            let deleteFlag = data[recordOffset]
            guard deleteFlag != 0x2A else { continue } // deleted record

            var properties: [String: Sendable] = [:]
            var fieldOffset = 1 // skip delete flag

            for field in fields {
                let endOffset = fieldOffset + Int(field.length)
                guard endOffset <= recordLength else { break }

                let raw = data[recordOffset + fieldOffset..<recordOffset + endOffset]
                let value = parseDbfValue(raw, field: field)
                if value != nil {
                    properties[field.name] = value
                }
                fieldOffset = endOffset
            }

            records.append(properties)
        }

        return records
    }

    private static func parseDbfValue(
        _ raw: Data.SubSequence,
        field: DbfFieldDescriptor
    ) -> Sendable? {
        let trimmed = raw.reduce(into: "") { result, byte in
            guard byte != 0 else { return }
            result += String(UnicodeScalar(byte))
        }

        switch field.type {
        case .character:
            let cleaned = trimmed.trimmingCharacters(in: .whitespaces)
            return cleaned.isEmpty ? nil : cleaned

        case .numeric, .float:
            let cleaned = trimmed.trimmingCharacters(in: .whitespaces)
            guard !cleaned.isEmpty else { return nil }
            if field.decimalCount > 0 {
                return Double(cleaned)
            }
            else {
                return Int(cleaned)
            }

        case .logical:
            let upper = trimmed.trimmingCharacters(in: .whitespaces).uppercased()
            if upper == "Y" || upper == "T" { return true }
            if upper == "N" || upper == "F" { return false }
            return nil

        case .date:
            let cleaned = trimmed.trimmingCharacters(in: .whitespaces)
            return cleaned.isEmpty ? nil : cleaned

        case .memo:
            let cleaned = trimmed.trimmingCharacters(in: .whitespaces)
            return cleaned.isEmpty ? nil : cleaned
        }
    }

}

// MARK: - Writing

extension ShapefileCoder {

    /// Write a ``FeatureCollection`` to a Shapefile at the given base URL.
    /// Writes `<url>.shp`, `<url>.dbf`, and `<url>.prj`.
    ///
    /// - Parameters:
    ///   - featureCollection: The features to write
    ///   - url: The base output URL (without extension)
    ///   - encoding: The string encoding for the .dbf and .prj files
    public static func write(
        _ featureCollection: FeatureCollection,
        to url: URL,
        encoding: String.Encoding = .utf8
    ) throws {
        let baseURL: URL
        let shpURL: URL
        if url.pathExtension == "shp" {
            baseURL = url.deletingPathExtension()
            shpURL = url
        } else {
            baseURL = url
            shpURL = url.appendingPathExtension("shp")
        }
        let dbfURL = baseURL.appendingPathExtension("dbf")
        let shxURL = baseURL.appendingPathExtension("shx")
        let prjURL = baseURL.appendingPathExtension("prj")

        let features = featureCollection.features
        let projection = featureCollection.projection

        let (shpData, shxData) = try writeShp(features)
        let dbfData = writeDbf(features)
        let prjString = writePrj(projection)

        try shpData.write(to: shpURL, options: .atomic)
        try shxData.write(to: shxURL, options: .atomic)
        try dbfData.write(to: dbfURL, options: .atomic)

        if let prjString {
            try prjString.write(to: prjURL, atomically: true, encoding: encoding)
        }
    }

    // MARK: - .shp / .shx writing

    private static func writeShp(_ features: [Feature]) throws -> (shp: Data, shx: Data) {
        var recordsData = Data()
        var shxRecords = Data()

        var recordNumber: Int32 = 1
        var boundingBoxes: [BoundingBox] = []

        // .shp records start after the 100-byte header
        var recordOffsetInWords: Int32 = 100 / 2 // 50

        for feature in features {
            let shapeData = try writeShape(feature.geometry)
            let contentLength = Int32((shapeData.count + 1) / 2) // in 16-bit words, rounded up

            var recordHeader = Data()
            recordHeader.appendBigEndian(recordNumber)
            recordHeader.appendBigEndian(contentLength)
            recordsData.append(recordHeader)
            recordsData.append(shapeData)

            // .shx entry: offset to record + content length (both in 16-bit words, BE)
            var shxEntry = Data()
            shxEntry.appendBigEndian(recordOffsetInWords)
            shxEntry.appendBigEndian(contentLength)
            shxRecords.append(shxEntry)

            recordOffsetInWords += 4 + contentLength // 4 words = 8-byte record header

            if let box = feature.geometry.boundingBox?.projected(to: .epsg4326) {
                boundingBoxes.append(box)
            }

            recordNumber += 1
        }

        let shapeType = determineShapeType(features)
        let shpHeader = writeHeader(shapeType: shapeType, boundingBoxes: boundingBoxes, recordsData: recordsData)
        let shxData = writeShxHeader(shapeType: shapeType, boundingBoxes: boundingBoxes, shxRecords: shxRecords)
        return (shpHeader + recordsData, shxData + shxRecords)
    }

    private static func writeShxHeader(
        shapeType: ShapeType,
        boundingBoxes: [BoundingBox],
        shxRecords: Data
    ) -> Data {
        let fileLength = Int32((100 + shxRecords.count + 1) / 2)
        var minX = Double.infinity, minY = Double.infinity
        var maxX = -Double.infinity, maxY = -Double.infinity
        for box in boundingBoxes {
            minX = min(minX, box.southWest.longitude)
            minY = min(minY, box.southWest.latitude)
            maxX = max(maxX, box.northEast.longitude)
            maxY = max(maxY, box.northEast.latitude)
        }
        if minX == .infinity { minX = 0; maxX = 0; minY = 0; maxY = 0 }

        var header = Data()
        header.appendBigEndian(Int32(9994))
        header.append(Data(count: 20))
        header.appendBigEndian(fileLength)
        header.appendLittleEndian(Int32(1000))
        header.appendLittleEndian(Int32(shapeType.rawValue))
        header.appendLittleEndian(minX); header.appendLittleEndian(minY)
        header.appendLittleEndian(maxX); header.appendLittleEndian(maxY)
        header.appendLittleEndian(Double(0)); header.appendLittleEndian(Double(0)) // Z range unused
        header.appendLittleEndian(Double(0)); header.appendLittleEndian(Double(0)) // M range unused
        return header
    }

    private static func writeHeader(
        shapeType: ShapeType,
        boundingBoxes: [BoundingBox],
        recordsData: Data
    ) -> Data {
        let fileLength = Int32((100 + recordsData.count + 1) / 2) // in 16-bit words

        var minX = Double.infinity
        var minY = Double.infinity
        var maxX = -Double.infinity
        var maxY = -Double.infinity
        var minZ = Double.infinity
        var maxZ = -Double.infinity
        var minM = Double.infinity
        var maxM = -Double.infinity

        for box in boundingBoxes {
            minX = min(minX, box.southWest.longitude)
            minY = min(minY, box.southWest.latitude)
            maxX = max(maxX, box.northEast.longitude)
            maxY = max(maxY, box.northEast.latitude)
        }

        if minX == .infinity {
            minX = 0; maxX = 0; minY = 0; maxY = 0
        }
        if minZ == .infinity { minZ = 0; maxZ = 0 }
        if minM == .infinity { minM = 0; maxM = 0 }

        var header = Data()
        header.appendBigEndian(Int32(9994)) // file code (BE)
        header.append(Data(count: 20)) // unused
        header.appendBigEndian(fileLength) // file length (BE)
        header.appendLittleEndian(Int32(1000)) // version (LE)
        header.appendLittleEndian(Int32(shapeType.rawValue)) // shape type (LE)
        header.appendLittleEndian(minX) // bbox and ranges are LE
        header.appendLittleEndian(minY)
        header.appendLittleEndian(maxX)
        header.appendLittleEndian(maxY)
        header.appendLittleEndian(minZ)
        header.appendLittleEndian(maxZ)
        header.appendLittleEndian(minM)
        header.appendLittleEndian(maxM)

        return header
    }

    private static func determineShapeType(_ features: [Feature]) -> ShapeType {
        guard let first = features.first?.geometry else {
            return .nullShape
        }

        let type = shapeTypeForGeometry(first)

        let hasZ = features.contains { feature in
            feature.geometry.allCoordinates.contains { $0.altitude != nil }
        }

        let hasM = features.contains { feature in
            feature.geometry.allCoordinates.contains { $0.m != nil }
        }

        if hasZ { return ShapefileCoder.withZ(type) }
        if hasM { return ShapefileCoder.withM(type) }
        return type
    }

    private static func shapeTypeForGeometry(_ geometry: GeoJsonGeometry) -> ShapeType {
        switch geometry {
        case is Point:
            return .point
        case is MultiPoint:
            return .multiPoint
        case is LineString, is MultiLineString:
            return .polyLine
        case is Polygon, is MultiPolygon:
            return .polygon
        case is GeometryCollection:
            return .multiPatch
        default:
            return .nullShape
        }
    }

    private static func writeShape(_ geometry: GeoJsonGeometry) throws -> Data {
        switch geometry {
        case let point as Point:
            return writePointShape(point)
        case let multiPoint as MultiPoint:
            return writeMultiPointShape(multiPoint)
        case let lineString as LineString:
            return writePolyLineShape([lineString.coordinates])
        case let multiLineString as MultiLineString:
            return writePolyLineShape(multiLineString.lineStrings.map(\.coordinates))
        case let polygon as Polygon:
            return writePolygonShape([polygon.rings])
        case let multiPolygon as MultiPolygon:
            return writePolygonShape(multiPolygon.polygons.map(\.rings))
        case let geometryCollection as GeometryCollection:
            return try writeMultiPatchShape(geometryCollection)
        default:
            throw ShapefileCoderError.unsupportedShapeType(0)
        }
    }

    // MARK: - Point writer

    private static func writePointShape(_ point: Point) -> Data {
        let coord = point.coordinate
        let projected = coord.projected(to: .epsg4326)

        let shapeType: ShapeType
        let hasZ = coord.altitude != nil
        let hasM = coord.m != nil

        if hasZ { shapeType = .pointZ }
        else if hasM { shapeType = .pointM }
        else { shapeType = .point }

        var data = Data()
        data.appendLittleEndian(Int32(shapeType.rawValue))
        data.appendLittleEndian(projected.longitude)
        data.appendLittleEndian(projected.latitude)

        if shapeType == .pointZ {
            data.appendLittleEndian(coord.altitude ?? 0.0)
            data.appendLittleEndian(coord.m ?? shapefileNoData)
        }
        else if shapeType == .pointM {
            data.appendLittleEndian(coord.m ?? shapefileNoData)
        }

        return data
    }

    // MARK: - PolyLine writer

    private static func writePolyLineShape(_ parts: [[Coordinate3D]]) -> Data {
        let projectedParts = parts.map { $0.map { $0.projected(to: .epsg4326) } }

        let numParts = Int32(projectedParts.count)
        let numPoints = Int32(projectedParts.reduce(0) { $0 + $1.count })

        let hasZ = projectedParts.contains(where: { $0.contains(where: { $0.altitude != nil }) })
        let hasM = projectedParts.contains(where: { $0.contains(where: { $0.m != nil }) })
        let shapeType: ShapeType = hasZ ? .polyLineZ : (hasM ? .polyLineM : .polyLine)

        var data = Data()
        data.appendLittleEndian(Int32(shapeType.rawValue))

        // Bounding box
        var minX = Double.infinity; var minY = Double.infinity
        var maxX = -Double.infinity; var maxY = -Double.infinity
        for coord in projectedParts.flatMap({ $0 }) {
            minX = min(minX, coord.longitude); minY = min(minY, coord.latitude)
            maxX = max(maxX, coord.longitude); maxY = max(maxY, coord.latitude)
        }
        if minX == .infinity { minX = 0; maxX = 0; minY = 0; maxY = 0 }
        data.appendLittleEndian(minX); data.appendLittleEndian(minY)
        data.appendLittleEndian(maxX); data.appendLittleEndian(maxY)

        data.appendLittleEndian(numParts)
        data.appendLittleEndian(numPoints)

        // Part starts
        var offset = 0
        for part in projectedParts {
            data.appendLittleEndian(Int32(offset))
            offset += part.count
        }

        // Points (X, Y pairs)
        for coord in projectedParts.flatMap({ $0 }) {
            data.appendLittleEndian(coord.longitude)
            data.appendLittleEndian(coord.latitude)
        }

        // Z range + Z array
        let allCoords = projectedParts.flatMap { $0 }
        if shapeType.hasZ {
            let zValues = allCoords.map { $0.altitude ?? 0.0 }
            let minZ = zValues.min() ?? 0.0
            let maxZ = zValues.max() ?? 0.0
            data.appendLittleEndian(minZ)
            data.appendLittleEndian(maxZ)
            for z in zValues {
                data.appendLittleEndian(z)
            }
        }

        // M range + M array
        if shapeType.hasM {
            let mValues = allCoords.map { $0.m ?? shapefileNoData }
            let validMs = mValues.filter { $0.isFinite && abs($0) < abs(shapefileNoData) }
            let minM = validMs.min() ?? shapefileNoData
            let maxM = validMs.max() ?? shapefileNoData
            data.appendLittleEndian(minM)
            data.appendLittleEndian(maxM)
            for m in mValues {
                data.appendLittleEndian(m)
            }
        }

        return data
    }

    // MARK: - Polygon writer

    private static func writePolygonShape(_ polygons: [[Ring]]) -> Data {
        let projectedPolygons = polygons.map { polygon in
            polygon.map { ring in
                Ring(ring.coordinates.map { $0.projected(to: .epsg4326) })!
            }
        }

        // Build parts: each ring is one part
        var parts: [[Coordinate3D]] = []
        var ringIsOuter: [Bool] = []

        for rings in projectedPolygons {
            for (index, ring) in rings.enumerated() {
                var coords = ring.coordinates
                // Close the ring if needed
                if coords.count > 1, coords.first != coords.last {
                    coords.append(coords[0])
                }
                parts.append(coords)
                ringIsOuter.append(index == 0)
            }
        }

        let numParts = Int32(parts.count)
        let numPoints = Int32(parts.reduce(0) { $0 + $1.count })

        let hasZ = parts.contains(where: { $0.contains(where: { $0.altitude != nil }) })
        let hasM = parts.contains(where: { $0.contains(where: { $0.m != nil }) })
        let shapeType: ShapeType = hasZ ? .polygonZ : (hasM ? .polygonM : .polygon)

        var data = Data()
        data.appendLittleEndian(Int32(shapeType.rawValue))

        var minX = Double.infinity; var minY = Double.infinity
        var maxX = -Double.infinity; var maxY = -Double.infinity
        for coord in parts.flatMap({ $0 }) {
            minX = min(minX, coord.longitude); minY = min(minY, coord.latitude)
            maxX = max(maxX, coord.longitude); maxY = max(maxY, coord.latitude)
        }
        if minX == .infinity { minX = 0; maxX = 0; minY = 0; maxY = 0 }
        data.appendLittleEndian(minX); data.appendLittleEndian(minY)
        data.appendLittleEndian(maxX); data.appendLittleEndian(maxY)

        data.appendLittleEndian(numParts)
        data.appendLittleEndian(numPoints)

        var offset = 0
        for part in parts {
            data.appendLittleEndian(Int32(offset))
            offset += part.count
        }

        for coord in parts.flatMap({ $0 }) {
            data.appendLittleEndian(coord.longitude)
            data.appendLittleEndian(coord.latitude)
        }

        let allCoords = parts.flatMap { $0 }
        if shapeType.hasZ {
            let zValues = allCoords.map { $0.altitude ?? 0.0 }
            let minZ = zValues.min() ?? 0.0; let maxZ = zValues.max() ?? 0.0
            data.appendLittleEndian(minZ); data.appendLittleEndian(maxZ)
            for z in zValues { data.appendLittleEndian(z) }
        }

        if shapeType.hasM {
            let mValues = allCoords.map { $0.m ?? shapefileNoData }
            let validMs = mValues.filter { $0.isFinite && abs($0) < abs(shapefileNoData) }
            let minM = validMs.min() ?? shapefileNoData
            let maxM = validMs.max() ?? shapefileNoData
            data.appendLittleEndian(minM); data.appendLittleEndian(maxM)
            for m in mValues { data.appendLittleEndian(m) }
        }

        return data
    }

    // MARK: - MultiPoint writer

    private static func writeMultiPointShape(_ multiPoint: MultiPoint) -> Data {
        let projected = multiPoint.coordinates.map { $0.projected(to: .epsg4326) }
        let numPoints = Int32(projected.count)

        let hasZ = projected.contains(where: { $0.altitude != nil })
        let hasM = projected.contains(where: { $0.m != nil })
        let shapeType: ShapeType = hasZ ? .multiPointZ : (hasM ? .multiPointM : .multiPoint)

        var data = Data()
        data.appendLittleEndian(Int32(shapeType.rawValue))

        var minX = Double.infinity; var minY = Double.infinity
        var maxX = -Double.infinity; var maxY = -Double.infinity
        for coord in projected {
            minX = min(minX, coord.longitude); minY = min(minY, coord.latitude)
            maxX = max(maxX, coord.longitude); maxY = max(maxY, coord.latitude)
        }
        if minX == .infinity { minX = 0; maxX = 0; minY = 0; maxY = 0 }
        data.appendLittleEndian(minX); data.appendLittleEndian(minY)
        data.appendLittleEndian(maxX); data.appendLittleEndian(maxY)

        data.appendLittleEndian(numPoints)

        for coord in projected {
            data.appendLittleEndian(coord.longitude)
            data.appendLittleEndian(coord.latitude)
        }

        if shapeType.hasZ {
            let zValues = projected.map { $0.altitude ?? 0.0 }
            let minZ = zValues.min() ?? 0.0; let maxZ = zValues.max() ?? 0.0
            data.appendLittleEndian(minZ); data.appendLittleEndian(maxZ)
            for z in zValues { data.appendLittleEndian(z) }
        }

        if shapeType.hasM {
            let mValues = projected.map { $0.m ?? shapefileNoData }
            let validMs = mValues.filter { $0.isFinite && abs($0) < abs(shapefileNoData) }
            let minM = validMs.min() ?? shapefileNoData
            let maxM = validMs.max() ?? shapefileNoData
            data.appendLittleEndian(minM); data.appendLittleEndian(maxM)
            for m in mValues { data.appendLittleEndian(m) }
        }

        return data
    }

    // MARK: - MultiPatch writer

    private static func writeMultiPatchShape(_ geometryCollection: GeometryCollection) throws -> Data {
        var parts: [[Coordinate3D]] = []
        var partTypes: [MultiPatchPartType] = []

        for geometry in geometryCollection.geometries {
            switch geometry {
            case let polygon as Polygon:
                for (index, ring) in polygon.rings.enumerated() {
                    var coords = ring.coordinates.map { $0.projected(to: .epsg4326) }
                    if coords.count > 1, coords.first != coords.last {
                        coords.append(coords[0])
                    }
                    parts.append(coords)
                    partTypes.append(index == 0 ? .outerRing : .innerRing)
                }

            case let multiPolygon as MultiPolygon:
                for polygon in multiPolygon.polygons {
                    for (index, ring) in polygon.rings.enumerated() {
                        var coords = ring.coordinates.map { $0.projected(to: .epsg4326) }
                        if coords.count > 1, coords.first != coords.last {
                            coords.append(coords[0])
                        }
                        parts.append(coords)
                        partTypes.append(index == 0 ? .outerRing : .innerRing)
                    }
                }

            case let lineString as LineString:
                let coords = lineString.coordinates.map { $0.projected(to: .epsg4326) }
                parts.append(coords)
                partTypes.append(.ring)

            default:
                break
            }
        }

        let numParts = Int32(parts.count)
        let numPoints = Int32(parts.reduce(0) { $0 + $1.count })
        let shapeType: ShapeType = .multiPatch

        var data = Data()
        data.appendLittleEndian(Int32(shapeType.rawValue))

        var minX = Double.infinity; var minY = Double.infinity
        var maxX = -Double.infinity; var maxY = -Double.infinity
        for coord in parts.flatMap({ $0 }) {
            minX = min(minX, coord.longitude); minY = min(minY, coord.latitude)
            maxX = max(maxX, coord.longitude); maxY = max(maxY, coord.latitude)
        }
        if minX == .infinity { minX = 0; maxX = 0; minY = 0; maxY = 0 }
        data.appendLittleEndian(minX); data.appendLittleEndian(minY)
        data.appendLittleEndian(maxX); data.appendLittleEndian(maxY)

        data.appendLittleEndian(numParts)
        data.appendLittleEndian(numPoints)

        var offset = 0
        for part in parts {
            data.appendLittleEndian(Int32(offset))
            offset += part.count
        }

        // Part types
        for pt in partTypes {
            data.appendLittleEndian(Int32(pt.rawValue))
        }

        // Points
        for coord in parts.flatMap({ $0 }) {
            data.appendLittleEndian(coord.longitude)
            data.appendLittleEndian(coord.latitude)
        }

        let allCoords = parts.flatMap { $0 }
        let zValues = allCoords.map { $0.altitude ?? 0.0 }
        let minZ = zValues.min() ?? 0.0; let maxZ = zValues.max() ?? 0.0
        data.appendLittleEndian(minZ); data.appendLittleEndian(maxZ)
        for z in zValues { data.appendLittleEndian(z) }

        let mValues = allCoords.map { $0.m ?? shapefileNoData }
        let validMs = mValues.filter { $0.isFinite && abs($0) < abs(shapefileNoData) }
        let minM = validMs.min() ?? shapefileNoData
        let maxM = validMs.max() ?? shapefileNoData
        data.appendLittleEndian(minM); data.appendLittleEndian(maxM)
        for m in mValues { data.appendLittleEndian(m) }

        return data
    }

    /// Returns `true` if the ring is oriented clockwise (signed area < 0 in lat/lon plane).
    private static func isClockwise(_ ring: Ring) -> Bool {
        let coords = ring.coordinates
        guard coords.count >= 3 else { return false }
        var area: Double = 0.0
        for i in 0..<coords.count {
            let j = (i + 1) % coords.count
            area += coords[i].longitude * coords[j].latitude
            area -= coords[j].longitude * coords[i].latitude
        }
        return area < 0.0
    }

}

// MARK: - DBF writing

extension ShapefileCoder {

    private static func withZ(_ type: ShapeType) -> ShapeType {
        switch type {
        case .point:      return .pointZ
        case .polyLine:   return .polyLineZ
        case .polygon:    return .polygonZ
        case .multiPoint: return .multiPointZ
        default:          return type
        }
    }

    private static func withM(_ type: ShapeType) -> ShapeType {
        switch type {
        case .point:      return .pointM
        case .polyLine:   return .polyLineM
        case .polygon:    return .polygonM
        case .multiPoint: return .multiPointM
        default:          return type
        }
    }

}

// MARK: - DBF writing

extension ShapefileCoder {

    private static func writeDbf(_ features: [Feature]) -> Data {
        guard !features.isEmpty else { return Data() }

        let fields = buildFieldDescriptors(features: features)
        let recordLength = Int16(fields.reduce(1) { $0 + Int($1.length) })

        // Header
        var header = Data()
        header.append(0x03) // version (no memo)
        header.append(UInt8(Calendar.current.component(.year, from: Date()) % 100))
        header.append(UInt8(Calendar.current.component(.month, from: Date())))
        header.append(UInt8(Calendar.current.component(.day, from: Date())))
        header.appendLittleEndian(Int32(features.count))
        header.appendLittleEndian(Int16(32 + Int16(fields.count) * 32 + 1)) // header length
        header.appendLittleEndian(recordLength)
        header.append(Data(count: 20)) // reserved

        // Field descriptors
        for field in fields {
            var nameBytes = field.name.prefix(10).data(using: .ascii) ?? Data()
            nameBytes.append(contentsOf: repeatElement(0, count: 11 - nameBytes.count))
            header.append(nameBytes)
            let typeByte = UInt8(truncatingIfNeeded: field.type.rawValue.unicodeScalars.first?.value ?? 0x20)
            header.append(typeByte)
            header.appendLittleEndian(Int32(0)) // field address (unused for writing)
            header.append(field.length)
            header.append(field.decimalCount)
            header.append(Data(count: 14)) // reserved
        }

        header.append(UInt8(0x0D)) // field descriptor terminator

        // Records
        var records = Data()
        for feature in features {
            records.append(UInt8(0x20)) // active record flag
            for field in fields {
                let value = feature.properties[field.name]
                let formatted = formatDbfValue(value, field: field)
                records.append(formatted)
            }
        }

        records.append(0x1A) // EOF marker
        return header + records
    }

    private static func buildFieldDescriptors(features: [Feature]) -> [DbfFieldDescriptor] {
        // Collect all unique property keys preserving insertion order
        var keys: [String] = []
        var seen = Set<String>()

        for feature in features {
            let properties = feature.properties
            for key in properties.keys where !key.isEmpty {
                if seen.insert(key).inserted {
                    keys.append(key)
                }
            }
        }

        return keys.map { key in
            // Determine type from first feature that has this key
            for feature in features {
                guard let value = feature.properties[key] else { continue }
                switch value {
                case is Bool:
                    return DbfFieldDescriptor(name: key, type: .logical, length: 1, decimalCount: 0)
                case is Int:
                    return DbfFieldDescriptor(name: key, type: .numeric, length: 12, decimalCount: 0)
                case is Double:
                    return DbfFieldDescriptor(name: key, type: .numeric, length: 24, decimalCount: 8)
                case is String:
                    let maxLen = min(max(features.compactMap { (($0.properties[key] as? String)?.count ?? 0) }.max() ?? 1, 1), 254)
                    return DbfFieldDescriptor(name: key, type: .character, length: UInt8(maxLen), decimalCount: 0)
                default:
                    let strLen = min("\(value)".count, 254)
                    return DbfFieldDescriptor(name: key, type: .character, length: UInt8(max(1, strLen)), decimalCount: 0)
                }
            }
            return DbfFieldDescriptor(name: key, type: .character, length: 1, decimalCount: 0)
        }
    }

    private static func formatDbfValue(_ value: Sendable?, field: DbfFieldDescriptor) -> Data {
        let length = Int(field.length)
        let formatted: String

        switch (field.type, value) {
        case (.logical, let bool as Bool):
            formatted = bool ? "T" : "F"
        case (.numeric, let int as Int):
            let str = "\(int)"
            formatted = str.count >= length ? String(str.suffix(length)) : String(repeating: " ", count: length - str.count) + str
        case (.numeric, let double as Double):
            if field.decimalCount > 0 {
                let fmt = String(format: "%\(length).\(field.decimalCount)f", double)
                formatted = fmt.count >= length ? String(fmt.suffix(length)) : fmt
            }
            else {
                let str = "\(Int(double))"
                formatted = str.count >= length ? String(str.suffix(length)) : String(repeating: " ", count: length - str.count) + str
            }
        case (.character, let string as String):
            let truncated = string.count >= length ? String(string.prefix(length)) : string
            formatted = truncated + String(repeating: " ", count: length - truncated.count)
        case (.date, let string as String):
            let cleaned = string.filter { $0.isNumber }
            formatted = cleaned.count >= 8 ? String(cleaned.prefix(8)) : cleaned + String(repeating: " ", count: length - cleaned.count)
        default:
            formatted = String(repeating: " ", count: length)
        }

        return formatted.prefix(length).data(using: .ascii) ?? Data(repeating: 0x20, count: length)
    }

}

// MARK: - PRJ writing

extension ShapefileCoder {

    private static func writePrj(_ projection: Projection) -> String? {
        switch projection {
        case .epsg4326:
            return #"GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]]"#

        case .epsg3857:
            return #"PROJCS["WGS 84 / Pseudo-Mercator",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]],PROJECTION["Mercator_1SP"],PARAMETER["central_meridian",0],PARAMETER["scale_factor",1],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["metre",1]]"#

        case .epsg4978:
            return #"GEOCCS["WGS 84 (geocentric)",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["metre",1]]"#

        case .noSRID:
            return nil
        }
    }

}

#endif
