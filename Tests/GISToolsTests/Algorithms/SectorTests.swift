@testable import GISTools
import Testing

struct SectorTests {

    @Test
    func sectorQuarter() async throws {
        let center = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let sector = try #require(center.sector(radius: 100_000.0, bearing1: 0.0, bearing2: 90.0))
        #expect(sector.isValid)
        #expect(sector.outerRing?.coordinates.count == 18) // center + 16 arc steps + center
    }

    @Test
    func sectorProperties() async throws {
        let center = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let sector = try #require(center.sector(radius: 100_000.0, bearing1: 0.0, bearing2: 90.0))
        let ring = try #require(sector.outerRing)
        let coords = ring.coordinates

        // First and last coordinate must be the center
        #expect(coords.first!.isCoincident(to: center.coordinate))
        #expect(coords.last!.isCoincident(to: center.coordinate))

        // Arc coordinates should be approximately at the given radius from center
        for i in 1 ..< coords.count - 1 {
            let distance = center.coordinate.distance(from: coords[i])
            #expect(abs(distance - 100_000.0) < 100.0)
        }
    }

    @Test
    func sectorBearingEndpoints() async throws {
        let center = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let sector = try #require(center.sector(radius: 100_000.0, bearing1: 0.0, bearing2: 90.0, steps: 64))
        let coords = try #require(sector.outerRing?.coordinates)

        // The first arc point (coords[1]) should be approximately at bearing 0 (North)
        let firstArc = coords[1]
        let bearingToFirst = center.bearing(to: firstArc)
        #expect(abs(bearingToFirst - 0.0) < 1.0)

        // The last arc point ends shy of bearing2 by at most one step (360/64 ≈ 5.6°)
        let lastArc = coords[coords.count - 2]
        let bearingToLast = center.bearing(to: lastArc)
        #expect(bearingToLast >= 80.0)
        #expect(bearingToLast <= 90.0)
    }

    @Test
    func sectorFullCircle() async throws {
        let center = Coordinate3D(latitude: 39.984, longitude: -75.343)
        let sector = try #require(center.sector(radius: 5000.0, bearing1: 0.0, bearing2: 360.0))
        #expect(sector.isValid)

        // A full-circle sector should approximate a circle
        let circle = center.circle(radius: 5000.0)
        let circleArea = try #require(circle?.area)
        let sectorArea = sector.area
        #expect(abs(sectorArea - circleArea) < 1.0)
    }

    @Test
    func sectorZeroRadius() async throws {
        let center = Coordinate3D(latitude: 0.0, longitude: 0.0)
        #expect(center.sector(radius: 0.0, bearing1: 0.0, bearing2: 90.0) == nil)
    }

    @Test
    func sectorInvalidSteps() async throws {
        let center = Coordinate3D(latitude: 0.0, longitude: 0.0)
        #expect(center.sector(radius: 1000.0, bearing1: 0.0, bearing2: 90.0, steps: 1) == nil)
    }

    @Test
    func sectorFromPoint() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let sector = try #require(point.sector(radius: 100_000.0, bearing1: 0.0, bearing2: 90.0))
        #expect(sector.isValid)
    }

    // MARK: - EPSG:3857

    @Test
    func sector3857() async throws {
        let center = Coordinate3D(x: 0.0, y: 0.0)
        let sector = try #require(center.sector(radius: 100_000.0, bearing1: 0.0, bearing2: 90.0))
        #expect(sector.isValid)
    }

    // MARK: - Antimeridian

    @Test
    func sectorAntimeridian() async throws {
        let center = Coordinate3D(latitude: 0.0, longitude: 180.0)
        let sector = try #require(center.sector(radius: 100_000.0, bearing1: 0.0, bearing2: 90.0))
        #expect(sector.isValid)
    }

    @Test
    func sectorAntimeridianNegative() async throws {
        let center = Coordinate3D(latitude: 0.0, longitude: -180.0)
        let sector = try #require(center.sector(radius: 100_000.0, bearing1: 180.0, bearing2: 270.0))
        #expect(sector.isValid)
    }

}
