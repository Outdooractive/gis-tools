@testable import GISTools
import Testing

struct AlongTests {

    // Tests coordinateAlong(distance:) returns the correct coordinate at a given distance along a LineString.
    @Test
    func along() async throws {
        let lineString = try TestData.lineString(package: "Along", name: "AlongLineString1")

        let distance1: Double = GISTool.convert(length: 1.0, from: .miles, to: .meters)!
        let distance2: Double = GISTool.convert(length: 100.0, from: .miles, to: .meters)!

        let coordinate1: Coordinate3D = lineString.coordinateAlong(distance: distance1)
        let coordinate2: Coordinate3D = lineString.coordinateAlong(distance: distance2)

        #expect(coordinate1 == Coordinate3D(latitude: 38.88533832382329, longitude: -77.02418026178886))
        #expect(coordinate2 == lineString.coordinates[lineString.coordinates.count - 1])
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
        ]))
        let coordinate = lineString.coordinateAlong(distance: 500_000.0)
        #expect(coordinate.latitude >= 0.0)
        #expect(coordinate.latitude <= 10.0)
        #expect(abs(coordinate.longitude) > 150.0)
    }

    // MARK: - Distance along

    /// Returns the full length of the line when querying the last coordinate.
    @Test
    func distanceAlongLast() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])
        let dist = line.distanceAlong(to: Coordinate3D(latitude: 10.0, longitude: 0.0))
        #expect(dist != nil)
        if let dist { #expect(abs(dist - line.length) < 1.0) }
    }

    /// Returns 0 when querying the first coordinate.
    @Test
    func distanceAlongFirst() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])
        let dist = line.distanceAlong(to: Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(dist != nil)
        if let dist { #expect(dist < 1.0) }
    }

    /// Returns half the length when querying the midpoint.
    @Test
    func distanceAlongMidpoint() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])
        let mid = Coordinate3D(latitude: 5.0, longitude: 0.0)
        let dist = line.distanceAlong(to: mid)
        #expect(dist != nil)
        if let dist { #expect(abs(dist - line.length / 2.0) < 1.0) }
    }

    /// Returns nil for a point far from the line (beyond tolerance).
    @Test
    func distanceAlongBeyondTolerance() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])
        let far = Coordinate3D(latitude: 5.0, longitude: 100.0)
        #expect(line.distanceAlong(to: far) == nil)
    }

    /// Custom tolerance accepts a point at the specified distance from the line.
    @Test
    func distanceAlongCustomTolerance() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])
        // 50 meters away from the line — fails with default 1m tolerance
        let near = Coordinate3D(latitude: 5.0, longitude: 0.001)
        #expect(line.distanceAlong(to: near) == nil)
        // But passes with a generous tolerance
        #expect(line.distanceAlong(to: near, tolerance: 200.0) != nil)
    }

}
