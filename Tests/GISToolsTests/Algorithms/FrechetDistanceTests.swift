#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import GISTools
import Testing

struct FrechetDistanceTests {

    // Validates Frechet distance between two arcs in EPSG:4326 using haversine and rhumb line distance functions.
    @Test
    func frechetDistance4326() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let lineArc1 = try #require(point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0))
        let lineArc2 = try #require(point.lineArc(radius: 6000.0, bearing1: 20.0, bearing2: 60.0))

        let distanceHaversine = lineArc1.frechetDistance(from: lineArc2, distanceFunction: .haversine)
        let distanceRhumbLine = lineArc1.frechetDistance(from: lineArc2, distanceFunction: .rhumbLine)

        #expect(abs(distanceHaversine - 1000.0) < 0.0001)
        #expect(abs(distanceRhumbLine - 1000.0) < 0.0001)
    }

    // Validates Frechet distance between two arcs in EPSG:3857 using the Euclidean distance function.
    @Test
    func frechetDistance3857() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0)).projected(to: .epsg3857)
        let lineArc1 = try #require(point.lineArc(radius: 5000.0, bearing1: 20.0, bearing2: 60.0))
        let lineArc2 = try #require(point.lineArc(radius: 6000.0, bearing1: 20.0, bearing2: 60.0))

        let distanceEucliden = lineArc1.frechetDistance(from: lineArc2, distanceFunction: .euclidean)
        #expect(abs(distanceEucliden - 1000.0) < 2.0)
    }

}
