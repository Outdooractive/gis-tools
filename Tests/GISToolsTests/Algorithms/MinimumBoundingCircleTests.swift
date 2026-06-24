import Foundation
@testable import GISTools
import Testing

struct MinimumBoundingCircleTests {

    // MARK: - Minimum bounding radius

    /// Validates that a single ``Point`` has a minimum bounding radius of 0.
    @Test
    func radiusPoint() {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        #expect(point.minimumBoundingRadius() == 0.0)
    }

    /// Validates that two points define a circle with half their distance as radius.
    @Test
    func radiusTwoPoints() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ])
        let r = line.minimumBoundingRadius()
        #expect(r != nil)
        if let r { #expect(abs(r - 5.0) < 0.001) }
    }

    /// Validates the MBC radius of a 10x10 square: half the diagonal (5√2 ≈ 7.07).
    @Test
    func radiusSquare() {
        let square = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
        let r = square.minimumBoundingRadius()
        #expect(r != nil)
        if let r { #expect(abs(r - 5.0 * sqrt(2.0)) < 0.01) }
    }

    /// Validates the MBC radius of a pentagon matching the shapely example (radius 5.0).
    @Test
    func radiusPentagon() {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
        ]])
        let r = polygon.minimumBoundingRadius()
        #expect(r != nil)
        if let r { #expect(abs(r - 5.0) < 0.01) }
    }

    /// Validates that an empty geometry returns `nil` for the radius.
    @Test
    func radiusEmpty() {
        let empty = MultiPoint()
        #expect(empty.minimumBoundingRadius() == nil)
    }

    // MARK: - Minimum bounding circle

    /// Validates that a single ``Point`` returns `nil` for the circle polygon.
    @Test
    func circlePoint() {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        #expect(point.minimumBoundingCircle() == nil)
    }

    /// Validates that a square produces a 65-vertex circle polygon (64 steps + close).
    @Test
    func circleSquare() {
        let square = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
        let circle = square.minimumBoundingCircle()
        #expect(circle != nil)
        #expect(circle?.projection == square.projection)
        if let circle { #expect(circle.outerRing?.coordinates.count == 65) }
    }

    /// Validates that the `steps` parameter controls polygon vertex count (12 steps → 13 coords).
    @Test
    func circleStepsCount() {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
        let circle = polygon.minimumBoundingCircle(steps: 12)
        #expect(circle != nil)
        #expect(circle?.projection == polygon.projection)
        if let circle { #expect(circle.outerRing?.coordinates.count == 13) }
    }

    // MARK: - Antimeridian

    /// A square crossing the antimeridian: MBC radius should be half the diagonal (~7.07 deg).
    @Test
    func radiusAntimeridian() {
        let square = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 10.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
        ]])
        let r = square.minimumBoundingRadius()
        #expect(r != nil)
        // Diagonal = sqrt(10^2 + 2^2) ≈ 10.2, half = ~5.1
        if let r { #expect(abs(r - 5.1) < 0.5) }
    }

    // MARK: - EPSG:3857

    /// Validates that a multi-point in EPSG:3857 produces a valid minimum bounding circle.
    @Test
    func minimumBoundingCircle3857() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 0.0),
            Coordinate3D(x: 0.0, y: 100_000.0),
            Coordinate3D(x: 100_000.0, y: 100_000.0),
        ]))
        let circle = mp.minimumBoundingCircle()
        #expect(circle != nil)
        #expect(circle?.isValid == true)
        #expect(circle?.projection == .epsg3857)
    }

    /// Validates that a multi-point in EPSG:4978 produces a valid minimum bounding circle.
    @Test
    func minimumBoundingCircle4978() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 1.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 1.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 1.0, longitude: 1.0).projected(to: .epsg4978),
        ]))
        let circle = mp.minimumBoundingCircle()
        #expect(circle != nil)
        #expect(circle?.isValid == true)
        #expect(circle?.projection == .epsg4978)

        let radius = mp.minimumBoundingRadius()
        #expect(radius != nil)
        #expect(radius! > 0.0)
    }

    // MARK: - noSRID

    @Test
    func minimumBoundingCircleNoSRID() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
        ]))
        let circle = mp.minimumBoundingCircle()
        #expect(circle != nil)
        #expect(circle?.isValid == true)
        #expect(circle?.projection == .noSRID)

        let radius = mp.minimumBoundingRadius()
        #expect(radius != nil)
        #expect(radius! > 0.0)
    }
}
