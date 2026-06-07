@testable import GISTools
import Testing

struct BufferTests {

    @Test
    func bufferedPoint() async throws {
        let point = Point(Coordinate3D(latitude: 47.56, longitude: 10.22))
        let buffered = try #require(point.buffered(by: GISTool.convertToMeters(1000, .meters)))
        let polygon = try #require(buffered.polygons.first)
        let ring = try #require(polygon.outerRing)
        #expect(ring.coordinates.count <= 66)
        #expect(polygon.area > 0)
    }

    @Test
    func bufferedPoints() async throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 47.56, longitude: 10.2),
            Coordinate3D(latitude: 47.56, longitude: 10.25),
        ]))
        let buffered = try #require(multiPoint.buffered(by: GISTool.convertToMeters(1000, .meters)))
        #expect(buffered.polygons.count == 2)
        for polygon in buffered.polygons {
            #expect(polygon.area > 0)
        }
    }

    @Test
    func bufferedLineShort() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 47.56, longitude: 10.2),
            Coordinate3D(latitude: 47.56, longitude: 10.25),
        ]))
        let buffered = try #require(lineString.buffered(by: GISTool.convertToMeters(1000, .meters)))
        #expect(buffered.polygons.count == 1)
        let polygon = try #require(buffered.polygons.first)
        let ring = try #require(polygon.outerRing)
        let coords = ring.coordinates

        // Must be a proper stadium: ~64 vertices, no duplicates, correct area
        #expect(coords.count >= 60)
        for i in 0..<(coords.count - 1) {
            let latDiff = abs(coords[i].latitude - coords[i + 1].latitude)
            let lonDiff = abs(coords[i].longitude - coords[i + 1].longitude)
            #expect(latDiff > 1e-5 || lonDiff > 1e-5, "Near-duplicate consecutive vertices")
        }
        #expect(abs(polygon.area - 10600000) < 600000)
    }

    @Test
    func bufferedLineShortFlatEnds() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 47.56, longitude: 10.2),
            Coordinate3D(latitude: 47.56, longitude: 10.25),
        ]))
        let buffered = try #require(lineString.buffered(by: GISTool.convertToMeters(1000, .meters), lineEndStyle: .flat))
        #expect(buffered.polygons.count == 1)
        let polygon = try #require(buffered.polygons.first)
        #expect(polygon.area > 0)
    }

    @Test
    func bufferedLineLong() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 47.56, longitude: 10.2),
            Coordinate3D(latitude: 47.56, longitude: 10.25),
            Coordinate3D(latitude: 47.60, longitude: 10.25),
            Coordinate3D(latitude: 47.65, longitude: 10.25),
            Coordinate3D(latitude: 47.70, longitude: 10.2),
        ]))
        let buffered = try #require(lineString.buffered(by: GISTool.convertToMeters(1000, .meters)))
        #expect(!buffered.polygons.isEmpty)
        let totalArea = buffered.polygons.reduce(0) { $0 + $1.area }
        #expect(totalArea > 0)
    }

    @Test
    func bufferedLineLongFlatEnds() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 47.56, longitude: 10.2),
            Coordinate3D(latitude: 47.56, longitude: 10.25),
            Coordinate3D(latitude: 47.60, longitude: 10.25),
            Coordinate3D(latitude: 47.65, longitude: 10.25),
            Coordinate3D(latitude: 47.70, longitude: 10.2),
        ]))
        let buffered = try #require(lineString.buffered(by: GISTool.convertToMeters(1000, .meters), lineEndStyle: .flat))
        #expect(!buffered.polygons.isEmpty)
        let totalArea = buffered.polygons.reduce(0) { $0 + $1.area }
        #expect(totalArea > 0)
    }

    @Test
    func bufferedLines() async throws {
        let multiLineString = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 47.56, longitude: 10.2),
                Coordinate3D(latitude: 47.56, longitude: 10.25),
            ],
            [
                Coordinate3D(latitude: 47.60, longitude: 10.25),
                Coordinate3D(latitude: 47.65, longitude: 10.25),
                Coordinate3D(latitude: 47.70, longitude: 10.2),
            ],
        ]))
        let buffered = try #require(multiLineString.buffered(by: GISTool.convertToMeters(1000, .meters)))
        #expect(buffered.polygons.count == 2)
        for polygon in buffered.polygons {
            #expect(polygon.area > 0)
        }
    }

    @Test
    func bufferedLinesFlatEnds() async throws {
        let multiLineString = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 47.56, longitude: 10.2),
                Coordinate3D(latitude: 47.56, longitude: 10.25),
            ],
            [
                Coordinate3D(latitude: 47.60, longitude: 10.25),
                Coordinate3D(latitude: 47.65, longitude: 10.25),
                Coordinate3D(latitude: 47.70, longitude: 10.2),
            ],
        ]))
        let buffered = try #require(multiLineString.buffered(by: GISTool.convertToMeters(1000, .meters), lineEndStyle: .flat))
        #expect(buffered.polygons.count == 2)
        for polygon in buffered.polygons {
            #expect(polygon.area > 0)
        }
    }

    @Test
    func bufferedPolygon() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 47.5, longitude: 10.2),
                Coordinate3D(latitude: 47.5, longitude: 10.25),
                Coordinate3D(latitude: 47.6, longitude: 10.35),
                Coordinate3D(latitude: 47.7, longitude: 10.25),
                Coordinate3D(latitude: 47.6, longitude: 10.15),
                Coordinate3D(latitude: 47.5, longitude: 10.2),
            ],
            [
                Coordinate3D(latitude: 47.52, longitude: 10.25),
                Coordinate3D(latitude: 47.56, longitude: 10.30),
                Coordinate3D(latitude: 47.65, longitude: 10.23),
                Coordinate3D(latitude: 47.6, longitude: 10.22),
                Coordinate3D(latitude: 47.52, longitude: 10.25),
            ],
        ]))
        let buffered = try #require(polygon.buffered(by: GISTool.convertToMeters(1000, .meters)))
        #expect(!buffered.polygons.isEmpty)
        #expect(buffered.polygons.first!.outerRing != nil)
    }

    @Test
    func bufferedMultiPolygon() async throws {
        let multiPolygon = try #require(MultiPolygon([
            Polygon([
                [
                    Coordinate3D(latitude: 47.5, longitude: 10.2),
                    Coordinate3D(latitude: 47.5, longitude: 10.25),
                    Coordinate3D(latitude: 47.6, longitude: 10.35),
                    Coordinate3D(latitude: 47.7, longitude: 10.25),
                    Coordinate3D(latitude: 47.6, longitude: 10.15),
                    Coordinate3D(latitude: 47.5, longitude: 10.2),
                ],
                [
                    Coordinate3D(latitude: 47.52, longitude: 10.25),
                    Coordinate3D(latitude: 47.56, longitude: 10.30),
                    Coordinate3D(latitude: 47.65, longitude: 10.23),
                    Coordinate3D(latitude: 47.6, longitude: 10.22),
                    Coordinate3D(latitude: 47.52, longitude: 10.25),
                ],
            ])!,
            Polygon([[
                Coordinate3D(latitude: 47.56, longitude: 10.1),
                Coordinate3D(latitude: 47.56, longitude: 10.15),
                Coordinate3D(latitude: 47.60, longitude: 10.15),
                Coordinate3D(latitude: 47.65, longitude: 10.15),
                Coordinate3D(latitude: 47.70, longitude: 10.1),
                Coordinate3D(latitude: 47.56, longitude: 10.1),
            ]])!,
        ]))
        let buffered = try #require(multiPolygon.buffered(by: GISTool.convertToMeters(1000, .meters)))
        #expect(!buffered.polygons.isEmpty)
        #expect(buffered.polygons.first!.area > 0)
    }

}
