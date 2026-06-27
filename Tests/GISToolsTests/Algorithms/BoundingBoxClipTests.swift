@testable import GISTools
import Testing

struct BoundingBoxClipTests {

    // Validates clipping a single line segment to a bounding box.
    @Test
    func lineStringSingleLine() async throws {
        let lineString = try TestData.lineString(package: "BoundingBoxClip", name: "SingleLine")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 39.095962936305476, longitude: -77.72552490234374),
            northEast: Coordinate3D(latitude: 39.59722324495565, longitude: -77.0361328125))
        let expected = MultiLineString([
            try TestData.lineString(package: "BoundingBoxClip", name: "SingleLineResult")
        ])

        let clipped = lineString.clipped(to: boundingBox)
        #expect(clipped == expected)
    }

    // Validates clipping a multi-segment line string to a bounding box.
    @Test
    func lineString() async throws {
        let lineString = try TestData.lineString(package: "BoundingBoxClip", name: "LineString")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 36.29741818650811, longitude: -81.551513671875),
            northEast: Coordinate3D(latitude: 39.58875727696545, longitude: -76.475830078125))
        let expected = try TestData.multiLineString(package: "BoundingBoxClip", name: "LineStringResult")

        let clipped = lineString.clipped(to: boundingBox)
        #expect(clipped == expected)
    }

    // Validates clipping a `MultiLineString` to a bounding box.
    @Test
    func multiLineString() async throws {
        let lineString = try TestData.multiLineString(package: "BoundingBoxClip", name: "MultiLineString")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 38.49229419236133, longitude: -78.3929443359375),
            northEast: Coordinate3D(latitude: 39.56758783088905, longitude: -76.9097900390625))
        let expected = try TestData.multiLineString(package: "BoundingBoxClip", name: "MultiLineStringResult")

        let clipped = lineString.clipped(to: boundingBox)
        #expect(clipped == expected)
    }

    // Validates clipping a `MultiPolygon` to a bounding box.
    @Test
    func multiPolygon() async throws {
        let multiPolygon = try TestData.multiPolygon(package: "BoundingBoxClip", name: "MultiPolygon")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 36.2354121683998, longitude: -80.1123046875),
            northEast: Coordinate3D(latitude: 41.22824901518529, longitude: -76.959228515625))
        let expected = try TestData.multiPolygon(package: "BoundingBoxClip", name: "MultiPolygonResult")

        let clipped = multiPolygon.clipped(to: boundingBox)
        #expect(clipped == expected)
    }

    // Validates clipping a polygon with a crossing hole to a bounding box.
    @Test
    func polygonCrossingHole() async throws {
        let polygon = try TestData.polygon(package: "BoundingBoxClip", name: "PolygonCrossingHole")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 36.34167804918315, longitude: -79.12353515625),
            northEast: Coordinate3D(latitude: 39.027718840211605, longitude: -76.739501953125))
        let expected = try TestData.polygon(package: "BoundingBoxClip", name: "PolygonCrossingHoleResult")

        let clipped = polygon.clipped(to: boundingBox)
        #expect(clipped == expected)
    }

    // Validates clipping a polygon with multiple holes to a bounding box.
    @Test
    func polygonHoles() async throws {
        let polygon = try TestData.polygon(package: "BoundingBoxClip", name: "PolygonHoles")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 36.38591277287651, longitude: -79.60693359375),
            northEast: Coordinate3D(latitude: 39.07890809706475, longitude: -76.717529296875))
        let expected = try TestData.polygon(package: "BoundingBoxClip", name: "PolygonHolesResult")

        let clipped = polygon.clipped(to: boundingBox)
        #expect(clipped == expected)
    }

    // Validates that clipping returns nil when the bounding box intersects at only a point (degenerate/invalid).
    @Test
    func polygonPointIntersection() async throws {
        let polygon = try TestData.polygon(package: "BoundingBoxClip", name: "PolygonPointIntersection")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: -31.98, longitude: 115.875),
            northEast: Coordinate3D(latitude: -31.975, longitude: 115.880))

        let clipped = polygon.clipped(to: boundingBox)
        #expect(clipped == nil) // invalid
    }

    // MARK: - Projections

    // Validates clipping in EPSG:3857 projection.
    @Test
    func boundingBoxClip3857() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000_000.0, y: 1_000_000.0),
        ]))
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(x: -100_000.0, y: -100_000.0),
            northEast: Coordinate3D(x: 500_000.0, y: 500_000.0))
        let clipped = lineString.clipped(to: boundingBox)
        #expect(clipped != nil)
    }

    // Validates clipping in noSRID projection.
    @Test
    func boundingBoxClipNoSRID() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000_000.0, y: 1_000_000.0, projection: .noSRID),
        ]))
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(x: -100_000.0, y: -100_000.0, projection: .noSRID),
            northEast: Coordinate3D(x: 500_000.0, y: 500_000.0, projection: .noSRID))
        let clipped = lineString.clipped(to: boundingBox)
        #expect(clipped != nil)
    }

    // Validates clipping in EPSG:4978 projection.
    @Test
    func boundingBoxClip4978() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000_000.0, y: 1_000_000.0, z: 0.0, projection: .epsg4978),
        ]))
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(x: -100_000.0, y: -100_000.0, z: 0.0, projection: .epsg4978),
            northEast: Coordinate3D(x: 500_000.0, y: 500_000.0, z: 0.0, projection: .epsg4978))
        let clipped = lineString.clipped(to: boundingBox)
        #expect(clipped != nil)
    }

    // MARK: - Antimeridian

    // Validates clipping near the antimeridian.
    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 175.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
        ]))
        let bbox = BoundingBox.world
        let clipped = lineString.clipped(to: bbox)
        #expect(clipped != nil)
    }

}
