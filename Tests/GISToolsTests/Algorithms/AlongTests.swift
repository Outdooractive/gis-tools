@testable import GISTools
import Testing

struct AlongTests {

    // Tests coordinateAlong at 1 mile and 100 miles.
    @Test
    func along() async throws {
        let lineString = LineString(unchecked: [
            Coordinate3D(latitude: 38.878605901789236, longitude: -77.0316696166992),
            Coordinate3D(latitude: 38.88194668656296, longitude: -77.02960968017578),
            Coordinate3D(latitude: 38.88408470638821, longitude: -77.02033996582031),
            Coordinate3D(latitude: 38.885821800123196, longitude: -77.02566146850586),
            Coordinate3D(latitude: 38.88956308852534, longitude: -77.02188491821289),
            Coordinate3D(latitude: 38.89236892551996, longitude: -77.01982498168944),
            Coordinate3D(latitude: 38.89370499941828, longitude: -77.02291488647461),
            Coordinate3D(latitude: 38.89958342598271, longitude: -77.02291488647461),
            Coordinate3D(latitude: 38.90011780426885, longitude: -77.01896667480469),
            Coordinate3D(latitude: 38.90733151751689, longitude: -77.01845169067383),
            Coordinate3D(latitude: 38.907865837489105, longitude: -77.02291488647461),
            Coordinate3D(latitude: 38.91200668090932, longitude: -77.02377319335936),
            Coordinate3D(latitude: 38.91254096569048, longitude: -77.02995300292969),
            Coordinate3D(latitude: 38.91708222394378, longitude: -77.03338623046875),
            Coordinate3D(latitude: 38.920821865485834, longitude: -77.03784942626953),
            Coordinate3D(latitude: 38.92830055730587, longitude: -77.03115463256836),
            Coordinate3D(latitude: 38.931505469602044, longitude: -77.03596115112305),
        ])
        let distance1: Double = GISTool.convert(length: 1.0, from: .miles, to: .meters)!
        let distance2: Double = GISTool.convert(length: 100.0, from: .miles, to: .meters)!

        let coordinate1: Coordinate3D = lineString.coordinateAlong(distance: distance1)
        let coordinate2: Coordinate3D = lineString.coordinateAlong(distance: distance2)

        #expect(coordinate1 == Coordinate3D(latitude: 38.88533832382329, longitude: -77.02418026178886))
        #expect(coordinate2 == lineString.coordinates[lineString.coordinates.count - 1])
    }

    // MARK: - Projections

    // Tests coordinateAlong in EPSG:3857.
    @Test
    func along3857() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 500_000.0, y: 500_000.0),
            Coordinate3D(x: 1_000_000.0, y: 0.0),
        ]))
        let coordinate = lineString.coordinateAlong(distance: 500_000.0)
        #expect(coordinate.x.isFinite)
        #expect(coordinate.y.isFinite)
    }

    // Validates coordinateAlong in EPSG:4978.
    @Test
    func along4978() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 3.0, longitude: 3.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 6.0, longitude: 0.0).projected(to: .epsg4978),
        ]))
        let coordinate = lineString.coordinateAlong(distance: 500_000.0)
        #expect(coordinate.x.isFinite)
        #expect(coordinate.y.isFinite)
    }

    // Validates coordinateAlong in noSRID.
    @Test
    func alongNoSRID() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 0.0, projection: .noSRID),
        ]))
        let coordinate = lineString.coordinateAlong(distance: 500.0)
        #expect(coordinate.x.isFinite)
        #expect(coordinate.y.isFinite)
    }

    // MARK: - Antimeridian

    // Tests coordinateAlong across the antimeridian.
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

    // Returns the full length when querying the last coordinate.
    @Test
    func distanceAlongLast() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let dist = line.distanceAlong(to: Coordinate3D(latitude: 10.0, longitude: 0.0))
        #expect(dist != nil)
        if let dist { #expect(abs(dist - line.length) < 1.0) }
    }

    // Returns 0 when querying the first coordinate.
    @Test
    func distanceAlongFirst() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let dist = line.distanceAlong(to: Coordinate3D(latitude: 0.0, longitude: 0.0))
        #expect(dist != nil)
        if let dist { #expect(dist < 1.0) }
    }

    // Returns half the length when querying the midpoint.
    @Test
    func distanceAlongMidpoint() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let mid = Coordinate3D(latitude: 5.0, longitude: 0.0)
        let dist = line.distanceAlong(to: mid)
        #expect(dist != nil)
        if let dist { #expect(abs(dist - line.length / 2.0) < 1.0) }
    }

    // Returns nil for a point far from the line.
    @Test
    func distanceAlongBeyondTolerance() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let far = Coordinate3D(latitude: 5.0, longitude: 100.0)
        #expect(line.distanceAlong(to: far) == nil)
    }

    // Custom tolerance accepts a point at the specified distance from the line.
    @Test
    func distanceAlongCustomTolerance() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let near = Coordinate3D(latitude: 5.0, longitude: 0.001)
        #expect(line.distanceAlong(to: near) == nil)
        #expect(line.distanceAlong(to: near, tolerance: 200.0) != nil)
    }

}
