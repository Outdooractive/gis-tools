import Foundation
@testable import GISTools
import Testing

struct ReaderTests {

    private let pointJson = """
    {
        "type": "Point",
        "coordinates": [100.0, 0.0],
        "other": "something else"
    }
    """

    @Test
    func loadJson() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let someGeoJson = try #require(GeoJsonReader.geoJsonFrom(json: point.asJson))
        let castedPoint = try #require(someGeoJson as? Point)

        #expect(someGeoJson.type == .point)
        #expect(someGeoJson.projection == .epsg4326)
        #expect(castedPoint.asJsonString(prettyPrinted: true) == point.asJsonString(prettyPrinted: true))
    }

    @Test
    func loadString() async throws {
        let someGeoJson = try #require(GeoJsonReader.geoJsonFrom(jsonString: pointJson))
        let point = try #require(Point(jsonString: pointJson))
        let castedPoint = try #require(someGeoJson as? Point)

        #expect(someGeoJson.type == .point)
        #expect(someGeoJson.projection == .epsg4326)
        #expect(castedPoint.asJsonString(prettyPrinted: true) == point.asJsonString(prettyPrinted: true))
    }

}
