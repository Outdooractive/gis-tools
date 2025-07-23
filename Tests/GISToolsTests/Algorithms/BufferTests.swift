@testable import GISTools
import Testing

struct BufferTests {

    @Test()
    func bufferedPoint() async throws {
        let point = Point(Coordinate3D(latitude: 47.56, longitude: 10.22))
        let buffered = point.buffered(by: 1000.meters)

        buffered?.dump()
    }

    @Test()
    func bufferedPoints() async throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 47.56, longitude: 10.2),
            Coordinate3D(latitude: 47.56, longitude: 10.25),
        ]))
        let buffered = multiPoint.buffered(by: 1000.meters)

        buffered?.dump()
    }

    @Test()
    func bufferedLineShort() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 47.56, longitude: 10.2),
            Coordinate3D(latitude: 47.56, longitude: 10.25),
        ]))
        let buffered = lineString.buffered(by: 1000.meters)
        
        buffered?.dump()
    }

    @Test()
    func bufferedLineShortFlatEnds() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 47.56, longitude: 10.2),
            Coordinate3D(latitude: 47.56, longitude: 10.25),
        ]))
        let buffered = lineString.buffered(by: 1000.meters, lineEndStyle: .flat)

        buffered?.dump()
    }

    @Test()
    func bufferedLineLong() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 47.56, longitude: 10.2),
            Coordinate3D(latitude: 47.56, longitude: 10.25),
            Coordinate3D(latitude: 47.60, longitude: 10.25),
            Coordinate3D(latitude: 47.65, longitude: 10.25),
            Coordinate3D(latitude: 47.70, longitude: 10.2),
        ]))
        let buffered = lineString.buffered(by: 1000.meters)

        buffered?.dump()
    }

    @Test()
    func bufferedLineLongFlatEnds() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 47.56, longitude: 10.2),
            Coordinate3D(latitude: 47.56, longitude: 10.25),
            Coordinate3D(latitude: 47.60, longitude: 10.25),
            Coordinate3D(latitude: 47.65, longitude: 10.25),
            Coordinate3D(latitude: 47.70, longitude: 10.2),
        ]))
        let buffered = lineString.buffered(by: 1000.meters, lineEndStyle: .flat)

        buffered?.dump()
    }

    @Test()
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
        let buffered = multiLineString.buffered(by: 1000.meters)
        
        buffered?.dump()
    }

    @Test()
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
        let buffered = multiLineString.buffered(by: 1000.meters, lineEndStyle: .flat)

        buffered?.dump()
    }

    @Test()
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
        let buffered = polygon.buffered(by: 1000.meters)

        buffered?.dump()
    }


}
