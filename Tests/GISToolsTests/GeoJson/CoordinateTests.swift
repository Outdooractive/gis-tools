import Foundation
@testable import GISTools
import Testing

struct CoordinateTests {

    /// Validates the ``Coordinate3D.description`` string for EPSG:4326 coordinates with various optional components.
    @Test
    func coordinate3DDescription() async throws {
        let coordinate = Coordinate3D(latitude: 15.0, longitude: 10.0)
        #expect(coordinate.description == "Coordinate3D<EPSG:4326>(latitude: 15.0, longitude: 10.0)")

        let coordinateZ = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0)
        #expect(coordinateZ.description == "Coordinate3D<EPSG:4326>(latitude: 15.0, longitude: 10.0, altitude: 500.0)")

        let coordinateM = Coordinate3D(latitude: 15.0, longitude: 10.0, m: 1234)
        #expect(coordinateM.description == "Coordinate3D<EPSG:4326>(latitude: 15.0, longitude: 10.0, m: 1234.0)")

        let coordinateZM = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0, m: 1234)
        #expect(coordinateZM.description == "Coordinate3D<EPSG:4326>(latitude: 15.0, longitude: 10.0, altitude: 500.0, m: 1234.0)")
    }

    /// Validates the ``Coordinate3D.description`` string for EPSG:3857 coordinates with various optional components.
    @Test
    func coordinateXYDescription() async throws {
        let coordinate = Coordinate3D(x: 10.0, y: 15.0)
        #expect(coordinate.description == "Coordinate3D<EPSG:3857>(x: 10.0, y: 15.0)")

        let coordinateZ = Coordinate3D(x: 10.0, y: 15.0, z: 500.0)
        #expect(coordinateZ.description == "Coordinate3D<EPSG:3857>(x: 10.0, y: 15.0, z: 500.0)")

        let coordinateM = Coordinate3D(x: 10.0, y: 15.0, m: 1234)
        #expect(coordinateM.description == "Coordinate3D<EPSG:3857>(x: 10.0, y: 15.0, m: 1234.0)")

        let coordinateZM = Coordinate3D(x: 10.0, y: 15.0, z: 500.0, m: 1234)
        #expect(coordinateZM.description == "Coordinate3D<EPSG:3857>(x: 10.0, y: 15.0, z: 500.0, m: 1234.0)")
    }

    /// Validates JSON encoding of a ``Coordinate3D`` produces the expected array.
    @Test
    func encodable() async throws {
        let coordinate = Coordinate3D(latitude: 15.0, longitude: 10.0)
        let coordinateData = try JSONEncoder().encode(coordinate)

        #expect(String(data: coordinateData, encoding: .utf8) == "[10,15]")
    }

    /// Validates JSON encoding handles ``nil`` altitude and ``m`` values correctly.
    @Test
    func encodableNull() async throws {
        let coordinateM = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: nil, m: 1234)
        let coordinateZ = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0, m: nil)

        let coordinateDataM = try JSONEncoder().encode(coordinateM)
        let coordinateDataZ = try JSONEncoder().encode(coordinateZ)

        #expect(String(data: coordinateDataM, encoding: .utf8) == "[10,15,null,1234]")
        #expect(String(data: coordinateDataZ, encoding: .utf8) == "[10,15,500]")

        #expect(coordinateM.asMinimalJson == [10, 15])
        #expect(coordinateZ.asMinimalJson == [10, 15, 500])
    }

    /// Validates round-trip JSON encoding and decoding of an EPSG:3857 ``Coordinate3D``.
    @Test
    func encodable3857() async throws {
        let coordinate = Coordinate3D(latitude: 15.0, longitude: 10.0).projected(to: .epsg3857)
        let coordinateData = try JSONEncoder().encode(coordinate)
        let decodedCoordinate = try JSONDecoder().decode(Coordinate3D.self, from: coordinateData)

        #expect(abs(Double(decodedCoordinate.asJson[0]!) - 10.0) < 0.000001)
        #expect(abs(Double(decodedCoordinate.asJson[1]!) - 15.0) < 0.000001)
    }

    /// Validates JSON decoding of a coordinate array.
    @Test
    func decodable() async throws {
        let coordinateData = try #require("[10,15]".data(using: .utf8))
        let decodedCoordinate = try JSONDecoder().decode(Coordinate3D.self, from: coordinateData)

        #expect(decodedCoordinate.asJson == [10.0, 15.0])
    }

    /// Validates initializing a ``Coordinate3D`` from a JSON dictionary with ``x`` and ``y`` keys.
    @Test
    func JSONDictionary() async throws {
        let decodedCoordinate = try #require(Coordinate3D(json: [
            "x": 10.0,
            "y": 15.0,
        ]))

        #expect(decodedCoordinate.asJson == [10.0, 15.0])
    }

    /// Validates that malformed coordinate arrays throw on decode.
    @Test
    func decodableInvalid() async throws {
        let coordinateData1 =  try #require("[10]".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Coordinate3D.self, from: coordinateData1)
        }

        let coordinateData2 =  try #require("[10,]".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Coordinate3D.self, from: coordinateData2)
        }

        let coordinateData3 =  try #require("[null,null]".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Coordinate3D.self, from: coordinateData3)
        }

        let coordinateData4 =  try #require("[]".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Coordinate3D.self, from: coordinateData4)
        }

        let coordinateData5 =  try #require("[,15]".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Coordinate3D.self, from: coordinateData5)
        }
    }

    /// Validates that incomplete JSON dictionaries return ``nil``.
    @Test
    func JSONDictionaryInvalid() async throws {
        #expect(Coordinate3D(json: [
            "x": 10.0,
        ]) == nil)

        #expect(Coordinate3D(json: [
            "y": 15.0,
        ]) == nil)

        #expect(Coordinate3D(json: []) == nil)

        #expect(Coordinate3D(json: [
            "x": 10.0,
            "y": nil,
        ]) == nil)

        #expect(Coordinate3D(json: [
            "x": 10.0,
            "y": NSNull(),
        ]) == nil)
    }

    /// Validates that a coordinate array with ``null`` in an invalid position throws on decode.
    @Test
    func decodableInvalidNull() async throws {
        let coordinateDataM =  try #require("[10,null,null,1234]".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Coordinate3D.self, from: coordinateDataM)
        }
    }

    /// Validates decoding coordinates with ``null`` values in valid positions.
    @Test
    func decodableNull() async throws {
        let coordinateDataM =  try #require("[10,15,null,1234]".data(using: .utf8))
        let coordinateDataZ =  try #require("[10,15,500]".data(using: .utf8))
        let coordinateDataZM =  try #require("[10,15,500,null]".data(using: .utf8))

        let decodedCoordinateM = try JSONDecoder().decode(Coordinate3D.self, from: coordinateDataM)
        let decodedCoordinateZ = try JSONDecoder().decode(Coordinate3D.self, from: coordinateDataZ)
        let decodedCoordinateZM = try JSONDecoder().decode(Coordinate3D.self, from: coordinateDataZM)

        #expect(decodedCoordinateM.asJson == [10.0, 15.0, nil, 1234])
        #expect(decodedCoordinateM.asMinimalJson == [10.0, 15.0])
        #expect(decodedCoordinateZ.asJson == [10.0, 15.0, 500])
        #expect(decodedCoordinateZM.asJson == [10.0, 15.0, 500])
    }

    /// Validates coordinate equality including and excluding altitude comparisons.
    @Test
    func equalityWithAltitude() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 100.0)
        let b = Coordinate3D(latitude: -100.0, longitude: -100.0, altitude: 100.0)
        let c = Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 99.0)

        #expect(a == a)
        #expect(a != b)
        #expect(a != c)
        #expect(b != c)

        #expect(a.equals(other: a, includingAltitude: false))
        #expect(a.equals(other: a, includingAltitude: true))
        #expect(a.equals(other: c, includingAltitude: false))
        #expect(a.equals(other: c, includingAltitude: true) == false)
        #expect(a.equals(other: c, includingAltitude: true, altitudeDelta: 1.0))
        #expect(a.equals(other: c, includingAltitude: true, altitudeDelta: 0.5) == false)

        #expect(a.equals(other: b, includingAltitude: false) == false)
        #expect(a.equals(other: b, includingAltitude: true) == false)
    }

    /// Validates coordinate equality for coordinates without altitude.
    @Test
    func equalityWithoutAltitude() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 10.0)
        let b = Coordinate3D(latitude: -100.0, longitude: -100.0)

        #expect(a == a)
        #expect(a.equals(other: a, includingAltitude: false))
        #expect(a.equals(other: a, includingAltitude: true))
        #expect(a != b)
        #expect(a.equals(other: b, includingAltitude: false) == false)
        #expect(a.equals(other: b, includingAltitude: true) == false)
    }

    // MARK: - Normalization

    /// Validates longitude normalization wraps 200 to -160 for EPSG:4326.
    @Test
    func normalizedEPSG4326() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 200.0)
        let n = a.normalized()
        #expect(n.longitude == -160.0)
        #expect(n.latitude == 10.0)
    }

    /// Validates longitude normalization wraps around multiple times (730 to 10).
    @Test
    func normalizedEPSG4326MultipleWrap() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 730.0)
        let n = a.normalized()
        #expect(n.longitude == 10.0)
        #expect(n.latitude == 10.0)
    }

    /// Validates longitude normalization for negative values (-190 to 170).
    @Test
    func normalizedEPSG4326Negative() async throws {
        let a = Coordinate3D(latitude: -20.0, longitude: -190.0)
        let n = a.normalized()
        #expect(n.longitude == 170.0)
        #expect(n.latitude == -20.0)
    }

    /// Validates normalization does not alter in-range coordinates.
    @Test
    func normalizedEPSG4326InRange() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 45.0)
        let n = a.normalized()
        #expect(n.longitude == 45.0)
        #expect(n.latitude == 10.0)
    }

    /// Validates normalization preserves longitude at the 180-degree boundary.
    @Test
    func normalizedEPSG4326Boundary180() async throws {
        let a = Coordinate3D(latitude: 0.0, longitude: 180.0)
        let n = a.normalized()
        #expect(n.longitude == 180.0)
    }

    /// Validates normalization preserves longitude at the -180-degree boundary.
    @Test
    func normalizedEPSG4326BoundaryNegative180() async throws {
        let a = Coordinate3D(latitude: 0.0, longitude: -180.0)
        let n = a.normalized()
        #expect(n.longitude == -180.0)
    }

    /// Validates normalization for EPSG:3857 coordinates wraps at originShift.
    @Test
    func normalizedEPSG3857() async throws {
        let shift = GISTool.originShift
        let a = Coordinate3D(x: shift * 3.0, y: 10.0)
        let n = a.normalized()
        #expect(abs(n.x - shift) < 1e-6)
    }

    /// Validates that normalization preserves altitude and m values.
    @Test
    func normalizedPreservesAltitudeAndM() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 200.0, altitude: 500.0, m: 42.0)
        let n = a.normalized()
        #expect(n.longitude == -160.0)
        #expect(n.altitude == 500.0)
        #expect(n.m == 42.0)
    }

    /// Validates the mutating ``normalize()`` method.
    @Test
    func normalizedMutating() async throws {
        var a = Coordinate3D(latitude: 10.0, longitude: 200.0)
        a.normalize()
        #expect(a.longitude == -160.0)
    }

    // MARK: - Clamping

    /// Validates clamping clamps longitude to 180 when too large.
    @Test
    func clampedEPSG4326LongitudeTooLarge() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 200.0)
        let c = a.clamped()
        #expect(c.longitude == 180.0)
        #expect(c.latitude == 10.0)
    }

    /// Validates clamping clamps longitude to -180 when too small.
    @Test
    func clampedEPSG4326LongitudeTooSmall() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: -200.0)
        let c = a.clamped()
        #expect(c.longitude == -180.0)
        #expect(c.latitude == 10.0)
    }

    /// Validates clamping clamps latitude to 90 when too large.
    @Test
    func clampedEPSG4326LatitudeTooLarge() async throws {
        let a = Coordinate3D(latitude: 100.0, longitude: 10.0)
        let c = a.clamped()
        #expect(c.latitude == 90.0)
        #expect(c.longitude == 10.0)
    }

    /// Validates clamping clamps latitude to -90 when too small.
    @Test
    func clampedEPSG4326LatitudeTooSmall() async throws {
        let a = Coordinate3D(latitude: -100.0, longitude: 10.0)
        let c = a.clamped()
        #expect(c.latitude == -90.0)
        #expect(c.longitude == 10.0)
    }

    /// Validates clamping clamps both latitude and longitude when both are out of range.
    @Test
    func clampedEPSG4326BothOutOfRange() async throws {
        let a = Coordinate3D(latitude: 200.0, longitude: 300.0)
        let c = a.clamped()
        #expect(c.latitude == 90.0)
        #expect(c.longitude == 180.0)
    }

    /// Validates clamping does not alter in-range coordinates.
    @Test
    func clampedEPSG4326InRange() async throws {
        let a = Coordinate3D(latitude: 45.0, longitude: 90.0)
        let c = a.clamped()
        #expect(a == c)
    }

    /// Validates clamping for EPSG:3857 coordinates at originShift.
    @Test
    func clampedEPSG3857() async throws {
        let shift = GISTool.originShift
        let a = Coordinate3D(x: shift * 3.0, y: shift * 4.0)
        let c = a.clamped()
        #expect(c.x == shift)
        #expect(c.y == shift)
    }

    /// Validates that clamping preserves altitude and m values.
    @Test
    func clampedPreservesAltitudeAndM() async throws {
        let a = Coordinate3D(latitude: 200.0, longitude: 300.0, altitude: 1000.0, m: 7.0)
        let c = a.clamped()
        #expect(c.latitude == 90.0)
        #expect(c.longitude == 180.0)
        #expect(c.altitude == 1000.0)
        #expect(c.m == 7.0)
    }

    /// Validates the mutating ``clamp()`` method.
    @Test
    func clampedMutating() async throws {
        var a = Coordinate3D(latitude: 200.0, longitude: 10.0)
        a.clamp()
        #expect(a.latitude == 90.0)
    }

    /// Validates that normalization is a no-op for ``Projection.noSRID`` coordinates.
    @Test
    func normalizedNoSRID() async throws {
        let a = Coordinate3D(x: 200.0, y: 10.0, projection: .noSRID)
        let n = a.normalized()
        #expect(n.longitude == 200.0)
        #expect(n.latitude == 10.0)
    }

    /// Validates that clamping is a no-op for ``Projection.noSRID`` coordinates.
    @Test
    func clampedNoSRID() async throws {
        let a = Coordinate3D(x: 300.0, y: 200.0, projection: .noSRID)
        let c = a.clamped()
        #expect(c.longitude == 300.0)
        #expect(c.latitude == 200.0)
    }

    // MARK: - Hashable

    /// Validates that equal coordinates have the same hash value.
    @Test
    func hashableEquality() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 20.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 20.0)
        #expect(a.hashValue == b.hashValue)
    }

    /// Validates that different coordinates are not equal.
    @Test
    func hashableInequality() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 20.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 21.0)
        #expect(a != b)
    }

    /// Validates coordinates within the hash bucket threshold are equal.
    @Test
    func hashableWithinSameBucket() async throws {
        let a = Coordinate3D(latitude: 10.0 + 0.4e-10, longitude: 20.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 20.0)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    /// Validates coordinates just outside the hash bucket threshold are not equal.
    @Test
    func hashableEdgeDelta() async throws {
        let a = Coordinate3D(latitude: 10.0 + 1.1e-10, longitude: 20.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 20.0)
        #expect(a != b)
    }

    /// Validates coordinates work correctly as elements in a ``Set``.
    @Test
    func hashableInSet() async throws {
        let coords: Set<Coordinate3D> = [
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 30.0, longitude: 40.0),
        ]
        #expect(coords.contains(Coordinate3D(latitude: 10.0, longitude: 20.0)))
        #expect(coords.count == 2)
    }

    /// Validates coordinates work correctly as dictionary keys.
    @Test
    func hashableInDictionary() async throws {
        let dict: [Coordinate3D: String] = [
            Coordinate3D(latitude: 10.0, longitude: 20.0): "A",
            Coordinate3D(latitude: 30.0, longitude: 40.0): "B",
        ]
        #expect(dict[Coordinate3D(latitude: 10.0, longitude: 20.0)] == "A")
    }

    // MARK: - Equality edge cases

    /// Validates coordinates with different projections are not equal.
    @Test
    func equalityProjectionMismatch() async throws {
        let epsg4326 = Coordinate3D(latitude: 10.0, longitude: 20.0)
        let epsg3857 = Coordinate3D(x: 20.0, y: 10.0)
        #expect(epsg4326 != epsg3857)
    }

    /// Validates ``Coordinate3D.equals(other:includingAltitude:equalityDelta:altitudeDelta:)`` with a custom delta across projections.
    @Test
    func equalityCustomDeltaProjection() async throws {
        let a = Coordinate3D(x: 1000.0, y: 2000.0)
        let b = Coordinate3D(x: 1000.000_001, y: 2000.0)
        #expect(a.equals(other: b, equalityDelta: 0.001))
        #expect(a.equals(other: b, equalityDelta: 1e-10) == false)
    }

    /// Validates equality between EPSG:4326 and projected EPSG:3857 coordinates.
    @Test
    func equalityProjected() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 20.0)
        let b = Coordinate3D(x: 2226389.0, y: 1118889.0)
        #expect(a.equals(other: b, equalityDelta: 0.5))
    }

    /// Validates coordinates differing only in altitude nil versus non-nil are not equal.
    @Test
    func equalityAltitudeNilVsNonNil() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 20.0)
        let b = Coordinate3D(latitude: 10.0, longitude: 20.0, altitude: 100.0)
        #expect(a != b)
        #expect(a.equals(other: b, includingAltitude: false))
    }

    // MARK: - EPSG:4978 (ECEF) conversion tests

    /// Validates the ECEF conversion for Null Island (0°, 0°, 0m) → (a, 0, 0) and round-trip.
    @Test
    func ecefNullIsland() async throws {
        let geo = Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 0.0)
        let ecef = geo.projected(to: .epsg4978)
        #expect(ecef.projection == .epsg4978)
        #expect(abs(ecef.longitude - 6_378_137.0) < 0.001)
        #expect(abs(ecef.latitude) < 0.001)
        #expect(abs(ecef.altitude ?? 0.0) < 0.001)

        let back = ecef.projected(to: .epsg4326)
        #expect(abs(back.latitude) < 1e-10)
        #expect(abs(back.longitude) < 1e-10)
        #expect(abs(back.altitude ?? 0.0) < 0.001)
    }

    /// Validates the ECEF conversion for (0°, 90°E, 0m) → (0, a, 0) and round-trip.
    @Test
    func ecefEquator90E() async throws {
        let geo = Coordinate3D(latitude: 0.0, longitude: 90.0, altitude: 0.0)
        let ecef = geo.projected(to: .epsg4978)
        #expect(abs(ecef.longitude) < 0.001)
        #expect(abs(ecef.latitude - 6_378_137.0) < 0.001)
        #expect(abs(ecef.altitude ?? 0.0) < 0.001)

        let back = ecef.projected(to: .epsg4326)
        #expect(abs(back.latitude) < 1e-10)
        #expect(abs(back.longitude - 90.0) < 1e-10)
    }

    /// Validates the ECEF conversion for the North Pole (90°N, 0°, 0m) → (0, 0, b) and round-trip.
    @Test
    func ecefNorthPole() async throws {
        let geo = Coordinate3D(latitude: 90.0, longitude: 0.0, altitude: 0.0)
        let ecef = geo.projected(to: .epsg4978)
        #expect(abs(ecef.longitude) < 0.001)
        #expect(abs(ecef.latitude) < 0.001)
        #expect(abs((ecef.altitude ?? 0.0) - 6_356_752.314) < 0.1)

        let back = ecef.projected(to: .epsg4326)
        #expect(abs(back.latitude - 90.0) < 1e-10)
        #expect(abs(back.longitude) < 1e-10)
    }

    /// Validates round-trip conversion: EPSG:4326 → EPSG:4978 → EPSG:4326 with altitude preserved.
    @Test
    func ecefRoundTrip() async throws {
        let original = Coordinate3D(latitude: 45.0, longitude: -45.0, altitude: 100.0)
        let ecef = original.projected(to: .epsg4978)
        let back = ecef.projected(to: .epsg4326)
        #expect(abs(back.latitude - 45.0) < 1e-8)
        #expect(abs(back.longitude - -45.0) < 1e-8)
        #expect(abs((back.altitude ?? 0.0) - 100.0) < 0.001)
    }

    /// Validates round-trip conversion: EPSG:4978 → EPSG:4326 → EPSG:4978.
    @Test
    func ecefRoundTrip4978() async throws {
        let original = Coordinate3D(x: 4_000_000.0, y: 5_000_000.0, z: 3_000_000.0, projection: .epsg4978)
        let geo = original.projected(to: .epsg4326)
        let back = geo.projected(to: .epsg4978)
        #expect(abs(back.longitude - original.longitude) < 0.001)
        #expect(abs(back.latitude - original.latitude) < 0.001)
        #expect(abs((back.altitude ?? 0.0) - (original.altitude ?? 0.0)) < 0.001)
    }

    /// Validates the ``Coordinate3D.description`` for EPSG:4978 coordinates.
    @Test
    func ecefDescription() async throws {
        let coord = Coordinate3D(x: 6_378_137.0, y: 0.0, z: 0.0, projection: .epsg4978)
        #expect(coord.description == "Coordinate3D<EPSG:4978>(x: 6378137.0, y: 0.0, z: 0.0)")
    }

    /// Validates that EPSG:4978 coordinates project to EPSG:4326 for GeoJSON output.
    @Test
    func ecefAsJson() async throws {
        let ecef = Coordinate3D(x: 6_378_137.0, y: 0.0, z: 0.0, projection: .epsg4978)
        let json = ecef.asJson
        #expect(json.count >= 2)
        #expect(abs(json[0]! - 0.0) < 1e-10)
        #expect(abs(json[1]! - 0.0) < 1e-10)
    }

    /// Validates that ``normalized()`` is a no-op for EPSG:4978 coordinates.
    @Test
    func ecefNormalizedNoOp() async throws {
        let coord = Coordinate3D(x: 10_000_000.0, y: 20_000_000.0, z: 5_000_000.0, projection: .epsg4978)
        let n = coord.normalized()
        #expect(n.x == coord.x)
        #expect(n.y == coord.y)
    }

    /// Validates that ``clamped()`` is a no-op for EPSG:4978 coordinates.
    @Test
    func ecefClampedNoOp() async throws {
        let coord = Coordinate3D(x: 10_000_000.0, y: 20_000_000.0, z: 5_000_000.0, projection: .epsg4978)
        let c = coord.clamped()
        #expect(c.x == coord.x)
        #expect(c.y == coord.y)
    }

    /// Validates Euclidean distance between two EPSG:4978 points.
    @Test
    func ecefDistance() async throws {
        let a = Coordinate3D(x: 6_378_137.0, y: 0.0, z: 0.0, projection: .epsg4978)
        let b = Coordinate3D(x: 0.0, y: 6_378_137.0, z: 0.0, projection: .epsg4978)
        let dist = a.distance(to: b)
        #expect(abs(dist - 6_378_137.0 * sqrt(2.0)) < 0.001)
    }

    /// Validates bearing between two EPSG:4978 points converts through EPSG:4326 internally.
    @Test
    func ecefBearing() async throws {
        let a = Coordinate3D(x: 6_378_137.0, y: 0.0, z: 0.0, projection: .epsg4978)
        let b = Coordinate3D(x: 0.0, y: 6_378_137.0, z: 0.0, projection: .epsg4978)
        let bearing = a.bearing(to: b)
        #expect(abs(bearing - 90.0) < 2.0)
    }

    /// Validates that EPSG:4978 → EPSG:3857 projection matches the chain 4978 → 4326 → 3857.
    @Test
    func ecefProjectedTo3857() async throws {
        let geo = Coordinate3D(latitude: 41.0, longitude: -71.0)
        let ecef = geo.projected(to: .epsg4978)
        let merc = ecef.projected(to: .epsg3857)
        let directMerc = geo.projected(to: .epsg3857)
        #expect(abs(merc.longitude - directMerc.longitude) < 0.001)
        #expect(abs(merc.latitude - directMerc.latitude) < 0.001)
    }

}
