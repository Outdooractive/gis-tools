import Foundation
import Testing
@testable import GISTools

/// Deterministic property-based tests for cross-cutting geometry invariants.
///
/// The generators are seeded so failures reproduce from the seed printed in
/// the assertion message.
struct PropertyInvariantTests {

    @Test
    func geoJSONRoundTripsGeneratedGeometries() throws {
        for seed in 0 ..< 25 {
            var random = SeededRNG(seed: UInt64(seed))
            let point = Point(PropertyGenerators.coordinate(&random, projection: .epsg4326))
            let line = try #require(PropertyGenerators.lineString(&random, projection: .epsg4326))
            let polygon = PropertyGenerators.rectangle(&random, projection: .epsg4326)

            for geometry in [point, line, polygon] as [any GeoJson] {
                let json = try #require(geometry.asJsonString(), "seed \(seed)")
                let decoded = try GeoJsonParser.parse(jsonString: json, mode: .strict)
                let object = try #require(decoded.object, "seed \(seed)")
                #expect(object.isEqualTo(geometry), "seed \(seed), type \(geometry.type)")
            }
        }
    }

    @Test
    func wkbAndWKTRoundTripGeneratedGeometries() throws {
        for seed in 0 ..< 25 {
            var random = SeededRNG(seed: UInt64(seed))
            let line = try #require(PropertyGenerators.lineString(&random, projection: .epsg4326))
            let polygon = PropertyGenerators.rectangle(&random, projection: .epsg4326)

            for geometry in [line, polygon] as [GeoJsonGeometry] {
                let wkb = try #require(WKBCoder.encode(geometry: geometry, targetProjection: nil), "seed \(seed)")
                let decodedWKB = try WKBCoder.decode(wkb: wkb, sourceProjection: .epsg4326)
                #expect(decodedWKB.isEqualTo(geometry), "WKB seed \(seed), type \(geometry.type)")

                let wkt = try #require(WKTCoder.encode(geometry: geometry, targetProjection: nil), "seed \(seed)")
                let decodedWKT = try WKTCoder.decode(wkt: wkt, sourceProjection: .epsg4326)
                #expect(decodedWKT.isEqualTo(geometry), "WKT seed \(seed), type \(geometry.type)")
            }
        }
    }

    @Test
    func twkbRoundTripsEveryGeometryType() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let geometries: [GeoJsonGeometry] = [
            Point(Coordinate3D(latitude: 1.0, longitude: 2.0)),
            try #require(MultiPoint([
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 2.0),
            ])),
            try #require(LineString([
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 2.0),
                Coordinate3D(latitude: 2.0, longitude: 3.0),
            ])),
            try #require(MultiLineString([[
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 2.0),
            ]])),
            polygon,
            try #require(MultiPolygon([polygon])),
            GeometryCollection([
                Point(Coordinate3D(latitude: 1.0, longitude: 2.0)),
                polygon,
            ]),
        ]

        for geometry in geometries {
            let data = TWKBTestEncoder.encode(geometry)
            let decoded = try TWKBCoder.decode(
                twkb: data,
                sourceProjection: .epsg4326,
                targetProjection: .epsg4326)
            #expect(decoded.isEqualTo(geometry), "TWKB type \(geometry.type)")
        }
    }

    @Test
    func overlayInvariantsInProjectedSpace() throws {
        for seed in 0 ..< 30 {
            var random = SeededRNG(seed: UInt64(seed))
            let a = PropertyGenerators.rectangle(&random, projection: .epsg3857)
            let b = PropertyGenerators.rectangle(&random, projection: .epsg3857)

            let intersection = a.intersection(with: b)
            let difference = a.difference(with: b)
            let union = a.union(with: b)
            let symmetricDifference = a.symmetricDifference(with: b)

            let intersectionArea = PropertyGenerators.area(of: intersection)
            let differenceArea = PropertyGenerators.area(of: difference)
            let unionArea = PropertyGenerators.area(of: union)
            let symmetricDifferenceArea = PropertyGenerators.area(of: symmetricDifference)
            let aArea = a.area
            let bArea = b.area
            let tolerance = max(1.0, aArea * 0.002)

            #expect(
                abs(aArea - (intersectionArea + differenceArea)) <= tolerance,
                "seed \(seed): A != intersection + difference")
            #expect(
                abs(unionArea - (aArea + bArea - intersectionArea)) <= tolerance,
                "seed \(seed): union != A + B - intersection")
            #expect(
                abs(symmetricDifferenceArea - (aArea + bArea - 2.0 * intersectionArea)) <= tolerance,
                "seed \(seed): symmetric difference invariant")
            #expect(intersection?.isValid != false, "seed \(seed): invalid intersection")
            #expect(difference?.isValid != false, "seed \(seed): invalid difference")
            #expect(union?.isValid != false, "seed \(seed): invalid union")
            #expect(symmetricDifference?.isValid != false, "seed \(seed): invalid symmetric difference")
        }
    }

    @Test
    func overlayInvariantsAcrossAntimeridian() throws {
        for seed in 0 ..< 20 {
            var random = SeededRNG(seed: UInt64(seed) &+ 1_000)
            let a = PropertyGenerators.seamRectangle(&random)
            let b = PropertyGenerators.seamRectangle(&random)

            let intersection = a.intersection(with: b)
            let difference = a.difference(with: b)
            let union = a.union(with: b)
            let symmetricDifference = a.symmetricDifference(with: b)

            let intersectionArea = PropertyGenerators.area(of: intersection)
            let differenceArea = PropertyGenerators.area(of: difference)
            let unionArea = PropertyGenerators.area(of: union)
            let symmetricDifferenceArea = PropertyGenerators.area(of: symmetricDifference)
            let aArea = a.area
            let bArea = b.area
            let tolerance = max(1.0, aArea * 0.005)

            #expect(
                abs(aArea - (intersectionArea + differenceArea)) <= tolerance,
                "seed \(seed): A != intersection + difference across the seam")
            #expect(
                abs(unionArea - (aArea + bArea - intersectionArea)) <= tolerance,
                "seed \(seed): union != A + B - intersection across the seam")
        }
    }

    @Test
    func simplifyInvariants() throws {
        for seed in 0 ..< 25 {
            var random = SeededRNG(seed: UInt64(seed) &+ 2_000)
            let line = try #require(PropertyGenerators.lineString(&random, projection: .epsg4326, count: 40))
            let simplified = line.simplified(tolerance: 50_000.0)

            #expect(simplified.coordinates.count <= line.coordinates.count, "seed \(seed)")
            #expect(simplified.coordinates.count >= 2, "seed \(seed)")
            #expect(simplified.firstCoordinate == line.firstCoordinate, "seed \(seed)")
            #expect(simplified.lastCoordinate == line.lastCoordinate, "seed \(seed)")
            #expect(simplified.isValid, "seed \(seed)")
        }
    }

    @Test
    func bufferInvariants() throws {
        for seed in 0 ..< 20 {
            var random = SeededRNG(seed: UInt64(seed) &+ 3_000)
            let polygon = PropertyGenerators.rectangle(&random, projection: .epsg3857, span: 100.0 ... 1_000.0)
            let distance = random.double(in: 20.0 ... 200.0)
            let buffer = try #require(polygon.buffered(by: distance, steps: 32), "seed \(seed)")

            #expect(buffer.isStructurallyValid, "seed \(seed)")
            #expect(buffer.area >= polygon.area, "seed \(seed)")
            #expect(buffer.covers(polygon), "seed \(seed): buffer does not contain input")
        }
    }

}

// MARK: - Deterministic generation

private struct SeededRNG: RandomNumberGenerator {

    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    mutating func double(in range: ClosedRange<Double>) -> Double {
        let unit = Double(next() >> 11) / 9_007_199_254_740_992.0
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }

}

private enum PropertyGenerators {

    static func coordinate(
        _ random: inout SeededRNG,
        projection: Projection,
        span: ClosedRange<Double> = 0.0 ... 10.0
    ) -> Coordinate3D {
        Coordinate3D(
            x: random.double(in: span),
            y: random.double(in: span),
            projection: projection)
    }

    static func lineString(
        _ random: inout SeededRNG,
        projection: Projection,
        count: Int = 12
    ) -> LineString? {
        let start = coordinate(&random, projection: projection)
        var coordinates = [start]
        for _ in 1 ..< count {
            let previous = coordinates[coordinates.count - 1]
            coordinates.append(Coordinate3D(
                x: previous.x + random.double(in: -2.0 ... 2.0),
                y: previous.y + random.double(in: -2.0 ... 2.0),
                projection: projection))
        }
        return LineString(coordinates)
    }

    static func area(of geometry: (any PolygonGeometry)?) -> Double {
        guard let geometry else { return 0.0 }
        if let polygon = geometry as? Polygon {
            return polygon.area
        }
        if let multiPolygon = geometry as? MultiPolygon {
            return multiPolygon.area
        }
        return 0.0
    }

    static func rectangle(
        _ random: inout SeededRNG,
        projection: Projection,
        span: ClosedRange<Double> = 0.0 ... 5_000.0
    ) -> Polygon {
        let x = random.double(in: span)
        let y = random.double(in: span)
        let width = random.double(in: 100.0 ... 1_500.0)
        let height = random.double(in: 100.0 ... 1_500.0)
        return rectangle(x: x, y: y, width: width, height: height, projection: projection)
    }

    static func seamRectangle(_ random: inout SeededRNG) -> Polygon {
        let west = random.double(in: 178.5 ... 179.9)
        let width = random.double(in: 0.2 ... 1.5)
        var east = west + width
        if east > 180.0 { east -= 360.0 }
        let south = random.double(in: -5.0 ... 5.0)
        let height = random.double(in: 0.2 ... 3.0)
        return rectangle(
            x: west,
            y: south,
            width: east - west,
            height: height,
            projection: .epsg4326)
    }

    static func rectangle(
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        projection: Projection
    ) -> Polygon {
        Polygon(unchecked: [[
            Coordinate3D(x: x, y: y, projection: projection),
            Coordinate3D(x: x + width, y: y, projection: projection),
            Coordinate3D(x: x + width, y: y + height, projection: projection),
            Coordinate3D(x: x, y: y + height, projection: projection),
            Coordinate3D(x: x, y: y, projection: projection),
        ]])
    }

}

// MARK: - Minimal TWKB encoder for round-trip tests

/// Encodes the subset of TWKB needed by the property tests: XY geometry,
/// precision 0, no bounding box, no IDs, no Z/M.
private enum TWKBTestEncoder {

    static func encode(_ geometry: GeoJsonGeometry) -> Data {
        var bytes: [UInt8] = []
        append(geometry, to: &bytes)
        return Data(bytes)
    }

    private static func append(_ geometry: GeoJsonGeometry, to bytes: inout [UInt8]) {
        switch geometry {
        case let point as Point:
            appendHeader(type: 1, to: &bytes)
            appendCoordinate(point.coordinate, to: &bytes, baseX: 0, baseY: 0)

        case let lineString as LineString:
            appendHeader(type: 2, to: &bytes)
            appendCoordinates(lineString.coordinates, to: &bytes)

        case let polygon as Polygon:
            appendHeader(type: 3, to: &bytes)
            appendCount(polygon.rings.count, to: &bytes)
            for ring in polygon.rings {
                appendCoordinates(ring.coordinates, to: &bytes)
            }

        case let multiPoint as MultiPoint:
            appendHeader(type: 4, to: &bytes)
            appendCoordinates(multiPoint.coordinates, to: &bytes)

        case let multiLineString as MultiLineString:
            appendHeader(type: 5, to: &bytes)
            appendCount(multiLineString.lineStrings.count, to: &bytes)
            for lineString in multiLineString.lineStrings {
                appendCoordinates(lineString.coordinates, to: &bytes)
            }

        case let multiPolygon as MultiPolygon:
            appendHeader(type: 6, to: &bytes)
            appendCount(multiPolygon.polygons.count, to: &bytes)
            for polygon in multiPolygon.polygons {
                appendCount(polygon.rings.count, to: &bytes)
                for ring in polygon.rings {
                    appendCoordinates(ring.coordinates, to: &bytes)
                }
            }

        case let collection as GeometryCollection:
            appendHeader(type: 7, to: &bytes)
            appendCount(collection.geometries.count, to: &bytes)
            for child in collection.geometries {
                append(child, to: &bytes)
            }

        default:
            Issue.record("Unsupported geometry for TWKB test encoder: \(geometry.type)")
        }
    }

    private static func appendHeader(type: UInt8, to bytes: inout [UInt8]) {
        bytes.append(type) // precision 0
        bytes.append(0) // metadata: no bbox, no size, no IDs, no Z/M
    }

    private static func appendCoordinates(
        _ coordinates: [Coordinate3D],
        to bytes: inout [UInt8]
    ) {
        appendCount(coordinates.count, to: &bytes)
        var baseX: Int64 = 0
        var baseY: Int64 = 0
        for coordinate in coordinates {
            appendCoordinate(coordinate, to: &bytes, baseX: baseX, baseY: baseY)
            baseX = Int64(coordinate.x.rounded())
            baseY = Int64(coordinate.y.rounded())
        }
    }

    private static func appendCoordinate(
        _ coordinate: Coordinate3D,
        to bytes: inout [UInt8],
        baseX: Int64,
        baseY: Int64
    ) {
        appendZigZag(Int64(coordinate.x.rounded()) - baseX, to: &bytes)
        appendZigZag(Int64(coordinate.y.rounded()) - baseY, to: &bytes)
    }

    private static func appendCount(_ count: Int, to bytes: inout [UInt8]) {
        appendVarUInt(UInt64(count), to: &bytes)
    }

    private static func appendZigZag(_ value: Int64, to bytes: inout [UInt8]) {
        appendVarUInt(UInt64(bitPattern: (value << 1) ^ (value >> 63)), to: &bytes)
    }

    private static func appendVarUInt(_ value: UInt64, to bytes: inout [UInt8]) {
        var value = value
        while value >= 0x80 {
            bytes.append(UInt8(value & 0x7F) | 0x80)
            value >>= 7
        }
        bytes.append(UInt8(value))
    }

}
