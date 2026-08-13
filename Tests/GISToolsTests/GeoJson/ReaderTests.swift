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

    // Validates reading a GeoJson object from an in-memory JSON dictionary.
    @Test
    func loadJson() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let someGeoJson = try #require(GeoJsonReader.geoJsonFrom(json: point.asJson))
        let castedPoint = try #require(someGeoJson as? Point)

        #expect(someGeoJson.type == .point)
        #expect(someGeoJson.projection == .epsg4326)
        #expect(castedPoint.asJsonString(prettyPrinted: true) == point.asJsonString(prettyPrinted: true))
    }

    // Validates reading a GeoJson object from a JSON string.
    @Test
    func loadString() async throws {
        let someGeoJson = try #require(GeoJsonReader.geoJsonFrom(jsonString: pointJson))
        let point = try #require(Point(jsonString: pointJson))
        let castedPoint = try #require(someGeoJson as? Point)

        #expect(someGeoJson.type == .point)
        #expect(someGeoJson.projection == .epsg4326)
        #expect(castedPoint.asJsonString(prettyPrinted: true) == point.asJsonString(prettyPrinted: true))
    }

    // MARK: - Geometry auto-detection

    // A PostGIS EWKB LINESTRING with embedded SRID 3857 (Web Mercator).
    private let ewkbLineStringHex = "0102000020110F00000F000000B1AB426CB24C3141FF9A56141D015741AC6335BCD04C31414C475DB321015741ED12DD37F14C3141A108733D240157410B3F0D08104D3141930997E929015741B6607F03364D3141EF0AD7643A0157415F3425CA4C4D31411CA75DBE43015741EE7275C6624D3141BB7F3DBC4A01574143F574298B4D314127F08B8E550157412E207A6FB24D314172BC8B0E59015741DEEDD74ECD4D31412A5F69605801574149F56264EE4D3141B4213FDD540157417E97E4BB044E31414813A5AB54015741383AAE891E4E3141201F4C71580157413CF330C6434E3141D260EB125E015741CEAD8B65734E3141034DA5EF63015741"

    // Validates auto-detecting a WKT string.
    @Test
    func geometryFromWKT() async throws {
        let geometry = try #require(GeoJsonReader.geometryFrom(string: "POINT (11.5 48.1)"))
        let point = try #require(geometry as? Point)
        #expect(point.coordinate.longitude == 11.5)
        #expect(point.coordinate.latitude == 48.1)
    }

    // Validates auto-detecting an SRID-prefixed WKT string.
    @Test
    func geometryFromSRIDWKT() async throws {
        let geometry = try #require(GeoJsonReader.geometryFrom(string: "SRID=4326;POINT (11.5 48.1)"))
        let point = try #require(geometry as? Point)
        #expect(point.coordinate.longitude == 11.5)
        #expect(point.coordinate.latitude == 48.1)
    }

    // Validates auto-detecting a GeoJSON string.
    @Test
    func geometryFromGeoJsonString() async throws {
        let geometry = try #require(GeoJsonReader.geometryFrom(string: pointJson))
        #expect(geometry is Point)
    }

    // Validates auto-detecting an EWKB hex string with an embedded SRID.
    @Test
    func geometryFromEWKBHex() async throws {
        let geometry = try #require(GeoJsonReader.geometryFrom(string: ewkbLineStringHex))
        let lineString = try #require(geometry as? LineString)
        #expect(lineString.coordinates.count == 15)
        #expect(abs(lineString.coordinates[0].longitude - 10.184617401417709) < 0.0000001)
        #expect(abs(lineString.coordinates[0].latitude - 47.53870670004494) < 0.0000001)
    }

    // Validates auto-detecting a plain WKB hex string (no embedded SRID).
    @Test
    func geometryFromPlainWKBHex() async throws {
        // SELECT 'LINESTRING (1 1, 1 2, 1 3, 2 2)'::geometry;
        let hex = "010200000004000000000000000000F03F000000000000F03F000000000000F03F0000000000000040000000000000F03F000000000000084000000000000000400000000000000040"
        let geometry = try #require(GeoJsonReader.geometryFrom(string: hex))
        let lineString = try #require(geometry as? LineString)
        #expect(lineString.coordinates.count == 4)
        #expect(lineString.coordinates[0] == Coordinate3D(latitude: 1, longitude: 1))
    }

    // Validates auto-detecting a TWKB hex string.
    @Test
    func geometryFromTWKBHex() async throws {
        // TWKB Point at (0, 0) with precision 6.
        let hex = "61000000"
        let geometry = try #require(GeoJsonReader.geometryFrom(string: hex))
        #expect(geometry is Point)
    }

    // Validates auto-detecting a WKB data payload.
    @Test
    func geometryFromWKBData() async throws {
        let data = try #require(Data(hex: "0101000000000000000000F03F0000000000000040"))
        let geometry = try #require(GeoJsonReader.geometryFrom(data: data))
        let point = try #require(geometry as? Point)
        #expect(point.coordinate.longitude == 1)
        #expect(point.coordinate.latitude == 2)
    }

    // Validates auto-detecting a TWKB data payload.
    @Test
    func geometryFromTWKBData() async throws {
        let data = Data([0x61, 0x00, 0x00, 0x00])
        let geometry = try #require(GeoJsonReader.geometryFrom(data: data))
        #expect(geometry is Point)
    }

    // Validates auto-detecting a GeoJSON data payload.
    @Test
    func geometryFromGeoJsonData() async throws {
        let data = Data(pointJson.utf8)
        let geometry = try #require(GeoJsonReader.geometryFrom(data: data))
        #expect(geometry is Point)
    }

    // Validates that invalid input returns nil.
    @Test
    func geometryFromInvalid() async throws {
        #expect(GeoJsonReader.geometryFrom(string: "NOT A GEOMETRY") == nil)
        #expect(GeoJsonReader.geometryFrom(string: "") == nil)
        #expect(GeoJsonReader.geometryFrom(data: Data()) == nil)
    }

}
